set terminal pngcairo enhanced font 'Arial,10' size 1600,1200
set output 'combined_plot.png'

set multiplot layout 2,2 title "K-means Parallel Performance Analysis" font 'Arial Bold,16'

# Plot 1: Speedup
set title "Speedup vs Number of Cores"
set xlabel "Number of Cores"
set ylabel "Speedup"
set grid
set key left top
set xrange [0:17]
set yrange [0:*]
plot 'statistics.txt' using 1:1 with lines lw 2 lc rgb "gray" dashtype 2 title "Ideal", \
     'statistics.txt' using 1:4 with linespoints lw 2 pt 7 ps 1 lc rgb "blue" title "Actual"

# Plot 2: Execution Time
set title "Execution Time with Standard Deviation"
set xlabel "Number of Cores"
set ylabel "Time (seconds)"
set key right top
plot 'statistics.txt' using 1:2:3 with errorbars lw 2 pt 7 ps 1 lc rgb "red" title "Mean +/- StdDev", \
     'statistics.txt' using 1:2 with lines lw 2 lc rgb "red" notitle

# Plot 3: Efficiency
set title "Parallel Efficiency"
set xlabel "Number of Cores"
set ylabel "Efficiency (%)"
set yrange [0:110]
set arrow from 0,100 to 17,100 nohead lc rgb "gray" dashtype 2 lw 2
plot 'statistics.txt' using 1:5 with linespoints lw 2 pt 7 ps 1 lc rgb "green" title "Efficiency"

# Plot 4: All raw data points
set title "All Execution Times (Raw Data)"
set xlabel "Number of Cores"
set ylabel "Time (seconds)"
unset arrow
set yrange [0:*]
set key right top
plot 'benchmark_data.txt' using 1:3 with points pt 7 ps 0.5 lc rgb "orange" title "Individual Runs", \
     'statistics.txt' using 1:2 with linespoints lw 2 pt 7 ps 1 lc rgb "red" title "Mean"

unset multiplot
