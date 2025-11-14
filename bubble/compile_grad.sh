#!/bin/bash

################################################################################
# Script de Compilação para o Cluster Grad
#
# Este script carrega os módulos necessários e compila os programas
# para execução no cluster Grad
################################################################################

echo "=================================="
echo "Compilação para o Cluster Grad"
echo "=================================="
echo ""

# Carrega módulo MPI (ajuste conforme o cluster)
echo "Carregando módulos..."

# Tenta carregar OpenMPI (ajuste o nome do módulo conforme necessário)
if module avail 2>&1 | grep -q "openmpi"; then
    module load openmpi
    echo "✓ OpenMPI carregado"
elif module avail 2>&1 | grep -q "mpich"; then
    module load mpich
    echo "✓ MPICH carregado"
else
    echo "⚠ Nenhum módulo MPI encontrado - assumindo que MPI já está no PATH"
fi

echo ""

# Verifica se mpicc está disponível
if ! command -v mpicc &> /dev/null; then
    echo "ERRO: mpicc não encontrado!"
    echo "Verifique se o módulo MPI foi carregado corretamente."
    echo ""
    echo "Módulos disponíveis:"
    module avail
    exit 1
fi

echo "Compilador MPI encontrado:"
which mpicc
mpicc --version | head -1
echo ""

# Compilação
echo "=================================="
echo "Compilando programas..."
echo "=================================="
echo ""

# Versão sequencial
echo "[1/3] Compilando versão sequencial (seq)..."
gcc -Wall -Wextra -O2 seq.c -o seq
if [ $? -eq 0 ]; then
    echo "✓ seq compilado com sucesso"
else
    echo "✗ Erro ao compilar seq"
    exit 1
fi
echo ""

# Versão paralela - Fases Paralelas
echo "[2/3] Compilando versão MPI - Fases Paralelas (mpi_phases)..."
mpicc -Wall -Wextra -O2 mpi_bubblesort_phases.c -lm -o mpi_phases
if [ $? -eq 0 ]; then
    echo "✓ mpi_phases compilado com sucesso"
else
    echo "✗ Erro ao compilar mpi_phases"
    exit 1
fi
echo ""

# Versão paralela - Divisão e Conquista (para comparação)
echo "[3/3] Compilando versão MPI - Divisão e Conquista (mpi_merge)..."
if [ -f "mpi_bubblesort.c" ]; then
    mpicc -Wall -Wextra -O2 mpi_bubblesort.c -lm -o mpi_merge
    if [ $? -eq 0 ]; then
        echo "✓ mpi_merge compilado com sucesso"
    else
        echo "✗ Erro ao compilar mpi_merge"
    fi
else
    echo "⚠ mpi_bubblesort.c não encontrado - pulando"
fi
echo ""

echo "=================================="
echo "Compilação concluída!"
echo "=================================="
echo ""
echo "Executáveis gerados:"
ls -lh seq mpi_phases mpi_merge 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}'
echo ""
echo "Próximos passos:"
echo "  1. Teste rápido: ./seq 40 1"
echo "  2. Teste MPI: mpirun -np 4 ./mpi_phases 40 1"
echo "  3. Experimentos: ./run_phases_experiments.sh"
echo ""
