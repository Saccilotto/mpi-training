set terminal pngcairo enhanced font 'Arial,14' size 1600,900
set output 'speedup_efficiency_combined.png'

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

# Style definitions with distinct dash patterns
set style line 1 lc rgb "#0066CC" lw 3.5 dt (10,5)       # Ideal speedup - blue, long dashes
set style line 2 lc rgb "#0066CC" lw 3 pt 7 ps 1.8       # Actual speedup (blue with points)
set style line 3 lc rgb "#0066CC" lw 2                   # Actual speedup line (blue)
set style line 4 lc rgb "#00AA00" lw 3 pt 9 ps 1.5       # Efficiency (green with triangles)
set style line 5 lc rgb "#008800" lw 4 dt (15,5,3,5)     # 100% efficiency - darker green, dash-dot

# Plot
plot 'speedup_with_error.txt' using 1:1 with lines ls 1 title "Ideal Speedup", \
     'speedup_with_error.txt' using 1:2:3 with errorbars ls 2 title "Actual Speedup +/- Std Dev", \
     'speedup_with_error.txt' using 1:2 with lines ls 3 notitle, \
     100 axes x1y2 with lines ls 5 title "100% Efficiency", \
     'statistics.txt' using 1:5 axes x1y2 with linespoints ls 4 title "Parallel Efficiency"
