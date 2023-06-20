# line style Trill
set style line 1 pt 2 lc 'forest-green' ps 2 lw 2
# line style CROWN
set style line 2 pt 1 lc 'purple' ps 2 lw 2

set logscale y
set xlabel "Latency"
set ylabel "Processing Time (Sec)"
set xrange [1:29]
set yrange [9.9:10000]
set ytics ("1e+01" 10, "1e+02" 100, "1e+03" 1000, "1e+04" 10000)
set key above
set grid lt 0 lc 0 lw 1
set border lw 2

set term pngcairo size 700,350
set output "log/figure/figure9.png"
data = "log/result/figure9.dat"
plot data using 1:($2) title "Trill" ls 1 w lp, data using 1:($3) title "   CROWN" ls 2 w lp