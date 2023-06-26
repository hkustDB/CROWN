# line style CROWN SNBQ3
set style line 1 pt 2 lc 'forest-green' ps 2 lw 2
# line style CROWN 4HOP
set style line 2 pt 1 lc 'purple' ps 2 lw 2
# line style DBToaster
set style line 3 pt 4 lc 'orange' ps 2 lw 2
# line style Flink
set style line 4 pt 3 lc 'skyblue' ps 2 lw 2

set logscale y
set xlabel "Parallelism"
set ylabel "Processing Time (Sec)"
set xrange [1:6]
set yrange [1:10000]
set xtics ("1" 1, "2" 2, "4" 3, "8" 4, "16" 5, "32" 6)
set ytics ("1e+00" 1, "1e+01" 10, "1e+02" 100, "1e+03" 1000, "1e+04" 10000)
set key above
set grid lt 0 lc 0 lw 1
set border lw 2

set term pngcairo size 700,350
set output "log/figure/figure8.png"
data = "log/result/figure8.dat"
plot data using 1:($2) title "CROWN 4-Hop" ls 2 w lp, data using 1:($3) title "Flink 4-Hop" ls 4 w lp, data using 1:($4) title "CROWN SNB Q3" ls 1 w lp, data using 1:($5) title "DBToaster SNB Q3" ls 3 w lp