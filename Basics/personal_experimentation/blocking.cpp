/*
    This code is intended to practice blocking communications in a 
    point-to-point enviroment with processes in a single machine.
    Its design focuses on visualizing the exact time where a process 
    sends and receives a message. 
*/

#include <iostream>
#include <unistd.h>
#include <mpi.h>

int buffer_count;
int rank;

void blocking() {
    int buffer[buffer_count];
    for(int i = 0;i < buffer_count; ++i) {
        buffer[i] = (rank == 0 ? i * 2:0);
    }
    // blocks all processes until all inside the communicator reach this command in the program. 
    MPI_Barrier(MPI_COMM_WORLD);

    /* 
        Measuring time on MPI:
        Store it "inside" a double
        for start counting.
            Start: -MPI_Wtime();
        Get counter when done.
            End:  var = var +  MPI_Wtime()
    */

    // Starting the chronometer
    double time = -MPI_Wtime(); 

    // Sleeping should simulate working processes.

    if(rank == 0) {
        sleep(2);
        MPI_Send(buffer, buffer_count, MPI_INT, 1, 0, MPI_COMM_WORLD);
        sleep(4);

        for(int i = 0;i < buffer_count;++i) {
            buffer[i] = -i;
        }
        MPI_Send(buffer, buffer_count, MPI_INT, 1, 1, MPI_COMM_WORLD);
    } else {
        sleep(3);
        MPI_Recv(buffer, buffer_count, MPI_INT, 0, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
        sleep(1);
        MPI_Recv(buffer, buffer_count, MPI_INT, 0, 1, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
    }

    // Stoping the chronometer.
    time += MPI_Wtime();
    // Store the last time received.
    double final_time;
    
    /*
        MPI_Reduce: Used for updating a memory value from a process.
        MPI_Reduce(&var, &memory_value_to_be_updated, size, MPI_type, MPI_Operation, root_process_that_holds_the_value, communicator);
    */

    // MPI_Reduce for updating final_time var with the highest value produces from each process.
    MPI_Reduce(&time, &final_time, 1, MPI_DOUBLE, MPI_MAX, 0, MPI_COMM_WORLD);

    if(rank == 0) {
        std::cout << "Total time for blocking scenario: " << final_time << "s" << std::endl;
    }
}

int main(int argc, char **argv) {
    int setup = MPI_Init(NULL,NULL);

    if(setup != MPI_SUCCESS) {
        std::cout << stderr << "Unable to set up MPI environment.";
        MPI_Abort(MPI_COMM_WORLD, setup);
    }

    MPI_Comm_size(MPI_COMM_WORLD, &buffer_count);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);

    blocking();

    MPI_Finalize();
    return 0;
}
