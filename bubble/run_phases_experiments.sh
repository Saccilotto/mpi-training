#!/bin/bash

################################################################################
# Script de Experimentos: Bubble Sort com Fases Paralelas
#
# Este script executa experimentos com:
# 1. Versão sequencial do Bubble Sort
# 2. Versão paralela usando Fases Paralelas (MPI)
# 3. Comparação com versão Divide-and-Conquer (opcional)
#
# Uso no cluster Grad:
#   ./run_phases_experiments.sh
#
# Configuração: 2 nós, 16 ou 32 processos (com HT)
################################################################################

# Configurações
RESULTS_DIR="results_phases"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_FILE="${RESULTS_DIR}/phases_results_${TIMESTAMP}.csv"

# Detecta ambiente
if command -v srun &> /dev/null; then
    ENVIRONMENT="grad"
    RUN_CMD="srun --exclusive"
    echo "Detectado ambiente: GRAD (usando srun)"
else
    ENVIRONMENT="local"
    RUN_CMD="mpirun"
    echo "Detectado ambiente: LOCAL (usando mpirun)"
fi

# Tamanho do vetor conforme especificação
ARRAY_SIZE=1000000

# Configurações de processos para o Grad (2 nós)
# Cada nó no Grad tem 8 cores (16 com HT)
# Com 2 nós: 16 cores (32 com HT)
PROCESS_CONFIGS=(4 8 16 32)
NODES=2

# Cria diretório de resultados
mkdir -p ${RESULTS_DIR}

################################################################################
# Cabeçalho do CSV
################################################################################
echo "Criando arquivo de resultados: ${OUTPUT_FILE}"
echo "Algorithm,ArraySize,NumProcs,NumNodes,TimeSeconds,Iterations,Environment" > ${OUTPUT_FILE}

################################################################################
# Função para executar teste sequencial
################################################################################
run_sequential() {
    local size=$1

    echo ""
    echo "=========================================="
    echo "Teste: SEQUENTIAL"
    echo "Array Size: $size"
    echo "=========================================="

    # Executa o teste 3 vezes e pega o melhor tempo
    local best_time=999999

    for run in 1 2 3; do
        echo -n "  Execução $run/3... "

        output=$(./seq ${size} 0 2>&1)

        # Extrai o tempo (formato: "Tempo de execucao: X.XXXXXX segundos")
        time=$(echo "$output" | grep "Tempo de execucao" | tail -1 | awk '{print $4}')

        # Valida se o tempo foi extraído
        if [ -z "$time" ] || ! [[ "$time" =~ ^[0-9]+\.?[0-9]*$ ]]; then
            echo "ERRO: Não foi possível extrair o tempo (obtido: '$time')"
            echo "DEBUG: Output:"
            echo "$output"
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
        echo "Sequential,${size},1,1,${best_time},0,${ENVIRONMENT}" >> ${OUTPUT_FILE}
        echo "  ✓ Melhor tempo: ${best_time}s"
    else
        echo "  ✗ Teste falhou"
        echo "Sequential,${size},1,1,-1,0,${ENVIRONMENT}" >> ${OUTPUT_FILE}
    fi

    # Retorna o tempo para cálculos posteriores
    echo "$best_time"
}

################################################################################
# Função para executar teste paralelo (Fases Paralelas)
################################################################################
run_parallel_phases() {
    local size=$1
    local procs=$2
    local nodes=$3

    echo ""
    echo "=========================================="
    echo "Teste: MPI PHASES (Fases Paralelas)"
    echo "Array Size: $size"
    echo "Processos: $procs (Nós: $nodes)"
    echo "=========================================="

    # Executa o teste 3 vezes e pega o melhor tempo
    local best_time=999999
    local iterations=0

    for run in 1 2 3; do
        echo -n "  Execução $run/3... "

        if [ "$ENVIRONMENT" = "grad" ]; then
            output=$(${RUN_CMD} -N ${nodes} -n ${procs} ./mpi_phases ${size} 0 2>&1)
        else
            output=$(${RUN_CMD} -np ${procs} ./mpi_phases ${size} 0 2>&1)
        fi

        # Extrai o tempo
        time=$(echo "$output" | grep "Tempo de execucao" | tail -1 | awk '{print $4}')

        # Extrai o número de iterações
        iter=$(echo "$output" | grep "Numero de iteracoes" | tail -1 | awk '{print $4}')

        # Valida extração
        if [ -z "$time" ] || ! [[ "$time" =~ ^[0-9]+\.?[0-9]*$ ]]; then
            echo "ERRO: Não foi possível extrair o tempo (obtido: '$time')"
            echo "DEBUG: Últimas 10 linhas do output:"
            echo "$output" | tail -10
            continue
        fi

        echo "Tempo: ${time}s, Iterações: ${iter}"

        # Compara com o melhor tempo
        if (( $(echo "$time < $best_time" | bc -l) )); then
            best_time=$time
            iterations=$iter
        fi
    done

    # Salva o melhor tempo no CSV
    if [ "$best_time" != "999999" ]; then
        echo "MPI_Phases,${size},${procs},${nodes},${best_time},${iterations},${ENVIRONMENT}" >> ${OUTPUT_FILE}
        echo "  ✓ Melhor tempo: ${best_time}s (${iterations} iterações)"
    else
        echo "  ✗ Teste falhou"
        echo "MPI_Phases,${size},${procs},${nodes},-1,0,${ENVIRONMENT}" >> ${OUTPUT_FILE}
    fi

    # Retorna o tempo
    echo "$best_time"
}

################################################################################
# INÍCIO DOS EXPERIMENTOS
################################################################################

echo ""
echo "################################################################################"
echo "# Experimentos: Bubble Sort com Fases Paralelas"
echo "# Array Size: ${ARRAY_SIZE}"
echo "# Processos: ${PROCESS_CONFIGS[@]}"
echo "# Ambiente: ${ENVIRONMENT}"
echo "# Timestamp: ${TIMESTAMP}"
echo "################################################################################"
echo ""

# Verifica se os binários existem
if [ ! -f "./seq" ]; then
    echo "ERRO: Binário 'seq' não encontrado!"
    echo "Execute 'make seq' antes de rodar os experimentos."
    exit 1
fi

if [ ! -f "./mpi_phases" ]; then
    echo "ERRO: Binário 'mpi_phases' não encontrado!"
    echo "Execute 'make mpi-phases' antes de rodar os experimentos."
    exit 1
fi

################################################################################
# FASE 1: VERSÃO SEQUENCIAL
################################################################################

echo ""
echo "################################################################################"
echo "# FASE 1: VERSÃO SEQUENCIAL"
echo "################################################################################"
echo ""

seq_time=$(run_sequential $ARRAY_SIZE)

################################################################################
# FASE 2: VERSÃO PARALELA (FASES PARALELAS)
################################################################################

echo ""
echo "################################################################################"
echo "# FASE 2: VERSÃO PARALELA - FASES PARALELAS"
echo "################################################################################"
echo ""

# Arrays para armazenar tempos e calcular speedup
declare -a parallel_times

for procs in "${PROCESS_CONFIGS[@]}"; do
    # Calcula número de nós necessários (assumindo 16 cores por nó com HT)
    if [ $procs -le 16 ]; then
        nodes=1
    else
        nodes=2
    fi

    par_time=$(run_parallel_phases $ARRAY_SIZE $procs $nodes)
    parallel_times[$procs]=$par_time
done

################################################################################
# GERAÇÃO DE RELATÓRIO
################################################################################

REPORT_FILE="${RESULTS_DIR}/report_phases_${TIMESTAMP}.txt"

echo ""
echo "################################################################################"
echo "# Gerando relatório..."
echo "################################################################################"

cat > ${REPORT_FILE} << EOF
========================================================================
RELATÓRIO DE EXPERIMENTOS - BUBBLE SORT COM FASES PARALELAS
========================================================================
Data/Hora: ${TIMESTAMP}
Ambiente: ${ENVIRONMENT}
Tamanho do vetor: ${ARRAY_SIZE}
Processos testados: ${PROCESS_CONFIGS[@]}
Arquivo de dados: ${OUTPUT_FILE}

========================================================================
RESULTADOS
========================================================================

VERSÃO SEQUENCIAL:
  Tempo: ${seq_time}s

VERSÃO PARALELA (FASES PARALELAS):

EOF

# Calcula speedup e eficiência para cada configuração
for procs in "${PROCESS_CONFIGS[@]}"; do
    par_time=${parallel_times[$procs]}

    if [ -n "$par_time" ] && [ "$par_time" != "999999" ] && [ "$seq_time" != "999999" ]; then
        # Calcula speedup
        speedup=$(echo "scale=4; $seq_time / $par_time" | bc -l)

        # Calcula eficiência (speedup / num_processos)
        efficiency=$(echo "scale=4; $speedup / $procs" | bc -l)

        # Converte para porcentagem
        efficiency_pct=$(echo "scale=2; $efficiency * 100" | bc -l)

        echo "  ${procs} processos:" >> ${REPORT_FILE}
        echo "    Tempo:       ${par_time}s" >> ${REPORT_FILE}
        echo "    Speedup:     ${speedup}x" >> ${REPORT_FILE}
        echo "    Eficiência:  ${efficiency_pct}%" >> ${REPORT_FILE}
        echo "" >> ${REPORT_FILE}
    fi
done

cat >> ${REPORT_FILE} << EOF

========================================================================
ANÁLISE DE ESCALABILIDADE
========================================================================

EOF

# Calcula escalabilidade entre configurações consecutivas
prev_procs=""
prev_time=""

for procs in "${PROCESS_CONFIGS[@]}"; do
    par_time=${parallel_times[$procs]}

    if [ -n "$prev_procs" ] && [ -n "$prev_time" ] && [ "$prev_time" != "999999" ] && [ "$par_time" != "999999" ]; then
        scale_speedup=$(echo "scale=4; $prev_time / $par_time" | bc -l)
        proc_ratio=$(echo "scale=2; $procs / $prev_procs" | bc -l)

        echo "  ${prev_procs} → ${procs} processos (${proc_ratio}x mais processos):" >> ${REPORT_FILE}
        echo "    Tempo: ${prev_time}s → ${par_time}s" >> ${REPORT_FILE}
        echo "    Speedup: ${scale_speedup}x" >> ${REPORT_FILE}
        echo "" >> ${REPORT_FILE}
    fi

    prev_procs=$procs
    prev_time=$par_time
done

cat >> ${REPORT_FILE} << EOF

========================================================================
COMPARAÇÃO COM MODELO DIVISÃO E CONQUISTA
========================================================================

EOF

# Se existir resultado do modelo divide-and-conquer, comparar
if [ -f "./mpi_merge" ]; then
    echo "  Executando teste com modelo Divisão e Conquista para comparação..." >> ${REPORT_FILE}
    echo "" >> ${REPORT_FILE}

    # Testa com 16 processos (configuração comum)
    dc_procs=16

    if [ "$ENVIRONMENT" = "grad" ]; then
        dc_output=$(${RUN_CMD} -N 2 -n ${dc_procs} ./mpi_merge ${ARRAY_SIZE} $((ARRAY_SIZE / dc_procs / 8)) 0 2>&1)
    else
        dc_output=$(${RUN_CMD} -np ${dc_procs} ./mpi_merge ${ARRAY_SIZE} $((ARRAY_SIZE / dc_procs / 8)) 0 2>&1)
    fi

    dc_time=$(echo "$dc_output" | grep "Tempo de execucao" | tail -1 | awk '{print $4}')
    phases_time=${parallel_times[$dc_procs]}

    if [ -n "$dc_time" ] && [ -n "$phases_time" ] && [ "$dc_time" != "" ] && [ "$phases_time" != "999999" ]; then
        comparison=$(echo "scale=4; $phases_time / $dc_time" | bc -l)

        echo "  Configuração: ${dc_procs} processos" >> ${REPORT_FILE}
        echo "  Divisão e Conquista: ${dc_time}s" >> ${REPORT_FILE}
        echo "  Fases Paralelas:     ${phases_time}s" >> ${REPORT_FILE}
        echo "  Relação:             ${comparison}x" >> ${REPORT_FILE}

        if (( $(echo "$comparison < 1" | bc -l) )); then
            echo "  Fases Paralelas é MAIS RÁPIDO" >> ${REPORT_FILE}
        else
            echo "  Divisão e Conquista é MAIS RÁPIDO" >> ${REPORT_FILE}
        fi
    fi
else
    echo "  Binário 'mpi_merge' não encontrado. Comparação não disponível." >> ${REPORT_FILE}
fi

cat >> ${REPORT_FILE} << EOF

========================================================================
ARQUIVOS GERADOS
========================================================================
- Dados CSV: ${OUTPUT_FILE}
- Relatório: ${REPORT_FILE}

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
