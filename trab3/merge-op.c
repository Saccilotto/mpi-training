#include <stdio.h>
#include <stdlib.h>
#include <mpi.h>

// Descomente para prints detalhados
// #define DEBUG 1

// ===================================================
// MERGE SORT SEQUENCIAL COM BUFFER AUXILIAR REUTILIZADO
// ===================================================

void merge_sort_rec(int *arr, int *aux, int left, int right) {
    if (left >= right) return;

    int mid = left + (right - left) / 2;

    merge_sort_rec(arr, aux, left, mid);
    merge_sort_rec(arr, aux, mid + 1, right);

    int i = left;
    int j = mid + 1;
    int k = left;

    while (i <= mid && j <= right) {
        if (arr[i] <= arr[j]) {
            aux[k++] = arr[i++];
        } else {
            aux[k++] = arr[j++];
        }
    }

    while (i <= mid) {
        aux[k++] = arr[i++];
    }

    while (j <= right) {
        aux[k++] = arr[j++];
    }

    for (i = left; i <= right; i++) {
        arr[i] = aux[i];
    }
}

void merge_sort(int *arr, int *aux, int n) {
    if (n > 1) {
        merge_sort_rec(arr, aux, 0, n - 1);
    }
}

// ===================================================
// CÓDIGO PRINCIPAL COM MPI
// ===================================================

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

    // Leitura do tamanho do vetor
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

    // Tamanho local e alocação
    local_size = array_size / size;
    local_array = (int*)malloc(local_size * sizeof(int));
    if (!local_array) {
        fprintf(stderr, "Rank %d: erro ao alocar local_array\n", rank);
        MPI_Abort(MPI_COMM_WORLD, 1);
    }

    // Geração dos dados: sequência decrescente global
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

    // Buffer auxiliar único para mergesort (reutilizado)
    int *aux = (int*)malloc(local_size * sizeof(int));
    if (!aux) {
        fprintf(stderr, "Rank %d: erro ao alocar aux\n", rank);
        MPI_Abort(MPI_COMM_WORLD, 1);
    }

    // Buffers para trocas entre vizinhos (reutilizados)
    int num_troca = local_size / 2;
    int *buffer_envio = (int*)malloc(num_troca * sizeof(int));
    int *buffer_recebe = (int*)malloc(num_troca * sizeof(int));
    int *temp = (int*)malloc(local_size * sizeof(int));

    if (!buffer_envio || !buffer_recebe || !temp) {
        fprintf(stderr, "Rank %d: erro ao alocar buffers de troca\n", rank);
        MPI_Abort(MPI_COMM_WORLD, 1);
    }

    MPI_Barrier(MPI_COMM_WORLD);
    if (rank == 0) {
        start_time = MPI_Wtime();
    }

    // ====================================
    // LOOP PRINCIPAL - FASES PARALELAS
    // ====================================
    while (!ordenado_global) {
        iteracao++;

        // --------------------------
        // FASE 1: ORDENAR LOCALMENTE
        // --------------------------
        merge_sort(local_array, aux, local_size);

        // --------------------------
        // FASE 2: VERIFICAÇÃO GLOBAL
        // --------------------------
        ordenado_local = 1;

        // Envia maior para direita e recebe menor da direita
        if (rank < size - 1) {
            int meu_maior = local_array[local_size - 1];
            int menor_direita;

            MPI_Send(&meu_maior, 1, MPI_INT, rank + 1, 0, MPI_COMM_WORLD);
            MPI_Recv(&menor_direita, 1, MPI_INT, rank + 1, 1, MPI_COMM_WORLD, MPI_STATUS_IGNORE);

            if (meu_maior > menor_direita) {
                ordenado_local = 0;
            }
        }

        // Recebe maior da esquerda e envia menor para esquerda
        if (rank > 0) {
            int maior_esquerda;
            int meu_menor = local_array[0];

            MPI_Recv(&maior_esquerda, 1, MPI_INT, rank - 1, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
            MPI_Send(&meu_menor, 1, MPI_INT, rank - 1, 1, MPI_COMM_WORLD);
        }

        MPI_Allreduce(&ordenado_local, &ordenado_global, 1, MPI_INT, MPI_LAND, MPI_COMM_WORLD);

        if (ordenado_global) {
            break;
        }

        // --------------------------
        // FASE 3: TROCA DE ELEMENTOS ENTRE VIZINHOS
        // --------------------------

        // Troca com vizinho da direita (rank < size-1)
        if (rank < size - 1) {
            // Copia metade superior local para envio
            for (i = 0; i < num_troca; i++) {
                buffer_envio[i] = local_array[local_size - num_troca + i];
            }

            // Troca com vizinho da direita
            MPI_Sendrecv(buffer_envio, num_troca, MPI_INT, rank + 1, 2,
                         buffer_recebe, num_troca, MPI_INT, rank + 1, 3,
                         MPI_COMM_WORLD, MPI_STATUS_IGNORE);

            // Monta vetor temp: metade inferior local + recebidos
            int idx_temp = 0;
            for (i = 0; i < num_troca; i++) {
                temp[idx_temp++] = local_array[i];
            }
            for (i = 0; i < num_troca; i++) {
                temp[idx_temp++] = buffer_recebe[i];
            }

            // Ordena temp e mantém os menores localmente
            merge_sort(temp, aux, local_size);
            for (i = 0; i < local_size; i++) {
                local_array[i] = temp[i];
            }
        }

        // Troca com vizinho da esquerda (rank > 0)
        if (rank > 0) {
            // Copia metade inferior local para envio
            for (i = 0; i < num_troca; i++) {
                buffer_envio[i] = local_array[i];
            }

            // Troca com vizinho da esquerda
            MPI_Sendrecv(buffer_envio, num_troca, MPI_INT, rank - 1, 3,
                         buffer_recebe, num_troca, MPI_INT, rank - 1, 2,
                         MPI_COMM_WORLD, MPI_STATUS_IGNORE);

            // Monta vetor temp: recebidos + metade superior local
            int idx_temp = 0;
            for (i = 0; i < num_troca; i++) {
                temp[idx_temp++] = buffer_recebe[i];
            }
            for (i = num_troca; i < local_size; i++) {
                temp[idx_temp++] = local_array[i];
            }

            // Ordena temp e mantém os maiores localmente
            merge_sort(temp, aux, local_size);
            for (i = 0; i < local_size; i++) {
                local_array[i] = temp[i];
            }
        }
    }

    MPI_Barrier(MPI_COMM_WORLD);
    if (rank == 0) {
        end_time = MPI_Wtime();
        printf("\nOrdenação concluída!\n");
        printf("Iterações: %d\n", iteracao);
        printf("Tempo total: %.6f segundos\n", end_time - start_time);
    }

#ifdef DEBUG
    // Impressão resumida de cada rank
    MPI_Barrier(MPI_COMM_WORLD);
    for (int r = 0; r < size; r++) {
        if (rank == r) {
            printf("\n=== RANK %d ===\n", rank);
            printf("Primeiro valor: %d\n", local_array[0]);
            printf("Último valor: %d\n", local_array[local_size - 1]);
        }
        MPI_Barrier(MPI_COMM_WORLD);
    }
#endif

    // Verificação simples (apenas local + vizinho direito)
    int verificacao_local = 1;

    // Verifica ordenação local
    for (i = 0; i < local_size - 1; i++) {
        if (local_array[i] > local_array[i + 1]) {
            verificacao_local = 0;
            break;
        }
    }

    // Verifica fronteira com vizinho da direita
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

    int verificacao_global = 0;
    MPI_Reduce(&verificacao_local, &verificacao_global, 1, MPI_INT, MPI_LAND, 0, MPI_COMM_WORLD);

    if (rank == 0) {
        if (verificacao_global) {
            printf("✓ Vetor ORDENADO corretamente!\n");
        } else {
            printf("✗ ERRO: Vetor NÃO está ordenado!\n");
        }
    }

    // Liberação de memória
    free(local_array);
    free(aux);
    free(buffer_envio);
    free(buffer_recebe);
    free(temp);

    MPI_Finalize();
    return 0;
}

