#!/bin/bash

# ============================================================
# Script OTIMIZADO para o Trabalho - Máximo 2 horas
# ============================================================
#
# Estratégia:
#   - 1M elementos: 1 repetição (para o trabalho)
#   - 100k elementos: 3 repetições (para std dev)
#   - ODD-EVEN: apenas 100k (comparação com std dev)
#
# Tempo estimado: ~110-120 minutos
#
# ============================================================

MODE=${1:-atlantica}
OUTPUT_DIR="results"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configurações
ARRAY_SIZES_SINGLE=(1000000)      # 1M: apenas 1 execução
ARRAY_SIZES_MULTIPLE=(100000)     # 100k: 3 execuções (std dev)
PROCESSES=(3 7 15)
REPS_SINGLE=1                      # Para 1M
REPS_MULTIPLE=3                    # Para 100k (std dev)

echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}   EXPERIMENTOS OTIMIZADOS - BUBBLE SORT MPI${NC}"
echo -e "${BLUE}   Tempo estimado: ~2 horas${NC}"
echo -e "${BLUE}============================================================${NC}"
echo -e "Modo: ${GREEN}$MODE${NC}"
echo -e "Timestamp: ${GREEN}$TIMESTAMP${NC}"
echo ""
echo "Estratégia:"
echo "  - 1M elementos: 1 execução (trabalho)"
echo "  - 100k elementos: 3 execuções (std dev)"
echo "  - ODD-EVEN: apenas 100k"
echo ""

mkdir -p $OUTPUT_DIR

# ============================================================
# Funções
# ============================================================

execute_mpi() {
    local binary=$1
    local np=$2
    local size=$3
    local delta=$4

    if [ "$MODE" = "atlantica" ]; then
        local nodes=$(( (np + 7) / 8 ))
        srun --exclusive -N $nodes -n $np ./$binary $size $delta 0 2>&1
    else
        mpirun -np $np ./$binary $size $delta 0 2>&1
    fi
}

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

extract_time() {
    grep "Tempo de execucao:\|Elapsed =" | grep -oP '[\d.]+' | tail -1
}

# ============================================================
# PASSO 1: Compilar
# ============================================================

echo -e "${GREEN}[1/5] Compilando...${NC}"

if [ "$MODE" = "atlantica" ]; then
    ladcomp -env gcc seq.c -o seq 2>&1 | grep -v "^$"
    ladcomp -env mpicc mpi_bubblesort.c -lm -o mpi_merge 2>&1 | grep -v "^$"
    ladcomp -env mpicc mpi_bubblesort_extra.c -lm -o mpi_oddeven 2>&1 | grep -v "^$"
else
    make clean > /dev/null 2>&1
    make all > /dev/null 2>&1
fi

echo -e "${GREEN}✓ Compilação concluída${NC}\n"

# ============================================================
# PASSO 2: Sequencial
# ============================================================

echo -e "${GREEN}[2/5] Executando sequencial...${NC}"

SEQ_FILE="$OUTPUT_DIR/seq_${TIMESTAMP}.dat"
echo "# Tamanho Tempo(s) StdDev" > $SEQ_FILE

# 1M - 1 execução
for size in "${ARRAY_SIZES_SINGLE[@]}"; do
    echo -n "  ${size} elementos (1 exec)..."
    time=$(./seq $size 0 2>&1 | extract_time)
    echo "$size $time 0.0" >> $SEQ_FILE
    echo -e " ${GREEN}✓${NC} (${time}s)"
done

# 100k - 3 execuções (para std dev)
for size in "${ARRAY_SIZES_MULTIPLE[@]}"; do
    echo -n "  ${size} elementos (3 execs)..."

    times=()
    for rep in $(seq 1 $REPS_MULTIPLE); do
        t=$(./seq $size 0 2>&1 | extract_time)
        times+=($t)
    done

    # Calcula média e std dev
    sum=0
    for t in "${times[@]}"; do
        sum=$(echo "$sum + $t" | bc)
    done
    avg=$(echo "scale=6; $sum / ${#times[@]}" | bc)

    # Std dev simples
    sum_sq=0
    for t in "${times[@]}"; do
        diff=$(echo "$t - $avg" | bc)
        sq=$(echo "$diff * $diff" | bc)
        sum_sq=$(echo "$sum_sq + $sq" | bc)
    done
    variance=$(echo "scale=6; $sum_sq / ${#times[@]}" | bc)
    stddev=$(echo "scale=6; sqrt($variance)" | bc -l)

    echo "$size $avg $stddev" >> $SEQ_FILE
    echo -e " ${GREEN}✓${NC} (média: ${avg}s, σ: ${stddev}s)"
done

echo -e "${GREEN}✓ Sequencial concluído${NC}\n"

# ============================================================
# PASSO 3: MPI MERGE
# ============================================================

echo -e "${GREEN}[3/5] Executando MPI MERGE...${NC}"

MERGE_FILE="$OUTPUT_DIR/merge_${TIMESTAMP}.dat"
echo "# NP Tamanho Tempo(s) StdDev Speedup Eficiencia" > $MERGE_FILE

# 1M - 1 execução por configuração
for np in "${PROCESSES[@]}"; do
    echo -e "\n  ${BLUE}MERGE - $np processos:${NC}"

    for size in "${ARRAY_SIZES_SINGLE[@]}"; do
        echo -n "    ${size} elementos (1 exec)..."

        time=$(execute_mpi mpi_merge $np $size 0 | extract_time)

        if [ ! -z "$time" ]; then
            seq_time=$(grep "^$size " $SEQ_FILE | awk '{print $2}')
            speedup=$(echo "scale=4; $seq_time / $time" | bc)
            efficiency=$(echo "scale=4; $speedup / $np" | bc)

            echo "$np $size $time 0.0 $speedup $efficiency" >> $MERGE_FILE
            echo -e " ${GREEN}✓${NC} (${time}s, speedup: ${speedup}x)"
        else
            echo -e " ${RED}✗ Falhou${NC}"
        fi
    done
done

# 100k - 3 execuções por configuração (std dev)
for np in "${PROCESSES[@]}"; do
    for size in "${ARRAY_SIZES_MULTIPLE[@]}"; do
        echo -n "    ${size} elementos (3 execs)..."

        times=()
        for rep in $(seq 1 $REPS_MULTIPLE); do
            t=$(execute_mpi mpi_merge $np $size 0 | extract_time)
            if [ ! -z "$t" ]; then
                times+=($t)
            fi
        done

        if [ ${#times[@]} -gt 0 ]; then
            # Calcula média
            sum=0
            for t in "${times[@]}"; do
                sum=$(echo "$sum + $t" | bc)
            done
            avg=$(echo "scale=6; $sum / ${#times[@]}" | bc)

            # Std dev
            sum_sq=0
            for t in "${times[@]}"; do
                diff=$(echo "$t - $avg" | bc)
                sq=$(echo "$diff * $diff" | bc)
                sum_sq=$(echo "$sum_sq + $sq" | bc)
            done
            variance=$(echo "scale=6; $sum_sq / ${#times[@]}" | bc)
            stddev=$(echo "scale=6; sqrt($variance)" | bc -l)

            seq_time=$(grep "^$size " $SEQ_FILE | awk '{print $2}')
            speedup=$(echo "scale=4; $seq_time / $avg" | bc)
            efficiency=$(echo "scale=4; $speedup / $np" | bc)

            echo "$np $size $avg $stddev $speedup $efficiency" >> $MERGE_FILE
            echo -e " ${GREEN}✓${NC} (média: ${avg}s, σ: ${stddev}s)"
        else
            echo -e " ${RED}✗ Falhou${NC}"
        fi
    done
done

echo -e "\n${GREEN}✓ MPI MERGE concluído${NC}\n"

# ============================================================
# PASSO 4: MPI ODD-EVEN (apenas 100k para comparação)
# ============================================================

echo -e "${GREEN}[4/5] Executando MPI ODD-EVEN (apenas 100k)...${NC}"

ODDEVEN_FILE="$OUTPUT_DIR/oddeven_${TIMESTAMP}.dat"
echo "# NP Tamanho Tempo(s) StdDev Speedup Eficiencia" > $ODDEVEN_FILE

# Apenas 100k com 3 repetições
for np in "${PROCESSES[@]}"; do
    echo -e "\n  ${BLUE}ODD-EVEN - $np processos:${NC}"

    for size in "${ARRAY_SIZES_MULTIPLE[@]}"; do
        echo -n "    ${size} elementos (3 execs)..."

        times=()
        for rep in $(seq 1 $REPS_MULTIPLE); do
            t=$(execute_oddeven $np $size | extract_time)
            if [ ! -z "$t" ]; then
                times+=($t)
            fi
        done

        if [ ${#times[@]} -gt 0 ]; then
            sum=0
            for t in "${times[@]}"; do
                sum=$(echo "$sum + $t" | bc)
            done
            avg=$(echo "scale=6; $sum / ${#times[@]}" | bc)

            sum_sq=0
            for t in "${times[@]}"; do
                diff=$(echo "$t - $avg" | bc)
                sq=$(echo "$diff * $diff" | bc)
                sum_sq=$(echo "$sum_sq + $sq" | bc)
            done
            variance=$(echo "scale=6; $sum_sq / ${#times[@]}" | bc)
            stddev=$(echo "scale=6; sqrt($variance)" | bc -l)

            seq_time=$(grep "^$size " $SEQ_FILE | awk '{print $2}')
            speedup=$(echo "scale=4; $seq_time / $avg" | bc)
            efficiency=$(echo "scale=4; $speedup / $np" | bc)

            echo "$np $size $avg $stddev $speedup $efficiency" >> $ODDEVEN_FILE
            echo -e " ${GREEN}✓${NC} (média: ${avg}s, σ: ${stddev}s)"
        else
            echo -e " ${RED}✗ Falhou${NC}"
        fi
    done
done

echo -e "\n${GREEN}✓ MPI ODD-EVEN concluído${NC}\n"

# ============================================================
# PASSO 5: Gerar arquivo comparativo
# ============================================================

echo -e "${GREEN}[5/5] Gerando arquivos comparativos...${NC}"

COMPARISON_FILE="$OUTPUT_DIR/comparison_${TIMESTAMP}.dat"
echo "# NP Tamanho Merge_Time Merge_StdDev OddEven_Time OddEven_StdDev" > $COMPARISON_FILE

# Comparação para 100k (onde ambos foram executados)
for np in "${PROCESSES[@]}"; do
    for size in "${ARRAY_SIZES_MULTIPLE[@]}"; do
        merge_data=$(grep "^$np $size " $MERGE_FILE)
        oddeven_data=$(grep "^$np $size " $ODDEVEN_FILE)

        if [ ! -z "$merge_data" ] && [ ! -z "$oddeven_data" ]; then
            merge_time=$(echo "$merge_data" | awk '{print $3}')
            merge_std=$(echo "$merge_data" | awk '{print $4}')
            oddeven_time=$(echo "$oddeven_data" | awk '{print $3}')
            oddeven_std=$(echo "$oddeven_data" | awk '{print $4}')

            echo "$np $size $merge_time $merge_std $oddeven_time $oddeven_std" >> $COMPARISON_FILE
        fi
    done
done

echo -e "${GREEN}✓ Arquivos gerados:${NC}"
echo -e "   - ${BLUE}$SEQ_FILE${NC}"
echo -e "   - ${BLUE}$MERGE_FILE${NC}"
echo -e "   - ${BLUE}$ODDEVEN_FILE${NC}"
echo -e "   - ${BLUE}$COMPARISON_FILE${NC}"

# ============================================================
# RESUMO
# ============================================================

echo ""
echo -e "${BLUE}============================================================${NC}"
echo -e "${GREEN}   EXPERIMENTOS CONCLUÍDOS!${NC}"
echo -e "${BLUE}============================================================${NC}"
echo ""
echo "Dados coletados:"
echo "  ✓ 1M elementos: MERGE (3, 7, 15 proc) - Para o trabalho"
echo "  ✓ 100k elementos: MERGE + ODD-EVEN com 3 reps - Para std dev"
echo ""
echo "Para gerar gráficos:"
echo -e "  ${GREEN}gnuplot plot_comparison.gnuplot${NC}"
echo ""
