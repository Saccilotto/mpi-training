#include <cstdlib>
#include <cstdio>
#include <chrono>
#include <iostream>
#include <getopt.h>
#include <cstring>
#include "concurrentQueue.hpp"
#include <mpi.h>

using namespace concurrent::queue;
using namespace std;

int workers;
int total;
int n=500000;

struct Item {

private:
	static int start;

public:
	bool isLast;
	int id = start;

    Item() {
		setIsLast();
		nextId();
    }

	Item(int i) {
		start = i;
		setIsLast();
		nextId();
    }

    void setIsLast() {
		id >= n ? isLast = true:isLast = false;
    }
 
    void nextId() {
		id++;
    }

    int getCurrentId() {
		return id;
    }

    bool getIsLast() { 
		return isLast;
    }  
};

blocking_queue<Item> queue1;
blocking_queue<Item> queue2;
int Item::start = 2;

class Source {
public:   

    Source(){}

    void operator()() {
		while(1){  
            Item it;  
            if(it.getIsLast()) {                         
                queue1.enqueue(it);     
                break;
            }               
            queue1.enqueue(it);    
        }
		return;
    };
};

class Computation {
public:   
	int prime = 1;
	int max;
	int j = 2;

	Computation(int _max):
		max(_max)
	{}

    Computation(int start, int _max):
		j(start),
		max(_max)
	{}

    void operator()() {
		while(1) {
			Item it = queue1.dequeue(); 

			if(it.getCurrentId() >= n) { //iterate based on process number's respective chunk
				break;
			}

			if(it.getCurrentId() % j == 0) {
				break;
			}

			if(j >= it.getCurrentId()) {
				queue2.enqueue(it);
			}
			j++;
		}
		return;
	};
};

class Sink {
public:   

    Sink(){}

    void operator()() {
		while(1) {
			Item it = queue2.dequeue(); 
			if(it.getCurrentId() >= n) {
				break;
			}
			total = total + 1;
		}
		return;
    };
};

int main (int argc, char *argv[]){
	MPI_Comm world, workers;
	MPI_Group world_group, worker_group; 
	int rank, size, number_workers;
	int chunk = 0;

	MPI_Init(&argc, &argv);
	world = MPI_COMM_WORLD;

	MPI_Comm_rank(MPI_COMM_WORLD, &rank);
	MPI_Comm_size(MPI_COMM_WORLD, &size);

	int ranges[3] = {1, size - 2, 1};
	MPI_Comm_group(world, &world_group);
	MPI_Group_incl(world_group, 1, ranges, &worker_group);
	MPI_Comm_create(world, world_group, &workers);
	MPI_Comm_size(workers, &number_workers);

	auto t_start = std::chrono::high_resolution_clock::now();
	if(rank == 0) {
		Source();
	}

	if(rank > 0 && rank < size - 2) {
		chunk += n/number_workers;
		if(rank == 1) {
			Computation(n/number_workers);
		} else {
			Computation(chunk, chunk + n/number_workers);
		}
	}

	if(rank == size - 1) {
		Sink();
	}
	
	MPI_Barrier(MPI_COMM_WORLD);
	auto t_end = std::chrono::high_resolution_clock::now();

	if(rank == 0) {
		std::cout << "\n PRIME APP (CPP Parallel MPI version) \nNormal end of execution." << std::endl;
		std::cout << "Execution Time(seconds): "  <<  std::chrono::duration<double>(t_end-t_start).count() << " Primes: " << total << std::endl;
	}

	MPI_Group_free(&worker_group);
	MPI_Comm_free(&workers);
	MPI_Finalize();
	return 0;
}