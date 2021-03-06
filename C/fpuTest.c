#include <stdio.h>
#include <string.h>
#include <math.h>
#include "fpu.h"

int main (int argc, char* argv[]) {

  if (argc < 2) {
    puts("16進数でテストケースを与えると、結果を標準出力に、間違えたケースを標準エラー出力に出力します");
    puts("使用例: ./fpuTest fadd");
    return 0;
  }

  if (strcmp(argv[1], "fadd") == 0) {

    uni a, b;
    while(scanf("%x %x", &a.u, &b.u) == 2) {

      printf("%08x\n", fadd(a.u, b.u));

      if (faddCheck(a, b) == 0) {
        uni ans;
        ans.f = a.f + b.f;
        fprintf(stderr, "WrongAnswer: %08x %08x Result=%08x Answer=%08x\n",
                a.u, b.u, fadd(a.u, b.u), ans.u);

      }

    }

  } else if (strcmp(argv[1], "fmul") == 0){

    uni a, b;
    while(scanf("%x %x", &a.u, &b.u) == 2) {

      printf("%08x\n", fmul(a.u, b.u));

      fmulCheck(a, b);

    }


  } else if (strcmp(argv[1], "fdiv") == 0){

    uni a, b;
    while(scanf("%x %x", &a.u, &b.u) == 2) {

      printf("%08x\n", fdiv(a.u, b.u));
      fdivCheck(a, b);
    }


  } else if (strcmp(argv[1], "finv") == 0) {

    uni a;
    while(scanf("%x", &a.u) == 1) {
      printf("%08x\n", finv(a.u));
      finvCheck(a);
    }

  } else if (strcmp(argv[1], "fsqrt") == 0) {
    uni a;
    while(scanf("%x", &a.u) == 1) {
      printf("%08x\n", fsqrt(a.u));
      fsqrtCheck(a);
    }

  } else if (strcmp(argv[1], "itof") == 0) {
    uni a;
    int n;
    while(scanf("%x", &n) == 1) { // signedを受け取る
      a.u = n;
      printf("%08x\n", itof(a.u));
      itofCheck(a);
    }
  } else if (strcmp(argv[1], "ftoi") == 0) {
    uni a;
    while(scanf("%x", &a.u) == 1) {
      printf("%08x\n", ftoi(a.u));
      ftoiCheck(a);
    }

  } else if (strcmp(argv[1], "ffloor") == 0) {
    uni a;
    while(scanf("%x", &a.u) == 1) {
      printf("%08x\n", ffloor(a.u));
      ffloorCheck(a);
    }

  } else if (strcmp(argv[1], "feq") == 0) {
    uni a, b;

    while(scanf("%x %x", &a.u, &b.u) == 2) {
      printf("%08x\n", feq(a.u, b.u));
      feqCheck(a, b);
    }

  } else if (strcmp(argv[1], "flt") == 0) {
    uni a, b;

    while(scanf("%x %x", &a.u, &b.u) == 2) {
      printf("%08x\n", flt(a.u, b.u));
      fltCheck(a, b);
    }

  } else if (strcmp(argv[1], "fle") == 0) {
    uni a, b;

    while(scanf("%x %x", &a.u, &b.u) == 2) {
      printf("%08x\n", fle(a.u, b.u));
      fleCheck(a, b);
    }

  } else if (strcmp(argv[1], "conv") == 0) {
    uni a;
    while(scanf("%x", &a.u) == 1) {
      print_bits(a);
      printf("float:%.10f int:%u\n", a.f, a.u);
    }

  }else if (strcmp(argv[1], "float") == 0) {
    uni a;
    while(scanf("%f", &a.f) == 1) {
      print_bits(a);
      printf("float:%.10f int:%u hex:%08x\n", a.f, a.u, a.u);
    }

  } else if (strcmp(argv[1], "-all") == 0 && argc == 3) {
    uni a;
    uint32_t i = 0;
    int flg = 0;
    if (strcmp(argv[2], "ftoi") == 0) {
      flg = 1;
    } else if (strcmp(argv[2], "itof") == 0) {
      flg = 2;
    } else if (strcmp(argv[2], "finv") == 0) {
      flg = 3;
    } else if (strcmp(argv[2], "fsqrt") == 0) {
      flg = 4;
    }
    if (flg == 0) {
      fprintf(stderr, "Error");
      return 0;
    }
    do {
      if (i % (1 << 24) == 0) {
        printf("%lf%%\n", (double)i*100/pow(2, 32));
      }
      a.u = i;
      switch (flg) {
      case 1:
        ftoiCheck(a);
        break;
      case 2:
        itofCheck(a);
        break;
      case 3:
        finvCheck(a);
        break;
      case 4:
        fsqrtCheck(a);
        break;
      default:
        break;
      }
      i++;
    } while(i != 0);

  } else {

    fprintf(stderr, "target error: %s", argv[1]);

  }
  return 0;
}
