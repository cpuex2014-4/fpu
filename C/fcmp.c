#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include <stdint.h>
#include <math.h>
#include "fpu.h"

int feq (uint32_t a1, uint32_t b1) {
  uni a, b;
  a.u = a1;
  b.u = b1;

  if (isDenormal(a) || isZero(a)) {
    a.u = 0;
  }
  if (isDenormal(b) || isZero(b)) {
    b.u = 0;
  }

  if (isNaN(a) || isNaN(b)) {
    return 0;
  }


  return (a.u == b.u) ? 1 : 0;

}

int flt (uint32_t a1, uint32_t b1) {
  uni a, b;
  a.u = a1;
  b.u = b1;

  if (isDenormal(a) || isZero(a)) {
    a.u = 0;
  }
  if (isDenormal(b) || isZero(b)) {
    b.u = 0;
  }

  if (isNaN(a) || isNaN(b)) {
    return 0;
  }

  return ((int)a.u < (int)b.u) ? 1 : 0;
}

int fle (uint32_t a, uint32_t b) {
  return feq(a, b) | flt(a, b);
}
