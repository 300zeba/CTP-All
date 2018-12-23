reset
n=2500 #number of intervals
max=2500. #max value
min=0. #min value
width=(max-min)/n #interval width
total = 39899
#function used to map a value to the intervals
hist(x,width)=width*floor(x/width)+width/2.0
set term png #output terminal and file
set output "Atraso.png"
set xrange [min:max]
set yrange [0:1.01]
#to put an empty boundary around the
#data inside an autoscaled graph.
set offset graph 0.05,0.05,0.05,0.0
set xtics min,(max-min)/5,max
set boxwidth width*0.9
set style fill solid 0.5 #fillstyle
set tics out nomirror
set xlabel "Custo total"
set ylabel "CDF"
set key right bottom 

#count and plot
 
 plot "delay_data_ALT.data" u (hist($1,width)):(1.0/total) smooth cumulative title "PAC-A" with lines lw 2 lc rgb "#0", \
 "delay_data_IND.data" u (hist($1,width)):(1.0/total) smooth cumulative title "PAC-I" with lines lw 2 lc rgb "#778899", \
 "delay_data_COMP.data" u (hist($1,width)):(1.0/total) smooth cumulative  title "CTP-Multi" with lines lw 2 lc rgb "#696969", \
 "delay_data_SING.data" u (hist($1,width)):(1.0/total) smooth cumulative title "CTP" with lines lw 2 lc rgb "#a9a9a9" ;

	
