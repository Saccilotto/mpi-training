set terminal pngcairo enhanced font 'Arial,14' size 1400,900
set output 'speedup_filled_error.png'

set title "K-means Parallel Speedup (Shaded Standard Deviation)" font 'Arial Bold,16'
set xlabel "Number of Cores" font 'Arial Bold,14'
set ylabel "Speedup" font 'Arial Bold,14'

set grid linewidth 1.5
set key left top font 'Arial,12'

set xrange [0:17]
set xtics 0,1,16
set yrange [0:12]
set ytics 0,1,12

set style fill transparent solid 0.25

plot 'speedup_with_error.txt' using 1:1 with lines lw 3 lc rgb "#808080" dashtype 2 title "Ideal Speedup (Linear)", \
     'speedup_with_error.txt' using 1:($2-$3):($2+$3) with filledcurves lc rgb "#0066CC" title "Std Dev Range", \
     'speedup_with_error.txt' using 1:2 with linespoints lw 3 pt 7 ps 1.8 lc rgb "#0066CC" title "Actual Speedup"
