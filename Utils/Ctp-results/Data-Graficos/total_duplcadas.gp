reset
n=10 #number of intervals
max=1000. #max value
min=000. #min value
width=1

set term png #output terminal and file
set output "GraficoDuplicadasDown.png"
set xrange [max:min]
set yrange [0:6000]

set xlabel "Período de geração de pacotes"
set ylabel "Total de mensagens duplicadas na rede"
set key left top

plot "ALTDuplicadas.data" using 1:2 title "PAC-A" with linespoints lw 2 ps 2 lc rgb "#0", \
 "INDDuplicadas.data" using 1:2 title "PAC-I" with linespoints lw 2 ps 2 lc rgb "#778899", \
 "COMPDuplicadas.data" using 1:2  title "CTP-Multi" with linespoints lw 2 ps 2 lc rgb "#696969", \
 "SINGDuplicadas.data" using 1:2 title "CTP" with linespoints lw 2 ps 2 lc rgb "#a9a9a9" ;
