set terminal pngcairo enhanced font 'Arial,12' size 1200,800
set output 'benchmark_results/execution_time_plot.png'

set title "K-means Execution Time vs Number of Cores" font 'Arial Bold,14'
set xlabel "Number of Cores" font 'Arial,12'
set ylabel "Execution Time (seconds)" font 'Arial,12'

set grid
set key right top

set xrange [0:17]
set yrange [0:*]

# Plot execution time with standard deviation as error bars
plot 'benchmark_results/statistics.txt' using 1:2:3 with errorbars lw 2 pt 7 ps 1.5 lc rgb "red" title "Mean Time +/- Std Dev", \
     'benchmark_results/statistics.txt' using 1:2 with lines lw 2 lc rgb "red" notitle
