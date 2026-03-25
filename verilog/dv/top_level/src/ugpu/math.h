#ifndef _UGPU_MATH_H
#define _UGPU_MATH_H

#include <stdint.h>

// Fixed point type
typedef int32_t ugpu_fp_t;

#define UGPU_DECIMAL_POS (16)

#define UGPU_FIXED(n)          ((ugpu_fp_t) (n << UGPU_DECIMAL_POS))
#define UGPU_FLOAT_TO_FIXED(n) ((ugpu_fp_t) ((float) (n) * (1 << UGPU_DECIMAL_POS)))
#define UGPU_FIXED_TO_FLOAT(n) ((float) (n) / (1 << UGPU_DECIMAL_POS))

#define UGPU_FIXED_MUL(a, b) ((ugpu_fp_t) ((((int64_t) a) * ((int64_t) b)) >> (UGPU_DECIMAL_POS * 2)))

#endif
