# ============================================================
# Script GNUplot - Comparação MERGE vs ODD-EVEN (Redesenhado)
# ============================================================
# Gera gráficos separados para cada magnitude + visão geral

# Configurações gerais
set terminal pngcairo enhanced font 'Verdana,12' size 1400,900
set style data linespoints
set grid

# Define cores
set style line 1 lc rgb '#E41A1C' lt 1 lw 3 pt 7 ps 1.8  # Vermelho - MERGE
set style line 2 lc rgb '#377EB8' lt 1 lw 3 pt 9 ps 1.8  # Azul - ODD-EVEN
set style line 3 lc rgb '#4DAF4A' lt 1 lw 3 pt 5 ps 1.8  # Verde - MERGE 100k
set style line 4 lc rgb '#984EA3' lt 1 lw 3 pt 11 ps 1.8 # Roxo - ODD-EVEN 100k
set style line 5 lc rgb '#FF7F00' lt 1 lw 3 pt 13 ps 1.8 # Laranja - MERGE 1M
set style line 6 lc rgb '#888888' lt 2 lw 2              # Cinza - baseline

# Encontra arquivos mais recentes
merge_file = system('ls -t results/merge_*.dat | head -1')
oddeven_file = system('ls -t results/oddeven_*.dat | head -1')
seq_file = system('ls -t results/seq_*.dat | head -1')

# ============================================================
# GRÁFICO 1: VISÃO GERAL - Todos os tamanhos (escala log)
# ============================================================

set output 'results/01_visao_geral_log.png'
set title 'Visão Geral: MERGE vs ODD-EVEN (escala logarítmica)' font 'Verdana,16'
set xlabel 'Número de Processos' font 'Verdana,12'
set ylabel 'Tempo (segundos) - escala log' font 'Verdana,12'
set key left top
set logscale y
set xrange [2:16]
set xtics 3,2,15

plot merge_file using 1:($2==100000?$3:1/0) with linespoints ls 3 title 'MERGE - 100k', \
     oddeven_file using 1:($2==100000?$3:1/0) with linespoints ls 4 title 'ODD-EVEN - 100k', \
     merge_file using 1:($2==1000000?$3:1/0) with linespoints ls 1 title 'MERGE - 1M'

# ============================================================
# GRÁFICO 2: 100k ELEMENTOS
# ============================================================

unset logscale y
set output 'results/02_100k_elementos.png'
set title '100.000 Elementos: MERGE vs ODD-EVEN' font 'Verdana,16'
set ylabel 'Tempo (segundos)' font 'Verdana,12'
set key right top
set yrange [0:*]

seq_time_100k = real(system('grep "^100000 " ' . seq_file . ' | awk "{print $2}"'))

plot seq_time_100k with lines dt 2 lc rgb '#888888' lw 3 title 'Sequencial (baseline)', \
     merge_file using 1:($2==100000?$3:1/0) with linespoints ls 3 title 'MERGE', \
     oddeven_file using 1:($2==100000?$3:1/0) with linespoints ls 4 title 'ODD-EVEN'

# ============================================================
# GRÁFICO 3: 1M ELEMENTOS (com baseline sequencial)
# ============================================================

seq_time_1m = real(system('grep "^1000000 " ' . seq_file . ' | awk "{print $2}"'))

set output 'results/03_1m_elementos.png'
set title '1.000.000 Elementos: MERGE vs ODD-EVEN' font 'Verdana,16'
set key right top

plot seq_time_1m with lines dt 2 lc rgb '#888888' lw 3 title 'Sequencial (baseline)', \
     merge_file using 1:($2==1000000?$3:1/0) with linespoints ls 1 title 'MERGE', \
     oddeven_file using 1:($2==1000000?$3:1/0) with linespoints ls 2 title 'ODD-EVEN'

# ============================================================
# GRÁFICO 4: SPEEDUP - 100k
# ============================================================

set output 'results/04_speedup_100k.png'
set title 'Speedup: 100.000 Elementos' font 'Verdana,16'
set ylabel 'Speedup' font 'Verdana,12'
set key left top

plot x with lines dt 2 lc rgb '#888888' lw 2 title 'Ideal', \
     merge_file using 1:($2==100000?$4:1/0) with linespoints ls 3 title 'MERGE', \
     oddeven_file using 1:($2==100000?$4:1/0) with linespoints ls 4 title 'ODD-EVEN'

# ============================================================
# GRÁFICO 5: SPEEDUP - 1M
# ============================================================

set output 'results/05_speedup_1m.png'
set title 'Speedup: 1.000.000 Elementos' font 'Verdana,16'

plot x with lines dt 2 lc rgb '#888888' lw 2 title 'Ideal', \
     merge_file using 1:($2==1000000?$4:1/0) with linespoints ls 1 title 'MERGE', \
     oddeven_file using 1:($2==1000000?$4:1/0) with linespoints ls 2 title 'ODD-EVEN'

# ============================================================
# GRÁFICO 6: EFICIÊNCIA - 100k
# ============================================================

set output 'results/06_eficiencia_100k.png'
set title 'Eficiência: 100.000 Elementos' font 'Verdana,16'
set ylabel 'Eficiência' font 'Verdana,12'
set yrange [0:1.5]
set key right top

plot 1 with lines dt 2 lc rgb '#888888' lw 2 title 'Ideal', \
     merge_file using 1:($2==100000?$5:1/0) with linespoints ls 3 title 'MERGE', \
     oddeven_file using 1:($2==100000?$5:1/0) with linespoints ls 4 title 'ODD-EVEN'

# ============================================================
# GRÁFICO 7: EFICIÊNCIA - 1M
# ============================================================

set output 'results/07_eficiencia_1m.png'
set title 'Eficiência: 1.000.000 Elementos' font 'Verdana,16'

plot 1 with lines dt 2 lc rgb '#888888' lw 2 title 'Ideal', \
     merge_file using 1:($2==1000000?$5:1/0) with linespoints ls 1 title 'MERGE', \
     oddeven_file using 1:($2==1000000?$5:1/0) with linespoints ls 2 title 'ODD-EVEN'

# ============================================================
# GRÁFICO 8: SPEEDUP CONSOLIDADO (ambos os tamanhos)
# ============================================================

set output 'results/08_speedup_consolidado.png'
set title 'Speedup: Comparação MERGE vs ODD-EVEN' font 'Verdana,16'
set ylabel 'Speedup' font 'Verdana,12'
set yrange [0:*]
set key left top

plot x with lines dt 2 lc rgb '#888888' lw 2 title 'Ideal', \
     merge_file using 1:($2==100000?$4:1/0) with linespoints ls 3 title 'MERGE - 100k', \
     oddeven_file using 1:($2==100000?$4:1/0) with linespoints ls 4 title 'ODD-EVEN - 100k', \
     merge_file using 1:($2==1000000?$4:1/0) with linespoints ls 1 title 'MERGE - 1M'

# ============================================================
# GRÁFICO 9: EFICIÊNCIA CONSOLIDADA
# ============================================================

set output 'results/09_eficiencia_consolidada.png'
set title 'Eficiência: Comparação MERGE vs ODD-EVEN' font 'Verdana,16'
set ylabel 'Eficiência' font 'Verdana,12'
set yrange [0:1.5]

plot 1 with lines dt 2 lc rgb '#888888' lw 2 title 'Ideal', \
     merge_file using 1:($2==100000?$5:1/0) with linespoints ls 3 title 'MERGE - 100k', \
     oddeven_file using 1:($2==100000?$5:1/0) with linespoints ls 4 title 'ODD-EVEN - 100k', \
     merge_file using 1:($2==1000000?$5:1/0) with linespoints ls 1 title 'MERGE - 1M'

# ============================================================
# GRÁFICO 10: COMPARAÇÃO DIRETA - Diferença de Performance
# ============================================================

set output 'results/10_diferenca_percentual.png'
set title 'Vantagem do MERGE sobre ODD-EVEN (%)' font 'Verdana,16'
set ylabel 'Vantagem (%)' font 'Verdana,12'
set yrange [*:*]
set key right top

# Calcula: ((oddeven_time - merge_time) / merge_time) * 100
# Positivo = MERGE é mais rápido que ODD-EVEN
comparison_file = system('ls -t results/comparison_*.dat | head -1')

plot 0 with lines dt 2 lc rgb 'black' lw 2 title 'Paridade', \
     comparison_file using 1:(($2==100000?(($5-$3)/$3)*100:1/0)) with linespoints ls 3 lw 3 title '100k elementos', \
     comparison_file using 1:(($2==1000000?(($5-$3)/$3)*100:1/0)) with linespoints ls 1 lw 3 title '1M elementos'

print ""
print "=============================================="
print "  GRÁFICOS GERADOS COM SUCESSO!"
print "=============================================="
print ""
print "Visão Geral:"
print "  01_visao_geral_log.png .......... Todos os tamanhos (escala log)"
print ""
print "Análise por Tamanho (Tempo):"
print "  02_100k_elementos.png ........... 100k elementos (com baseline)"
print "  03_1m_elementos.png ............. 1M elementos (com baseline)"
print ""
print "Análise por Tamanho (Speedup):"
print "  04_speedup_100k.png ............. 100k elementos"
print "  05_speedup_1m.png ............... 1M elementos"
print ""
print "Análise por Tamanho (Eficiência):"
print "  06_eficiencia_100k.png .......... 100k elementos"
print "  07_eficiencia_1m.png ............ 1M elementos"
print ""
print "Comparação Consolidada:"
print "  08_speedup_consolidado.png ...... Todos os speedups juntos"
print "  09_eficiencia_consolidada.png ... Todas as eficiências juntas"
print "  10_diferenca_percentual.png ..... Vantagem do MERGE vs ODD-EVEN"
print ""
print "=============================================="
print ""
