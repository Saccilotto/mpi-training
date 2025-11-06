#include <stdio.h>
#include <stdlib.h>
#include <mpi.h>

#ifndef DEBUG
#define DEBUG 1            // comentar esta linha quando for medir tempo
#endif

#ifndef ARRAY_SIZE
#define ARRAY_SIZE 40      // trabalho final com o valores 10.000, 100.000, 1.000.000
#endif

#ifndef DELTA
#define DELTA 10           // tamanho minimo para conquistar (ordenar localmente)
#endif

/* Variaveis globais para controle */
int g_debug = DEBUG;

/* Funcao auxiliar para trocar dois elementos */
void swap(int *a, int *b)
{
    int temp = *a;
    *a = *b;
    *b = temp;
}

/* Funcao de particao para quicksort - esquema de Lomuto */
/* Retorna o indice do pivo apos particionar */
int partition(int *vetor, int low, int high)
{
    int pivot = vetor[high];  // escolhe o ultimo elemento como pivo
    int i = low - 1;          // indice do menor elemento

    for (int j = low; j < high; j++) {
        if (vetor[j] <= pivot) {
            i++;
            swap(&vetor[i], &vetor[j]);
        }
    }
    swap(&vetor[i + 1], &vetor[high]);
    return i + 1;
}

/* Funcao Quick Sort recursiva - ordena um vetor localmente */
void quicksort_seq(int *vetor, int low, int high)
{
    if (low < high) {
        int pi = partition(vetor, low, high);
        quicksort_seq(vetor, low, pi - 1);
        quicksort_seq(vetor, pi + 1, high);
    }
}

/* Wrapper para quicksort sequencial */
void qs(int n, int *vetor)
{
    if (n > 0) {
        quicksort_seq(vetor, 0, n - 1);
    }
}

/* Particiona o vetor em dois subvetores baseado em um pivo global */
/* Retorna o tamanho da particao esquerda (elementos <= pivo) */
int partition_for_parallel(int *vetor, int tam, int pivot, int **left, int **right)
{
    int *temp_left = (int *)malloc(sizeof(int) * tam);
    int *temp_right = (int *)malloc(sizeof(int) * tam);
    int left_count = 0;
    int right_count = 0;

    for (int i = 0; i < tam; i++) {
        if (vetor[i] <= pivot) {
            temp_left[left_count++] = vetor[i];
        } else {
            temp_right[right_count++] = vetor[i];
        }
    }

    /* Realoca para o tamanho exato */
    *left = (int *)malloc(sizeof(int) * left_count);
    *right = (int *)malloc(sizeof(int) * right_count);

    for (int i = 0; i < left_count; i++) {
        (*left)[i] = temp_left[i];
    }
    for (int i = 0; i < right_count; i++) {
        (*right)[i] = temp_right[i];
    }

    free(temp_left);
    free(temp_right);

    return left_count;
}

/* Escolhe um pivo - usa o elemento do meio para melhor distribuicao */
int choose_pivot(int *vetor, int tam)
{
    if (tam <= 0) return 0;
    return vetor[tam / 2];
}

/* Funcao recursiva que implementa divide-and-conquer com quicksort paralelo */
void divide_conquer_quicksort(int *vetor, int tamanho, int rank, int delta, int num_procs)
{
    int filho_esquerdo, filho_direito, pai;
    int pivot;
    int *left_partition = NULL, *right_partition = NULL;
    int left_size, right_size;
    MPI_Status status;

    if (g_debug) {
        printf("[Rank %d] Recebeu vetor de tamanho %d\n", rank, tamanho);
    }

    filho_esquerdo = 2 * rank + 1;
    filho_direito = 2 * rank + 2;

    /* Verifica se deve CONQUISTAR ou DIVIDIR */
    /* Conquista se: tamanho <= delta OU nao ha processos filhos disponiveis */
    if (tamanho <= delta || filho_esquerdo >= num_procs) {
        /* ========== CONQUISTAR ========== */
        if (g_debug) {
            printf("[Rank %d] CONQUISTANDO: ordenando %d elementos com quicksort\n", rank, tamanho);
        }

        qs(tamanho, vetor);  // Ordena localmente com quicksort

        /* Envia de volta para o pai (se nao for raiz) */
        if (rank != 0) {
            pai = (rank - 1) / 2;
            if (g_debug) {
                printf("[Rank %d] Enviando %d elementos ordenados para pai [Rank %d]\n",
                       rank, tamanho, pai);
            }
            MPI_Send(vetor, tamanho, MPI_INT, pai, 0, MPI_COMM_WORLD);
        }

    } else {
        /* ========== DIVIDIR ========== */
        if (g_debug) {
            printf("[Rank %d] DIVIDINDO: %d elementos usando particao com pivo\n", rank, tamanho);
        }

        /* Escolhe o pivo */
        pivot = choose_pivot(vetor, tamanho);

        if (g_debug) {
            printf("[Rank %d] Pivo escolhido: %d\n", rank, pivot);
        }

        /* Particiona o vetor em dois subvetores */
        left_size = partition_for_parallel(vetor, tamanho, pivot, &left_partition, &right_partition);
        right_size = tamanho - left_size;

        if (g_debug) {
            printf("[Rank %d] Particao: esquerda=%d elementos, direita=%d elementos\n",
                   rank, left_size, right_size);
        }

        /* Envia particao esquerda para filho esquerdo */
        if (left_size > 0) {
            if (g_debug) {
                printf("[Rank %d] Enviando %d elementos (<=pivo) para filho esquerdo [Rank %d]\n",
                       rank, left_size, filho_esquerdo);
            }
            MPI_Send(left_partition, left_size, MPI_INT, filho_esquerdo, 0, MPI_COMM_WORLD);
        }

        /* Verifica se filho direito existe antes de enviar */
        if (filho_direito < num_procs && right_size > 0) {
            /* Envia particao direita para filho direito */
            if (g_debug) {
                printf("[Rank %d] Enviando %d elementos (>pivo) para filho direito [Rank %d]\n",
                       rank, right_size, filho_direito);
            }
            MPI_Send(right_partition, right_size, MPI_INT, filho_direito, 0, MPI_COMM_WORLD);
        } else if (right_size > 0) {
            /* Nao ha filho direito, ordena localmente a particao direita */
            if (g_debug) {
                printf("[Rank %d] Filho direito [Rank %d] nao existe, ordenando %d elementos localmente\n",
                       rank, filho_direito, right_size);
            }
            qs(right_size, right_partition);
        }

        /* Recebe vetores ordenados dos filhos */
        if (g_debug) {
            printf("[Rank %d] Aguardando respostas dos filhos...\n", rank);
        }

        /* Recebe da esquerda */
        if (left_size > 0) {
            MPI_Recv(left_partition, left_size, MPI_INT, filho_esquerdo, 0, MPI_COMM_WORLD, &status);
        }

        /* Recebe da direita */
        if (filho_direito < num_procs && right_size > 0) {
            MPI_Recv(right_partition, right_size, MPI_INT, filho_direito, 0, MPI_COMM_WORLD, &status);
        }

        if (g_debug) {
            printf("[Rank %d] Recebeu respostas! Concatenando particoes...\n", rank);
        }

        /* Para quicksort, basta concatenar: esquerda + direita */
        /* Ja estao ordenados e particionados corretamente */
        int idx = 0;
        for (int i = 0; i < left_size; i++) {
            vetor[idx++] = left_partition[i];
        }
        for (int i = 0; i < right_size; i++) {
            vetor[idx++] = right_partition[i];
        }

        /* Libera memoria temporaria */
        if (left_partition) free(left_partition);
        if (right_partition) free(right_partition);

        /* Envia para o pai (se nao for raiz) */
        if (rank != 0) {
            pai = (rank - 1) / 2;
            if (g_debug) {
                printf("[Rank %d] Enviando %d elementos ordenados para pai [Rank %d]\n",
                       rank, tamanho, pai);
            }
            MPI_Send(vetor, tamanho, MPI_INT, pai, 0, MPI_COMM_WORLD);
        }
    }
}

int main(int argc, char **argv)
{
    int rank, size;
    int *vetor = NULL;
    int array_size = ARRAY_SIZE;
    int delta = DELTA;
    MPI_Status status;
    double start_time, end_time;

    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    if (rank == 0) {
        if (argc > 1) {
            array_size = atoi(argv[1]);
        }

        if (argc > 2) {
            delta = atoi(argv[2]);
        }

        if (argc > 3) {
            g_debug = atoi(argv[3]);
        }
    }

    /* Broadcast das variaveis de configuracao para todos os processos */
    MPI_Bcast(&delta, 1, MPI_INT, 0, MPI_COMM_WORLD);
    MPI_Bcast(&g_debug, 1, MPI_INT, 0, MPI_COMM_WORLD);

    if (rank == 0) {
        /* ========== PROCESSO RAIZ (rank 0) ========== */
        printf("\n========== QUICK SORT PARALELO (MPI) ==========\n");
        printf("Processos: %d\n", size);
        printf("Tamanho do vetor: %d\n", array_size);
        printf("Delta (conquista): %d\n", delta);
        printf("Debug: %s\n\n", g_debug ? "ON" : "OFF");

        /* Aloca e inicializa vetor com pior caso (ordem decrescente) */
        vetor = (int *)malloc(sizeof(int) * array_size);
        if (vetor == NULL) {
            fprintf(stderr, "Erro ao alocar memoria!\n");
            MPI_Abort(MPI_COMM_WORLD, 1);
        }

        for (int i = 0; i < array_size; i++) {
            vetor[i] = array_size - i;
        }

        if (g_debug) {
            printf("\nVetor inicial: ");
            for (int i = 0; i < array_size && i < 40; i++) {
                printf("[%03d] ", vetor[i]);
            }
            if (array_size > 40) printf("...");
            printf("\n\n");
        }

        start_time = MPI_Wtime();  // Inicia medicao de tempo

        /* Chama funcao divide-and-conquer com quicksort */
        divide_conquer_quicksort(vetor, array_size, rank, delta, size);

        end_time = MPI_Wtime();  // Finaliza medicao de tempo

        printf("\n========== RESULTADO ==========\n");
        printf("Tempo de execucao: %.6f segundos\n\n", end_time - start_time);

        if (g_debug) {
            printf("Vetor ordenado: ");
            for (int i = 0; i < array_size && i < 40; i++) {
                printf("[%03d] ", vetor[i]);
            }
            if (array_size > 40) printf("...");
            printf("\n\n");
        }

        /* Verifica se esta ordenado corretamente */
        int ordenado = 1;
        for (int i = 0; i < array_size - 1; i++) {
            if (vetor[i] > vetor[i + 1]) {
                ordenado = 0;
                fprintf(stderr, "ERRO: Vetor nao esta ordenado na posicao %d (%d > %d)\n",
                        i, vetor[i], vetor[i + 1]);
                break;
            }
        }
        if (ordenado && g_debug) {
            printf("Verificacao: Vetor esta corretamente ordenado! \n\n");
        }

        free(vetor);

    } else {
        /* ========== PROCESSOS FILHOS ========== */
        int tam_recebido;
        int pai;

        /* Usa MPI_Probe para descobrir o tamanho da mensagem que esta chegando */
        /* MPI_Probe "espia" a mensagem sem remove-la da fila */
        MPI_Probe(MPI_ANY_SOURCE, 0, MPI_COMM_WORLD, &status);

        /* Descobre quem enviou a mensagem */
        pai = status.MPI_SOURCE;

        /* Usa MPI_Get_count para descobrir quantos elementos estao na mensagem */
        MPI_Get_count(&status, MPI_INT, &tam_recebido);

        if (g_debug) {
            printf("[Rank %d] MPI_Probe detectou mensagem com %d elementos do rank %d\n",
                   rank, tam_recebido, pai);
        }

        /* Aloca vetor local com o tamanho EXATO descoberto por MPI_Probe */
        vetor = (int *)malloc(sizeof(int) * tam_recebido);

        if (vetor == NULL) {
            fprintf(stderr, "[Rank %d] Erro ao alocar memoria para %d elementos!\n",
                    rank, tam_recebido);
            MPI_Abort(MPI_COMM_WORLD, 1);
        }

        /* Agora sim, recebe os dados do vetor */
        MPI_Recv(vetor, tam_recebido, MPI_INT, pai, 0, MPI_COMM_WORLD, &status);

        if (g_debug) {
            printf("[Rank %d] Dados recebidos com sucesso\n", rank);
        }

        /* Chama funcao divide-and-conquer com o tamanho correto */
        divide_conquer_quicksort(vetor, tam_recebido, rank, delta, size);

        free(vetor);
    }

    MPI_Finalize();

    return 0;
}
