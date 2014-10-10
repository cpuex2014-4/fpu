#include <stdio.h>
#include <assert.h>
#include <stdlib.h>
#include <stdint.h>
#include <math.h>
#include "myfloat.h"
#define CONST_ZERO 0
#define CONST_MINUS_ZERO 0x80000000
#define CONST_NAN ~0
#define CONST_INF   0x7f800000
#define CONST_MINUS_INF 0xff800000


uint32_t fmul (uint32_t a1, uint32_t b1) {

  uni a, b, ans;
  a.u = a1;
  b.u = b1;
	if (a.Float.exp ==0 || b.Float.exp == 0) {
		if (isInf(a) || isInf(b)) {
			return CONST_NAN;
		} else {
			return (a.Float.sign ^ b.Float.sign) ? CONST_MINUS_ZERO : CONST_ZERO;
		}
	}

  if (isNaN(a) || isNaN(b)) {
    return CONST_NAN;
  }

  ans.Float.sign = a.Float.sign ^ b.Float.sign; //Sign


  //Aの仮数部に1bitを足した値を 上位13bitと下位11bitにわける
  unsigned aFrac = a.Float.frac | (1<<23);
  unsigned aHigh = aFrac>>11;             //上位13bit
  unsigned aLow = (~(~0 << 11)) & aFrac;  //下位11bit

  unsigned bFrac = b.Float.frac | (1<<23);
  unsigned bHigh = bFrac>>11;
  unsigned bLow = (~(~0 << 11)) & bFrac;

  unsigned mulFrac = aHigh * bHigh + (aHigh * bLow >> 11) + (aLow * bHigh >> 11) + 2;


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

int ok (uni a, uni b, uni ans, uni result) { //チェック

	if (isNaN(ans) && isNaN(result)) {
		return 1;
	}

	if (isInf(ans) && isInf(result)) {
		if (ans.Float.sign != result.Float.sign) {
			return 0;
		}
		return 1;
	}

	if (isDenormal(ans) && isZero(result)) {
		if (ans.Float.sign != result.Float.sign) {
			return 0;
		}
		return 1;
	}

	if (isDenormal(a) || isDenormal(b)) {
		//非正規化数は0として扱うので、それによる積も0
		if (ans.Float.sign == result.Float.sign && isZero(result)) {
			return 1;
		}
		return 0;
	}


	int flg = 1;

	if (ans.Float.sign != result.Float.sign) {
		flg = 0;
	}

	if (ans.Float.exp != result.Float.exp) {
		flg = 0;
	}

	if (abs(ans.Float.frac - result.Float.frac) > 1) {
		//仮数部の1bitの誤差のみ許容
		flg = 0;
	}

	if (flg==0){
		printf("c");
	}
	return flg;
}


int main () {

  uni a, b, result, ans;
	int r, w;
	r=w=0;

  while(scanf("%x %x", &a.u, &b.u) == 2) {

    result.u = fmul(a.u, b.u);

		ans.f = a.f * b.f;


		if (!ok(a, b, ans,result)) {

			puts("--a / b--");
			print_bits(a);
			print_bits(b);
			puts("--Ans / Result--");
			print_bits(ans);
			print_bits(result);

			w++;

		} else {
			r++;
		}

  }
	printf("O: %d / X: %d\n", r, w);
  return 0;

}
