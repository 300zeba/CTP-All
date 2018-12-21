reset
n=10 #number of intervals
max=5000. #max value
min=0. #min value
width=1

set term png #output terminal and file
set output "GraficoTotalMensagens5min.png"
set xrange [max:min]
set yrange [0:60]

set xlabel "Período de criação de pacotes"
set ylabel "Total de pacotes de dados enviados na rede"
set key right bottom

plot "SINGTotalMensagens.data" using 1:2 smooth unique title "CTP" with lines lt 1, \
 "ALTTotalMensagens.data" using 1:2 smooth unique title "PAC-A" with lines lt 2, \
 "COMPTotalMensagens.data" using 1:2  smooth unique title "CTP-Multi" with lines lt 3, \
 "INDTotalMensagens.data" using 1:2 smooth unique title "PAC-I" with lines lt 4 ;
