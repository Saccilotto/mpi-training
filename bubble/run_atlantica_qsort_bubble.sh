#!/bin/bash

################################################################################
# Script de Experimentos Atlantica: Quicksort vs Bubblesort
# Apenas 15 e 31 processos
# Ordem: Todos Quicksorts primeiro, depois todos Bubbles
################################################################################

# Configurações
RESULTS_DIR="results"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_FILE="${RESULTS_DIR}/atlantica_qsort_bubble_${TIMESTAMP}.csv"

# Detecta ambiente (deve ser atlantica)
if command -v srun &> /dev/null; then
    ENVIRONMENT="atlantica"
    RUN_CMD="srun --exclusive"
    echo "Detectado ambiente: ATLANTICA (usando srun)"
else
    ENVIRONMENT="local"
    RUN_CMD="mpirun"
    echo "AVISO: Ambiente LOCAL detectado - este script é para Atlantica!"
fi

# Tamanhos de array para testar
ARRAY_SIZES=(1000 10000 100000 1000000)

# Configurações de processos e nós
# Quicksort: apenas 15 e 31
declare -A QSORT_CONFIGS
QSORT_CONFIGS["15"]="2"  # 15 processos, 2 nós
QSORT_CONFIGS["31"]="4"  # 31 processos, 4 nós

# Bubblesort: todos (3, 7, 15, 31)
declare -A BUBBLE_CONFIGS
BUBBLE_CONFIGS["3"]="1"   # 3 processos, 1 nó
BUBBLE_CONFIGS["7"]="1"   # 7 processos, 1 nó
BUBBLE_CONFIGS["15"]="2"  # 15 processos, 2 nós
BUBBLE_CONFIGS["31"]="4"  # 31 processos, 4 nós

# Delta values (tamanho mínimo para conquista local)
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
# Função para executar um teste
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
        time=$(echo "$output" | grep "Tempo de execucao" | awk '{print $4}')

        if [ -z "$time" ]; then
            echo "ERRO: Não foi possível extrair o tempo"
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

    # Salva o melhor tempo no CSV
    if [ "$best_time" != "999999" ]; then
        echo "${algorithm},${size},${procs},${nodes},${delta},${best_time},${ENVIRONMENT}" >> ${OUTPUT_FILE}
        echo "  ✓ Melhor tempo: ${best_time}s"
    else
        echo "  ✗ Teste falhou - salvando com tempo -1"
        echo "${algorithm},${size},${procs},${nodes},${delta},-1,${ENVIRONMENT}" >> ${OUTPUT_FILE}
    fi
}

################################################################################
# INÍCIO DOS EXPERIMENTOS
################################################################################

echo ""
echo "################################################################################"
echo "# Experimentos Atlantica: Quicksort vs Bubblesort"
echo "# Quicksort: 15 e 31 processos"
echo "# Bubblesort: 3, 7, 15 e 31 processos"
echo "# Ambiente: ${ENVIRONMENT}"
echo "# Timestamp: ${TIMESTAMP}"
echo "################################################################################"
echo ""

# Verifica se os binários existem
if [ ! -f "./mpi_qsort" ] || [ ! -f "./mpi_merge" ]; then
    echo "ERRO: Binários não encontrados!"
    echo "Execute 'make -f Makefile.atlantica all' antes de rodar os experimentos."
    exit 1
fi

################################################################################
# FASE 1: QUICKSORT (apenas 15 e 31 processos)
################################################################################

echo ""
echo "################################################################################"
echo "# FASE 1: MPI QUICKSORT (15 e 31 processos)"
echo "################################################################################"
echo ""

for size in "${ARRAY_SIZES[@]}"; do
    echo ""
    echo "############################################################"
    echo "# QUICKSORT - ARRAY SIZE: ${size}"
    echo "############################################################"

    for procs in "${!QSORT_CONFIGS[@]}"; do
        nodes=${QSORT_CONFIGS[$procs]}
        delta=$(calculate_delta $size $procs)

        # Se delta for 0, usa 1 como mínimo
        if [ $delta -eq 0 ]; then
            delta=1
        fi

        run_test "MPI_Quicksort" "mpi_qsort" $size $procs $nodes $delta
    done
done

################################################################################
# FASE 2: BUBBLESORT (3, 7, 15 e 31 processos)
################################################################################

echo ""
echo "################################################################################"
echo "# FASE 2: MPI BUBBLESORT (3, 7, 15 e 31 processos)"
echo "################################################################################"
echo ""

for size in "${ARRAY_SIZES[@]}"; do
    echo ""
    echo "############################################################"
    echo "# BUBBLESORT - ARRAY SIZE: ${size}"
    echo "############################################################"

    for procs in "${!BUBBLE_CONFIGS[@]}"; do
        nodes=${BUBBLE_CONFIGS[$procs]}
        delta=$(calculate_delta $size $procs)

        # Se delta for 0, usa 1 como mínimo
        if [ $delta -eq 0 ]; then
            delta=1
        fi

        run_test "MPI_Bubblesort" "mpi_merge" $size $procs $nodes $delta
    done
done

################################################################################
# GERAÇÃO DE RELATÓRIO
################################################################################

REPORT_FILE="${RESULTS_DIR}/report_atlantica_${TIMESTAMP}.txt"

echo ""
echo "################################################################################"
echo "# Gerando relatório..."
echo "################################################################################"

cat > ${REPORT_FILE} << EOF
========================================================================
RELATÓRIO DE EXPERIMENTOS ATLANTICA - QUICKSORT VS BUBBLESORT
========================================================================
Data/Hora: ${TIMESTAMP}
Ambiente: ${ENVIRONMENT}
Quicksort: 15 (2 nós), 31 (4 nós)
Bubblesort: 3 (1 nó), 7 (1 nó), 15 (2 nós), 31 (4 nós)
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

    # Bubblesort (todos os processos)
    for procs in 3 7 15 31; do
        bs_time=$(grep "MPI_Bubblesort,${size},${procs}" ${OUTPUT_FILE} | cut -d',' -f6)

        if [ -n "$bs_time" ] && [ "$bs_time" != "-1" ]; then
            echo "  ${procs} processos - Bubblesort: ${bs_time}s" >> ${REPORT_FILE}
        fi
    done

    echo "" >> ${REPORT_FILE}

    # Quicksort vs Bubblesort (apenas 15 e 31 onde ambos existem)
    for procs in 15 31; do
        qs_time=$(grep "MPI_Quicksort,${size},${procs}" ${OUTPUT_FILE} | cut -d',' -f6)
        bs_time=$(grep "MPI_Bubblesort,${size},${procs}" ${OUTPUT_FILE} | cut -d',' -f6)

        if [ -n "$qs_time" ] && [ -n "$bs_time" ] && [ "$qs_time" != "-1" ] && [ "$bs_time" != "-1" ]; then
            # Calcula speedup (bubblesort / quicksort)
            speedup=$(echo "scale=2; $bs_time / $qs_time" | bc -l)

            echo "  ${procs} processos - Comparação:" >> ${REPORT_FILE}
            echo "    Quicksort:   ${qs_time}s" >> ${REPORT_FILE}
            echo "    Bubblesort:  ${bs_time}s" >> ${REPORT_FILE}
            echo "    Speedup:     ${speedup}x (Quicksort é ${speedup}x mais rápido)" >> ${REPORT_FILE}
            echo "" >> ${REPORT_FILE}
        fi
    done
done

cat >> ${REPORT_FILE} << EOF

========================================================================
ESTATÍSTICAS DE ESCALABILIDADE
========================================================================

EOF

# Análise de escalabilidade para cada algoritmo
for algo in "MPI_Quicksort" "MPI_Bubblesort"; do
    echo "" >> ${REPORT_FILE}
    echo "--- ${algo} ---" >> ${REPORT_FILE}
    echo "" >> ${REPORT_FILE}

    for size in "${ARRAY_SIZES[@]}"; do
        time_15=$(grep "${algo},${size},15" ${OUTPUT_FILE} | cut -d',' -f6)
        time_31=$(grep "${algo},${size},31" ${OUTPUT_FILE} | cut -d',' -f6)

        if [ -n "$time_15" ] && [ -n "$time_31" ] && [ "$time_15" != "-1" ] && [ "$time_31" != "-1" ]; then
            # Calcula speedup de escalabilidade (15 procs -> 31 procs)
            scale_speedup=$(echo "scale=2; $time_15 / $time_31" | bc -l)

            echo "  ${size} elementos:" >> ${REPORT_FILE}
            echo "    15 procs: ${time_15}s" >> ${REPORT_FILE}
            echo "    31 procs: ${time_31}s" >> ${REPORT_FILE}
            echo "    Speedup:  ${scale_speedup}x" >> ${REPORT_FILE}
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
  gnuplot plot_qsort_comparison.gnuplot

========================================================================
EOF

echo ""
echo "✓ Experimentos concluídos!"
echo ""
echo "Arquivos gerados:"
echo "  - Dados: ${OUTPUT_FILE}"
echo "  - Relatório: ${REPORT_FILE}"
echo ""
echo "Resumo do relatório:"
echo "=========================================="
cat ${REPORT_FILE}
