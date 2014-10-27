import math
import struct

delta = 2**(-11)

def calcA(t):
    return (-1/t) * (1/ (t+delta))

def calcB(t):
    return (0.5 * (math.sqrt(1/t) + math.sqrt(1/(t+delta)))**2)

def float2bin(f):
    return ''.join(bin(ord(c)).replace('0b', '').rjust(8, '0') for c in struct.pack('!f', f))


def main():
    f = open('./finvTable.data', 'w')
    t = 1.0
    while t < 2.0:
        a = calcA(t)
        b = calcB(t)
        f.write(float2bin(a) + '\n')
        f.write(float2bin(b) + '\n')
        t += delta

if __name__ == '__main__':
    main()
