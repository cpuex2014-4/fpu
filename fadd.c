#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include <math.h>
#include <stdint.h>
#include "myfloat.h"

uint32_t ops (uni a, uni b) {

  if (isNaN (a)) {
    return ~0;
  } else if (isInf(a) && isInf(b)
             && (a.Float.sign ^ b.Float.sign)) {
    return ~0;
  } else if (isInf(a)) {
    return a.u;
  } else if (isInf(b)){
    return b.u;
  } else if (isZero(a) && isZero(b)) {
    if (a.Float.sign & b.Float.sign) {
      return (1<<31);
    } else {
      return 0;
    }
  } else {
    if(isZero(a)) {
      return b.u;
    } else if (isZero(b)) {
      return a.u;
    }
  }

  assert(0);
}

uint32_t fadd (uint32_t a1, uint32_t b1) {
  uni a, b;
  uni ans;
  a.u = a1; b.u = b1;
  //compare abs
  if (uni_abscomp (a, b) < 0) { // swap
    uni t;
    t = a; a = b; b = t;
  }

  // ops
  if (a.Float.exp == 0 || a.Float.exp == 255 ||
      b.Float.exp == 0 || b.Float.exp == 255) {
    return ops(a, b);
  }


  // bit shift
  uint32_t d = a.Float.exp - b.Float.exp;
  uint32_t na = (1 << (23 + 3))|(a.Float.frac << 3);
  uint32_t nb = (1 << (23 + 3))|(b.Float.frac << 3);

  int flg = 0;
  uint32_t i;

  for (i = 0; i < d; i++) {
    flg |= nb&1;
    nb = (nb >> 1);
  }
  nb |= flg;
  nb *= (a.Float.sign == b.Float.sign)? 1:-1;

  // sum
  uint32_t frac = na + nb;

  int t = (int) log2(frac);

  // frac
  if (frac == 0) {
    return 0;
  } else if (t < 26) {
    frac = frac << (26 - t);
    int exp = a.Float.exp - (26 - t);
    if (exp <= 0) {
      if (a.Float.sign) {
        return 0b10000000000000000000000000000000;
      } else {
        return 0;
      }
    } else {
      ans.Float.exp = exp;
    }
  } else if (t > 26) {
    assert(t==27);
    frac = (frac>>1)|(frac&1);
    ans.Float.exp = a.Float.exp + 1;
  } else {
    // t == 26 繰り上がりなし
    ans.Float.exp = a.Float.exp;
  }


  uint32_t ulp   = 1 & (frac>>3);
  uint32_t guard = 1 & (frac>>2);
  uint32_t round = 1 & (frac>>1);
  uint32_t stick = 1 & frac;


  if (guard & (ulp|round|stick)) {
    frac += (1<<3);
    if (1&(frac>>27)) {
      ans.Float.exp += 1;
    }
  }

  if (ans.Float.exp >= 255) {
    frac = 0;
  }

  ans.Float.frac = (frac >> 3);
  ans.Float.sign = a.Float.sign;

  return ans.u;
}


int main () {
  uni a, b, ans;

  while(scanf("%x %x", &a.u, &b.u) == 2) {


    ans.u = fadd(a.u, b.u);


    printf("%08x\n", ans.u);

  }
  return 0;
}
