reset
n=10 #number of intervals
max=1000. #max value
min=000. #min value
width=1

set term png #output terminal and file
set output "GraficoTotalMensagensDown.png"
set xrange [max:min]
set yrange [0:300000]

set xlabel "Período de geração de pacotes"
set ylabel "Total de pacotes de dados enviados na rede"
set key left top

plot "ALTTotalMensagens.data" using 1:2 title "PAC-A" with linespoints lw 2 ps 2 lc rgb "#0", \
 "INDTotalMensagens.data" using 1:2 title "PAC-I" with linespoints lw 2 ps 2 lc rgb "#778899", \
 "COMPTotalMensagens.data" using 1:2  title "CTP-Multi" with linespoints lw 2 ps 2 lc rgb "#696969", \
 "SINGTotalMensagens.data" using 1:2 title "CTP" with linespoints lw 2 ps 2 lc rgb "#a9a9a9" ;
