#!/bin/bash

################################################################################
# Script de Teste Rápido - Fases Paralelas
#
# Este script realiza testes rápidos com tamanhos pequenos para validar
# a corretude da implementação antes de rodar experimentos completos
################################################################################

echo "=========================================="
echo "Testes de Validação - Fases Paralelas"
echo "=========================================="
echo ""

# Cores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Verifica se os binários existem
if [ ! -f "./seq" ] || [ ! -f "./mpi_phases" ]; then
    echo -e "${RED}✗ Binários não encontrados!${NC}"
    echo "Execute primeiro: make seq mpi-phases"
    echo "Ou no cluster: ./compile_grad.sh"
    exit 1
fi

# Detecta ambiente
if command -v srun &> /dev/null; then
    RUN_CMD="srun --exclusive"
    ENV="GRAD/Atlantica"
else
    RUN_CMD="mpirun"
    ENV="Local"
fi

echo "Ambiente: $ENV"
echo ""

################################################################################
# Teste 1: Verificação básica (40 elementos)
################################################################################

echo "=========================================="
echo "Teste 1: Verificação com 40 elementos"
echo "=========================================="
echo ""

TEST_SIZE=40

echo "Sequencial:"
./seq $TEST_SIZE 1 | tail -3
echo ""

for np in 2 4 8; do
    echo "Paralelo ($np processos):"

    if [ "$ENV" = "Local" ]; then
        output=$(${RUN_CMD} -np $np ./mpi_phases $TEST_SIZE 1 2>&1)
    else
        output=$(${RUN_CMD} -n $np ./mpi_phases $TEST_SIZE 1 2>&1)
    fi

    # Verifica se tem erro
    if echo "$output" | grep -q "ERRO"; then
        echo -e "${RED}✗ ERRO encontrado!${NC}"
        echo "$output"
    elif echo "$output" | grep -q "CORRETAMENTE"; then
        echo -e "${GREEN}✓ Vetor ordenado corretamente${NC}"
        echo "$output" | grep "Numero de iteracoes"
        echo "$output" | grep "Tempo de execucao"
    else
        echo -e "${YELLOW}⚠ Verifique manualmente:${NC}"
        echo "$output" | tail -5
    fi
    echo ""
done

################################################################################
# Teste 2: Diferentes tamanhos
################################################################################

echo "=========================================="
echo "Teste 2: Diferentes tamanhos (4 processos)"
echo "=========================================="
echo ""

NP=4

for size in 100 1000 10000; do
    echo "Tamanho: $size elementos"

    if [ "$ENV" = "Local" ]; then
        output=$(${RUN_CMD} -np $NP ./mpi_phases $size 0 2>&1)
    else
        output=$(${RUN_CMD} -n $NP ./mpi_phases $size 0 2>&1)
    fi

    time=$(echo "$output" | grep "Tempo de execucao" | awk '{print $4}')
    iter=$(echo "$output" | grep "Numero de iteracoes" | awk '{print $4}')

    if [ -n "$time" ] && [ -n "$iter" ]; then
        echo -e "  ${GREEN}✓${NC} Tempo: ${time}s, Iterações: ${iter}"
    else
        echo -e "  ${RED}✗${NC} Falha ao executar"
    fi
    echo ""
done

################################################################################
# Teste 3: Validação com verificação completa
################################################################################

echo "=========================================="
echo "Teste 3: Validação completa (100 elementos)"
echo "=========================================="
echo ""

VERIFY_SIZE=100
VERIFY_NP=4

echo "Executando com verificação ativada..."

if [ "$ENV" = "Local" ]; then
    output=$(${RUN_CMD} -np $VERIFY_NP ./mpi_phases $VERIFY_SIZE 1 2>&1)
else
    output=$(${RUN_CMD} -n $VERIFY_NP ./mpi_phases $VERIFY_SIZE 1 2>&1)
fi

if echo "$output" | grep -q "CORRETAMENTE ordenado"; then
    echo -e "${GREEN}✓✓✓ SUCESSO! Implementação está correta${NC}"
    echo ""
    echo "$output" | grep "Numero de iteracoes"
    echo "$output" | grep "Tempo de execucao"
elif echo "$output" | grep -q "ERRO"; then
    echo -e "${RED}✗✗✗ ERRO! Vetor não está ordenado corretamente${NC}"
    echo ""
    echo "Debug output:"
    echo "$output" | grep "ERRO"
else
    echo -e "${YELLOW}⚠ Verificação não disponível (debug desabilitado?)${NC}"
fi

echo ""

################################################################################
# Teste 4: Comparação de desempenho rápida
################################################################################

echo "=========================================="
echo "Teste 4: Comparação rápida (10.000 elementos)"
echo "=========================================="
echo ""

COMP_SIZE=10000

echo "Sequencial:"
seq_output=$(./seq $COMP_SIZE 0 2>&1)
seq_time=$(echo "$seq_output" | grep "Tempo de execucao" | awk '{print $4}')
echo "  Tempo: ${seq_time}s"
echo ""

for np in 2 4 8; do
    echo "Paralelo ($np processos):"

    if [ "$ENV" = "Local" ]; then
        par_output=$(${RUN_CMD} -np $np ./mpi_phases $COMP_SIZE 0 2>&1)
    else
        par_output=$(${RUN_CMD} -n $np ./mpi_phases $COMP_SIZE 0 2>&1)
    fi

    par_time=$(echo "$par_output" | grep "Tempo de execucao" | awk '{print $4}')
    iter=$(echo "$par_output" | grep "Numero de iteracoes" | awk '{print $4}')

    if [ -n "$seq_time" ] && [ -n "$par_time" ]; then
        speedup=$(echo "scale=2; $seq_time / $par_time" | bc -l)
        efficiency=$(echo "scale=2; $speedup / $np * 100" | bc -l)

        echo "  Tempo: ${par_time}s"
        echo "  Iterações: ${iter}"
        echo "  Speedup: ${speedup}x"
        echo "  Eficiência: ${efficiency}%"
    else
        echo "  Erro ao calcular métricas"
    fi
    echo ""
done

################################################################################
# Resumo
################################################################################

echo "=========================================="
echo "Resumo dos Testes"
echo "=========================================="
echo ""
echo -e "${GREEN}✓${NC} = Sucesso   ${RED}✗${NC} = Falha   ${YELLOW}⚠${NC} = Verificar"
echo ""
echo "Próximos passos:"
echo "  1. Se todos os testes passaram, você pode rodar experimentos completos"
echo "  2. Para experimentos: ./run_phases_experiments.sh"
echo "  3. Para testes específicos, edite este script"
echo ""
