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
total_messages_0 = 0

file = open(file_name,"r")
out = open('delay_data_'+sys.argv[2] + '.data',"w")


for line in file:
    linha = line.split()
    if len(linha) >= 3:
        if linha[1] == 'RECEIVED_PACKET':
        	received_count += int(linha[2])
        	overflow_id = 1
        elif linha[1] == 'RECEIVED_COUNT':
        	total_messages = int(linha[2])
        	overflow_id = 2
        elif linha[1] == 'OVERFLOW_COUNTER':
            if overflow_id == 1:
                received_count += (int(linha[2]))<<16
                received_count /= 1000
                overflow_id = 3
                for l in range(total_messages - total_messages_0):
                	out.write("{:f}\n".format(received_count))
                received_count = 0.0
                total_messages_0 = total_messages
            elif overflow_id == 2:
				total_messages += (int(linha[2]))<<16
				overflow_id = 3
           				








out.close()
file.close()
