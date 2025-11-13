#!/usr/bin/python3
import sys

for linha in sys.stdin:
    partes = linha.split()
    juiz_id = int(partes[0])
    print(juiz_id,*partes[1:-1])