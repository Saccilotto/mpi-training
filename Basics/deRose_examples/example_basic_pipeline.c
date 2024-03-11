#include <stdio.h>
#include "mpi.h"

main(int argc, char** argv)
  {
  int my_rank;       // Identificador deste processo
  int proc_n;        // Numero de processos disparados pelo usuario na linha de comando (np)  
  int message;       // Buffer para as mensagens                    
  MPI_Status status; // estrutura que guarda o estado de retorno          


  MPI_Init(&argc , &argv); // funcao que inicializa o MPI, todo o codigo paralelo estah abaixo

  MPI_Comm_rank(MPI_COMM_WORLD, &my_rank); // pega pega o numero do processo atual (rank)
  MPI_Comm_size(MPI_COMM_WORLD, &proc_n);  // pega informacao do numero de processos (quantidade total)

  // receber da esquerda

  if ( my_rank == 0 ) // sou o primeiro?
     message = 5;     // sim, sou o primeiro, crio a mensagem sem receber
  else
     MPI_Recv(&message, 1, MPI_INT, my_rank-1, MPI_ANY_TAG, MPI_COMM_WORLD, &status); // recebo da esquerda
     
  // processo mensagem

  printf("Pid: %d, mensagem %d\n", my_rank, message); // mostro mensagem na tela 
  message +=1; // incremento um na mensagem recebida

  // enviar para a direita

  if ( my_rank == proc_n-1 ) // sou o utlimo?
     printf("Pid: %d, sou o ultimo!\n", my_rank); // mostro mensagem na tela pois sou o ultimo
  else
     MPI_Send(&message, 1, MPI_INT, my_rank+1, 1, MPI_COMM_WORLD); // envio para a direita

  MPI_Finalize();
}
