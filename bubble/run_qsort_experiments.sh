#!/bin/bash

################################################################################
# Script de Experimentos: Comparação MPI Quicksort vs Odd-Even
# Para execução no cluster Atlantica
################################################################################

# Configurações
RESULTS_DIR="results"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_FILE="${RESULTS_DIR}/qsort_comparison_${TIMESTAMP}.csv"

# Detecta ambiente (local ou atlantica)
if command -v srun &> /dev/null; then
    ENVIRONMENT="atlantica"
    RUN_CMD="srun --exclusive"
    echo "Detectado ambiente: ATLANTICA (usando srun)"
else
    ENVIRONMENT="local"
    RUN_CMD="mpirun"
    echo "Detectado ambiente: LOCAL (usando mpirun)"
fi

# Tamanhos de array para testar
ARRAY_SIZES=(1000 10000 100000 1000000)

# Configurações de processos e nós
if [ "$ENVIRONMENT" = "atlantica" ]; then
    # Atlantica: múltiplos nós
    declare -A PROC_CONFIGS
    PROC_CONFIGS["3"]="1"   # 3 processos, 1 nó
    PROC_CONFIGS["7"]="1"   # 7 processos, 1 nó
    PROC_CONFIGS["15"]="2"  # 15 processos, 2 nós
    PROC_CONFIGS["31"]="4"  # 31 processos, 4 nós
else
    # Local: apenas 1 nó
    declare -A PROC_CONFIGS
    PROC_CONFIGS["3"]="1"
    PROC_CONFIGS["7"]="1"
fi

# Delta values (tamanho mínimo para conquista local)
# Calculado como array_size / num_procs / 8
calculate_delta() {
    local size=$1
    local procs=$2
    echo $((size / procs / 8))
}

# Cria diretório de resultados
mkdir -p ${RESULTS_DIR}

################################################################################
# Cabeçalho do CSV
################################################################################
echo "Criando arquivo de resultados: ${OUTPUT_FILE}"
echo "Algorithm,ArraySize,NumProcs,NumNodes,Delta,TimeSeconds,Environment" > ${OUTPUT_FILE}

################################################################################
# Função para executar um teste (quicksort)
################################################################################
run_test() {
    local algorithm=$1
    local binary=$2
    local size=$3
    local procs=$4
    local nodes=$5
    local delta=$6

    echo ""
    echo "=========================================="
    echo "Teste: $algorithm"
    echo "Array Size: $size"
    echo "Processos: $procs (Nós: $nodes)"
    echo "Delta: $delta"
    echo "=========================================="

    # Executa o teste 3 vezes e pega o melhor tempo
    local best_time=999999

    for run in 1 2 3; do
        echo -n "  Execução $run/3... "

        if [ "$ENVIRONMENT" = "atlantica" ]; then
            output=$(${RUN_CMD} -N ${nodes} -n ${procs} ./${binary} ${size} ${delta} 0 2>&1)
        else
            output=$(${RUN_CMD} -np ${procs} ./${binary} ${size} ${delta} 0 2>&1)
        fi

        # Extrai o tempo (formato: "Tempo de execucao: X.XXXXXX segundos")
        time=$(echo "$output" | grep "Tempo de execucao" | tail -1 | awk '{print $4}')

        # Valida se o tempo foi extraído e é um número válido
        if [ -z "$time" ] || ! [[ "$time" =~ ^[0-9]+\.?[0-9]*$ ]]; then
            echo "ERRO: Não foi possível extrair o tempo válido (obtido: '$time')"
            echo "DEBUG: Últimas 15 linhas do output:"
            echo "$output" | tail -15
            echo "=========================================="
            continue
        fi

        echo "Tempo: ${time}s"

        # Compara com o melhor tempo (usando bc para comparação de float)
        if (( $(echo "$time < $best_time" | bc -l) )); then
            best_time=$time
        fi
    done

    # Salva o melhor tempo no CSV
    if [ "$best_time" != "999999" ]; then
        echo "${algorithm},${size},${procs},${nodes},${delta},${best_time},${ENVIRONMENT}" >> ${OUTPUT_FILE}
        echo "  ✓ Melhor tempo: ${best_time}s"
    else
        echo "  ✗ Teste falhou"
    fi
}

################################################################################
# Função para executar teste odd-even (aceita apenas array size)
################################################################################
run_test_oddeven() {
    local algorithm=$1
    local binary=$2
    local size=$3
    local procs=$4
    local nodes=$5

    echo ""
    echo "=========================================="
    echo "Teste: $algorithm"
    echo "Array Size: $size"
    echo "Processos: $procs (Nós: $nodes)"
    echo "=========================================="

    # Executa o teste 3 vezes e pega o melhor tempo
    local best_time=999999

    for run in 1 2 3; do
        echo -n "  Execução $run/3... "

        if [ "$ENVIRONMENT" = "atlantica" ]; then
            output=$(${RUN_CMD} -N ${nodes} -n ${procs} ./${binary} ${size} 2>&1)
        else
            output=$(${RUN_CMD} -np ${procs} ./${binary} ${size} 2>&1)
        fi

        # Extrai o tempo (formato: "Elapsed = X.XXXX")
        time=$(echo "$output" | grep -i "elapsed" | tail -1 | grep -oP '\d+\.\d+' | head -1)

        # Valida se o tempo foi extraído e é um número válido
        if [ -z "$time" ] || ! [[ "$time" =~ ^[0-9]+\.?[0-9]*$ ]]; then
            echo "ERRO: Não foi possível extrair o tempo válido (obtido: '$time')"
            echo "DEBUG: Últimas 15 linhas do output:"
            echo "$output" | tail -15
            echo "=========================================="
            continue
        fi

        echo "Tempo: ${time}s"

        # Compara com o melhor tempo
        if (( $(echo "$time < $best_time" | bc -l) )); then
            best_time=$time
        fi
    done

    # Salva o melhor tempo no CSV (delta = 0 para odd-even)
    if [ "$best_time" != "999999" ]; then
        echo "${algorithm},${size},${procs},${nodes},0,${best_time},${ENVIRONMENT}" >> ${OUTPUT_FILE}
        echo "  ✓ Melhor tempo: ${best_time}s"
    else
        echo "  ✗ Teste falhou"
    fi
}

################################################################################
# INÍCIO DOS EXPERIMENTOS
################################################################################

echo ""
echo "################################################################################"
echo "# Experimentos: MPI Quicksort vs Odd-Even Sort"
echo "# Ambiente: ${ENVIRONMENT}"
echo "# Timestamp: ${TIMESTAMP}"
echo "################################################################################"
echo ""

# Verifica se os binários existem
if [ ! -f "./mpi_qsort" ] || [ ! -f "./mpi_oddeven" ]; then
    echo "ERRO: Binários não encontrados!"
    echo "Execute 'make all' antes de rodar os experimentos."
    exit 1
fi

# Loop principal: para cada tamanho de array
for size in "${ARRAY_SIZES[@]}"; do
    echo ""
    echo "############################################################"
    echo "# ARRAY SIZE: ${size}"
    echo "############################################################"

    # Para cada configuração de processos
    for procs in "${!PROC_CONFIGS[@]}"; do
        nodes=${PROC_CONFIGS[$procs]}
        delta=$(calculate_delta $size $procs)

        # Se delta for 0, usa 1 como mínimo
        if [ $delta -eq 0 ]; then
            delta=1
        fi

        # Testa MPI Quicksort
        run_test "MPI_Quicksort" "mpi_qsort" $size $procs $nodes $delta

        # Testa MPI Odd-Even (usa função separada pois aceita apenas 1 argumento)
        run_test_oddeven "MPI_OddEven" "mpi_oddeven" $size $procs $nodes
    done
done

################################################################################
# GERAÇÃO DE RELATÓRIO
################################################################################

REPORT_FILE="${RESULTS_DIR}/report_${TIMESTAMP}.txt"

echo ""
echo "################################################################################"
echo "# Gerando relatório..."
echo "################################################################################"

cat > ${REPORT_FILE} << EOF
========================================================================
RELATÓRIO DE EXPERIMENTOS - QUICKSORT VS ODD-EVEN
========================================================================
Data/Hora: ${TIMESTAMP}
Ambiente: ${ENVIRONMENT}
Arquivo de dados: ${OUTPUT_FILE}

========================================================================
RESUMO DOS RESULTADOS
========================================================================

EOF

# Processa os resultados para cada tamanho
for size in "${ARRAY_SIZES[@]}"; do
    echo "" >> ${REPORT_FILE}
    echo "--- Array Size: ${size} ---" >> ${REPORT_FILE}
    echo "" >> ${REPORT_FILE}

    # Para cada número de processos
    for procs in "${!PROC_CONFIGS[@]}"; do
        # Quicksort
        qs_time=$(grep "MPI_Quicksort,${size},${procs}" ${OUTPUT_FILE} | cut -d',' -f6)

        # Odd-Even
        oe_time=$(grep "MPI_OddEven,${size},${procs}" ${OUTPUT_FILE} | cut -d',' -f6)

        if [ -n "$qs_time" ] && [ -n "$oe_time" ]; then
            # Calcula speedup (odd-even / quicksort)
            speedup=$(echo "scale=2; $oe_time / $qs_time" | bc -l)

            echo "  ${procs} processos:" >> ${REPORT_FILE}
            echo "    Quicksort:  ${qs_time}s" >> ${REPORT_FILE}
            echo "    Odd-Even:   ${oe_time}s" >> ${REPORT_FILE}
            echo "    Speedup:    ${speedup}x (Quicksort é ${speedup}x mais rápido)" >> ${REPORT_FILE}
            echo "" >> ${REPORT_FILE}
        fi
    done
done

cat >> ${REPORT_FILE} << EOF

========================================================================
ARQUIVOS GERADOS
========================================================================
- Dados CSV: ${OUTPUT_FILE}
- Relatório: ${REPORT_FILE}

Para plotar os gráficos:
  gnuplot plot_comparison.gnuplot

========================================================================
EOF

echo ""
echo "✓ Experimentos concluídos!"
echo ""
echo "Arquivos gerados:"
echo "  - Dados: ${OUTPUT_FILE}"
echo "  - Relatório: ${REPORT_FILE}"
echo ""
cat ${REPORT_FILE}
