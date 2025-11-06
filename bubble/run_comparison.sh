#!/bin/bash

# ============================================================
# Script de Comparação - Bubble Sort MPI: Merge vs Odd-Even
# ============================================================
#
# Este script compara as duas implementações:
#   1. mpi_bubblesort.c (com interleaving/merge)
#   2. mpi_bubblesort_extra.c (com odd-even transposition)
#
# Uso:
#   ./run_comparison.sh [local|atlantica]
#
# ============================================================

MODE=${1:-local}  # local ou atlantica
OUTPUT_DIR="results"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configurações de experimentos
ARRAY_SIZES=(10000 100000 1000000)
PROCESSES=(3 7 15)
REPETITIONS=3  # Número de repetições para média

echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}   COMPARAÇÃO: MERGE vs ODD-EVEN - BUBBLE SORT MPI${NC}"
echo -e "${BLUE}============================================================${NC}"
echo -e "Modo: ${GREEN}$MODE${NC}"
echo -e "Diretório de saída: ${GREEN}$OUTPUT_DIR${NC}"
echo -e "Timestamp: ${GREEN}$TIMESTAMP${NC}"
echo ""

# Cria diretório de resultados
mkdir -p $OUTPUT_DIR

# Função para executar MPI baseado no modo
execute_mpi() {
    local binary=$1
    local np=$2
    local size=$3
    local delta=$4

    if [ "$MODE" = "atlantica" ]; then
        # Na Atlantica: usa srun
        local nodes=$(( (np + 7) / 8 ))  # 8 cores por nó
        srun --exclusive -N $nodes -n $np ./$binary $size $delta 0 2>&1
    else
        # Local: usa mpirun
        mpirun -np $np ./$binary $size $delta 0 2>&1
    fi
}

# Função para executar versão odd-even (sem DELTA)
execute_oddeven() {
    local np=$1
    local size=$2

    if [ "$MODE" = "atlantica" ]; then
        local nodes=$(( (np + 7) / 8 ))
        srun --exclusive -N $nodes -n $np ./mpi_oddeven $size 2>&1
    else
        mpirun -np $np ./mpi_oddeven $size 2>&1
    fi
}

# Função para extrair tempo de execução
extract_time() {
    grep "Tempo de execucao:\|Elapsed =" | grep -oP '[\d.]+' | tail -1
}

# ============================================================
# PASSO 1: Compilar programas
# ============================================================

echo -e "${GREEN}[1/5] Compilando programas...${NC}"

if [ "$MODE" = "atlantica" ]; then
    echo "  Usando ladcomp para compilação na Atlantica..."
    ladcomp -env gcc seq.c -o seq 2>&1 | grep -v "^$"
    ladcomp -env mpicc mpi_bubblesort.c -lm -o mpi_merge 2>&1 | grep -v "^$"
    ladcomp -env mpicc mpi_bubblesort_extra.c -lm -o mpi_oddeven 2>&1 | grep -v "^$"
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
# PASSO 2: Executar versão sequencial (baseline)
# ============================================================

echo -e "${GREEN}[2/5] Executando versão sequencial (baseline)...${NC}"

SEQ_FILE="$OUTPUT_DIR/seq_${TIMESTAMP}.dat"
echo "# Tamanho Tempo(s)" > $SEQ_FILE

for size in "${ARRAY_SIZES[@]}"; do
    echo -n "  Testando tamanho $size..."

    total_time=0
    success=0

    for rep in $(seq 1 $REPETITIONS); do
        result=$(./seq $size 0 2>&1)
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
        echo "$size $avg_time" >> $SEQ_FILE
        echo -e " ${GREEN}✓${NC} (média: ${avg_time}s)"
    else
        echo -e " ${RED}✗ Falhou${NC}"
    fi
done

echo -e "${GREEN}✓ Sequencial concluído${NC}\n"

# ============================================================
# PASSO 3: Executar versão MPI com MERGE (interleaving)
# ============================================================

echo -e "${GREEN}[3/5] Executando MPI com MERGE (interleaving)...${NC}"

MERGE_FILE="$OUTPUT_DIR/merge_${TIMESTAMP}.dat"
echo "# NP Tamanho Tempo(s) Speedup Eficiencia" > $MERGE_FILE

for np in "${PROCESSES[@]}"; do
    echo -e "\n  ${BLUE}Testando com $np processos:${NC}"

    for size in "${ARRAY_SIZES[@]}"; do
        echo -n "    Tamanho $size..."

        total_time=0
        success=0

        for rep in $(seq 1 $REPETITIONS); do
            result=$(execute_mpi mpi_merge $np $size 0)
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

            echo "$np $size $avg_time $speedup $efficiency" >> $MERGE_FILE
            echo -e " ${GREEN}✓${NC} (${avg_time}s, speedup: ${speedup}x)"
        else
            echo -e " ${RED}✗ Falhou${NC}"
        fi
    done
done

echo -e "\n${GREEN}✓ MPI MERGE concluído${NC}\n"

# ============================================================
# PASSO 4: Executar versão MPI com ODD-EVEN
# ============================================================

echo -e "${GREEN}[4/5] Executando MPI com ODD-EVEN transposition...${NC}"

ODDEVEN_FILE="$OUTPUT_DIR/oddeven_${TIMESTAMP}.dat"
echo "# NP Tamanho Tempo(s) Speedup Eficiencia" > $ODDEVEN_FILE

for np in "${PROCESSES[@]}"; do
    echo -e "\n  ${BLUE}Testando com $np processos:${NC}"

    for size in "${ARRAY_SIZES[@]}"; do
        echo -n "    Tamanho $size..."

        total_time=0
        success=0

        for rep in $(seq 1 $REPETITIONS); do
            result=$(execute_oddeven $np $size)
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

            echo "$np $size $avg_time $speedup $efficiency" >> $ODDEVEN_FILE
            echo -e " ${GREEN}✓${NC} (${avg_time}s, speedup: ${speedup}x)"
        else
            echo -e " ${RED}✗ Falhou${NC}"
        fi
    done
done

echo -e "\n${GREEN}✓ MPI ODD-EVEN concluído${NC}\n"

# ============================================================
# PASSO 5: Gerar arquivos comparativos
# ============================================================

echo -e "${GREEN}[5/5] Gerando arquivos comparativos...${NC}"

# Arquivo de comparação direta: Merge vs Odd-Even
COMPARISON_FILE="$OUTPUT_DIR/comparison_${TIMESTAMP}.dat"
echo "# NP Tamanho Merge_Time OddEven_Time Merge_Speedup OddEven_Speedup" > $COMPARISON_FILE

for np in "${PROCESSES[@]}"; do
    for size in "${ARRAY_SIZES[@]}"; do
        merge_data=$(grep "^$np $size " $MERGE_FILE)
        oddeven_data=$(grep "^$np $size " $ODDEVEN_FILE)

        if [ ! -z "$merge_data" ] && [ ! -z "$oddeven_data" ]; then
            merge_time=$(echo "$merge_data" | awk '{print $3}')
            merge_speedup=$(echo "$merge_data" | awk '{print $4}')
            oddeven_time=$(echo "$oddeven_data" | awk '{print $3}')
            oddeven_speedup=$(echo "$oddeven_data" | awk '{print $4}')

            echo "$np $size $merge_time $oddeven_time $merge_speedup $oddeven_speedup" >> $COMPARISON_FILE
        fi
    done
done

echo -e "${GREEN}✓ Arquivos comparativos gerados:${NC}"
echo -e "   - ${BLUE}$SEQ_FILE${NC}"
echo -e "   - ${BLUE}$MERGE_FILE${NC}"
echo -e "   - ${BLUE}$ODDEVEN_FILE${NC}"
echo -e "   - ${BLUE}$COMPARISON_FILE${NC}"

# ============================================================
# RESUMO
# ============================================================

echo ""
echo -e "${BLUE}============================================================${NC}"
echo -e "${GREEN}   COMPARAÇÃO CONCLUÍDA!${NC}"
echo -e "${BLUE}============================================================${NC}"
echo ""
echo "Para gerar gráficos comparativos, execute:"
echo -e "  ${GREEN}gnuplot plot_comparison.gnuplot${NC}"
echo ""
echo "Arquivos de dados estão em: ${BLUE}$OUTPUT_DIR/${NC}"
echo ""
