#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>

#define N 1000000     // number of samples
#define D 4            // number of features
#define K 3            // number of clusters
#define MAX_ITER 100

double data[N][D];
double centroids[K][D];
int labels[N];

double distance(double *a, double *b) {
    double sum = 0.0;
    for (int i = 0; i < D; i++)
        sum += (a[i] - b[i]) * (a[i] - b[i]);
    return sqrt(sum);
}

void generate_data() {
    srand(42);
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < D; j++) {
            data[i][j] = ((double)rand() / RAND_MAX) * 10.0;
        }
    }
    printf("Generated %d random samples.\n", N);
}

void initialize_centroids() {
    srand(time(NULL));
    int used[N] = {0};
    for (int k = 0; k < K; k++) {
        int idx;
        do {
            idx = rand() % N;
        } while (used[idx]);
        used[idx] = 1;
        for (int j = 0; j < D; j++)
            centroids[k][j] = data[idx][j];
    }
}

void assign_clusters() {
    for (int i = 0; i < N; i++) {
        double min_dist = 1e9;
        int best = 0;
        for (int k = 0; k < K; k++) {
            double dist = distance(data[i], centroids[k]);
            if (dist < min_dist) {
                min_dist = dist;
                best = k;
            }
        }
        labels[i] = best;
    }
}

void update_centroids() {
    double new_centroids[K][D] = {0};
    int count[K] = {0};
    for (int i = 0; i < N; i++) {
        int k = labels[i];
        count[k]++;
        for (int j = 0; j < D; j++) {
            new_centroids[k][j] += data[i][j];
        }
    }
    for (int k = 0; k < K; k++) {
        if (count[k] > 0) {
            for (int j = 0; j < D; j++)
                centroids[k][j] = new_centroids[k][j] / count[k];
        }
    }
}

int main() {
    clock_t start = clock();

    generate_data();
    initialize_centroids();

    for (int iter = 0; iter < MAX_ITER; iter++) {
        assign_clusters();
        update_centroids();
    }

    clock_t end = clock();
    double cpu_time = ((double)(end - start)) / CLOCKS_PER_SEC;

    printf("Final centroids:\n");
    for (int k = 0; k < K; k++) {
        printf("Cluster %d: ", k);
        for (int j = 0; j < D; j++)
            printf("%.2f ", centroids[k][j]);
        printf("\n");
    }

    printf("\nExecution time (CPU): %.3f seconds\n", cpu_time);
    return 0;
}
