#include <stdio.h>
#include <stdint.h>
#include "fpu.h"

uint32_t itof (uint32_t a) {
	uni low, high;
	low.u  = a&0x7fffff; //下位23bit
	high.u = a>>23;      //上位9bit

	//0x4b000000をfloatとしてみると2^23
	low.u += 0x4b000000;
	low.u = fadd(low.u, 0xcb000000);

	//0x56800000をfloatとしてみると2^46
	high.u += 0x56800000;
	high.u = fadd(high.u, 0xd6800000);
	return fadd(low.u, high.u);
}
int itofCheck (uni a) {
	uni ans,result;
	ans.f = (float) a.u;
	result.u = itof(a.u);
	return (ans.u == result.u) ? 1 : 0;
}
