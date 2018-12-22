import sys

file_name = './outputs/out_' + sys.argv[1] + '.txt'


total_beacons = 0
total_messages = 0
sent_count = 0
received_count = 0.0
time = 0.0
total_duplicates = 0
overflow_id = 3
throughput = 0.0
delivery_rate = 0.0

file = open(file_name,"r")
out = open('testes_vazao_sumario.txt',"a")

out.write(sys.argv[1] + ':\n')



for line in file:
    linha = line.split()
    if len(linha) >= 3:
        if linha[1] == 'SENT_COUNT':
            sent_count += int(linha[2])
        elif linha[1] == 'TOTAL_BEACONS':
            total_beacons += int(linha[2])
        elif linha[1] == 'DUPLICATES':
            total_duplicates += int(linha[2])
        elif linha[1] == 'TOTAL_MESSAGES':
            total_messages += int(linha[2])
        elif linha[1] == 'RECEIVED_COUNT':
            received_count = int(linha[2])
            overflow_id = 1
        elif linha[1] == 'THROUGHPUT_TIME':
            time = int(linha[2])
            overflow_id = 2
        elif linha[1] == 'OVERFLOW_COUNTER':
            if overflow_id == 1:
                received_count += (int(linha[2]))<<16
                overflow_id = 3
            elif overflow_id == 2:
                time += (int(linha[2]))<<16
                overflow_id = 3

        if linha[0] == '40' and linha[1] == 'MAX_THL':
            max_thl = int(linha[2])
        elif linha[0] == '40' and linha[1] == 'AVERAGE_THL':
            average_thl = int(linha[2])


throughput = (received_count/float(time))*(1024/1000)*29

delivery_rate = received_count/float(sent_count)

out.write('Vazao = {:f}\n'.format(throughput))
out.write('TaxaDeEntrega = {:f}\n'.format(delivery_rate))
out.write('TotalEnvios = {0}\nTotalBeacons = {1}\nTotalMensagens = {2}\nDuplicadas = {3}\n'.format(sent_count,total_beacons,total_messages,total_duplicates))




out.close()
file.close()
