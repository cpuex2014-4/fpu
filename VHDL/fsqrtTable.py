import math
import struct

def calcA(t, delta):
    return 1.0/(math.sqrt(t) + math.sqrt(t+delta))

def calcB(t, delta):
    a = calcA(t, delta)
    h = -a*t + math.sqrt(t) + 1.0/(4.0*a)
    return 0.5 * h

def float2bin(f):
    return ''.join(bin(ord(c)).replace('0b', '').rjust(8, '0') for c in struct.pack('!f', f))



def main():
    f = open('./fsqrtTable.data', 'w')
    d = 2**(-9)
    t = 2.0
    while t < 8.0:
        if t == 4.0:
            d = 2**(-8)
        a = calcA(t, d)
        b = calcB(t, d)
        f.write(float2bin(a) + '\n')
        f.write(float2bin(b) + '\n')
        t += d



if __name__ == '__main__':
    main()
