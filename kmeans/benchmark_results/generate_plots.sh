#!/bin/bash

# Script to generate plots from benchmark data
# Run this from the benchmark_results directory

echo "Generating plots from benchmark data..."

# Check if we have the required files
if [ ! -f "statistics.txt" ] || [ ! -f "benchmark_data.txt" ]; then
    echo "Error: statistics.txt or benchmark_data.txt not found!"
    echo "Please run this script from the benchmark_results directory"
    exit 1
fi

# Create gnuplot script for speedup plot
cat > plot_speedup_local.gnu << 'EOF'
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
EOF

# Create gnuplot script for execution time with error bars
cat > plot_time_local.gnu << 'EOF'
set terminal pngcairo enhanced font 'Arial,12' size 1200,800
set output 'execution_time_plot.png'

set title "K-means Execution Time vs Number of Cores" font 'Arial Bold,14'
set xlabel "Number of Cores" font 'Arial,12'
set ylabel "Execution Time (seconds)" font 'Arial,12'

set grid
set key right top

set xrange [0:17]
set yrange [0:*]

plot 'statistics.txt' using 1:2:3 with errorbars lw 2 pt 7 ps 1.5 lc rgb "red" title "Mean Time +/- Std Dev", \
     'statistics.txt' using 1:2 with lines lw 2 lc rgb "red" notitle
EOF

# Create gnuplot script for efficiency plot
cat > plot_efficiency_local.gnu << 'EOF'
set terminal pngcairo enhanced font 'Arial,12' size 1200,800
set output 'efficiency_plot.png'

set title "K-means Parallel Efficiency" font 'Arial Bold,14'
set xlabel "Number of Cores" font 'Arial,12'
set ylabel "Efficiency (%)" font 'Arial,12'

set grid
set key right top

set xrange [0:17]
set yrange [0:110]

set arrow from 0,100 to 17,100 nohead lc rgb "gray" dashtype 2 lw 2

plot 'statistics.txt' using 1:5 with linespoints lw 2 pt 7 ps 1.5 lc rgb "green" title "Parallel Efficiency"
EOF

# Create combined plot
cat > plot_combined_local.gnu << 'EOF'
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
EOF

# Generate plots
echo "Generating speedup plot..."
gnuplot plot_speedup_local.gnu

echo "Generating execution time plot..."
gnuplot plot_time_local.gnu

echo "Generating efficiency plot..."
gnuplot plot_efficiency_local.gnu

echo "Generating combined plot..."
gnuplot plot_combined_local.gnu

echo ""
echo "Done! Plots generated:"
echo "  - speedup_plot.png"
echo "  - execution_time_plot.png"
echo "  - efficiency_plot.png"
echo "  - combined_plot.png"
