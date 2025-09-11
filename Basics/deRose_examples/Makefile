MPI = mpicc
TARGETS = example_basic_pipeline example_hello_message example_hello

.PHONY: all clean

all: $(TARGETS)

example_basic_pipeline: example_basic_pipeline.c
	$(MPI) -o example_basic_pipeline example_basic_pipeline.c

example_hello_message: example_hello_message.c
	$(MPI) -o example_hello_message example_hello_message.c

example_hello: example_hello.c
	$(MPI) -o example_hello example_hello.c

clean:
	rm -f $(TARGETS) *~
