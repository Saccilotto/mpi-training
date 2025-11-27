#include <stdio.h>
#include <stdlib.h>
#include <mpi.h>

//#define DEBUG 1            // comentar para medições de tempo

// Função Bubble Sort local
void bs(int n, int *vetor) {
    int c = 0, d, troca, trocou = 1;
    
    while (c < (n-1) && trocou) {
        trocou = 0;
        for (d = 0; d < n - c - 1; d++) {
            if (vetor[d] > vetor[d+1]) {
                troca = vetor[d];
                vetor[d] = vetor[d+1];
                vetor[d+1] = troca;
                trocou = 1;
            }
        }
        c++;
    }
}

int main(int argc, char *argv[]) {
    int rank, size;
    int local_size;
    int *local_array;
    int i, iteracao = 0;
    int ordenado_global = 0;
    int ordenado_local;
    int array_size;
    double start_time, end_time;
    
    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);
    
    // Lê o tamanho do vetor da linha de comando
    if (argc < 2) {
        if (rank == 0) {
            printf("Uso: %s <tamanho_do_vetor>\n", argv[0]);
            printf("Exemplo: %s 1000000\n", argv[0]);
        }
        MPI_Finalize();
        return 1;
    }
    
    array_size = atoi(argv[1]);
    
    if (array_size <= 0 || array_size % size != 0) {
        if (rank == 0) {
            printf("Erro: O tamanho do vetor deve ser positivo e divisível pelo número de processos (%d)\n", size);
        }
        MPI_Finalize();
        return 1;
    }
    
    // Calcula tamanho local de cada processo
    local_size = array_size / size;
    local_array = (int*)malloc(local_size * sizeof(int));
    
    // Cada processo gera sua parte do vetor (ordem decrescente)
    int offset = rank * local_size;
    for (i = 0; i < local_size; i++) {
        local_array[i] = array_size - (offset + i);
    }
    
    #ifdef DEBUG
    if (rank == 0) {
        printf("Iniciando ordenação paralela com %d processos\n", size);
        printf("Tamanho total: %d, Tamanho local: %d\n\n", array_size, local_size);
    }
    #endif
    
    MPI_Barrier(MPI_COMM_WORLD);
    if (rank == 0) {
        start_time = MPI_Wtime();
    }
    
    // FASES PARALELAS
    while (!ordenado_global) {
        iteracao++;
        
        // FASE 1: Ordenação local
        bs(local_size, local_array);
        
        // FASE 2: Verificação distribuída
        ordenado_local = 1;
        
        // Cada processo (exceto o último) envia seu maior valor para o vizinho da direita
        if (rank < size - 1) {
            int meu_maior = local_array[local_size - 1];
            int menor_direita;
            
            MPI_Send(&meu_maior, 1, MPI_INT, rank + 1, 0, MPI_COMM_WORLD);
            MPI_Recv(&menor_direita, 1, MPI_INT, rank + 1, 1, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
            
            // Verifica se está ordenado em relação ao vizinho da direita
            if (meu_maior > menor_direita) {
                ordenado_local = 0;
            }
        }
        
        // Cada processo (exceto o primeiro) recebe o maior valor do vizinho da esquerda
        if (rank > 0) {
            int maior_esquerda;
            int meu_menor = local_array[0];
            
            MPI_Recv(&maior_esquerda, 1, MPI_INT, rank - 1, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
            MPI_Send(&meu_menor, 1, MPI_INT, rank - 1, 1, MPI_COMM_WORLD);
        }
        
        // Redução para verificar se todos estão ordenados
        MPI_Allreduce(&ordenado_local, &ordenado_global, 1, MPI_INT, MPI_LAND, MPI_COMM_WORLD);
        
        if (ordenado_global) {
            break;
        }
        
        // FASE 3: Troca de valores entre vizinhos
        if (rank < size - 1) {
            // Processo envia metade superior para o vizinho da direita
            int num_troca = local_size / 2;
            int *buffer_envio = (int*)malloc(num_troca * sizeof(int));
            int *buffer_recebe = (int*)malloc(num_troca * sizeof(int));
            
            // Copia metade superior
            for (i = 0; i < num_troca; i++) {
                buffer_envio[i] = local_array[local_size - num_troca + i];
            }
            
            // Troca com vizinho da direita
            MPI_Sendrecv(buffer_envio, num_troca, MPI_INT, rank + 1, 2,
                        buffer_recebe, num_troca, MPI_INT, rank + 1, 3,
                        MPI_COMM_WORLD, MPI_STATUS_IGNORE);
            
            // Combina valores recebidos com metade inferior
            int *temp = (int*)malloc(local_size * sizeof(int));
            int idx_temp = 0;
            
            // Copia metade inferior
            for (i = 0; i < num_troca; i++) {
                temp[idx_temp++] = local_array[i];
            }
            
            // Adiciona valores recebidos
            for (i = 0; i < num_troca; i++) {
                temp[idx_temp++] = buffer_recebe[i];
            }
            
            // Ordena e mantém os menores
            bs(local_size, temp);
            for (i = 0; i < local_size; i++) {
                local_array[i] = temp[i];
            }
            
            free(buffer_envio);
            free(buffer_recebe);
            free(temp);
        }
        
        if (rank > 0) {
            // Processo envia metade inferior para o vizinho da esquerda
            int num_troca = local_size / 2;
            int *buffer_envio = (int*)malloc(num_troca * sizeof(int));
            int *buffer_recebe = (int*)malloc(num_troca * sizeof(int));
            
            // Copia metade inferior
            for (i = 0; i < num_troca; i++) {
                buffer_envio[i] = local_array[i];
            }
            
            // Troca com vizinho da esquerda
            MPI_Sendrecv(buffer_envio, num_troca, MPI_INT, rank - 1, 3,
                        buffer_recebe, num_troca, MPI_INT, rank - 1, 2,
                        MPI_COMM_WORLD, MPI_STATUS_IGNORE);
            
            // Combina valores recebidos com metade superior
            int *temp = (int*)malloc(local_size * sizeof(int));
            int idx_temp = 0;
            
            // Adiciona valores recebidos
            for (i = 0; i < num_troca; i++) {
                temp[idx_temp++] = buffer_recebe[i];
            }
            
            // Copia metade superior
            for (i = num_troca; i < local_size; i++) {
                temp[idx_temp++] = local_array[i];
            }
            
            // Ordena e mantém os maiores
            bs(local_size, temp);
            for (i = 0; i < local_size; i++) {
                local_array[i] = temp[i];
            }
            
            free(buffer_envio);
            free(buffer_recebe);
            free(temp);
        }
    }
    
    MPI_Barrier(MPI_COMM_WORLD);
    if (rank == 0) {
        end_time = MPI_Wtime();
        printf("\nOrdenação concluída!\n");
        printf("Iterações: %d\n", iteracao);
        printf("Tempo total: %.6f segundos\n", end_time - start_time);
    }
    
    // IMPRESSÃO DOS RESULTADOS DE CADA RANK
    MPI_Barrier(MPI_COMM_WORLD);
    
    // Cada processo imprime seus valores em ordem
    for (int r = 0; r < size; r++) {
        if (rank == r) {
            printf("\n=== RANK %d ===\n", rank);
            printf("Faixa: [%d - %d]\n", rank * local_size + 1, (rank + 1) * local_size);
            printf("Primeiro valor: %d\n", local_array[0]);
            printf("Último valor: %d\n", local_array[local_size - 1]);
            
            // Imprime primeiros e últimos 5 valores
            printf("Primeiros 5: ");
            for (i = 0; i < 5 && i < local_size; i++) {
                printf("%d ", local_array[i]);
            }
            printf("\nÚltimos 5: ");
            for (i = (local_size - 5 > 0 ? local_size - 5 : 0); i < local_size; i++) {
                printf("%d ", local_array[i]);
            }
            printf("\n");
            fflush(stdout);
        }
        MPI_Barrier(MPI_COMM_WORLD);
    }
    
    // Verificação final de ordenação
    if (rank == 0) {
        printf("\n=== VERIFICAÇÃO DE ORDENAÇÃO ===\n");
    }
    
    int verificacao_local = 1;
    // Verifica ordenação local
    for (i = 0; i < local_size - 1; i++) {
        if (local_array[i] > local_array[i + 1]) {
            verificacao_local = 0;
            break;
        }
    }
    
    // Verifica com vizinho da direita
    if (rank < size - 1 && verificacao_local) {
        int meu_max = local_array[local_size - 1];
        int vizinho_min;
        MPI_Send(&meu_max, 1, MPI_INT, rank + 1, 99, MPI_COMM_WORLD);
        MPI_Recv(&vizinho_min, 1, MPI_INT, rank + 1, 100, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
        if (meu_max > vizinho_min) {
            verificacao_local = 0;
        }
    }
    
    if (rank > 0 && verificacao_local) {
        int meu_min = local_array[0];
        int vizinho_max;
        MPI_Recv(&vizinho_max, 1, MPI_INT, rank - 1, 99, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
        MPI_Send(&meu_min, 1, MPI_INT, rank - 1, 100, MPI_COMM_WORLD);
    }
    
    int verificacao_global;
    MPI_Reduce(&verificacao_local, &verificacao_global, 1, MPI_INT, MPI_LAND, 0, MPI_COMM_WORLD);
    
    if (rank == 0) {
        if (verificacao_global) {
            printf("✓ Vetor ORDENADO corretamente!\n");
        } else {
            printf("✗ ERRO: Vetor NÃO está ordenado!\n");
        }
    }
    
    #ifdef DEBUG
    // Coleta e imprime resultado (apenas para debug com vetores pequenos)
    if (rank == 0) {
        int *vetor_completo = (int*)malloc(array_size * sizeof(int));
        MPI_Gather(local_array, local_size, MPI_INT,
                  vetor_completo, local_size, MPI_INT, 0, MPI_COMM_WORLD);
        
        printf("\nVetor ordenado (primeiros 20): ");
        for (i = 0; i < 20 && i < array_size; i++) {
            printf("%d ", vetor_completo[i]);
        }
        printf("\n");
        free(vetor_completo);
    } else {
        MPI_Gather(local_array, local_size, MPI_INT, NULL, 0, MPI_INT, 0, MPI_COMM_WORLD);
    }
    #endif
    
    free(local_array);
    MPI_Finalize();
    
    return 0;
}
