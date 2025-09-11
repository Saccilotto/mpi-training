#include <cstdlib>
#include <cstdio>
#include <chrono>
#include <iostream>
#include <getopt.h>
#include <cstring>
#include <mpi.h>
#include <atomic>
#include <memory>

using namespace std;

int n = 500000;

struct Item {
    int id;
    bool isLast;

    Item() : id(0), isLast(false) {}
    
    Item(int i) : id(i), isLast(false) {}

    int getCurrentId() const {
        return id;
    }

    bool getIsLast() const {
        return isLast;
    }
};

class Source {
public:   
    int world_size;

    Source(int size) : world_size(size) {}

    void operator()() {
        cout << "Source: Generating numbers from 2 to " << n << endl;
        
        for (int num = 2; num <= n; ++num) {
            Item it(num);
            MPI_Send(&it, sizeof(Item), MPI_BYTE, 1, 0, MPI_COMM_WORLD);
        }
        
        // Send sentinel to terminate
        Item sentinel(-1);
        MPI_Send(&sentinel, sizeof(Item), MPI_BYTE, 1, 0, MPI_COMM_WORLD);
        
        cout << "Source: Finished sending " << (n-1) << " numbers" << endl;
    }
};

class Filter {
public:   
    int my_rank;
    int world_size;
    int prime_to_filter;

    Filter(int rank, int size) : my_rank(rank), world_size(size) {
        prime_to_filter = rank + 1; // rank 1 filters by 2, rank 2 by 3, etc.
    }

    void operator()() {
        cout << "Filter " << my_rank << ": Filtering multiples of " << prime_to_filter << endl;
        
        Item it;
        int received = 0;
        int passed = 0;
        
        while (true) {
            MPI_Recv(&it, sizeof(Item), MPI_BYTE, my_rank - 1, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
            received++;
            
            if (it.getCurrentId() == -1) {
                // Forward sentinel
                MPI_Send(&it, sizeof(Item), MPI_BYTE, my_rank + 1, 0, MPI_COMM_WORLD);
                break;
            }
            
            // Pass primes and numbers not divisible by our prime
            if (it.getCurrentId() == prime_to_filter || it.getCurrentId() % prime_to_filter != 0) {
                MPI_Send(&it, sizeof(Item), MPI_BYTE, my_rank + 1, 0, MPI_COMM_WORLD);
                passed++;
            }
        }
        
        cout << "Filter " << my_rank << ": Received " << received << ", passed " << passed << endl;
    }
};

class Sink {
public:   
    int my_rank;
    int count;

    Sink(int rank) : my_rank(rank), count(0) {}

    void operator()() {
        cout << "Sink: Starting to count primes" << endl;
        
        Item it;
        while (true) {
            MPI_Recv(&it, sizeof(Item), MPI_BYTE, my_rank - 1, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
            
            if (it.getCurrentId() == -1) break;
            
            count++;
            if (count <= 20) { // Show first 20 primes
                cout << "Prime: " << it.getCurrentId() << endl;
            }
        }
        
        cout << "Sink: Found " << count << " primes" << endl;
    }
    
    int getCount() const { return count; }
};

int main(int argc, char *argv[]) {
    MPI_Init(&argc, &argv);

    int world_rank, world_size;
    MPI_Comm_rank(MPI_COMM_WORLD, &world_rank);
    MPI_Comm_size(MPI_COMM_WORLD, &world_size);

    if (world_size < 3) {
        if (world_rank == 0) {
            cout << "Need at least 3 processes (Source + Filters + Sink)." << endl;
            cout << "Usage: mpirun -n <num_processes> ./pipeline_send_prime" << endl;
        }
        MPI_Finalize();
        return 1;
    }

    auto t_start = chrono::high_resolution_clock::now();
    int prime_count = 0;

    if (world_rank == 0) {
        // Source process
        Source source(world_size);
        source();
    } else if (world_rank == world_size - 1) {
        // Sink process (last rank)
        Sink sink(world_rank);
        sink();
        prime_count = sink.getCount();
    } else {
        // Filter processes (middle ranks)
        Filter filter(world_rank, world_size);
        filter();
    }

    // Gather the count from sink to rank 0
    if (world_rank == world_size - 1) {
        MPI_Send(&prime_count, 1, MPI_INT, 0, 0, MPI_COMM_WORLD);
    } else if (world_rank == 0) {
        MPI_Recv(&prime_count, 1, MPI_INT, world_size - 1, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
    }

    MPI_Barrier(MPI_COMM_WORLD);
    auto t_end = chrono::high_resolution_clock::now();

    if (world_rank == 0) {
        cout << "\n=== PRIME SIEVE PIPELINE (MPI) ===" << endl;
        cout << "Execution Time: " << chrono::duration<double>(t_end - t_start).count() 
             << " seconds" << endl;
        cout << "Total Primes found: " << prime_count << endl;
        cout << "Processes used: " << world_size << endl;
        cout << "Range: 2 to " << n << endl;
    }

    MPI_Finalize();
    return 0;
}