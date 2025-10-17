# ============================================================
# Script GNUplot - Bubble Sort Paralelo MPI
# ============================================================
#
# Gera gráficos de:
#   1. Tempo de execução por tamanho
#   2. Speedup
#   3. Eficiência
#
# Uso:
#   gnuplot plot_results.gnuplot
#
# ============================================================

# Configurações gerais
set terminal pngcairo enhanced font 'Verdana,12' size 1200,800
set style data linespoints
set grid

# Define cores
set style line 1 lc rgb '#E41A1C' lt 1 lw 2 pt 7 ps 1.5  # Vermelho
set style line 2 lc rgb '#377EB8' lt 1 lw 2 pt 9 ps 1.5  # Azul
set style line 3 lc rgb '#4DAF4A' lt 1 lw 2 pt 11 ps 1.5 # Verde
set style line 4 lc rgb '#984EA3' lt 1 lw 2 pt 13 ps 1.5 # Roxo
set style line 5 lc rgb '#FF7F00' lt 1 lw 2 pt 5 ps 1.5  # Laranja

# Encontra o arquivo mais recente
DATADIR = 'results'

# ============================================================
# GRÁFICO 1: Tempo de Execução vs Tamanho do Vetor
# ============================================================

set output 'results/grafico_tempos.png'
set title 'Tempo de Execução - Bubble Sort (Pior Caso)' font 'Verdana,14'
set xlabel 'Tamanho do Vetor (elementos)' font 'Verdana,12'
set ylabel 'Tempo (segundos)' font 'Verdana,12'
set key left top
set logscale x
set logscale y
set format x "10^{%T}"

# Busca o arquivo mais recente
files = system('ls -t results/times_by_size_*.dat | head -1')

plot files using 1:2 with linespoints ls 1 title 'Sequencial', \
     files using 1:3 with linespoints ls 2 title '3 processos', \
     files using 1:4 with linespoints ls 3 title '7 processos', \
     files using 1:5 with linespoints ls 4 title '15 processos'

# ============================================================
# GRÁFICO 2: Speedup
# ============================================================

set output 'results/grafico_speedup.png'
set title 'Speedup - Bubble Sort Paralelo' font 'Verdana,14'
set xlabel 'Número de Processos' font 'Verdana,12'
set ylabel 'Speedup (Tp/T1)' font 'Verdana,12'
set key left top
unset logscale x
unset logscale y
set xrange [0:16]
set yrange [0:*]

# Linha de speedup ideal
set arrow from 1,1 to 15,15 nohead dt 2 lc rgb 'black' lw 1.5

speedup_file = system('ls -t results/speedup_*.dat | head -1')

plot x with lines dt 2 lc rgb 'black' lw 1.5 title 'Speedup Ideal', \
     speedup_file using ($2):($3):($1 == 10000 ? 1 : 0) every ::1 with linespoints ls 2 title '10.000 elementos', \
     speedup_file using ($2):($3):($1 == 100000 ? 1 : 0) every ::1 with linespoints ls 3 title '100.000 elementos', \
     speedup_file using ($2):($3):($1 == 1000000 ? 1 : 0) every ::1 with linespoints ls 4 title '1.000.000 elementos'

# ============================================================
# GRÁFICO 3: Eficiência
# ============================================================

set output 'results/grafico_eficiencia.png'
set title 'Eficiência - Bubble Sort Paralelo' font 'Verdana,14'
set xlabel 'Número de Processos' font 'Verdana,12'
set ylabel 'Eficiência (Speedup/P)' font 'Verdana,12'
set key right top
set xrange [0:16]
set yrange [0:1.2]

# Linha de eficiência ideal (1.0)
set arrow from 1,1 to 15,1 nohead dt 2 lc rgb 'black' lw 1.5

efficiency_file = system('ls -t results/efficiency_*.dat | head -1')

plot 1 with lines dt 2 lc rgb 'black' lw 1.5 title 'Eficiência Ideal', \
     efficiency_file using ($2):($3):($1 == 10000 ? 1 : 0) every ::1 with linespoints ls 2 title '10.000 elementos', \
     efficiency_file using ($2):($3):($1 == 100000 ? 1 : 0) every ::1 with linespoints ls 3 title '100.000 elementos', \
     efficiency_file using ($2):($3):($1 == 1000000 ? 1 : 0) every ::1 with linespoints ls 4 title '1.000.000 elementos'

# ============================================================
# GRÁFICO 4: Comparação Direta - 1M elementos
# ============================================================

set output 'results/grafico_comparacao_1m.png'
set title 'Tempo de Execução - 1.000.000 elementos' font 'Verdana,14'
set xlabel 'Número de Processos' font 'Verdana,12'
set ylabel 'Tempo (segundos)' font 'Verdana,12'
set key right top
unset logscale y
set xrange [0:16]
set yrange [0:*]
set xtics 1

mpi_file = system('ls -t results/mpi_*.dat | head -1')
seq_file = system('ls -t results/seq_*.dat | head -1')

# Extrai tempo sequencial para 1M
seq_time_1m = system('grep "^1000000 " ' . seq_file . ' | awk "{print $2}"')

plot seq_time_1m with lines dt 2 lc rgb 'red' lw 2 title 'Sequencial (baseline)', \
     mpi_file using ($1):($2 == 1000000 ? $3 : 1/0) every ::1 with linespoints ls 4 title 'MPI Paralelo'

print "Gráficos gerados com sucesso em results/"
print "  - grafico_tempos.png"
print "  - grafico_speedup.png"
print "  - grafico_eficiencia.png"
print "  - grafico_comparacao_1m.png"
