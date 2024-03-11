#include <mpi.h>
#include <iostream>

int main(int argc, char** argv) {
    //Initializing MPI without main arguments (useful for manipulating in terminal interface argument passing as a normal program)
    MPI_Init(NULL,NULL);
    //MPI_Init(&argc,&argv)
    int world_size, rank;
    // MPI_COMM_WORLD is the default startup communicator(abstraction that establishes communication between processes)

    // Get the number of processes 
    MPI_Comm_size(MPI_COMM_WORLD, &world_size); 
    // Get the rank(int id) inside the current process
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);

    std::cout << "Helo world, from process #" << rank << std::endl;

    int MPI_Finalize();
    return 0;
}