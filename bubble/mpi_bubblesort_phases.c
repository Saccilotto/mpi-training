/*
 * Bubble Sort Paralelo usando MPI - Modelo de Fases Paralelas
 *
 * Este programa implementa o algoritmo Bubble Sort paralelo seguindo
 * o modelo de fases paralelas:
 *
 * 1. Cada processo eh responsavel por 1/np do vetor global
 * 2. Fase 1: Ordenacao local usando Bubble Sort
 * 3. Fase 2: Verificacao distribuida se o vetor global esta ordenado
 * 4. Fase 3: Se nao estiver ordenado, troca valores entre vizinhos
 * 5. Repete ate o vetor global estar ordenado
 */

#include <stdio.h>
#include <stdlib.h>
#include <mpi.h>

#ifndef DEBUG
#define DEBUG 0            // comentar esta linha quando for medir tempo
#endif

#ifndef ARRAY_SIZE
#define ARRAY_SIZE 1000000  // tamanho do vetor global
#endif

/* Funcao Bubble Sort - ordena um vetor localmente */
void bs(int n, int *vetor)
{
    int c = 0, d, troca, trocou = 1;

    while (c < n - 1 && trocou) {
        trocou = 0;
        for (d = 0; d < n - c - 1; d++) {
            if (vetor[d] > vetor[d + 1]) {
                troca = vetor[d];
                vetor[d] = vetor[d + 1];
                vetor[d + 1] = troca;
                trocou = 1;
            }
        }
        c++;
    }
}

/* Funcao para intercalar e separar valores entre processos vizinhos */
void merge_and_split(int *local_array, int local_size, int *received_array, int keep_low)
{
    int *temp_array = (int *)malloc(sizeof(int) * local_size * 2);
    int i = 0, j = 0, k = 0;
    int total_size = local_size * 2;

    /* Intercala os dois vetores ordenados */
    while (i < local_size && j < local_size) {
        if (local_array[i] <= received_array[j]) {
            temp_array[k++] = local_array[i++];
        } else {
            temp_array[k++] = received_array[j++];
        }
    }

    /* Copia elementos restantes */
    while (i < local_size) {
        temp_array[k++] = local_array[i++];
    }
    while (j < local_size) {
        temp_array[k++] = received_array[j++];
    }

    /* Mantem a metade apropriada */
    if (keep_low) {
        /* Mantem os menores valores (metade inferior) */
        for (i = 0; i < local_size; i++) {
            local_array[i] = temp_array[i];
        }
        /* Devolve os maiores valores (metade superior) */
        for (i = 0; i < local_size; i++) {
            received_array[i] = temp_array[local_size + i];
        }
    } else {
        /* Mantem os maiores valores (metade superior) */
        for (i = 0; i < local_size; i++) {
            local_array[i] = temp_array[local_size + i];
        }
        /* Devolve os menores valores (metade inferior) */
        for (i = 0; i < local_size; i++) {
            received_array[i] = temp_array[i];
        }
    }

    free(temp_array);
}

int main(int argc, char **argv)
{
    int rank, size;
    int array_size = ARRAY_SIZE;
    int g_debug = DEBUG;
    int local_size;
    int *local_array;
    int pronto = 0;
    int iteracoes = 0;
    double start_time, end_time;

    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    /* Processo 0 processa argumentos */
    if (rank == 0) {
        if (argc > 1) {
            array_size = atoi(argv[1]);
        }
        if (argc > 2) {
            g_debug = atoi(argv[2]);
        }

        printf("\n========== BUBBLE SORT PARALELO - FASES PARALELAS ==========\n");
        printf("Processos: %d\n", size);
        printf("Tamanho do vetor: %d\n", array_size);
        printf("Debug: %s\n\n", g_debug ? "ON" : "OFF");

        /* Verifica se o tamanho eh divisivel pelo numero de processos */
        if (array_size % size != 0) {
            fprintf(stderr, "ERRO: Tamanho do vetor (%d) deve ser divisivel pelo numero de processos (%d)\n",
                    array_size, size);
            MPI_Abort(MPI_COMM_WORLD, 1);
        }
    }

    /* Broadcast das configuracoes */
    MPI_Bcast(&array_size, 1, MPI_INT, 0, MPI_COMM_WORLD);
    MPI_Bcast(&g_debug, 1, MPI_INT, 0, MPI_COMM_WORLD);

    /* Calcula tamanho local (1/np do vetor global) */
    local_size = array_size / size;

    /* Aloca vetor local */
    local_array = (int *)malloc(sizeof(int) * local_size);
    if (local_array == NULL) {
        fprintf(stderr, "[Rank %d] Erro ao alocar memoria!\n", rank);
        MPI_Abort(MPI_COMM_WORLD, 1);
    }

    /* Cada processo gera sua parte do vetor em ordem decrescente */
    /* O processo 0 tem os maiores valores, o processo np-1 tem os menores */
    int start_value = array_size - (rank * local_size);
    for (int i = 0; i < local_size; i++) {
        local_array[i] = start_value - i;
    }

    if (g_debug) {
        printf("[Rank %d] Vetor local inicial: ", rank);
        for (int i = 0; i < local_size && i < 10; i++) {
            printf("%d ", local_array[i]);
        }
        if (local_size > 10) printf("...");
        printf("\n");
    }

    MPI_Barrier(MPI_COMM_WORLD);

    if (rank == 0) {
        start_time = MPI_Wtime();
    }

    /* ========== LOOP PRINCIPAL - FASES PARALELAS ========== */
    while (!pronto) {
        iteracoes++;

        /* FASE 1: Ordenacao local */
        bs(local_size, local_array);

        if (g_debug && rank == 0) {
            printf("\n[Iteracao %d] Fase 1: Ordenacao local concluida\n", iteracoes);
        }

        /* FASE 2: Verificacao distribuida se esta ordenado */
        int meu_maior = local_array[local_size - 1];
        int maior_esquerda = -1;
        int estou_ordenado = 1;  /* Assume que esta ordenado */

        /* Se nao for o ultimo processo (np-1), envia maior valor para a direita */
        if (rank < size - 1) {
            MPI_Send(&meu_maior, 1, MPI_INT, rank + 1, 0, MPI_COMM_WORLD);
        }

        /* Se nao for o primeiro processo (0), recebe maior valor da esquerda */
        if (rank > 0) {
            MPI_Status status;
            MPI_Recv(&maior_esquerda, 1, MPI_INT, rank - 1, 0, MPI_COMM_WORLD, &status);

            /* Compara se esta ordenado em relacao ao vizinho da esquerda */
            int meu_menor = local_array[0];
            if (maior_esquerda > meu_menor) {
                estou_ordenado = 0;  /* Nao esta ordenado */
            }
        }

        /* Compartilha o estado com todos os processos usando Allreduce */
        /* Se todos estiverem ordenados (produto = 1), entao termina */
        int todos_ordenados = 1;
        MPI_Allreduce(&estou_ordenado, &todos_ordenados, 1, MPI_INT, MPI_LAND, MPI_COMM_WORLD);

        if (g_debug && rank == 0) {
            printf("[Iteracao %d] Fase 2: Verificacao - Todos ordenados? %s\n",
                   iteracoes, todos_ordenados ? "SIM" : "NAO");
        }

        if (todos_ordenados) {
            pronto = 1;
            break;
        }

        /* FASE 3: Troca valores para convergir */
        /*
         * Cada processo troca valores com o vizinho da esquerda
         * O processo i envia seus menores valores para i-1
         * O processo i-1 envia seus maiores valores para i
         */

        if (rank > 0) {
            /* Envia os menores valores para a esquerda */
            MPI_Send(local_array, local_size, MPI_INT, rank - 1, 1, MPI_COMM_WORLD);
        }

        if (rank < size - 1) {
            /* Recebe os menores valores da direita */
            int *received_from_right = (int *)malloc(sizeof(int) * local_size);
            MPI_Status status;
            MPI_Recv(received_from_right, local_size, MPI_INT, rank + 1, 1, MPI_COMM_WORLD, &status);

            /* Intercala e mantem os maiores valores */
            merge_and_split(local_array, local_size, received_from_right, 0);

            /* Devolve os menores valores para a direita */
            MPI_Send(received_from_right, local_size, MPI_INT, rank + 1, 2, MPI_COMM_WORLD);

            free(received_from_right);
        }

        if (rank > 0) {
            /* Recebe de volta os maiores valores da esquerda */
            int *received_back = (int *)malloc(sizeof(int) * local_size);
            MPI_Status status;
            MPI_Recv(received_back, local_size, MPI_INT, rank - 1, 2, MPI_COMM_WORLD, &status);

            /* Intercala e mantem os menores valores */
            merge_and_split(local_array, local_size, received_back, 1);

            free(received_back);
        }

        if (g_debug && rank == 0) {
            printf("[Iteracao %d] Fase 3: Troca de valores concluida\n", iteracoes);
        }
    }

    MPI_Barrier(MPI_COMM_WORLD);

    if (rank == 0) {
        end_time = MPI_Wtime();
    }

    /* Imprime resultados */
    if (g_debug) {
        printf("[Rank %d] Vetor local final: ", rank);
        for (int i = 0; i < local_size && i < 10; i++) {
            printf("%d ", local_array[i]);
        }
        if (local_size > 10) printf("...");
        printf("\n");
    }

    if (rank == 0) {
        printf("\n========== RESULTADO ==========\n");
        printf("Numero de iteracoes: %d\n", iteracoes);
        printf("Tempo de execucao: %.6f segundos\n\n", end_time - start_time);
    }

    /* Verificacao final (opcional) - coleta todos os dados no processo 0 */
    if (g_debug) {
        int *global_array = NULL;
        if (rank == 0) {
            global_array = (int *)malloc(sizeof(int) * array_size);
        }

        MPI_Gather(local_array, local_size, MPI_INT,
                   global_array, local_size, MPI_INT,
                   0, MPI_COMM_WORLD);

        if (rank == 0) {
            printf("\nVetor global ordenado (primeiros 20 elementos): ");
            for (int i = 0; i < array_size && i < 20; i++) {
                printf("%d ", global_array[i]);
            }
            if (array_size > 20) printf("...");
            printf("\n");

            /* Verifica se esta realmente ordenado */
            int ordenado = 1;
            for (int i = 0; i < array_size - 1; i++) {
                if (global_array[i] > global_array[i + 1]) {
                    ordenado = 0;
                    printf("\nERRO: Vetor nao esta ordenado na posicao %d (%d > %d)\n",
                           i, global_array[i], global_array[i + 1]);
                    break;
                }
            }

            if (ordenado) {
                printf("\nVERIFICACAO: Vetor esta CORRETAMENTE ordenado!\n");
            }

            free(global_array);
        }
    }

    free(local_array);
    MPI_Finalize();

    return 0;
}
