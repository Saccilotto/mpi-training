#!/bin/bash
################################################################################
# Script para gerar todos os gráficos de Speed-Up e Eficiência
################################################################################

# Configurações padrão
CSV_FILE="${1:-results_first/qsort_comparison_20251106_190224.csv}"
OUTPUT_DIR="${2:-plots}"

# Verifica se o arquivo CSV existe
if [ ! -f "$CSV_FILE" ]; then
    echo "ERRO: Arquivo CSV não encontrado: $CSV_FILE"
    echo "Uso: $0 [csv_file] [output_dir]"
    exit 1
fi

# Cria diretório de saída
mkdir -p "$OUTPUT_DIR"

echo "=================================="
echo "Gerando gráficos de Speed-Up"
echo "=================================="
echo "Arquivo CSV: $CSV_FILE"
echo "Diretório de saída: $OUTPUT_DIR"
echo ""

# Extrai os tamanhos de array únicos do CSV
ARRAY_SIZES=$(awk -F',' 'NR>1 {print $2}' "$CSV_FILE" | sort -nu)

echo "Tamanhos de array encontrados:"
echo "$ARRAY_SIZES"
echo ""

# Gera gráficos para cada tamanho de array
for size in $ARRAY_SIZES; do
    echo "--------------------------------------"
    echo "Array Size: $size"
    echo "--------------------------------------"

    # Quicksort
    echo -n "  Gerando gráfico Quicksort... "
    qsort_output="$OUTPUT_DIR/quicksort_speedup_${size}.png"
    gnuplot -e "csv_file='$CSV_FILE'; array_size=$size; output_file='$qsort_output'" \
        plot_quicksort_speedup.gnuplot 2>&1 | grep -v "^$"

    if [ -f "$qsort_output" ]; then
        echo "OK: $qsort_output"
    else
        echo "ERRO ao gerar gráfico"
    fi

    # Odd-Even
    echo -n "  Gerando gráfico Odd-Even... "
    oddeven_output="$OUTPUT_DIR/oddeven_speedup_${size}.png"
    gnuplot -e "csv_file='$CSV_FILE'; array_size=$size; output_file='$oddeven_output'" \
        plot_oddeven_speedup.gnuplot 2>&1 | grep -v "^$"

    if [ -f "$oddeven_output" ]; then
        echo "OK: $oddeven_output"
    else
        echo "ERRO ao gerar gráfico"
    fi

    echo ""
done

echo "=================================="
echo "Resumo"
echo "=================================="
echo "Gráficos gerados em: $OUTPUT_DIR"
ls -lh "$OUTPUT_DIR"/*.png 2>/dev/null
echo ""
echo "Total de gráficos: $(ls -1 "$OUTPUT_DIR"/*.png 2>/dev/null | wc -l)"
