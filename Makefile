CC   = gcc
CFLG = -lm -Wall
OBJ  = myfloat.o

all: FADD FMUL
FADD: fadd.c $(OBJ)
	$(CC) -o fadd $(OBJ) fadd.c $(CFLG)
FMUL: fmul.c
	$(CC) -o fmul $(OBJ) fmul.c $(CFLG)
MYFLOAT:
	gcc -c myfloat.c

clean:
	rm -f fadd fmul *~ *.o
