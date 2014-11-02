#include <stdint.h>
#include <stdio.h>
#include <math.h>
#include "fpu.h"

uint32_t fdiv (uint32_t a, uint32_t b) {
  if (downTo(a, 30, 23) == 0) {
    a &= 1<<31;
  }
  if (downTo(b, 30, 23) == 0) {
    b &= 1<<31;
  }
  uint32_t inv = finv(b);
  uint32_t ans = fmul(a, inv);
  return ans;
}

int fdivCheck (uni a, uni b) {
  uni ans, result;
  result.u = fdiv(a.u, b.u);

  if (downTo(a.u, 30, 23) == 0) {
    a.u &= 1<<31;
  }
  if (downTo(b.u, 30, 23) == 0) {
    b.u &= 1<<31;
  }

  ans.f = a.f / b.f;

  int flg = 0;
  flg |= optionalCheck(result, ans);
  flg |= ulpCheck(result, ans, 4);

  if (flg == 0) {
    fprintf(stderr, "%08x/%08x = result:%08x(%.10f), answer:%08x(%.10f)\n",
            a.u, b.u,  result.u, result.f, ans.u, ans.f);
  }

  return flg;
}
