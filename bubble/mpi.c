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

/* Recebe um ponteiro para um vetor que contem as mensagens recebidas dos filhos e */
/* intercala estes valores em um terceiro vetor auxiliar. Devolve um ponteiro para este vetor */
int *interleaving(int vetor[], int tam)
{
    int *vetor_auxiliar;
    int i1, i2, i_aux;

    vetor_auxiliar = (int *)malloc(sizeof(int) * tam);

    i1 = 0;
    i2 = tam / 2;

    for (i_aux = 0; i_aux < tam; i_aux++) {
        if (((vetor[i1] <= vetor[i2]) && (i1 < (tam / 2)))
            || (i2 == tam))
            vetor_auxiliar[i_aux] = vetor[i1++];
        else
            vetor_auxiliar[i_aux] = vetor[i2++];
    }

    return vetor_auxiliar;
}

/* Funcao recursiva que implementa divide-and-conquer */
void divide_conquer(int *vetor, int tamanho, int rank, int delta)
{
    int filho_esquerdo, filho_direito, pai;
    int meio;
    int *vetor_aux;
    MPI_Status status;

    if (g_debug) {
        printf("[Rank %d] Recebeu vetor de tamanho %d\n", rank, tamanho);
    }

    /* Verifica se deve CONQUISTAR ou DIVIDIR */
    if (tamanho <= delta) {
        /* ========== CONQUISTAR ========== */
        if (g_debug) {
            printf("[Rank %d] CONQUISTANDO: ordenando %d elementos\n", rank, tamanho);
        }

        bs(tamanho, vetor);  // Ordena localmente

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
            printf("[Rank %d] DIVIDINDO: %d elementos em 2 partes\n", rank, tamanho);
        }

        filho_esquerdo = 2 * rank + 1;
        filho_direito = 2 * rank + 2;
        meio = tamanho / 2;

        /* Envia metade esquerda para filho esquerdo */
        if (g_debug) {
            printf("[Rank %d] Enviando %d elementos para filho esquerdo [Rank %d]\n",
                   rank, meio, filho_esquerdo);
        }
        MPI_Send(&meio, 1, MPI_INT, filho_esquerdo, 0, MPI_COMM_WORLD);  // envia tamanho
        MPI_Send(vetor, meio, MPI_INT, filho_esquerdo, 0, MPI_COMM_WORLD);  // envia dados

        /* Envia metade direita para filho direito */
        int tamanho_direito = tamanho - meio;
        if (g_debug) {
            printf("[Rank %d] Enviando %d elementos para filho direito [Rank %d]\n",
                   rank, tamanho_direito, filho_direito);
        }
        MPI_Send(&tamanho_direito, 1, MPI_INT, filho_direito, 0, MPI_COMM_WORLD);
        MPI_Send(&vetor[meio], tamanho_direito, MPI_INT, filho_direito, 0, MPI_COMM_WORLD);

        /* Recebe vetores ordenados dos filhos */
        if (g_debug) {
            printf("[Rank %d] Aguardando respostas dos filhos...\n", rank);
        }

        MPI_Recv(vetor, meio, MPI_INT, filho_esquerdo, 0, MPI_COMM_WORLD, &status);
        MPI_Recv(&vetor[meio], tamanho - meio, MPI_INT, filho_direito, 0, MPI_COMM_WORLD, &status);

        if (g_debug) {
            printf("[Rank %d] Recebeu respostas! Intercalando...\n", rank);
        }

        /* Intercala os dois vetores ordenados */
        vetor_aux = interleaving(vetor, tamanho);

        /* Copia o vetor intercalado de volta */
        for (int i = 0; i < tamanho; i++) {
            vetor[i] = vetor_aux[i];
        }
        free(vetor_aux);

        /* Envia para o pai (se nao for raiz) */
        if (rank != 0) {
            pai = (rank - 1) / 2;
            if (g_debug) {
                printf("[Rank %d] Enviando %d elementos intercalados para pai [Rank %d]\n",
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
    int tamanho_local;
    int array_size = ARRAY_SIZE;
    int delta = DELTA;
    MPI_Status status;
    double start_time, end_time;

    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    /* Parse argumentos de linha de comando (apenas rank 0) */
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

        /* Se DELTA == 0 ou nao especificado, calcula automaticamente */
        /* DELTA = array_size / (2^depth) onde depth = log2(size) */
        if (delta == 0) {
            int depth = 0;
            int temp = size;
            while (temp > 1) {
                temp = temp / 2;
                depth++;
            }
            delta = array_size / (1 << depth);  // array_size / 2^depth
            if (delta < 1) delta = 1;
        }
    }

    /* Broadcast dos parametros para todos os processos */
    MPI_Bcast(&array_size, 1, MPI_INT, 0, MPI_COMM_WORLD);
    MPI_Bcast(&delta, 1, MPI_INT, 0, MPI_COMM_WORLD);
    MPI_Bcast(&g_debug, 1, MPI_INT, 0, MPI_COMM_WORLD);

    if (rank == 0) {
        /* ========== PROCESSO RAIZ (rank 0) ========== */
        printf("\n========== BUBBLE SORT PARALELO (MPI) ==========\n");
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

        /* Chama funcao divide-and-conquer */
        divide_conquer(vetor, array_size, rank, delta);

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

        free(vetor);

    } else {
        /* ========== PROCESSOS FILHOS ========== */
        /* Recebe tamanho do vetor */
        MPI_Recv(&tamanho_local, 1, MPI_INT, MPI_ANY_SOURCE, 0, MPI_COMM_WORLD, &status);

        /* Aloca vetor local */
        vetor = (int *)malloc(sizeof(int) * tamanho_local);
        if (vetor == NULL) {
            fprintf(stderr, "[Rank %d] Erro ao alocar memoria!\n", rank);
            MPI_Abort(MPI_COMM_WORLD, 1);
        }

        /* Recebe dados do vetor */
        MPI_Recv(vetor, tamanho_local, MPI_INT, status.MPI_SOURCE, 0, MPI_COMM_WORLD, &status);

        /* Chama funcao divide-and-conquer */
        divide_conquer(vetor, tamanho_local, rank, delta);

        free(vetor);
    }

    MPI_Finalize();
    return 0;
}
