#ifndef FPU_H
#define FPU_H

#include <stdint.h>

typedef union {
  struct {
    uint32_t frac: 23;
    uint32_t exp: 8;
    uint32_t sign: 1;
  } Float;
  float f;
  uint32_t u;
} uni;

// utils
int isNaN (uni );
int isZero(uni );
int isDenormal(uni );
int isInf (uni );
int uni_abscomp (uni , uni );


// for debug print
void print_bits (uni );
void u_print_bits (uint32_t );
void u_print_bits_with (uint32_t , char *);


// functions
uint32_t fadd (uint32_t, uint32_t );
int faddCheck (uni , uni);
uint32_t fmul (uint32_t, uint32_t );
int fmulCheck (uni , uni);

#endif