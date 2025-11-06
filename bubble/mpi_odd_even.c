/* Compile:
   mpicc mpi_bubblesort_mpi.c -lm -o mpi_bubblesort_mpi
   Run:
   mpirun -np <processos> ./mpi_bubblesort_mpi <array-size>
*/

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <mpi.h>
#include <sys/time.h>

/* -------------------- util: timer -------------------- */
static double get_time(void) {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return (double)tv.tv_sec + (double)tv.tv_usec * 1e-6;
}

/* Arrays size <= SMALL switches to insertion sort */
#define SMALL 32

/* -------------------- forward decls -------------------- */
void insertion_sort(int a[], int size);
void bubblesort_serial(int a[], int size, int temp[]);
void odd_even_merge_boundary(int a[], int size);

void bubblesort_parallel_mpi(int a[], int size, int temp[],
                             int level, int my_rank, int max_rank,
                             int tag, MPI_Comm comm);

int  my_topmost_level_mpi(int my_rank);
void run_root_mpi(int a[], int size, int temp[], int max_rank, int tag, MPI_Comm comm);
void run_helper_mpi(int my_rank, int max_rank, int tag, MPI_Comm comm);

/* -------------------- main -------------------- */
int main(int argc, char *argv[]) {
    MPI_Init(&argc, &argv);

    int comm_size, my_rank;
    MPI_Comm_size(MPI_COMM_WORLD, &comm_size);
    MPI_Comm_rank(MPI_COMM_WORLD, &my_rank);

    int max_rank = comm_size - 1;
    int tag = 123;

    if (my_rank == 0) {
        puts("-MPI Recursive Bubblesort-");
        if (argc != 2) {
            printf("Usage: %s array-size\n", argv[0]);
            MPI_Abort(MPI_COMM_WORLD, 1);
        }

        int size = atoi(argv[1]);
        printf("Array size = %d\nProcesses = %d\n", size, comm_size);

        int *a    = (int*) malloc(sizeof(int) * size);
        int *temp = (int*) malloc(sizeof(int) * size);
        if (!a || !temp) {
            printf("Error: Could not allocate array of size %d\n", size);
            MPI_Abort(MPI_COMM_WORLD, 1);
        }

        /* random init */
        srand(314159);
        for (int i = 0; i < size; i++) a[i] = rand() % size;

        double start = get_time();
        run_root_mpi(a, size, temp, max_rank, tag, MPI_COMM_WORLD);
        double end = get_time();

        printf("Start = %.6f\nEnd = %.6f\nElapsed = %.6f\n", start, end, end - start);

        /* check */
        for (int i = 1; i < size; i++) {
            if (a[i-1] > a[i]) {
                printf("Implementation error: a[%d]=%d > a[%d]=%d\n", i-1, a[i-1], i, a[i]);
                MPI_Abort(MPI_COMM_WORLD, 1);
            }
        }

        free(a);
        free(temp);
    } else {
        run_helper_mpi(my_rank, max_rank, tag, MPI_COMM_WORLD);
    }

    fflush(stdout);
    MPI_Finalize();
    return 0;
}

/* -------------------- root / helper -------------------- */
void run_root_mpi(int a[], int size, int temp[], int max_rank, int tag, MPI_Comm comm) {
    int my_rank;
    MPI_Comm_rank(comm, &my_rank);
    if (my_rank != 0) {
        printf("Error: run_root_mpi called from process %d; must be called from process 0 only\n", my_rank);
        MPI_Abort(MPI_COMM_WORLD, 1);
    }
    bubblesort_parallel_mpi(a, size, temp, 0, my_rank, max_rank, tag, comm);
}

void run_helper_mpi(int my_rank, int max_rank, int tag, MPI_Comm comm) {
    int level = my_topmost_level_mpi(my_rank);

    MPI_Status status;
    int size;
    MPI_Probe(MPI_ANY_SOURCE, tag, comm, &status);
    MPI_Get_count(&status, MPI_INT, &size);
    int parent_rank = status.MPI_SOURCE;

    int *a    = (int*) malloc(sizeof(int) * size);
    int *temp = (int*) malloc(sizeof(int) * size);
    if (!a || !temp) {
        printf("Error: helper rank %d could not allocate arrays of size %d\n", my_rank, size);
        MPI_Abort(MPI_COMM_WORLD, 1);
    }

    MPI_Recv(a, size, MPI_INT, parent_rank, tag, comm, &status);
    bubblesort_parallel_mpi(a, size, temp, level, my_rank, max_rank, tag, comm);
    MPI_Send(a, size, MPI_INT, parent_rank, tag, comm);

    free(a);
    free(temp);
}

/* Given a process rank, calculate the top level of the process tree in which the process participates */
int my_topmost_level_mpi(int my_rank) {
    int level = 0;
    while ((int)pow(2, level) <= my_rank) level++;
    return level;
}

/* -------------------- parallel recursive bubble -------------------- */
void bubblesort_parallel_mpi(int a[], int size, int temp[],
                             int level, int my_rank, int max_rank,
                             int tag, MPI_Comm comm)
{
    int helper_rank = my_rank + (int)pow(2, level);

    if (helper_rank > max_rank || size <= 1) {
        /* sem processos auxiliares disponíveis (ou tamanho trivial): ordena localmente */
        bubblesort_serial(a, size, temp);
        return;
    }

    /* envia a segunda metade para o helper de forma assíncrona */
    MPI_Request request;
    MPI_Isend(a + size/2, size - size/2, MPI_INT, helper_rank, tag, comm, &request);

    /* ordena a primeira metade recursivamente (neste processo) */
    bubblesort_parallel_mpi(a, size/2, temp, level + 1, my_rank, max_rank, tag, comm);

    /* libera a request (o receive correspondente completará a transferência) */
    MPI_Request_free(&request);

    /* recebe a metade ordenada do helper */
    MPI_Status status;
    MPI_Recv(a + size/2, size - size/2, MPI_INT, helper_rank, tag, comm, &status);

    /* "junção" por Odd–Even Transposition sobre o array inteiro já com metades ordenadas */
    odd_even_merge_boundary(a, size);
}

/* -------------------- serial bubble + insertion -------------------- */
void insertion_sort(int a[], int size) {
    for (int i = 0; i < size; i++) {
        int v = a[i], j = i - 1;
        while (j >= 0 && a[j] > v) { a[j+1] = a[j]; j--; }
        a[j+1] = v;
    }
}

void bubblesort_serial(int a[], int size, int temp[]) {
    (void)temp; /* não usado, para manter assinatura compatível */

    if (size <= SMALL) { insertion_sort(a, size); return; }

    for (int i = 0; i < size - 1; i++) {
        int trocou = 0;
        for (int j = 0; j < size - 1 - i; j++) {
            if (a[j] > a[j+1]) {
                int t = a[j]; a[j] = a[j+1]; a[j+1] = t;
                trocou = 1;
            }
        }
        if (!trocou) break; /* já está ordenado */
    }
}

/* -------------------- odd-even "merge" -------------------- */
/* Supõe a primeira metade a[0..mid-1] e a segunda metade a[mid..size-1] já ordenadas.
   Executa Odd–Even Transposition Sort no array inteiro (O(n^2)), suficiente para
   “costurar” as metades em uma ordem global correta. */
void odd_even_merge_boundary(int a[], int size) {
    if (size <= 1) return;
    for (int pass = 0; pass < size; pass++) {
        int start = pass % 2; /* 0 = pares (0,1)(2,3)... | 1 = ímpares (1,2)(3,4)... */
        for (int i = start; i + 1 < size; i += 2) {
            if (a[i] > a[i+1]) {
                int t = a[i]; a[i] = a[i+1]; a[i+1] = t;
            }
        }
    }
}
