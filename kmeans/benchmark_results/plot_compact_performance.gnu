set terminal pngcairo enhanced font 'Arial,16' size 1400,800
set output 'performance_compact.png'

set title "K-means Parallel Performance Analysis" font 'Arial Bold,18'
set xlabel "Number of Cores" font 'Arial Bold,16'

set ylabel "Speedup" font 'Arial Bold,16' textcolor rgb "#0066CC"
set ytics nomirror textcolor rgb "#0066CC"
set yrange [0:12]

set y2label "Efficiency (%)" font 'Arial Bold,16' textcolor rgb "#00AA00"
set y2tics nomirror textcolor rgb "#00AA00"
set y2range [0:120]

set xrange [0:17]
set xtics 0,2,16

set grid xtics ytics linewidth 1.5
set key top right font 'Arial,13' spacing 1.2

# Define distinct dash patterns:
# dashtype (dt) options: dt 2 = evenly spaced, dt 3 = longer dashes, dt 4 = dash-dot, dt 5 = dash-dot-dot
plot 'speedup_with_error.txt' using 1:1 with lines lw 3.5 lc rgb "#0066CC" dt (10,5) title "Ideal Speedup", \
     'speedup_with_error.txt' using 1:2:3 with errorbars lw 3 pt 7 ps 2 lc rgb "#0066CC" title "Actual Speedup", \
     'speedup_with_error.txt' using 1:2 with lines lw 2.5 lc rgb "#0066CC" notitle, \
     100 axes x1y2 with lines lw 4 lc rgb "#008800" dt (15,5,3,5) title "100% Efficiency", \
     'statistics.txt' using 1:5 axes x1y2 with linespoints lw 3.5 pt 9 ps 2 lc rgb "#00AA00" title "Efficiency"
