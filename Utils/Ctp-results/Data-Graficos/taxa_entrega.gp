reset
n=10 #number of intervals
max=5000. #max value
min=0. #min value
width=1

set term png #output terminal and file
set output "GraficoTaxadeEntrega5min.png"
set xrange [max:min]
set yrange [0:1]

set xlabel "Período de criação de pacotes"
set ylabel "Taxa de Entrega"
set key right bottom

plot "SINGTaxaDeEntrega.data" using 1:2 smooth unique title "CTP" with lines lt 1, \
 "ALTTaxaDeEntrega.data" using 1:2 smooth unique title "PAC-A" with lines lt 2, \
 "COMPTaxaDeEntrega.data" using 1:2  smooth unique title "CTP-Multi" with lines lt 3, \
 "INDTaxaDeEntrega.data" using 1:2 smooth unique title "PAC-I" with lines lt 4 ;
