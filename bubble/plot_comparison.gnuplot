# ============================================================
# Script GNUplot - Comparação: Merge vs Odd-Even
# ============================================================
#
# Gera gráficos comparativos entre:
#   1. MPI com MERGE (interleaving)
#   2. MPI com ODD-EVEN transposition
#
# Uso:
#   gnuplot plot_comparison.gnuplot
#
# ============================================================

# Configurações gerais
set terminal pngcairo enhanced font 'Verdana,12' size 1200,800
set style data linespoints
set grid

# Define cores
set style line 1 lc rgb '#E41A1C' lt 1 lw 2 pt 7 ps 1.5  # Vermelho - MERGE
set style line 2 lc rgb '#377EB8' lt 1 lw 2 pt 9 ps 1.5  # Azul - ODD-EVEN
set style line 3 lc rgb '#4DAF4A' lt 1 lw 2 pt 11 ps 1.5 # Verde
set style line 4 lc rgb '#984EA3' lt 1 lw 2 pt 13 ps 1.5 # Roxo
set style line 5 lc rgb '#FF7F00' lt 1 lw 2 pt 5 ps 1.5  # Laranja
set style line 6 lc rgb '#555555' lt 2 lw 1.5             # Cinza - baseline

# Encontra o arquivo mais recente
DATADIR = 'results'

# ============================================================
# GRÁFICO 1: Comparação de Tempo - MERGE vs ODD-EVEN
# ============================================================

set output 'results/grafico_comp_tempos.png'
set title 'Tempo de Execução: MERGE vs ODD-EVEN' font 'Verdana,14'
set xlabel 'Número de Processos' font 'Verdana,12'
set ylabel 'Tempo (segundos)' font 'Verdana,12'
set key left top
unset logscale x
set logscale y
set xrange [0:16]
set xtics 1,2,15

# Busca os arquivos mais recentes
merge_file = system('ls -t results/merge_*.dat | head -1')
oddeven_file = system('ls -t results/oddeven_*.dat | head -1')

# Para cada tamanho, plota MERGE vs ODD-EVEN
plot merge_file using 1:($2==10000?$3:1/0) with linespoints ls 1 title 'MERGE - 10k', \
     oddeven_file using 1:($2==10000?$3:1/0) with linespoints ls 2 title 'ODD-EVEN - 10k', \
     merge_file using 1:($2==100000?$3:1/0) with linespoints ls 1 dt 2 title 'MERGE - 100k', \
     oddeven_file using 1:($2==100000?$3:1/0) with linespoints ls 2 dt 2 title 'ODD-EVEN - 100k', \
     merge_file using 1:($2==1000000?$3:1/0) with linespoints ls 1 dt 3 title 'MERGE - 1M', \
     oddeven_file using 1:($2==1000000?$3:1/0) with linespoints ls 2 dt 3 title 'ODD-EVEN - 1M'

# ============================================================
# GRÁFICO 2: Speedup Comparativo
# ============================================================

set output 'results/grafico_comp_speedup.png'
set title 'Speedup: MERGE vs ODD-EVEN' font 'Verdana,14'
set xlabel 'Número de Processos' font 'Verdana,12'
set ylabel 'Speedup' font 'Verdana,12'
set key left top
unset logscale y
set yrange [0:*]

# Linha de speedup ideal
set arrow from 1,1 to 15,15 nohead dt 2 lc rgb 'black' lw 1.5

plot x with lines dt 2 lc rgb 'black' lw 1.5 title 'Speedup Ideal', \
     merge_file using 1:($2==10000?$4:1/0) with linespoints ls 1 title 'MERGE - 10k', \
     oddeven_file using 1:($2==10000?$4:1/0) with linespoints ls 2 title 'ODD-EVEN - 10k', \
     merge_file using 1:($2==100000?$4:1/0) with linespoints ls 1 dt 2 title 'MERGE - 100k', \
     oddeven_file using 1:($2==100000?$4:1/0) with linespoints ls 2 dt 2 title 'ODD-EVEN - 100k', \
     merge_file using 1:($2==1000000?$4:1/0) with linespoints ls 1 dt 3 title 'MERGE - 1M', \
     oddeven_file using 1:($2==1000000?$4:1/0) with linespoints ls 2 dt 3 title 'ODD-EVEN - 1M'

# ============================================================
# GRÁFICO 3: Eficiência Comparativa
# ============================================================

set output 'results/grafico_comp_eficiencia.png'
set title 'Eficiência: MERGE vs ODD-EVEN' font 'Verdana,14'
set xlabel 'Número de Processos' font 'Verdana,12'
set ylabel 'Eficiência' font 'Verdana,12'
set key right top
set yrange [0:1.2]

# Linha de eficiência ideal
unset arrow
set arrow from 1,1 to 15,1 nohead dt 2 lc rgb 'black' lw 1.5

plot 1 with lines dt 2 lc rgb 'black' lw 1.5 title 'Eficiência Ideal', \
     merge_file using 1:($2==10000?$5:1/0) with linespoints ls 1 title 'MERGE - 10k', \
     oddeven_file using 1:($2==10000?$5:1/0) with linespoints ls 2 title 'ODD-EVEN - 10k', \
     merge_file using 1:($2==100000?$5:1/0) with linespoints ls 1 dt 2 title 'MERGE - 100k', \
     oddeven_file using 1:($2==100000?$5:1/0) with linespoints ls 2 dt 2 title 'ODD-EVEN - 100k', \
     merge_file using 1:($2==1000000?$5:1/0) with linespoints ls 1 dt 3 title 'MERGE - 1M', \
     oddeven_file using 1:($2==1000000?$5:1/0) with linespoints ls 2 dt 3 title 'ODD-EVEN - 1M'

# ============================================================
# GRÁFICO 4: Comparação Direta - 1M elementos
# ============================================================

set output 'results/grafico_comp_1m.png'
set title 'Comparação Direta: 1.000.000 elementos' font 'Verdana,14'
set xlabel 'Número de Processos' font 'Verdana,12'
set ylabel 'Tempo (segundos)' font 'Verdana,12'
set key right top
unset logscale y
set yrange [0:*]
unset arrow

seq_file = system('ls -t results/seq_*.dat | head -1')
seq_time_1m = system('grep "^1000000 " ' . seq_file . ' | awk "{print $2}"')

plot seq_time_1m with lines dt 2 lc rgb 'gray' lw 2 title 'Sequencial (baseline)', \
     merge_file using 1:($2==1000000?$3:1/0) with linespoints ls 1 title 'MERGE - Interleaving', \
     oddeven_file using 1:($2==1000000?$3:1/0) with linespoints ls 2 title 'ODD-EVEN Transposition'

# ============================================================
# GRÁFICO 5: Diferença Percentual MERGE vs ODD-EVEN
# ============================================================

set output 'results/grafico_comp_diferenca.png'
set title 'Diferença Percentual: ODD-EVEN vs MERGE' font 'Verdana,14'
set xlabel 'Número de Processos' font 'Verdana,12'
set ylabel 'Diferença (%)' font 'Verdana,12'
set key right top
unset logscale y
set yrange [*:*]
set xrange [2:16]

# Linha de referência (0%)
set arrow from 3,0 to 15,0 nohead dt 2 lc rgb 'black' lw 1.5

comparison_file = system('ls -t results/comparison_*.dat | head -1')

# Calcula: ((oddeven_time - merge_time) / merge_time) * 100
# Positivo = ODD-EVEN mais lento, Negativo = ODD-EVEN mais rápido
plot 0 with lines dt 2 lc rgb 'black' lw 1.5 title 'Paridade', \
     comparison_file using 1:(($2==10000?(($4-$3)/$3)*100:1/0)) with linespoints ls 3 title '10k elementos', \
     comparison_file using 1:(($2==100000?(($4-$3)/$3)*100:1/0)) with linespoints ls 4 title '100k elementos', \
     comparison_file using 1:(($2==1000000?(($4-$3)/$3)*100:1/0)) with linespoints ls 5 title '1M elementos'

# ============================================================
# GRÁFICO 6: Speedup por Tamanho - Comparativo
# ============================================================

set output 'results/grafico_comp_speedup_by_size.png'
set title 'Speedup por Tamanho do Vetor' font 'Verdana,14'
set xlabel 'Tamanho do Vetor' font 'Verdana,12'
set ylabel 'Speedup' font 'Verdana,12'
set key left top
set logscale x
unset logscale y
set xrange [5000:2000000]
set yrange [0:*]
unset arrow

# Para cada configuração de processos
plot merge_file using 2:($1==3?$4:1/0) with linespoints ls 1 title 'MERGE - 3 proc', \
     oddeven_file using 2:($1==3?$4:1/0) with linespoints ls 2 title 'ODD-EVEN - 3 proc', \
     merge_file using 2:($1==7?$4:1/0) with linespoints ls 1 dt 2 title 'MERGE - 7 proc', \
     oddeven_file using 2:($1==7?$4:1/0) with linespoints ls 2 dt 2 title 'ODD-EVEN - 7 proc', \
     merge_file using 2:($1==15?$4:1/0) with linespoints ls 1 dt 3 title 'MERGE - 15 proc', \
     oddeven_file using 2:($1==15?$4:1/0) with linespoints ls 2 dt 3 title 'ODD-EVEN - 15 proc'

print ""
print "=========================================="
print "Gráficos comparativos gerados em results/"
print "=========================================="
print "  - grafico_comp_tempos.png"
print "  - grafico_comp_speedup.png"
print "  - grafico_comp_eficiencia.png"
print "  - grafico_comp_1m.png"
print "  - grafico_comp_diferenca.png"
print "  - grafico_comp_speedup_by_size.png"
print ""
