reset
n=10 #number of intervals
max=5000. #max value
min=0. #min value
width=1

set term png #output terminal and file
set output "GraficoTotalEnvios5min.png"
set xrange [max:min]
set yrange [0:60]

set xlabel "Período de criação de pacotes"
set ylabel "Número de pacotes únicos enviados"
set key right bottom

plot "ALTTotalEnvios.data" using 1:2 title "PAC-A" with linespoints lw 2 ps 2 lc rgb "#0", \
 "INDTotalEnvios.data" using 1:2 title "PAC-I" with linespoints lw 2 ps 2 lc rgb "#778899", \
 "COMPTotalEnvios.data" using 1:2  title "CTP-Multi" with linespoints lw 2 ps 2 lc rgb "#696969", \
 "SINGTotalEnvios.data" using 1:2 title "CTP" with linespoints lw 2 ps 2 lc rgb "#a9a9a9" ;
