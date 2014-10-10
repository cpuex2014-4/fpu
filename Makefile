CC   = gcc
CFLG = -lm -Wall
OBJ  = myfloat.o

all: FADD FMUL TESTGEN
FADD: fadd.c $(OBJ)
	$(CC) -o fadd $(OBJ) fadd.c $(CFLG)
FMUL: fmul.c
	$(CC) -o fmul $(OBJ) fmul.c $(CFLG)
TESTGEN: testGen.c
	$(CC) -o testGen $(OBJ) testGen.c $(CFLG)
MYFLOAT:
	gcc -c myfloat.c

clean:
	rm -f fadd fmul testGen *~ *.o
