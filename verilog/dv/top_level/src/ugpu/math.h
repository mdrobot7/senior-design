#ifndef _UGPU_MATH_H
#define _UGPU_MATH_H

#include <stdint.h>

// Fixed point type
typedef int32_t ugpu_fp_t;

#define UGPU_DECIMAL_POS (16)

#define UGPU_PI   (0x3243FUL)
#define UGPU_PI_2 (0x1921FUL)
#define UGPU_PI_4 (0xC90FUL)
#define UGPU_2_PI (0x6487FUL)

#define UGPU_PI_180 (0x478UL)

#define UGPU_ABS(n) ((n) > 0 ? (n) : (-n))

#define UGPU_FIXED(n)          ((ugpu_fp_t) (n << UGPU_DECIMAL_POS))
#define UGPU_FLOAT_TO_FIXED(n) ((ugpu_fp_t) ((float) (n) * (1 << UGPU_DECIMAL_POS)))
#define UGPU_FIXED_TO_FLOAT(n) ((float) (n) / (1 << UGPU_DECIMAL_POS))

#define _UGPU_FIXED_MUL(a, b) ((ugpu_fp_t) (((int64_t) (a) * (int64_t) (b)) >> UGPU_DECIMAL_POS))
#define UGPU_FIXED_DIV(a, b)  ((ugpu_fp_t) (((((int64_t) (a)) << UGPU_DECIMAL_POS) / (int64_t) (b))))

static inline ugpu_fp_t UGPU_FIXED_MUL(ugpu_fp_t a, ugpu_fp_t b) {
  MULTINATOR->a = a;
  MULTINATOR->b = b;

  return MULTINATOR->y;
}

#endif
