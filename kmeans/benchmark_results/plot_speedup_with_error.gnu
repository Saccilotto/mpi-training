set terminal pngcairo enhanced font 'Arial,14' size 1400,900
set output 'speedup_with_stddev.png'

set title "K-means Parallel Speedup with Standard Deviation" font 'Arial Bold,16'
set xlabel "Number of Cores" font 'Arial Bold,14'
set ylabel "Speedup" font 'Arial Bold,14'

set grid linewidth 1.5
set key left top font 'Arial,12'

set xrange [0:17]
set yrange [0:*]

# Increase line widths and point sizes for better visibility
set style line 1 lc rgb "gray" lw 3 dashtype 2
set style line 2 lc rgb "blue" lw 3 pt 7 ps 2
set style line 3 lc rgb "blue" lw 2

# Plot ideal speedup (linear) and actual speedup with error bars
plot 'speedup_stats.txt' using 1:1 with lines ls 1 title "Ideal Speedup (Linear)", \
     'speedup_stats.txt' using 1:2:3 with errorbars ls 2 title "Actual Speedup +/- Std Dev", \
     'speedup_stats.txt' using 1:2 with lines ls 3 notitle
