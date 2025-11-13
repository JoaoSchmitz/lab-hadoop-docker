#!/usr/local/bin/python
"""mapper.py"""

import sys

# Os inputs vem do entrada padrão, STDIN 
for linha in sys.stdin:
    linha = linha.strip() # Remove os espaços em branco
    palavras = linha.split() # Divide a linha em duas palavras
    
    for count in palavras: # Aumenta os contadores

        print (('%s\t%s') % (count, 1)) # A saída desse passo servirá de entrada 
                                        # para o reducer.py
