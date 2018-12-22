def print_in_file(protocol, metric, send_rate, value):
	out = open('../Data-Graficos/' + protocol + metric + '.data',"a")
	out.write(send_rate + '\t' + value + '\n')	
	out.close()	



file = open('testes_vazao_sumario.txt',"r")

for line in file:
	linha = line.split()
	if len(linha) < 3:
		break
	if linha[1] != "=":
		protocol = linha[1]
		send_rate = linha[2]
	else:
		print_in_file(protocol, linha[0], send_rate, linha[2])

file.close()

