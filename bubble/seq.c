#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#ifndef DEBUG
#define DEBUG 1            // comentar esta linha quando for medir tempo
#endif

#ifndef ARRAY_SIZE
#define ARRAY_SIZE 40      // trabalho final com o valores 10.000, 100.000, 1.000.000
#endif

void bs(int n, int * vetor)
{
    int c = 0, d, troca, trocou = 1;

    while (c < n-1 && trocou)
        {
        trocou = 0;
        for (d = 0 ; d < n - c - 1; d++)
            if (vetor[d] > vetor[d+1])
                {
                troca      = vetor[d];
                vetor[d]   = vetor[d+1];
                vetor[d+1] = troca;
                trocou = 1;
                }
        c++;
        }
}

int main(int argc, char **argv)
{
    int array_size = ARRAY_SIZE;
    int debug = DEBUG;
    int *vetor;
    int i;
    clock_t start_time, end_time;

    /* Parse argumentos de linha de comando */
    if (argc > 1) {
        array_size = atoi(argv[1]);
    }
    if (argc > 2) {
        debug = atoi(argv[2]);
    }

    printf("\n========== BUBBLE SORT SEQUENCIAL ==========\n");
    printf("Tamanho do vetor: %d\n", array_size);
    printf("Debug: %s\n\n", debug ? "ON" : "OFF");

    /* Aloca vetor dinamicamente */
    vetor = (int *)malloc(sizeof(int) * array_size);
    if (vetor == NULL) {
        fprintf(stderr, "Erro ao alocar memoria!\n");
        return 1;
    }

    for (i=0 ; i<array_size; i++)              /* init array with worst case for sorting */
        vetor[i] = array_size-i;

    if (debug) {
        printf("\nVetor inicial: ");
        for (i=0 ; i<array_size && i<40; i++)              /* print unsorted array (max 40) */
            printf("[%03d] ", vetor[i]);
        if (array_size > 40) printf("...");
        printf("\n\n");
    }

    start_time = clock();                      /* start time measurement */
    bs(array_size, vetor);                     /* sort array */
    end_time = clock();                        /* end time measurement */

    printf("\n========== RESULTADO ==========\n");
    printf("Tempo de execucao: %.6f segundos\n\n", ((double) (end_time - start_time)) / CLOCKS_PER_SEC);

    if (debug) {
        printf("Vetor ordenado: ");
        for (i=0 ; i<array_size && i<40; i++)                              /* print sorted array (max 40) */
            printf("[%03d] ", vetor[i]);
        if (array_size > 40) printf("...");
        printf("\n\n");
    }

    free(vetor);
    return 0;
}