reset
n=10 #number of intervals
max=5000. #max value
min=0. #min value
width=1

set term png #output terminal and file
set output "GraficoVazao5min.png"
set xrange [max:min]
set yrange [0:60]

set xlabel "Período de geração de pacotes"
set ylabel "Vazão (KBytes/s)"
set key right bottom

plot "SINGVazao.data" using 1:2 smooth unique title "CTP" with lines lt 1, \
 "ALTVazao.data" using 1:2 smooth unique title "PAC-A" with lines lt 2, \
 "COMPVazao.data" using 1:2  smooth unique title "CTP-Multi" with lines lt 3, \
 "INDVazao.data" using 1:2 smooth unique title "PAC-I" with lines lt 4 ;
