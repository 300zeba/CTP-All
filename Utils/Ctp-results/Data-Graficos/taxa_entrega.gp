reset
n=10 #number of intervals
max=10000. #max value
min=1000. #min value
width=1

set palette gray

set term png #output terminal and file
set output "GraficoTaxadeEntregaUp.png"
set xrange [max:min]
set yrange [0:1]

set xlabel "Período de geração de pacotes"
set ylabel "Taxa de Entrega
set key left bottom

plot "ALTTaxaDeEntrega.data" using 1:2 title "PAC-A" with linespoints lw 2 ps 2 lc rgb "#0", \
 "INDTaxaDeEntrega.data" using 1:2 title "PAC-I" with linespoints lw 2 ps 2 lc rgb "#778899", \
 "COMPTaxaDeEntrega.data" using 1:2  title "CTP-Multi" with linespoints lw 2 ps 2 lc rgb "#696969", \
 "SINGTaxaDeEntrega.data" using 1:2 title "CTP" with linespoints lw 2 ps 2 lc rgb "#a9a9a9" ;
