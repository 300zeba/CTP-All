reset
n=10 #number of intervals
max=10000. #max value
min=1000. #min value
width=1

set term png #output terminal and file
set output "GraficoTotalBeaconsUp.png"
set xrange [max:min]
set yrange [0:85000]

set xlabel "Período de geração de pacotes"
set ylabel "Total de beacons enviados na rede"

plot "ALTTotalBeacons.data" using 1:2 title "PAC-A" with linespoints lw 2 ps 2 lc rgb "#0", \
 "INDTotalBeacons.data" using 1:2 title "PAC-I" with linespoints lw 2 ps 2 lc rgb "#778899", \
 "COMPTotalBeacons.data" using 1:2  title "CTP-Multi" with linespoints lw 2 ps 2 lc rgb "#696969", \
 "SINGTotalBeacons.data" using 1:2 title "CTP" with linespoints lw 2 ps 2 lc rgb "#a9a9a9" ;
