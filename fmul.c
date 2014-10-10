#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include <stdint.h>
#include <math.h>
#include "myfloat.h"
#define CONST_ZERO 0
#define CONST_MINUS_ZERO 0x80000000
#define CONST_NAN ~0
#define CONST_INF   0x7f000000
#define CONST_MINUS_INF 0xff000000


uint32_t fmul (uint32_t a1, uint32_t b1) {

  uni a, b, ans;
  a.u = a1;
  b.u = b1;

  if (isNaN(a) || isNaN(b)) {
    return CONST_NAN;
  }

  ans.Float.sign = a.Float.sign ^ b.Float.sign; //Sign


  //Aの仮数部に1bitを足した値を 上位13bitと下位11bitにわける
  unsigned aFrac = a.Float.frac | (1<<23);
  unsigned aHigh = aFrac>>11;
  unsigned aLow = (~(~0 << 11)) & aFrac;

  unsigned bFrac = b.Float.frac | (1<<23);
  unsigned bHigh = bFrac>>11;
  unsigned bLow = (~(~0 << 11)) & bFrac;

  unsigned mulFrac = aHigh * bHigh + (aHigh * bLow >> 11) + (aLow * bHigh >> 11) + 2;


  int exp = a.Float.exp + b.Float.exp - 127;

  if (mulFrac & (1<< 25)) { //繰り上がり
    ans.Float.frac = ((1<<25)^mulFrac) >> 2;
    exp += 1;
  } else {
    ans.Float.frac = ((1<<24)^mulFrac) >> 1;
  }


  if (exp <= -1) {

    if (ans.Float.sign) {
      return CONST_MINUS_ZERO;
    } else {
      return CONST_ZERO;
    }

  } else if (255 <= exp) {

    if (ans.Float.sign) {
      return CONST_MINUS_INF;
    } else {
      return CONST_INF;
    }

  }

  ans.Float.exp = exp; //Exp

  return ans.u;

}

int isDenormal(uni a) {

  return (a.Float.exp==0) ? 0 : 1;

}


int main () {

  uni a, b, ans;

  while(scanf("%x %x", &a.u, &b.u) == 2) {

    ans.u = fmul(a.u, b.u);

    printf("%08x\n", ans.u);

  }
  return 0;

}
