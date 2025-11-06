set terminal pngcairo enhanced font 'Arial,14' size 1600,900
set output 'speedup_efficiency_filled.png'

set title "K-means Parallel Performance: Speedup and Efficiency" font 'Arial Bold,16'
set xlabel "Number of Cores" font 'Arial Bold,14'

# Left y-axis for Speedup
set ylabel "Speedup" font 'Arial Bold,14' textcolor rgb "#0066CC"
set ytics nomirror textcolor rgb "#0066CC"
set yrange [0:12]

# Right y-axis for Efficiency
set y2label "Efficiency (%)" font 'Arial Bold,14' textcolor rgb "#00AA00"
set y2tics nomirror textcolor rgb "#00AA00"
set y2range [0:120]

set xrange [0:17]
set xtics 0,1,16

set grid xtics ytics linewidth 1.5
set key top right font 'Arial,12'

set style fill transparent solid 0.2

# Plot with filled speedup region and distinct dash patterns
plot 'speedup_with_error.txt' using 1:1 with lines lw 3.5 lc rgb "#0066CC" dt (10,5) title "Ideal Speedup", \
     'speedup_with_error.txt' using 1:($2-$3):($2+$3) with filledcurves lc rgb "#0066CC" title "Speedup Std Dev Range", \
     'speedup_with_error.txt' using 1:2 with linespoints lw 3 pt 7 ps 1.8 lc rgb "#0066CC" title "Actual Speedup", \
     100 axes x1y2 with lines lw 4 lc rgb "#008800" dt (15,5,3,5) title "100% Efficiency", \
     'statistics.txt' using 1:5 axes x1y2 with linespoints lw 3 pt 9 ps 1.5 lc rgb "#00AA00" title "Parallel Efficiency"
