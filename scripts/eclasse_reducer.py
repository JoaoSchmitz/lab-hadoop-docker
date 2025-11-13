#!/usr/bin/python3
import sys

output = {}
for line in sys.stdin:
    line = line.strip().split()
    key = line[0]
    value = line[1:]
 
    if key not in output.keys():
        output[key] = [value]
    else:
        output[key].append(value)

for juiz in output.keys():
    print("Juiz: ", juiz)
    for processo in output[juiz]:
        print("\tProcesso: ", processo[0], " - Status", processo[1])