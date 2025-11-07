#!/usr/bin/gnuplot
################################################################################
# Script Gnuplot para gráfico de Speed-Up e Eficiência - MPI Quicksort
################################################################################

reset

# Configurações de entrada
if (!exists("csv_file")) csv_file = "results_first/qsort_comparison_20251106_190224.csv"
if (!exists("seq_file")) seq_file = "results_old/seq_20251105_233344.dat"
if (!exists("array_size")) array_size = 100000
if (!exists("output_file")) output_file = sprintf("plots/quicksort_speedup_%d.png", array_size)

# Cria diretório plots se não existir
system("mkdir -p plots")

# Processa dados sequenciais para obter baseline (usando LC_ALL=C)
baseline_cmd = sprintf("LC_ALL=C awk '$1 !~ /^#/ && $1 == %d {print $2}' %s", array_size, seq_file)
baseline_time = system(baseline_cmd)

# Se não há baseline sequencial, usa o tempo de 3 processos como baseline
baseline_source = "sequencial"
use_seq_baseline = 0
if (strlen(baseline_time) == 0 || baseline_time eq "") {
    baseline_cmd = sprintf("LC_ALL=C awk -F',' 'NR>1 && $1==\"MPI_Quicksort\" && $2==%d && $3==3 {print $6; exit}' %s", array_size, csv_file)
    baseline_time = system(baseline_cmd)
    baseline_source = "3 procs"
    use_seq_baseline = 0
} else {
    use_seq_baseline = 1
}

# Processa dados MPI e calcula métricas (usando LC_ALL=C)
# Mapeia processos para posições: 1→1, 3→2, 7→3, 15→4, 31→5
awk_cmd = sprintf("LC_ALL=C awk -F',' -v baseline=%s -v use_seq=%d '\
    BEGIN{\
        min_procs=1; \
        pos_map[1]=1; pos_map[3]=2; pos_map[7]=3; pos_map[15]=4; pos_map[31]=5\
    } \
    NR>1 && $1==\"MPI_Quicksort\" && $2==%d && $6>0 { \
        procs[$3]=$3; times[$3]=$6; positions[$3]=pos_map[$3] \
    } \
    END{ \
        if(baseline > 0){ \
            if(use_seq == 1) { \
                print \"1\", \"1.0\", \"1.0\", \"1.0\"; \
            } \
            for(p in procs){ \
                speedup=baseline/times[p]; \
                efficiency=speedup/p; \
                ideal=p/min_procs; \
                printf \"%%d %%.4f %%.4f %%.4f\\n\", positions[p], speedup, efficiency, ideal \
            } \
        } \
    }' %s | sort -n > plots/temp_qsort_data.txt", baseline_time, use_seq_baseline, array_size, csv_file)

system(awk_cmd)

# Configurações de saída - estilo similar à imagem
set terminal pngcairo size 900,650 enhanced font 'Verdana,11'
set output output_file

# Título com indicação do baseline
set title sprintf("Aplicação / Máquina (Quicksort) - Array Size: %d", array_size) font 'Verdana,14'

# Configuração dos eixos
set xlabel "Núcleos" font 'Verdana,12'
set ylabel "Fator de Aceleração" font 'Verdana,12'
set y2label "Eficiência" font 'Verdana,12'

# Ativa o segundo eixo Y
set ytics nomirror
set y2tics

# Ranges e tics personalizados - posições equidistantes
set xrange [0:6]
set yrange [0:*]
set y2range [0:*]  # Dinâmico para permitir eficiência > 1.0
set xtics ("1" 1, "3" 2, "7" 3, "15" 4, "31" 5) font 'Verdana,11'
set ytics font 'Verdana,11'
set y2tics font 'Verdana,11'

# Grid
set grid ytics xtics lt 0 lw 1 lc rgb "#d0d0d0"

# Estilo das barras - ajustado para distribuição equidistante
set style fill solid 0.75 border -1
set boxwidth 0.6

# Legenda - posicionada no topo esquerdo para não sobrepor barras
set key top left font 'Verdana,10'

# Cores - parecido com a imagem
color_bars = "#FFA500"    # Laranja para barras de eficiência
color_speedup = "#4169E1"  # Azul royal para speed-up
color_ideal = "#32CD32"    # Verde limão para speed-up ideal

# Plota o gráfico - barras primeiro, depois linhas (linhas ficam por cima)
# Formato: Position SpeedUp Efficiency IdealSpeedUp
plot "plots/temp_qsort_data.txt" using 1:3 with boxes axes x1y2 \
        lc rgb color_bars \
        fillstyle solid 0.5 \
        title "Eficiência", \
     "" using 1:4 with linespoints \
        lw 2.5 pt 7 ps 1.8 \
        lc rgb color_ideal \
        title "Speed-Up Ideal", \
     "" using 1:2 with linespoints \
        lw 2.5 pt 7 ps 1.8 \
        lc rgb color_speedup \
        title "Speed-Up"

# Remove arquivo temporário
system("rm -f plots/temp_qsort_data.txt")

print sprintf("Gráfico gerado: %s", output_file)
