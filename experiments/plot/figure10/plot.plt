# line style crown
set style line 1 pt 4 lc 'black' ps 2 lw 2
# line style flink
set style line 2 pt 1 lc 'forest-green' ps 2 lw 2
# line style dbtoaster_cpp
set style line 3 pt 2 lc 'skyblue' ps 2 lw 2
# line style dbtoaster
set style line 4 pt 2 lc 'blue' ps 2 lw 2
# line style crown_delta
set style line 5 pt 4 lc 'purple' ps 2 lw 2
# line style trill
set style line 6 pt 3 lc 'orange' ps 2 lw 2


set logscale y
set ylabel "Processing Time (Sec)"
set xrange [-1:12]
set yrange [1:100000]
set xtics ("3-Hop" 0, "4-Hop" 1, "2-Comb" 2, "SNB Q1" 3, "SNB Q2" 4, "SNB Q3" 5, "dumbbell" 6, "3-Hop" 7, "4-Hop" 8, "dumbbell" 9, "Star" 10, "SNB Q4" 11)
set ytics ("1e+00" 1, "1e+01" 10, "1e+02" 100, "1e+03" 1000, "1e+04" 10000, "1e+05" 100000)
set key above
set grid lt 0 lc 0 lw 1
set border lw 2

set style histogram cluster gap 3
set term pngcairo size 2100,350
set output "log/figure/figure10.png"
data = "log/result/figure10.dat"
plot data u ($1) ti "CROWN" ls 1 w hist fs pattern 2 bor lc 'black', data u ($2) ti "Flink" ls 2 w hist fs pattern 1 bor lc 'black', data u ($3) ti "DBToaster CPP" ls 3 w hist fs pattern 4 bor lc 'black', data u ($4) ti "DBToaster Spark" ls 4 w hist fs pattern 5 bor lc 'black', data u ($5) ti "CROWN Delta" ls 5 w hist fs pattern 2 bor lc 'black', data u ($6) ti "Trill" ls 6 w hist fs pattern 7 bor lc 'black'