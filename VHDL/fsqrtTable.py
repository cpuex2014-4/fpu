import math
import struct

def calcA(t):
    return 1.0/(math.sqrt(t) + math.sqrt(t+delta))

def calcB(t):
    a = calcA(t)
    h = -a*t + math.sqrt(t) + 1.0/(4*a)
    return 0.5 * h

def float2bin(f):
    return ''.join(bin(ord(c)).replace('0b', '').rjust(8, '0') for c in struct.pack('!f', f))


delta = 2**(-9)

def main():
    f = open('./fsqrtTable.data', 'w')
    delta = 2**(-9)
    t = 2.0
    while t < 8.0:
        if t == 4.0:
            delta = 2**(-8)
        a = calcA(t)
        b = calcB(t)
        f.write(float2bin(a) + '\n')
        f.write(float2bin(b) + '\n')
        t += delta



if __name__ == '__main__':
    main()
