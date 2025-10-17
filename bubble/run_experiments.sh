#!/bin/bash

# ============================================================
# Script de Experimentos - Bubble Sort Paralelo MPI
# ============================================================
#
# Este script executa experimentos completos e gera arquivos .dat
# para plotagem no GNUplot
#
# Uso:
#   ./run_experiments.sh [local|atlantica]
#
# ============================================================

MODE=${1:-local}  # local ou atlantica
OUTPUT_DIR="results"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configurações de experimentos
ARRAY_SIZES=(10000 100000 1000000)
PROCESSES=(1 3 7 15)
REPETITIONS=5  # Número de repetições para média

echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}   EXPERIMENTOS - BUBBLE SORT PARALELO MPI${NC}"
echo -e "${BLUE}============================================================${NC}"
echo -e "Modo: ${GREEN}$MODE${NC}"
echo -e "Diretório de saída: ${GREEN}$OUTPUT_DIR${NC}"
echo -e "Timestamp: ${GREEN}$TIMESTAMP${NC}"
echo ""

# Cria diretório de resultados
mkdir -p $OUTPUT_DIR

# Função para executar comando baseado no modo
execute_mpi() {
    local np=$1
    local size=$2
    local delta=$3

    if [ "$MODE" = "atlantica" ]; then
        # Na Atlantica: usa srun
        local nodes=$(( (np + 7) / 8 ))  # 8 cores por nó
        srun --exclusive -N $nodes -n $np ./mpi $size $delta 0
    else
        # Local: usa mpirun
        mpirun -np $np ./mpi $size $delta 0
    fi
}

# Função para extrair tempo de execução do output
extract_time() {
    grep "Tempo de execucao:" | awk '{print $4}'
}

# ============================================================
# PASSO 1: Compilar programas
# ============================================================

echo -e "${GREEN}[1/4] Compilando programas...${NC}"

if [ "$MODE" = "atlantica" ]; then
    echo "  Usando ladcomp para compilação na Atlantica..."
    ladcomp -env gcc seq.c -o seq
    ladcomp -env mpicc mpi.c -o mpi
else
    echo "  Usando make para compilação local..."
    make clean > /dev/null 2>&1
    make all > /dev/null 2>&1
fi

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Erro na compilação!${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Compilação concluída${NC}\n"

# ============================================================
# PASSO 2: Executar versão sequencial
# ============================================================

echo -e "${GREEN}[2/4] Executando versão sequencial...${NC}"

SEQ_FILE="$OUTPUT_DIR/seq_${TIMESTAMP}.dat"
echo "# Tamanho Tempo(s)" > $SEQ_FILE

for size in "${ARRAY_SIZES[@]}"; do
    echo -n "  Testando tamanho $size..."

    total_time=0
    for rep in $(seq 1 $REPETITIONS); do
        time=$(./seq $size 0 | extract_time)
        total_time=$(echo "$total_time + $time" | bc)
    done

    avg_time=$(echo "scale=6; $total_time / $REPETITIONS" | bc)
    echo "$size $avg_time" >> $SEQ_FILE
    echo -e " ${GREEN}✓${NC} (média: ${avg_time}s)"
done

echo -e "${GREEN}✓ Sequencial concluído${NC}"
echo -e "   Resultados salvos em: ${BLUE}$SEQ_FILE${NC}\n"

# ============================================================
# PASSO 3: Executar versão paralela (MPI)
# ============================================================

echo -e "${GREEN}[3/4] Executando versão paralela (MPI)...${NC}"

MPI_FILE="$OUTPUT_DIR/mpi_${TIMESTAMP}.dat"
echo "# NP Tamanho Tempo(s) Speedup Eficiencia" > $MPI_FILE

for np in "${PROCESSES[@]}"; do
    echo -e "\n  ${BLUE}Testando com $np processos:${NC}"

    for size in "${ARRAY_SIZES[@]}"; do
        echo -n "    Tamanho $size..."

        # Calcula DELTA automaticamente (deixa 0 para auto)
        delta=0

        total_time=0
        success=0

        for rep in $(seq 1 $REPETITIONS); do
            result=$(execute_mpi $np $size $delta 2>&1)
            if [ $? -eq 0 ]; then
                time=$(echo "$result" | extract_time)
                if [ ! -z "$time" ]; then
                    total_time=$(echo "$total_time + $time" | bc)
                    success=$((success + 1))
                fi
            fi
        done

        if [ $success -gt 0 ]; then
            avg_time=$(echo "scale=6; $total_time / $success" | bc)

            # Busca tempo sequencial correspondente
            seq_time=$(grep "^$size " $SEQ_FILE | awk '{print $2}')

            # Calcula speedup e eficiência
            speedup=$(echo "scale=4; $seq_time / $avg_time" | bc)
            efficiency=$(echo "scale=4; $speedup / $np" | bc)

            echo "$np $size $avg_time $speedup $efficiency" >> $MPI_FILE
            echo -e " ${GREEN}✓${NC} (tempo: ${avg_time}s, speedup: ${speedup}x)"
        else
            echo -e " ${RED}✗ Falhou${NC}"
        fi
    done
done

echo -e "\n${GREEN}✓ MPI concluído${NC}"
echo -e "   Resultados salvos em: ${BLUE}$MPI_FILE${NC}\n"

# ============================================================
# PASSO 4: Gerar arquivos de dados para GNUplot
# ============================================================

echo -e "${GREEN}[4/4] Gerando arquivos de dados para GNUplot...${NC}"

# Arquivo de tempos por tamanho
TIMES_FILE="$OUTPUT_DIR/times_by_size_${TIMESTAMP}.dat"
echo "# Tamanho Seq NP3 NP7 NP15" > $TIMES_FILE

for size in "${ARRAY_SIZES[@]}"; do
    seq_time=$(grep "^$size " $SEQ_FILE | awk '{print $2}')
    np3_time=$(grep "^3 $size " $MPI_FILE | awk '{print $3}')
    np7_time=$(grep "^7 $size " $MPI_FILE | awk '{print $3}')
    np15_time=$(grep "^15 $size " $MPI_FILE | awk '{print $3}')

    echo "$size $seq_time $np3_time $np7_time $np15_time" >> $TIMES_FILE
done

# Arquivo de speedup por número de processos
SPEEDUP_FILE="$OUTPUT_DIR/speedup_${TIMESTAMP}.dat"
echo "# Size NP Speedup" > $SPEEDUP_FILE
grep -v "^#" $MPI_FILE | awk '{print $2, $1, $4}' >> $SPEEDUP_FILE

# Arquivo de eficiência
EFFICIENCY_FILE="$OUTPUT_DIR/efficiency_${TIMESTAMP}.dat"
echo "# Size NP Efficiency" > $EFFICIENCY_FILE
grep -v "^#" $MPI_FILE | awk '{print $2, $1, $5}' >> $EFFICIENCY_FILE

echo -e "${GREEN}✓ Arquivos gerados:${NC}"
echo -e "   - ${BLUE}$TIMES_FILE${NC}"
echo -e "   - ${BLUE}$SPEEDUP_FILE${NC}"
echo -e "   - ${BLUE}$EFFICIENCY_FILE${NC}"

# ============================================================
# RESUMO
# ============================================================

echo ""
echo -e "${BLUE}============================================================${NC}"
echo -e "${GREEN}   EXPERIMENTOS CONCLUÍDOS!${NC}"
echo -e "${BLUE}============================================================${NC}"
echo ""
echo "Para gerar gráficos, execute:"
echo -e "  ${GREEN}gnuplot plot_results.gnuplot${NC}"
echo ""
echo "Arquivos de dados estão em: ${BLUE}$OUTPUT_DIR/${NC}"
echo ""
