#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>
#include <mpi.h>

#define N 1000000
#define D 4
#define K 3
#define MAX_ITER 100

double distance(double *a, double *b) {
    double sum = 0.0;
    for (int i = 0; i < D; i++)
        sum += (a[i] - b[i]) * (a[i] - b[i]);
    return sqrt(sum);
}

// Generate random data locally
void generate_data(double *data, int local_n, int rank) {
    srand(42 + rank);
    for (int i = 0; i < local_n; i++) {
        for (int j = 0; j < D; j++) {
            data[i * D + j] = ((double)rand() / RAND_MAX) * 10.0;
        }
    }
}

// Master initializes centroids randomly from full dataset
void initialize_centroids(double centroids[K][D], double *full_data) {
    srand(time(NULL));
    for (int k = 0; k < K; k++) {
        int idx = rand() % N;
        for (int j = 0; j < D; j++)
            centroids[k][j] = full_data[idx * D + j];
    }
}

int main(int argc, char **argv) {
    int rank, size;
    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    int local_n = N / size;
    double *local_data = (double*)malloc(local_n * D * sizeof(double));
    int *labels = (int*)malloc(local_n * sizeof(int));

    double *full_data = NULL;
    double centroids[K][D];

    if (rank == 0) {
        // Master generates full dataset
        full_data = (double*)malloc(N * D * sizeof(double));
        generate_data(full_data, N, 0);

        // Scatter data to all processes
        for (int i = 1; i < size; i++) {
            MPI_Send(full_data + i*local_n*D, local_n*D, MPI_DOUBLE, i, 0, MPI_COMM_WORLD);
        }
        // Copy master's chunk locally
        for (int i = 0; i < local_n*D; i++)
            local_data[i] = full_data[i];
        
        initialize_centroids(centroids, full_data);
    } else {
        // Workers receive their chunk
        MPI_Recv(local_data, local_n*D, MPI_DOUBLE, 0, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
    }

    double start_time = MPI_Wtime();

    for (int iter = 0; iter < MAX_ITER; iter++) {
        if (rank != 0) {
            // Worker receives centroids
            MPI_Recv(&centroids[0][0], K*D, MPI_DOUBLE, 0, 1, MPI_COMM_WORLD, MPI_STATUS_IGNORE);

            // Local computation
            double local_sums[K][D] = {{0}};
            int local_counts[K] = {0};
            for (int i = 0; i < local_n; i++) {
                double *point = &local_data[i*D];
                double min_dist = 1e9;
                int best = 0;
                for (int k = 0; k < K; k++) {
                    double dist = distance(point, centroids[k]);
                    if (dist < min_dist) {
                        min_dist = dist;
                        best = k;
                    }
                }
                labels[i] = best;
                local_counts[best]++;
                for (int j = 0; j < D; j++)
                    local_sums[best][j] += point[j];
            }

            // Send local sums and counts to master
            MPI_Send(local_sums, K*D, MPI_DOUBLE, 0, 2, MPI_COMM_WORLD);
            MPI_Send(local_counts, K, MPI_INT, 0, 3, MPI_COMM_WORLD);
        } else {
            // Master sends centroids to workers
            for (int i = 1; i < size; i++)
                MPI_Send(&centroids[0][0], K*D, MPI_DOUBLE, i, 1, MPI_COMM_WORLD);

            // Master computes its own local sums
            double local_sums[K][D] = {{0}};
            int local_counts[K] = {0};
            for (int i = 0; i < local_n; i++) {
                double *point = &local_data[i*D];
                double min_dist = 1e9;
                int best = 0;
                for (int k = 0; k < K; k++) {
                    double dist = distance(point, centroids[k]);
                    if (dist < min_dist) {
                        min_dist = dist;
                        best = k;
                    }
                }
                labels[i] = best;
                local_counts[best]++;
                for (int j = 0; j < D; j++)
                    local_sums[best][j] += point[j];
            }

            // Receive sums and counts from workers and accumulate
            double global_sums[K][D];
            int global_counts[K];
            for (int k = 0; k < K; k++) {
                global_counts[k] = local_counts[k];
                for (int j = 0; j < D; j++)
                    global_sums[k][j] = local_sums[k][j];
            }

            for (int i = 1; i < size; i++) {
                double worker_sums[K][D];
                int worker_counts[K];
                MPI_Recv(worker_sums, K*D, MPI_DOUBLE, i, 2, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
                MPI_Recv(worker_counts, K, MPI_INT, i, 3, MPI_COMM_WORLD, MPI_STATUS_IGNORE);

                for (int k = 0; k < K; k++) {
                    global_counts[k] += worker_counts[k];
                    for (int j = 0; j < D; j++)
                        global_sums[k][j] += worker_sums[k][j];
                }
            }

            // Update centroids
            for (int k = 0; k < K; k++)
                if (global_counts[k] > 0)
                    for (int j = 0; j < D; j++)
                        centroids[k][j] = global_sums[k][j] / global_counts[k];
        }
    }

    double end_time = MPI_Wtime();

    if (rank == 0) {
        printf("Final centroids:\n");
        for (int k = 0; k < K; k++) {
            printf("Cluster %d: ", k);
            for (int j = 0; j < D; j++)
                printf("%.2f ", centroids[k][j]);
            printf("\n");
        }
        printf("\nExecution time (Master wall time): %.3f seconds\n", end_time - start_time);
    }

    free(local_data);
    free(labels);
    if (full_data) free(full_data);
    MPI_Finalize();
    return 0;
}
