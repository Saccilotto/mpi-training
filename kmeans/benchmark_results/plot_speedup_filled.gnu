set terminal pngcairo enhanced font 'Arial,14' size 1400,900
set output 'speedup_filled_error.png'

set title "K-means Parallel Speedup (Shaded Error Region)" font 'Arial Bold,16'
set xlabel "Number of Cores" font 'Arial Bold,14'
set ylabel "Speedup" font 'Arial Bold,14'

set grid linewidth 1.5
set key left top font 'Arial,12'

set xrange [0:17]
set yrange [0:*]

set style fill transparent solid 0.3

# Plot with filled error region
plot 'speedup_stats.txt' using 1:1 with lines lw 3 lc rgb "gray" dashtype 2 title "Ideal Speedup (Linear)", \
     'speedup_stats.txt' using 1:($2-$3):($2+$3) with filledcurves lc rgb "blue" title "Std Dev Range", \
     'speedup_stats.txt' using 1:2 with linespoints lw 3 pt 7 ps 2 lc rgb "blue" title "Actual Speedup"
