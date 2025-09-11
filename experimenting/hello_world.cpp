/*
    This code is intended to practice basic blocking communications in a 
    point-to-point enviroment with processes in a single machine.
    It implements a producer-consumer abstraction 
*/

#include <iostream>
#include <mpi.h>

int count = 0;

int main(int argc, char **argv) {
    // MPI_Init(&argc, &argv);
    // In order to not use command line arguments the NULL MPI_Init is needed(when using OPenMPI).
    MPI_Init(NULL,NULL);

    int rank;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    // Read the local value of the process
    // local_value will hold a specific int for process 0, and another for process 1
    int local_value;
    local_value = atoi(argv[1]);

    int other_value;
    while(count < 10) {
        if(rank == 0) {
            // 1- Send the value to process 1 
            // 2- Receive the value from process 1 (in other_value)
            // 3- Print the sum of the two values on stdout 
            
            MPI_Send(&local_value, 1, MPI_INT, 1, count, MPI_COMM_WORLD);
            MPI_Recv(&other_value, 1, MPI_INT, MPI_ANY_SOURCE, MPI_ANY_TAG, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
            std::cout << "Process 1: You + Me = " << other_value + count << std::endl;
            count++;
        } else {
            // 1- Receive the value from process 0 (in other_value)
            // 2- Send the value to process 0
            // 3- Print the product of the two values on stdout

            MPI_Recv(&other_value, 1, MPI_INT, MPI_ANY_SOURCE, MPI_ANY_TAG, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
            MPI_Send(&local_value, 1, MPI_INT, 0, count, MPI_COMM_WORLD);
            std::cout << "Process 2: You + Me = " << other_value + count << std::endl;
            count++;
        }
    }
    MPI_Finalize();
    return 0;
}
