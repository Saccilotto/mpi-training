MPI = mpic++
TARGETS = original_prime prime_number_data prime_number_rankorder

.PHONY: all clean

all: $(TARGETS)

original_prime: original_prime.cpp
	$(MPI) -o original_prime original_prime.cpp

prime_number_data: prime_number_data.cpp
	$(MPI) -o prime_number_data prime_number_data.cpp

prime_number_rankorder: prime_number_rankorder.cpp
	$(MPI) -o prime_number_rankorder prime_number_rankorder.cpp

clean:
	rm -f $(TARGETS) *~
