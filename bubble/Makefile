# ============================================================
# Makefile para Bubble Sort Sequencial e Paralelo (MPI)
# ============================================================

# Compiladores
CC = gcc
MPICC = mpicc

# Flags de compilação
CFLAGS = -Wall -Wextra -O2
DEBUG_FLAGS = -g

# Arquivos fonte
SEQ_SRC = seq.c
MPI_SRC = mpi.c

# Executáveis
SEQ_BIN = seq
MPI_BIN = mpi

# Número de processos padrão para MPI
NP ?= 7

# Parâmetros padrão
SIZE ?= 40
DELTA ?= 10
DEBUG ?= 0

# ============================================================
# TARGETS DE COMPILAÇÃO
# ============================================================

.PHONY: all seq mpi clean help

all: seq mpi

seq: $(SEQ_SRC)
	@echo "Compilando versão sequencial..."
	$(CC) $(CFLAGS) $(SEQ_SRC) -o $(SEQ_BIN)
	@echo "✓ Compilação concluída: ./$(SEQ_BIN)"

mpi: $(MPI_SRC)
	@echo "Compilando versão paralela (MPI)..."
	$(MPICC) $(CFLAGS) $(MPI_SRC) -o $(MPI_BIN)
	@echo "✓ Compilação concluída: ./$(MPI_BIN)"

# Compilação com símbolos de debug
debug-seq: $(SEQ_SRC)
	@echo "Compilando versão sequencial com debug..."
	$(CC) $(CFLAGS) $(DEBUG_FLAGS) $(SEQ_SRC) -o $(SEQ_BIN)

debug-mpi: $(MPI_SRC)
	@echo "Compilando versão paralela (MPI) com debug..."
	$(MPICC) $(CFLAGS) $(DEBUG_FLAGS) $(MPI_SRC) -o $(MPI_BIN)

# ============================================================
# TARGETS DE TESTE RÁPIDO
# ============================================================

test-seq: seq
	@echo "\n========== TESTE SEQUENCIAL (SIZE=$(SIZE)) =========="
	./$(SEQ_BIN) $(SIZE) $(DEBUG)

test-mpi: mpi
	@echo "\n========== TESTE MPI (NP=$(NP), SIZE=$(SIZE), DELTA=$(DELTA)) =========="
	mpirun -np $(NP) ./$(MPI_BIN) $(SIZE) $(DELTA) $(DEBUG)

# Teste com diferentes números de processos
test-mpi-np3: mpi
	@echo "\n========== TESTE MPI (3 processos) =========="
	mpirun -np 3 ./$(MPI_BIN) $(SIZE) $(DELTA) $(DEBUG)

test-mpi-np7: mpi
	@echo "\n========== TESTE MPI (7 processos) =========="
	mpirun -np 7 ./$(MPI_BIN) $(SIZE) $(DELTA) $(DEBUG)

test-mpi-np15: mpi
	@echo "\n========== TESTE MPI (15 processos) =========="
	mpirun -np 15 ./$(MPI_BIN) $(SIZE) $(DELTA) $(DEBUG)

# ============================================================
# BENCHMARKS - TAMANHOS PEQUENOS (DEBUG ON)
# ============================================================

bench-small: all
	@echo "\n========== BENCHMARK - TAMANHO PEQUENO (40 elementos) =========="
	@echo "\n--- Sequencial ---"
	./$(SEQ_BIN) 40 1
	@echo "\n--- MPI (7 processos) ---"
	mpirun -np 7 ./$(MPI_BIN) 40 10 1

# ============================================================
# BENCHMARKS - MEDIÇÕES DE DESEMPENHO (DEBUG OFF)
# ============================================================

bench-seq-10k: seq
	@echo "\n========== BENCHMARK SEQUENCIAL - 10.000 elementos =========="
	./$(SEQ_BIN) 10000 0

bench-seq-100k: seq
	@echo "\n========== BENCHMARK SEQUENCIAL - 100.000 elementos =========="
	./$(SEQ_BIN) 100000 0

bench-seq-1m: seq
	@echo "\n========== BENCHMARK SEQUENCIAL - 1.000.000 elementos =========="
	./$(SEQ_BIN) 1000000 0

bench-mpi-10k: mpi
	@echo "\n========== BENCHMARK MPI - 10.000 elementos =========="
	@echo "--- 3 processos (DELTA=2500) ---"
	mpirun -np 3 ./$(MPI_BIN) 10000 2500 0
	@echo "\n--- 7 processos (DELTA=1250) ---"
	mpirun -np 7 ./$(MPI_BIN) 10000 1250 0
	@echo "\n--- 15 processos (DELTA=625) ---"
	mpirun -np 15 ./$(MPI_BIN) 10000 625 0

bench-mpi-100k: mpi
	@echo "\n========== BENCHMARK MPI - 100.000 elementos =========="
	@echo "--- 3 processos (DELTA=25000) ---"
	mpirun -np 3 ./$(MPI_BIN) 100000 25000 0
	@echo "\n--- 7 processos (DELTA=12500) ---"
	mpirun -np 7 ./$(MPI_BIN) 100000 12500 0
	@echo "\n--- 15 processos (DELTA=6250) ---"
	mpirun -np 15 ./$(MPI_BIN) 100000 6250 0

bench-mpi-1m: mpi
	@echo "\n========== BENCHMARK MPI - 1.000.000 elementos =========="
	@echo "--- 3 processos (DELTA=250000) ---"
	mpirun -np 3 ./$(MPI_BIN) 1000000 250000 0
	@echo "\n--- 7 processos (DELTA=125000) ---"
	mpirun -np 7 ./$(MPI_BIN) 1000000 125000 0
	@echo "\n--- 15 processos (DELTA=62500) ---"
	mpirun -np 15 ./$(MPI_BIN) 1000000 62500 0

# ============================================================
# BENCHMARKS COMPLETOS
# ============================================================

bench-all-seq: bench-seq-10k bench-seq-100k bench-seq-1m

bench-all-mpi: bench-mpi-10k bench-mpi-100k bench-mpi-1m

bench-all: bench-all-seq bench-all-mpi

# ============================================================
# TESTES DE CORRETUDE
# ============================================================

verify: all
	@echo "\n========== VERIFICAÇÃO DE CORRETUDE =========="
	@echo "\n--- Sequencial (40 elementos) ---"
	@./$(SEQ_BIN) 40 1 | grep -q "\[001\].*\[040\]" && echo "✓ Sequencial OK" || echo "✗ Sequencial FALHOU"
	@echo "\n--- MPI (40 elementos, 7 processos) ---"
	@mpirun -np 7 ./$(MPI_BIN) 40 10 1 | grep -q "\[001\].*\[040\]" && echo "✓ MPI OK" || echo "✗ MPI FALHOU"

# ============================================================
# ANÁLISE DE SPEEDUP
# ============================================================

speedup-analysis: all
	@echo "\n========== ANÁLISE DE SPEEDUP (10.000 elementos) =========="
	@echo "\nSEQUENCIAL:"
	@./$(SEQ_BIN) 10000 0 | grep "Tempo"
	@echo "\nMPI - 3 processos:"
	@mpirun -np 3 ./$(MPI_BIN) 10000 2500 0 | grep "Tempo"
	@echo "\nMPI - 7 processos:"
	@mpirun -np 7 ./$(MPI_BIN) 10000 1250 0 | grep "Tempo"
	@echo "\nMPI - 15 processos:"
	@mpirun -np 15 ./$(MPI_BIN) 10000 625 0 | grep "Tempo"

# ============================================================
# UTILIDADES
# ============================================================

clean:
	@echo "Limpando arquivos compilados..."
	rm -f $(SEQ_BIN) $(MPI_BIN)
	@echo "✓ Limpeza concluída"

help:
	@echo "============================================================"
	@echo "Makefile - Bubble Sort Sequencial e Paralelo (MPI)"
	@echo "============================================================"
	@echo ""
	@echo "COMPILAÇÃO:"
	@echo "  make all         - Compila versão sequencial e MPI"
	@echo "  make seq         - Compila apenas versão sequencial"
	@echo "  make mpi         - Compila apenas versão MPI"
	@echo ""
	@echo "TESTES RÁPIDOS:"
	@echo "  make test-seq              - Testa versão sequencial"
	@echo "  make test-mpi              - Testa versão MPI"
	@echo "  make test-mpi-np3/7/15     - Testa MPI com 3/7/15 processos"
	@echo ""
	@echo "BENCHMARKS:"
	@echo "  make bench-small           - Benchmark com 40 elementos (debug)"
	@echo "  make bench-seq-10k/100k/1m - Benchmark sequencial"
	@echo "  make bench-mpi-10k/100k/1m - Benchmark MPI (múltiplos processos)"
	@echo "  make bench-all             - Executa todos os benchmarks"
	@echo ""
	@echo "ANÁLISE:"
	@echo "  make verify                - Verifica corretude dos algoritmos"
	@echo "  make speedup-analysis      - Análise de speedup"
	@echo ""
	@echo "PARÂMETROS CUSTOMIZADOS:"
	@echo "  make test-seq SIZE=100 DEBUG=1"
	@echo "  make test-mpi NP=15 SIZE=1000 DELTA=100 DEBUG=0"
	@echo ""
	@echo "LIMPEZA:"
	@echo "  make clean       - Remove executáveis compilados"
	@echo ""
	@echo "============================================================"
