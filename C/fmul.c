#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include <stdint.h>
#include <math.h>
#include "fpu.h"
#define CONST_ZERO 0
#define CONST_MINUS_ZERO 0x80000000
#define CONST_NAN ~0
#define CONST_INF   0x7f800000
#define CONST_MINUS_INF 0xff800000


uint32_t fmul (uint32_t a1, uint32_t b1) {

  uni a, b, ans;
  a.u = a1;
  b.u = b1;

  if (isNaN(a)==1 || isNaN(b)==1) {
    return CONST_NAN;
  }

  if (a.Float.exp ==0 || b.Float.exp == 0) {
    if (isInf(a) || isInf(b)) {
      return CONST_NAN;
    } else {
      return (a.Float.sign ^ b.Float.sign) ? CONST_MINUS_ZERO : CONST_ZERO;
    }
  }

  if (isInf(a) || isInf(b)) {
    return (a.Float.sign ^ b.Float.sign) ? CONST_MINUS_INF : CONST_INF;
  }

  ans.Float.sign = a.Float.sign ^ b.Float.sign; //Sign


  //Aの仮数部に1bitを足した値を 上位13bitと下位11bitにわける
  uint32_t aFrac = a.Float.frac | (1<<23);
  uint32_t aHigh = aFrac>>11;             //上位13bit
  uint32_t aLow = (~(~0 << 11)) & aFrac;  //下位11bit

  uint32_t bFrac = b.Float.frac | (1<<23);
  uint32_t bHigh = bFrac>>11;
  uint32_t bLow = (~(~0 << 11)) & bFrac;

  uint32_t mulFrac = aHigh * bHigh + (aHigh * bLow >> 11) + (aLow * bHigh >> 11) + 2;


  int exp = a.Float.exp + b.Float.exp - 127;

  if (mulFrac & (1<< 25)) {

    //繰り上がり
    exp += 1;

    //fracにmulFrac(24 downto 2)をいれる
    ans.Float.frac = ((1<<25)^mulFrac) >> 2;

  } else {

    assert(mulFrac & (1 << 24));

    //fracにmulFrac(23 downto 1)をいれる
    ans.Float.frac = ((1<<24)^mulFrac) >> 1;
  }


  if (exp <= 0) {

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

int fmulCheck (uni a, uni b) { //チェック

  uni ans, result;
  result.u = fmul(a.u, b.u);
  if (isDenormal(a)) {
    a.Float.frac = 0;
  }
  if (isDenormal(b)) {
    b.Float.frac = 0;
  }

  ans.f = a.f * b.f;

  int flg = 0;
  flg |= optionalCheck(result, ans);
  flg |= ulpCheck(result, ans, 1);
  if (flg == 0) {
    fprintf(stderr, "WrongAnswer: %08x %08x Result=%08x Answer=%08x\n", a.u, b.u, result.u, ans.u);
  }
  return flg;
}
