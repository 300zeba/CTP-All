import sys

#argv[1] = file id
# argv[2] = s -> single radio
#argv[2] = d -> dual radio
file_name = './results/outputs/out_' + sys.argv[1] + '.txt'

file = open(file_name,"r")

if sys.argv[2] == 'i':
    nodes1 = []
    nodes2 = []
    radios1 = []
    radios2 = []
    nodo = 0
    for i in range(101):
        nodes1.append(1000)
        nodes2.append(1000)
        radios1.append(3)
        radios2.append(3)

    for line in file:
        linha = line.split()
        if len(linha) >= 3:
            if linha[1] == 'CURRENT_DAD':
                nodo = int(linha[2])
            elif linha[1] == 'SENT_BEACON' and linha[2] == '1':
                radios1[int(linha[0])] = int(linha[2])
                nodes1[int(linha[0])] = nodo
            elif linha[1] == 'SENT_BEACON' and linha[2] == '2':
                radios2[int(linha[0])] = int(linha[2])
                nodes2[int(linha[0])] = nodo

    string = file_name.split("_")
    str = string[1].split(".")

    out_file_name = './grafos/' + str[0] + '.gv'

    out = open(out_file_name,"w")

    out.write('graph {0}'.format(str[0]) + ' {\n')



    for i in range(1,101):
        if nodes1[i] != 1000 and radios1[i] != 3:
            print(nodes1[i], radios1[i])
            out.write('{0} -- '.format(i) + '{0}'.format(nodes1[i]))
            if radios1[i] == 1:
                out.write(' [color=blue];\n')
            else:
                out.write(' [color=red];\n')
    for i in range(1,101):
        if nodes2[i] != 1000 and radios2[i] != 3:
            print(nodes2[i], radios2[i])
            out.write('{0} -- '.format(i) + '{0}'.format(nodes2[i]))
            if radios2[i] == 1:
                out.write(' [color=blue];\n')
            else:
                out.write(' [color=red];\n')


    out.write('}')

    out.close()


else:
    nodes = []
    radios = []
    for i in range(101):
        nodes.append(1000)
        if sys.argv[2] == 'd':
            radios.append(3)
        else:
            radios.append(2)

    for line in file:
        linha = line.split()
        if len(linha) >= 3:
            if linha[1] == 'CURRENT_DAD':
                nodes[int(linha[0])] = int(linha[2])
            elif linha[1] == 'SEND_RADIO':
                radios[int(linha[0])] = int(linha[2])

    string = file_name.split("_")
    str = string[1].split(".")

    out_file_name = str[0] + '.gv'

    out = open(out_file_name,"w")

    out.write('graph {0}'.format(str[0]) + ' {\n')



    for i in range(1,101):
        if nodes[i] != 1000 and radios[i] != 3:
            print(nodes[i], radios[i])
            out.write('{0} -- '.format(i) + '{0}'.format(nodes[i]))
            if radios[i] == 1:
                out.write(' [color=blue];\n')
            else:
                out.write(' [color=red];\n')


    out.write('}')

    out.close()
file.close()
