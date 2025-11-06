#!/bin/bash

# Create combined speedup and efficiency plot
# Run this from the benchmark_results directory

echo "Generating combined speedup and efficiency plot..."

# Check for required files
if [ ! -f "speedup_with_error.txt" ] || [ ! -f "statistics.txt" ]; then
    echo "Error: Required files not found!"
    echo "Please run generate_speedup_with_stddev.sh first"
    exit 1
fi

# Create gnuplot script with dual y-axes
cat > plot_speedup_efficiency_combined.gnu << 'EOF'
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
EOF

# Create alternative version with shaded speedup region
cat > plot_speedup_efficiency_filled.gnu << 'EOF'
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
EOF

# Create compact version for papers/presentations
cat > plot_compact_performance.gnu << 'EOF'
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
EOF

# Generate all plots
echo "Generating error bar version..."
gnuplot plot_speedup_efficiency_combined.gnu
echo "  - speedup_efficiency_combined.png created"

echo "Generating filled region version..."
gnuplot plot_speedup_efficiency_filled.gnu
echo "  - speedup_efficiency_filled.png created"

echo "Generating compact version for presentations..."
gnuplot plot_compact_performance.gnu
echo "  - performance_compact.png created"

echo ""
echo "Done! Three versions created:"
echo "  1. speedup_efficiency_combined.png (error bars)"
echo "  2. speedup_efficiency_filled.png (shaded region)"
echo "  3. performance_compact.png (cleaner for presentations)"