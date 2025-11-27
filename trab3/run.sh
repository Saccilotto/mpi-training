#!/bin/bash

# Uso:
#   ./run.sh <executavel> <tamanho_do_vetor>
# Exemplo:
#   ./run.sh odd-even 320

if [ $# -ne 2 ]; then
    echo "Uso: $0 <executavel> <tamanho_do_vetor>"
    echo "Exemplo: $0 odd-even 320"
    exit 1
fi

EXEC_NAME="$1"
ARRAY_SIZE="$2"
EXECUTABLE="./$EXEC_NAME"

# Pasta de resultados
RESULTS_DIR="./results"

# Cria a pasta se não existir
mkdir -p "$RESULTS_DIR"

OUTPUT_FILE="${RESULTS_DIR}/${EXEC_NAME}_${ARRAY_SIZE}_results.txt"

# Verifica se o executável existe
if [ ! -f "$EXECUTABLE" ]; then
    echo "ERRO: Executável $EXECUTABLE não encontrado!"
    echo "Compile primeiro com: mpicc -o $EXEC_NAME ${EXEC_NAME}.c"
    exit 1
fi

# Verifica divisibilidade
for np in 1 2 4 8 16 32; do
    if (( ARRAY_SIZE % np != 0 )); then
        echo "ERRO: $ARRAY_SIZE não é divisível por $np processos."
        exit 1
    fi
done

echo "=========================================="
echo "TESTES DE DESEMPENHO - $EXEC_NAME"
echo "=========================================="
echo "Tamanho do vetor: $ARRAY_SIZE"
echo "Executável: $EXEC_NAME"
echo "Resultados: $OUTPUT_FILE"
echo "=========================================="
echo ""

# Criação do arquivo inicial
{
echo "========================================="
echo "TESTES DE DESEMPENHO - $EXEC_NAME"
echo "========================================="
echo "Tamanho do vetor: $ARRAY_SIZE"
echo "Executável: $EXEC_NAME"
echo "Data/Hora: $(date)"
echo "========================================="
echo ""
} > "$OUTPUT_FILE"

# Configurações de teste
declare -a CONFIGS=(
    "1:1"
    "2:1"
    "4:1"
    "8:1"
    "16:2"
    "32:2"
)

# Loop principal
for config in "${CONFIGS[@]}"; do
    NP=$(echo "$config" | cut -d':' -f1)
    NODES=$(echo "$config" | cut -d':' -f2)

    echo "=========================================="
    echo "Teste: $NP processos em $NODES nó(s)"
    echo "=========================================="

    {
    echo ""
    echo "========================================="
    echo "TESTE: $NP processos em $NODES nó(s)"
    echo "========================================="
    echo "Comando: time srun --exclusive -N $NODES -n $NP $EXECUTABLE $ARRAY_SIZE"
    echo ""
    } >> "$OUTPUT_FILE"

    echo "Executando:"
    echo "time srun --exclusive -N $NODES -n $NP $EXECUTABLE $ARRAY_SIZE"
    echo ""

    { time srun --exclusive -N $NODES -n $NP $EXECUTABLE $ARRAY_SIZE ; } 2>&1 | tee -a "$OUTPUT_FILE"

    echo ""
    echo "Teste concluído!"
    echo ""

    sleep 2
done

echo "=========================================="
echo "TODOS OS TESTES CONCLUÍDOS!"
echo "=========================================="
echo ""
echo "Arquivo final: $OUTPUT_FILE"
echo ""

# Resumo final
{
echo "========================================="
echo "RESUMO DOS TEMPOS DE EXECUÇÃO"
echo "========================================="
} >> "$OUTPUT_FILE"

echo "----------------------------------------"
printf "%-15s %-15s %-15s\n" "PROCESSOS" "NÓS" "TEMPO (s)"
echo "----------------------------------------"

for config in "${CONFIGS[@]}"; do
    NP=$(echo "$config" | cut -d':' -f1)
    NODES=$(echo "$config" | cut -d':' -f2)

    TEMPO=$(grep -A 20 "TESTE: $NP processos em $NODES nó(s)" "$OUTPUT_FILE" | grep "Tempo total:" | awk '{print $3}')

    if [ ! -z "$TEMPO" ]; then
        printf "%-15s %-15s %-15s\n" "$NP" "$NODES" "$TEMPO"
        echo "$NP processos, $NODES nó(s): $TEMPO segundos" >> "$OUTPUT_FILE"
    fi
done

echo "----------------------------------------"
echo ""
echo "Speedup = Tempo_Sequencial / Tempo_Paralelo"
echo "Eficiência = Speedup / Número_de_Processos"
echo ""
echo "Arquivo completo salvo em:"
echo "   $OUTPUT_FILE"
echo ""

