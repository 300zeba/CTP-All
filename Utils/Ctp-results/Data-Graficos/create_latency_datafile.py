import sys
import os.path
import math

#sys.argv[1] => NS ou N

class Task:
    def __init__(self):
        self.latency = []
        self.count = 0
        self.UpLatency = 0.0
        self.DownLatency = 0.0
        self.AvgLatency = 0.0

    def average_and_error(self):
        self.latency.sort()

        if self.count == 0:
            return

        latency_temp = 0.0
        std_dev = 0.0
        for i in range(self.count):
            latency_temp += self.latency[i]
            #print(i,self.latency[i])
        self.AvgLatency = latency_temp/self.count
        for i in range(self.count):
            std_dev += (self.latency[i] - self.AvgLatency)**2
        std_dev = math.sqrt(std_dev/self.count)
        self.UpLatency = self.AvgLatency + 1.96*(std_dev/math.sqrt(self.count))
        self.DownLatency = self.AvgLatency - 1.96*(std_dev/math.sqrt(self.count))



def get_path_size(nodes,source,destination):
    if(os.path.isfile('./routes'+sys.argv[1]+'/dual_{0}_{1}_{2}.txt'.format(nodes,source,destination))):
        routes = open('./routes'+sys.argv[1]+'/dual_{0}_{1}_{2}.txt'.format(nodes,source,destination))
        arquivo = routes.readlines()
        lenline = arquivo[1].split(' ')
        return int(lenline[4])/2
    else:
        return 0

def get_routes(taskNum):
    tasks = open('Formated_Tasks.txt',"r")
    tarefa = list();
    for line2 in tasks:
        linha2 = line2.split(" ")
        if linha2[0] == taskNum:
            len = get_path_size(linha2[2],linha2[3],linha2[4])
            print(len)
    tasks.close()
    return len

def insert_list(lista,len,latency):
    if len == 0:
        return
    lista[len].latency.append(latency)
    lista[len].count += 1




if sys.argv[1] == 'NS':
    baseFileName = 'latencyNSfinal'
elif sys.argv[1] == 'N':
    baseFileName = 'latencyNfinal'


lista = []
for i in range(10):
    lista.append(Task())

file = open(baseFileName +'.txt',"r")

for line in file:
    linha = line.split(' ')
    taskNum = linha[0]
    print(taskNum)
    length = get_routes(taskNum)
    #print(linha)
    insert_list(lista,length,float(linha[3]))
for i in range(9):
    lista[i].average_and_error()
    #print(i , lista[i].AvgLatency ,lista[i].count)


fileLt = open('datafileLatency'+ sys.argv[1] +'.dat',"w")

fileLt.write('# X  Y          Z1        Z2\n')
for i in {1,2,3,4,5,6,7,8}:
    fileLt.write('  {:d}'.format(i) + '  {:08.7f}'.format(lista[i].AvgLatency) + '  {:08.7f}'.format(lista[i].UpLatency) + '  {:08.7f}\n'.format(lista[i].DownLatency))
