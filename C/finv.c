#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <math.h>
#include "fpu.h"

uint32_t finv (uint32_t a) {
  //TODO
  return 0;
}


uint32_t finvTest (uint32_t a1) {
  uni result, ans, a;
  a.u = a1;
  result.u = finv(a.u);
  ans.f = 1.0 / a.f;
  return (result.u == ans.u)? 1 : 0;
}
