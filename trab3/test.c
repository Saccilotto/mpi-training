#include <mpi.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define ARRAY_SIZE 320       // trocar para 1.000.000 no experimento real
#define DEBUG 1             // comentar para medir tempo

// ---------------------------------------------------------------------
// Bubble Sort local (fornecido pelo professor)
// ---------------------------------------------------------------------
void bs(int n, int *vetor) {
    int c=0, d, troca, trocou = 1;

    while (c < (n-1) && trocou) {
        trocou = 0;
        for (d = 0; d < n - c - 1; d++)
            if (vetor[d] > vetor[d+1]) {
                troca        = vetor[d];
                vetor[d]     = vetor[d+1];
                vetor[d+1]   = troca;
                trocou       = 1;
            }
        c++;
    }
}

// troca os elementos mais baixos de A com os mais altos de B
void troca_blocos(int *meu, int *buf, int n) {

    // copia parte baixa do meu vetor para buf temporário
    for (int i = 0; i < n/4; i++)
        buf[i] = meu[i];

    // copia parte alta do meu vetor para o início
    for (int i = 0; i < n/4; i++)
        meu[i] = meu[n - n/4 + i];

    // coloca os valores recebidos como parte alta
    for (int i = 0; i < n/4; i++)
        meu[n - n/4 + i] = buf[i];
}


int main(int argc, char **argv) {

    int rank, size;
    MPI_Init(&argc,&argv);
    MPI_Comm_rank(MPI_COMM_WORLD,&rank);
    MPI_Comm_size(MPI_COMM_WORLD,&size);

    int nlocal = ARRAY_SIZE / size;
    int *vet = malloc(nlocal * sizeof(int));

    // ---------------------------------------------------------------------
    // 1 — Cada processo gera sua parte do vetor (ordem decrescente global simulada)
    // ---------------------------------------------------------------------
    for (int i = 0; i < nlocal; i++)
        vet[i] = ARRAY_SIZE - (rank*nlocal + i);

#if DEBUG
    printf("Rank %d inicial: ", rank);
    for (int i = 0 ; i < nlocal; i++)
        printf("[%03d] ", vet[i]);
    printf("\n");
#endif

    int ordenado_global = 0;
    int meu_maior, meu_menor;

    int viz_dir  = rank + 1;
    int viz_esq  = rank - 1;

    int troca_ok;
    MPI_Status st;

    // Buffer auxiliar para trocas de blocos
    int *buffer = malloc(nlocal * sizeof(int));

    // ---------------------------------------------------------------------
    // LOOP DE FASES PARALELAS
    // ---------------------------------------------------------------------
    while (!ordenado_global) {

        // ============================================================
        // FASE 1 — Ordenação local (Bubble Sort)
        // ============================================================
        bs(nlocal, vet);

        // ============================================================
        // FASE 2 — Verificação distribuída se todo vetor está ordenado
        // ============================================================

        meu_menor = vet[0];
        meu_maior = vet[nlocal-1];
        int local_ok = 1;

        // Envia maior para direita e recebe menor do vizinho da direita
        if (rank < size-1) {
            int menor_dir;
            MPI_Send(&meu_maior, 1, MPI_INT, viz_dir, 0, MPI_COMM_WORLD);
            MPI_Recv(&menor_dir, 1, MPI_INT, viz_dir, 0, MPI_COMM_WORLD, &st);

            if (meu_maior > menor_dir)
                local_ok = 0;       // não está ordenado entre rank e rank+1
        }

        // Envia menor para esquerda e recebe maior do vizinho da esquerda
        if (rank > 0) {
            int maior_esq;
            MPI_Recv(&maior_esq, 1, MPI_INT, viz_esq, 0, MPI_COMM_WORLD, &st);
            MPI_Send(&meu_menor, 1, MPI_INT, viz_esq, 0, MPI_COMM_WORLD);

            if (maior_esq > meu_menor)
                local_ok = 0;
        }

        // REDUÇÃO GLOBAL — todos os processos recebem se está ordenado
        MPI_Allreduce(&local_ok, &ordenado_global, 1, MPI_INT, MPI_LAND, MPI_COMM_WORLD);

        // Se estiver ordenado, todos saem
        if (ordenado_global)
            break;

        // ============================================================
        // FASE 3 — Troca de partes do vetor com o vizinho à esquerda
        // ============================================================
        if (rank > 0) {

            // envia parte baixa e recebe parte alta do vizinho esquerdo
            MPI_Sendrecv(vet, nlocal/4, MPI_INT, viz_esq, 1,
                         buffer, nlocal/4, MPI_INT, viz_esq, 1,
                         MPI_COMM_WORLD, &st);

            // troca efetivamente no meu vetor
            troca_blocos(vet, buffer, nlocal);
        }
    }

#if DEBUG
    printf("Rank %d FINAL: ", rank);
    for (int i = 0 ; i < nlocal; i++)
        printf("[%03d] ", vet[i]);
    printf("\n");
#endif

    free(vet);
    free(buffer);
    MPI_Finalize();
    return 0;
}

