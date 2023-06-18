# line style Google
set style line 1 pt 2 lc 'forest-green' ps 2 lw 2
# line style Epinion
set style line 2 pt 1 lc 'purple' ps 2 lw 2
# line style BerkStan
set style line 3 pt 4 lc 'orange' ps 2 lw 2
# line style Bitcoin
set style line 4 pt 3 lc 'skyblue' ps 2 lw 2

set logscale y
set xlabel "enclosureness"
set ylabel "Processing Time (Sec)"
set xrange [1:20]
set yrange [1:10000]
set xtics ("1" 1, "2" 2, "4" 4, "10" 10, "20" 20)
set ytics ("1e+00" 1, "1e+01" 10, "1e+02" 100, "1e+03" 1000, "1e+04" 10000)
set key above
set grid lt 0 lc 0 lw 1
set border lw 2

set term pngcairo size 700,350
set output "log/figure/figure7.png"
data = "log/result/figure7.dat"
plot data using 1:($2) title "Epinion" ls 2 w lp, data using 1:($3) title "Bitcoin" ls 4 w lp, data using 1:($4) title "BerkStan" ls 3 w lp, data using 1:($5) title "Google" ls 1 w lp