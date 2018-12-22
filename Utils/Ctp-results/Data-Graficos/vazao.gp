reset
n=10 #number of intervals
max=1000. #max value
min=000. #min value
width=1

set term png #output terminal and file
set output "GraficoVazaoDown.png"
set xrange [max:min]
set yrange [0:6]

set xlabel "Período de geração de pacotes"
set ylabel "Vazão (KBytes/s)"
set key left top

plot "ALTVazao.data" using 1:2 title "PAC-A" with linespoints lw 2 ps 2 lc rgb "#0", \
 "INDVazao.data" using 1:2 title "PAC-I" with linespoints lw 2 ps 2 lc rgb "#778899", \
 "COMPVazao.data" using 1:2  title "CTP-Multi" with linespoints lw 2 ps 2 lc rgb "#696969", \
 "SINGVazao.data" using 1:2 title "CTP" with linespoints lw 2 ps 2 lc rgb "#a9a9a9" ;
