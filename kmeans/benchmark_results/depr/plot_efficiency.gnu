set terminal pngcairo enhanced font 'Arial,12' size 1200,800
set output 'benchmark_results/efficiency_plot.png'

set title "K-means Parallel Efficiency" font 'Arial Bold,14'
set xlabel "Number of Cores" font 'Arial,12'
set ylabel "Efficiency (%)" font 'Arial,12'

set grid
set key right top

set xrange [0:17]
set yrange [0:110]

# Add reference line at 100% efficiency
set arrow from 0,100 to 17,100 nohead lc rgb "gray" dashtype 2 lw 2

plot 'benchmark_results/statistics.txt' using 1:5 with linespoints lw 2 pt 7 ps 1.5 lc rgb "green" title "Parallel Efficiency"
