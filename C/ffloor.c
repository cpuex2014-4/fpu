#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <math.h>
#include "fpu.h"

uint32_t ffloor (uint32_t a) {
  uint32_t sgn;
  uni abs;
  sgn = a>>31;
  abs.u = a;
  abs.Float.sign = 0;

  if (isDenormal(abs)) {
    return 0;;
  }

  if (flt(0x4b000000, abs.u) == 1) {
    return a;
  }

  abs.u = fadd(abs.u, 0x4b000000);
  abs.u = fsub(abs.u, 0x4b000000);

  uni ret = abs;
  ret.Float.sign = sgn;

  if (flt(a, ret.u) == 1) {
    ret.u = fsub(ret.u, 0x3f800000);
  }

  return ret.u;
}

int ffloorCheck (uni a) {
  uni ans,result;
  result.u = ffloor(a.u);

  if (isDenormal(a)) {
    a.u = 0;
  }
  ans.f = floorf(a.f);

  int flg = (ans.u != result.u && !(isNaN(ans)&&isNaN(result)));
  if (flg == 1) {
    fprintf (stderr, "wrong: %08x Result1: %08x Ans: %08x\n",
             a.u, result.u, ans.u);
  }

  return !flg;
}
