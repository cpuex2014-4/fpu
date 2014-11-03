#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <math.h>
#include <assert.h>
#include "fpu.h"
#define CONST_ZERO 0
#define CONST_MINUS_ZERO 0x80000000
#define CONST_NAN ~0
#define CONST_INF   0x7f800000
#define CONST_MINUS_INF 0xff800000

uint32_t getAForSqrt (uint32_t key) {
  uni t, a;
  double delta = (key<0b10000000000)? 1/512.0 : 1/256.0;
  //kにexpの最下位bitが含まれていることに注意
  t.Float.sign = 0;
  t.Float.exp  = 128;
  t.Float.frac = 0;
  t.u |= key<<13;
  double x = t.f;
  double f = 1.0/(sqrt(x) + sqrt(x+delta));
  a.f = f;
  return a.u;
}

uint32_t getBForSqrt (uint32_t key) {
  uni t, b;
  double delta = (key<0b10000000000)? 1/512.0 : 1/256.0;
  t.Float.sign = 0;
  t.Float.exp  = 128;
  t.Float.frac = 0;
  t.u |= key<<13;
  double x = t.f;
  double a = 1.0/(sqrt(x) + sqrt(x+delta));
  double r = 0.5 * (-a * x + sqrt(x) + 1.0/(4.0*a));
  b.f = r;
  return b.u;
}

uint32_t fsqrt (uint32_t x1) {
  uni x;
  x.u = x1;

  //optional

  if (isDenormal(x)|isZero(x)) {//sqrt(-0) = -0
    return (x1>>31) ? CONST_MINUS_ZERO : CONST_ZERO;
  }

  if (isNaN(x) || x1>>31) {//負数は-0以外はNaNを返す
    return CONST_NAN;
  }

  if (isInf(x)) {
    return CONST_INF;
  }

  /*
    [2.0, 8.0)に正規化する
    [1.0, 4.0)でないのは
    2.0のときexpの下位1bitが0になるから
  */
  uni reg = x, ret;
  reg.Float.sign = 0;
  if (x.Float.exp % 2 == 1) {
    reg.Float.exp = 129;
  } else {
    reg.Float.exp  = 128;
  }

  //key は (exp下位1bit + frac上位10bit)
  uint32_t key = downTo(x.u, 23, 13);
  uint32_t a = getAForSqrt(key);
  uint32_t b = getBForSqrt(key);



  uint32_t ax = fmul(a, reg.u);
  ret.u = fadd(ax, b);

  //指数部の調整
  ret.Float.exp = ((x.Float.exp+1)>>1) + 63;
  ret.Float.sign = 0;

  return ret.u;
}

int fsqrtCheck (uni a) {
  uni ans, result;

  result.u = fsqrt(a.u);

  if (isDenormal(a)) {
    a.Float.frac = 0;
  }
  ans.f = sqrt(a.f);

  int flg = 0;
  flg |= optionalCheck(result, ans);
  flg |= ulpCheck(result, ans, 2);

  if (flg == 0) {
    fprintf(stderr,
            "%08x(%.10f) -> result:%08x(%.10f), answer:%08x(%.10f)\n",
            a.u, a.f,
            result.u, result.f,
            ans.u, ans.f);
  }

  return flg;
}
