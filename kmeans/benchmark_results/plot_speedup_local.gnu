set terminal pngcairo enhanced font 'Arial,12' size 1200,800
set output 'speedup_plot.png'

set title "K-means Parallel Speedup" font 'Arial Bold,14'
set xlabel "Number of Cores" font 'Arial,12'
set ylabel "Speedup" font 'Arial,12'

set grid
set key left top

set xrange [0:17]
set yrange [0:*]

plot 'statistics.txt' using 1:1 with lines lw 2 lc rgb "gray" dashtype 2 title "Ideal Speedup (Linear)", \
     'statistics.txt' using 1:4 with linespoints lw 2 pt 7 ps 1.5 lc rgb "blue" title "Actual Speedup"
