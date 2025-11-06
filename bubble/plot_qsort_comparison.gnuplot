#!/usr/bin/gnuplot

################################################################################
# Gnuplot Script: Comparação MPI Quicksort vs Odd-Even
################################################################################

# Configurações gerais
set terminal pngcairo enhanced font 'Arial,12' size 1200,800
set datafile separator ","

# Define o arquivo de dados (será substituído pelo timestamp mais recente)
data_file = system("ls -t results/qsort_comparison_*.csv 2>/dev/null | head -1")

if (strlen(data_file) == 0) {
    print "ERRO: Nenhum arquivo de resultados encontrado!"
    print "Execute './run_qsort_experiments.sh' primeiro."
    exit
}

print "Usando arquivo de dados: ", data_file

################################################################################
# GRÁFICO 1: Tempo de Execução vs Tamanho do Array (para cada número de processos)
################################################################################

set output 'results/plot_time_vs_size.png'
set title 'Tempo de Execução: Quicksort vs Odd-Even\n(Diferentes Tamanhos de Array)'
set xlabel 'Tamanho do Array'
set ylabel 'Tempo de Execução (segundos)'
set logscale xy
set grid
set key left top

plot data_file u 2:6 every ::1 with linespoints title 'Todos os testes' lc rgb 'gray' pt 0

# Reset para próximo gráfico
reset
set terminal pngcairo enhanced font 'Arial,12' size 1200,800
set datafile separator ","

################################################################################
# GRÁFICO 2: Comparação Direta - 7 Processos
################################################################################

set output 'results/plot_7procs_comparison.png'
set title 'Comparação de Performance: Quicksort vs Odd-Even\n(7 Processos)'
set xlabel 'Tamanho do Array'
set ylabel 'Tempo de Execução (segundos)'
set logscale xy
set grid
set key left top

plot data_file u 2:($1 eq "MPI_Quicksort" && $3 == 7 ? $6 : 1/0) \
     with linespoints linewidth 2 pt 7 ps 1.5 lc rgb 'blue' title 'Quicksort', \
     data_file u 2:($1 eq "MPI_OddEven" && $3 == 7 ? $6 : 1/0) \
     with linespoints linewidth 2 pt 9 ps 1.5 lc rgb 'red' title 'Odd-Even'

reset
set terminal pngcairo enhanced font 'Arial,12' size 1200,800
set datafile separator ","

################################################################################
# GRÁFICO 3: Speedup (Odd-Even / Quicksort)
################################################################################

set output 'results/plot_speedup.png'
set title 'Speedup: Quantas vezes Quicksort é mais rápido que Odd-Even'
set xlabel 'Tamanho do Array'
set ylabel 'Speedup (Odd-Even Time / Quicksort Time)'
set logscale x
set grid
set key right bottom

# Extrair dados de quicksort e odd-even, calcular speedup
plot "< awk -F, 'NR>1 && $3==3 {size=$2; if($1==\"MPI_Quicksort\") qs[size]=$6; if($1==\"MPI_OddEven\") oe[size]=$6} END {for(s in qs) if(s in oe) print s, oe[s]/qs[s]}' ".data_file \
     using 1:2 with linespoints linewidth 2 pt 7 ps 1.5 lc rgb 'green' title '3 processos', \
     "< awk -F, 'NR>1 && $3==7 {size=$2; if($1==\"MPI_Quicksort\") qs[size]=$6; if($1==\"MPI_OddEven\") oe[size]=$6} END {for(s in qs) if(s in oe) print s, oe[s]/qs[s]}' ".data_file \
     using 1:2 with linespoints linewidth 2 pt 9 ps 1.5 lc rgb 'blue' title '7 processos'

reset
set terminal pngcairo enhanced font 'Arial,12' size 1200,800
set datafile separator ","

################################################################################
# GRÁFICO 4: Escalabilidade - Quicksort
################################################################################

set output 'results/plot_quicksort_scalability.png'
set title 'Escalabilidade: MPI Quicksort\n(Tempo vs Número de Processos)'
set xlabel 'Número de Processos'
set ylabel 'Tempo de Execução (segundos)'
set logscale y
set grid
set key left top

plot data_file u 3:($1 eq "MPI_Quicksort" && $2 == 1000 ? $6 : 1/0) \
     with linespoints linewidth 2 pt 7 ps 1.5 title '1K elementos', \
     data_file u 3:($1 eq "MPI_Quicksort" && $2 == 10000 ? $6 : 1/0) \
     with linespoints linewidth 2 pt 9 ps 1.5 title '10K elementos', \
     data_file u 3:($1 eq "MPI_Quicksort" && $2 == 100000 ? $6 : 1/0) \
     with linespoints linewidth 2 pt 11 ps 1.5 title '100K elementos', \
     data_file u 3:($1 eq "MPI_Quicksort" && $2 == 1000000 ? $6 : 1/0) \
     with linespoints linewidth 2 pt 13 ps 1.5 title '1M elementos'

reset
set terminal pngcairo enhanced font 'Arial,12' size 1200,800
set datafile separator ","

################################################################################
# GRÁFICO 5: Escalabilidade - Odd-Even
################################################################################

set output 'results/plot_oddeven_scalability.png'
set title 'Escalabilidade: MPI Odd-Even\n(Tempo vs Número de Processos)'
set xlabel 'Número de Processos'
set ylabel 'Tempo de Execução (segundos)'
set logscale y
set grid
set key left top

plot data_file u 3:($1 eq "MPI_OddEven" && $2 == 1000 ? $6 : 1/0) \
     with linespoints linewidth 2 pt 7 ps 1.5 title '1K elementos', \
     data_file u 3:($1 eq "MPI_OddEven" && $2 == 10000 ? $6 : 1/0) \
     with linespoints linewidth 2 pt 9 ps 1.5 title '10K elementos', \
     data_file u 3:($1 eq "MPI_OddEven" && $2 == 100000 ? $6 : 1/0) \
     with linespoints linewidth 2 pt 11 ps 1.5 title '100K elementos', \
     data_file u 3:($1 eq "MPI_OddEven" && $2 == 1000000 ? $6 : 1/0) \
     with linespoints linewidth 2 pt 13 ps 1.5 title '1M elementos'

reset
set terminal pngcairo enhanced font 'Arial,12' size 1600,1000
set datafile separator ","

################################################################################
# GRÁFICO 6: Painel de Comparação (Grid 2x2)
################################################################################

set output 'results/plot_comparison_grid.png'
set multiplot layout 2,2 title "Comparação Completa: Quicksort vs Odd-Even"

# Subplot 1: Tempo - 7 processos
set title '7 Processos - Tempo de Execução'
set xlabel 'Tamanho do Array'
set ylabel 'Tempo (s)'
set logscale xy
set grid
set key left top
plot data_file u 2:($1 eq "MPI_Quicksort" && $3 == 7 ? $6 : 1/0) \
     with linespoints lw 2 pt 7 title 'Quicksort', \
     data_file u 2:($1 eq "MPI_OddEven" && $3 == 7 ? $6 : 1/0) \
     with linespoints lw 2 pt 9 title 'Odd-Even'

# Subplot 2: Speedup
set title 'Speedup (Odd-Even / Quicksort)'
set xlabel 'Tamanho do Array'
set ylabel 'Speedup'
set logscale x
unset logscale y
set grid
set key right bottom
plot "< awk -F, 'NR>1 && $3==7 {size=$2; if($1==\"MPI_Quicksort\") qs[size]=$6; if($1==\"MPI_OddEven\") oe[size]=$6} END {for(s in qs) if(s in oe) print s, oe[s]/qs[s]}' ".data_file \
     using 1:2 with linespoints lw 2 pt 7 lc rgb 'green' title '7 procs'

# Subplot 3: Escalabilidade Quicksort
set title 'Quicksort - Escalabilidade'
set xlabel 'Número de Processos'
set ylabel 'Tempo (s)'
unset logscale x
set logscale y
set grid
set key left top
plot data_file u 3:($1 eq "MPI_Quicksort" && $2 == 10000 ? $6 : 1/0) \
     with linespoints lw 2 pt 7 title '10K elementos', \
     data_file u 3:($1 eq "MPI_Quicksort" && $2 == 100000 ? $6 : 1/0) \
     with linespoints lw 2 pt 9 title '100K elementos'

# Subplot 4: Escalabilidade Odd-Even
set title 'Odd-Even - Escalabilidade'
set xlabel 'Número de Processos'
set ylabel 'Tempo (s)'
set grid
set key left top
plot data_file u 3:($1 eq "MPI_OddEven" && $2 == 10000 ? $6 : 1/0) \
     with linespoints lw 2 pt 7 title '10K elementos', \
     data_file u 3:($1 eq "MPI_OddEven" && $2 == 100000 ? $6 : 1/0) \
     with linespoints lw 2 pt 9 title '100K elementos'

unset multiplot

print ""
print "✓ Gráficos gerados com sucesso em results/"
print "  - plot_time_vs_size.png"
print "  - plot_7procs_comparison.png"
print "  - plot_speedup.png"
print "  - plot_quicksort_scalability.png"
print "  - plot_oddeven_scalability.png"
print "  - plot_comparison_grid.png"
