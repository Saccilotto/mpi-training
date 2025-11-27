#include <stdio.h>
#include <stdlib.h>
#include <mpi.h>

void local_sort(int *v, int n) {
    // Bubble sort local
    int trocou = 1;
    while (trocou) {
        trocou = 0;
        for (int i = 0; i < n - 1; i++) {
            if (v[i] > v[i+1]) {
                int tmp = v[i];
                v[i] = v[i+1];
                v[i+1] = tmp;
                trocou = 1;
            }
        }
    }
}

void compare_split(int *local, int local_n, int *recv, int keep_small) {
    // Junta os dois blocos
    int *buffer = malloc(2 * local_n * sizeof(int));
    for (int i = 0; i < local_n; i++) buffer[i] = local[i];
    for (int i = 0; i < local_n; i++) buffer[i + local_n] = recv[i];
    
    // Ordena o bloco combinado
    for (int i = 0; i < 2 * local_n - 1; i++)
        for (int j = 0; j < 2 * local_n - 1 - i; j++)
            if (buffer[j] > buffer[j+1]) {
                int tmp = buffer[j];
                buffer[j] = buffer[j+1];
                buffer[j+1] = tmp;
            }
    
    // Mantém os menores ou os maiores
    if (keep_small)
        for (int i = 0; i < local_n; i++) local[i] = buffer[i];
    else
        for (int i = 0; i < local_n; i++) local[i] = buffer[i + local_n];
    
    free(buffer);
}

int main(int argc, char **argv) {
    int rank, np;
    double start_time, end_time;
    
    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &np);
    
    if (argc < 2) {
        if (rank == 0) {
            printf("Uso: %s <tamanho_do_vetor>\n", argv[0]);
            printf("Exemplo: %s 1000000\n", argv[0]);
        }
        MPI_Finalize();
        return 1;
    }
    
    int N = atoi(argv[1]);
    
    if (N <= 0 || N % np != 0) {
        if (rank == 0) {
            printf("Erro: O tamanho do vetor deve ser positivo e divisível pelo número de processos (%d)\n", np);
        }
        MPI_Finalize();
        return 1;
    }
    
    int local_n = N / np;
    int *local = malloc(local_n * sizeof(int));
    
    // Inicializa com valores decrescentes (pior caso)
    for (int i = 0; i < local_n; i++)
        local[i] = N - (rank * local_n + i);
    
    MPI_Barrier(MPI_COMM_WORLD);
    if (rank == 0) {
        start_time = MPI_Wtime();
    }
    
    // Ordena localmente
    local_sort(local, local_n);
    
    int *recv = malloc(local_n * sizeof(int));
    
    // Faz np iterações (garante convergência)
    for (int iter = 0; iter < np; iter++) {
        // Fase PAR
        if (iter % 2 == 0) {
            if (rank % 2 == 0 && rank + 1 < np) {
                MPI_Send(local, local_n, MPI_INT, rank + 1, 0, MPI_COMM_WORLD);
                MPI_Recv(recv, local_n, MPI_INT, rank + 1, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
                compare_split(local, local_n, recv, 1);
            }
            else if (rank % 2 == 1) {
                MPI_Recv(recv, local_n, MPI_INT, rank - 1, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
                MPI_Send(local, local_n, MPI_INT, rank - 1, 0, MPI_COMM_WORLD);
                compare_split(local, local_n, recv, 0);
            }
        }
        // Fase ÍMPAR
        else {
            if (rank % 2 == 1 && rank + 1 < np) {
                MPI_Send(local, local_n, MPI_INT, rank + 1, 1, MPI_COMM_WORLD);
                MPI_Recv(recv, local_n, MPI_INT, rank + 1, 1, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
                compare_split(local, local_n, recv, 1);
            }
            else if (rank % 2 == 0 && rank > 0) {
                MPI_Recv(recv, local_n, MPI_INT, rank - 1, 1, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
                MPI_Send(local, local_n, MPI_INT, rank - 1, 1, MPI_COMM_WORLD);
                compare_split(local, local_n, recv, 0);
            }
        }
        MPI_Barrier(MPI_COMM_WORLD);
    }
    
    MPI_Barrier(MPI_COMM_WORLD);
    if (rank == 0) {
        end_time = MPI_Wtime();
        printf("\nOrdenação concluída!\n");
        printf("Iterações: %d\n", np);
        printf("Tempo total: %.6f segundos\n", end_time - start_time);
    }
    
    // IMPRESSÃO DOS RESULTADOS DE CADA RANK
    MPI_Barrier(MPI_COMM_WORLD);
    
    // Cada processo imprime seus valores em ordem
    for (int r = 0; r < np; r++) {
        if (rank == r) {
            printf("\n=== RANK %d ===\n", rank);
            printf("Faixa: [%d - %d]\n", rank * local_n + 1, (rank + 1) * local_n);
            printf("Primeiro valor: %d\n", local[0]);
            printf("Último valor: %d\n", local[local_n - 1]);
            
            // Imprime primeiros e últimos 5 valores
            printf("Primeiros 5: ");
            for (int i = 0; i < 5 && i < local_n; i++) {
                printf("%d ", local[i]);
            }
            printf("\nÚltimos 5: ");
            for (int i = (local_n - 5 > 0 ? local_n - 5 : 0); i < local_n; i++) {
                printf("%d ", local[i]);
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
    for (int i = 0; i < local_n - 1; i++) {
        if (local[i] > local[i + 1]) {
            verificacao_local = 0;
            break;
        }
    }
    
    // Verifica com vizinho da direita
    if (rank < np - 1 && verificacao_local) {
        int meu_max = local[local_n - 1];
        int vizinho_min;
        MPI_Send(&meu_max, 1, MPI_INT, rank + 1, 99, MPI_COMM_WORLD);
        MPI_Recv(&vizinho_min, 1, MPI_INT, rank + 1, 100, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
        if (meu_max > vizinho_min) {
            verificacao_local = 0;
        }
    }
    
    if (rank > 0 && verificacao_local) {
        int meu_min = local[0];
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
    
    free(recv);
    free(local);
    MPI_Finalize();
    
    return 0;
}
