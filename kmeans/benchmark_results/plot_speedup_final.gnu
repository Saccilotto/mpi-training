set terminal pngcairo enhanced font 'Arial,14' size 1400,900
set output 'speedup_with_stddev.png'

set title "K-means Parallel Speedup with Standard Deviation" font 'Arial Bold,16'
set xlabel "Number of Cores" font 'Arial Bold,14'
set ylabel "Speedup" font 'Arial Bold,14'

set grid linewidth 1.5
set key left top font 'Arial,12'

set xrange [0:17]
set xtics 0,1,16
set yrange [0:12]
set ytics 0,1,12

set style line 1 lc rgb "#808080" lw 3 dashtype 2
set style line 2 lc rgb "#0066CC" lw 3 pt 7 ps 1.8
set style line 3 lc rgb "#0066CC" lw 2

plot 'speedup_with_error.txt' using 1:1 with lines ls 1 title "Ideal Speedup (Linear)", \
     'speedup_with_error.txt' using 1:2:3 with errorbars ls 2 title "Actual Speedup +/- Std Dev", \
     'speedup_with_error.txt' using 1:2 with lines ls 3 notitle
