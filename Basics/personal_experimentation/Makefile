MPI = mpic++
TARGET = hello hello_world blocking non_blocking

.PHONY: all clean cleanall 

all:$(TARGET)

hello: hello.cpp
	$(MPI) -o hello hello.cpp

hello_world: hello_world.cpp
	$(MPI) -o hello_world hello_world.cpp

blocking: blocking.cpp
	$(MPI) -o blocking blocking.cpp

non_blocking: non_blocking.cpp
	$(MPI) -o non_blocking non_blocking.cpp

cleanall: clean
	rm -fr $(TARGET) *~ 


