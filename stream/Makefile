MPI = mpic++
TARGET = stream_prime pipeline_send_prime

.PHONY: all clean

all: $(TARGET)

stream_prime: stream_prime.cpp concurrentQueue.hpp
	$(MPI) -o stream_prime stream_prime.cpp

pipeline_send_prime: pipeline_send_prime.cpp concurrentQueue.hpp
	$(MPI) -o pipeline_send_prime pipeline_send_prime.cpp

clean:
	rm -f $(TARGET) *~
