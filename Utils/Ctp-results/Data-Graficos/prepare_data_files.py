import os
import math

class Task:
    def __init__(self):
        self.value = []
        self.count = 0
        self.Upvalue = 0.0
        self.Downvalue = 0.0
        self.Avgvalue = 0.0

    def average_and_error(self):
        self.value.sort()

        if self.count == 0:
            return

        value_temp = 0.0
        std_dev = 0.0
        for i in range(self.count):
            value_temp += self.value[i]
            #print(i,self.value[i])
        self.Avgvalue = value_temp/self.count
        for i in range(self.count):
            std_dev += (self.value[i] - self.Avgvalue)**2
        std_dev = math.sqrt(std_dev/self.count)
        self.Upvalue = self.Avgvalue + 1.96*(std_dev/math.sqrt(self.count))
        self.Downvalue = self.Avgvalue - 1.96*(std_dev/math.sqrt(self.count))


def insert_list(lista,len,value):
    if len == 0:
        return
    lista[len].value.append(value)
    lista[len].count += 1



file_list = list(os.listdir('/home/gabriel/Desktop/Ctp-results/Data-Graficos'))


y_list = []

for i in range(len(file_list)):
	if file_list[i].split(".")[1] != 'data':
		continue
	
	for y in range(10001):
		y_list.append(Task())

	
	file = open(file_list[i],"r")
	
	for line in file:
		linha = line.split()
		if len(linha) < 2:
			continue
		y_list[int(linha[0])].value.append(float(linha[1]))
		y_list[int(linha[0])].count += 1
	
	file.close()
	
	file = open(file_list[i],"w")
	file.write('#X\tY\tZ1\tZ2\n')
	
	for y in range(10001):
		if(y_list[y].count > 0):
			y_list[y].average_and_error()
			
			file.write('{:d}\t{:08.7f}\t{:08.7f}\t{:08.7f}\n'.format(y,y_list[y].Avgvalue,y_list[y].Upvalue,y_list[y].Downvalue))
		
	file.close()
	
	
	del y_list[:]

	
	
