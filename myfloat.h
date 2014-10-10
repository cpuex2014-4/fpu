#ifndef MY_FLOAT_H
#define MY_FLOAT_H
#include <stdint.h>
#include <math.h>
#include <stdio.h>

typedef union {
  struct {
    unsigned frac: 23;
    unsigned exp: 8;
    unsigned sign: 1;
  } Float;
  float f;
  uint32_t u;
} uni;

float uni2float (uni );

int uni_abscomp (uni , uni );

void u_print_bits (unsigned );

void print_bits (uni );

void u_print_bits_with (unsigned , char *);

int isNaN (uni );

int isZero(uni );

int isDenormal(uni );

int isInf (uni );

#endif
