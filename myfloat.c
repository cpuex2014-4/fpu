#include "myfloat.h"

float uni2float (uni a) {
  float c;
  c = 1.0 + a.Float.frac/(pow(2, 1+log2(a.Float.frac)));
  return c * pow (2, a.Float.exp - 127);
}

int uni_abscomp (uni a, uni b) {
  unsigned s = (a.u&(~(1<<31)));
  unsigned t = (b.u&(~(1<<31)));
  return (s > t) ? 1 : ((s < t)? -1: 0);
}

void u_print_bits (unsigned a) {
  int i;
  for(i=32;i>=0;i--) {
    printf("%d",((a>>i)&1?1:0));
  }
  putchar('\n');
}

void print_bits (uni a) {
  int i;
  printf("%d",(1&(a.Float.sign))?1:0);
  putchar('|');
  for(i=7;i>=0;i--) {
    printf("%d",(1&(a.Float.exp>>i))?1:0);
  }
  putchar('|');
  for(i=22;i>=0;i--) {
    printf("%d",(1&(a.Float.frac>>i))?1:0);
  }
  putchar('\n');
}
void u_print_bits_with (unsigned a, char *c) {
  int i;
  for(i=32;i>=0;i--) {
    printf("%d",((a>>i)&1?1:0));
  }
  puts(c);
}

int isNaN (uni a) {
  return (a.Float.exp == 255) && (a.Float.frac != 0);
}

int isZero(uni a) {
  return (a.Float.exp == 0);
}

int isInf (uni a) {
  return (a.Float.exp == 255) && (a.Float.frac == 0);
}
