#include <iostream>
#include <unistd.h>
#include <mpi.h>

int buffer_count;
int rank;

void non_blocking() {
    MPI_Request request;
    MPI_Status  status;
    int request_finished = 0;

    int buffer[buffer_count];


    MPI_Barrier(MPI_COMM_WORLD);
    // Starting the chronometer
    double time = -MPI_Wtime(); 
    if (rank == 0) {
        sleep(3);
        
        // Initialising buffer :
        std::cout << "Process 0 is sending : ";
        for (int i = 0; i < buffer_count;++i) {
            buffer[i] = (rank == 0 ? i*2 : 0);
            std::cout << buffer[i] << " ";
        }
        std::cout << std::endl;
        // 1- Initialise the non-blocking send to process 1
        // [...]
        MPI_Isend(buffer, buffer_count, MPI_INT, 1, 0, MPI_COMM_WORLD, &request);
        
        double time_left = 6000.0;
        while (time_left > 0.0) {
            usleep(1000); // We work for 1ms

            // 2- Test if the request is finished (only if not already finished)
            // [...]
            if(!request_finished) {
                MPI_Test(&request, &request_finished, &status);
            }
            // 1ms left to work
            time_left -= 1000.0;
        }

        // 3- If the request is not yet complete, wait here. 
        // [...]
        if(!request_finished) {
            MPI_Wait(&request, &status);
        }

        // Modifying the buffer for second step
        std::cout << "Process 0 is sending : ";
        for (int i=0; i < buffer_count; ++i) {
            buffer[i] = -i;
            std::cout << buffer[i] << " ";
        }
        std::cout << std::endl;

        // 4- Prepare another request for process 1 with a different tag
        // [...]
        MPI_Isend(buffer, buffer_count, MPI_INT, 1, 1, MPI_COMM_WORLD, &request);

        time_left = 3000.0;
        while (time_left > 0.0) {
            usleep(1000); // We work for 1ms

            // 5- Test if the request is finished (only if not already finished)
            // [...]
            if(!request_finished) {
                MPI_Test(&request, &request_finished, &status);
            }

            // 1ms left to work
            time_left -= 1000.0;
        }
        // 6- Wait for it to finish
        // [...]
        if(!request_finished) {
            MPI_Wait(&request, &status);
        }
    }else {
        // Work for 5 seconds
        sleep(5);

        // 7- Initialise the non-blocking receive from process 0
        // [...]
        MPI_Irecv(buffer, buffer_count, MPI_INT, 0, 0, MPI_COMM_WORLD, &request);
        // 8- Wait here for the request to be completed
        // [...]
        MPI_Wait(&request, &status);

        std::cout << "Process 1 received : ";
        for(int i = 0;i < buffer_count;++i) {
            std::cout << buffer[i] << " ";
        }
        std::cout << std::endl;

        // Work for 3 seconds
        sleep(3);

        // 9- Initialise another non-blocking receive
        // [...]
        MPI_Irecv(buffer, buffer_count, MPI_INT, 0, 1, MPI_COMM_WORLD, &request);
        // 10- Wait for it to be completed
        // [...]
        MPI_Wait(&request, &status);

        std::cout << "Process 1 received : ";
        for(int i = 0;i < buffer_count;++i) {
            std::cout << buffer[i] << " ";
        }
        std::cout << std::endl;
    }
    ////////// should not modify anything AFTER this point //////////

    // Stopping the chronometer
    time += MPI_Wtime();

    double final_time;
    MPI_Reduce(&time, &final_time, 1, MPI_DOUBLE, MPI_MAX, 0, MPI_COMM_WORLD);

    if (rank == 0) {
        std::cout << "Total time for non-blocking scenario : " << final_time << "s" << std::endl;
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

    non_blocking();

    MPI_Finalize();
    return 0;
}
