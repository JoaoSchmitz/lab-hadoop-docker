#!/usr/local/bin/python
"""reducer.py"""

from operator import itemgetter
import sys

palavra_anterior = None
count_anterior = 0
palavra = None

for linha in sys.stdin:
    linha = linha.strip() # Remove espaços em branco

    palavra, count = linha.split('\t', 1) # Pega o que foi passado pelo mapper.py

    # Tenta converter o count q no momento é uma string para um inteiro
    try:
        count = int(count)
    except ValueError:  # Se o valor de count não for int ignora e continua
        continue

    if palavra_anterior == palavra: # Este if só funciona porque o Hadoop ordena a saída do map por
        count_anterior += count     # uma chave (no caso palavra) antes de ser passado para o reducer
    else:
        if palavra_anterior:
            print (('%s\t%s') % (palavra_anterior, count_anterior)) # Escreve o resultado na saída
        count_anterior = count
        palavra_anterior = palavra

if palavra_anterior == palavra:
    print (('%s\t%s') % (palavra_anterior, count_anterior))
