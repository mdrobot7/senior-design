#ifndef _UGPU_MATH_H
#define _UGPU_MATH_H

#include <stdint.h>

#define UGPU_DECIMAL_POS (16)

#define UGPU_FIXED(n)          ((int32_t) (n << UGPU_DECIMAL_POS))
#define UGPU_FLOAT_TO_FIXED(n) ((int32_t) ((float) (n) * (1 << UGPU_DECIMAL_POS)))
#define UGPU_FIXED_TO_FLOAT(n) ((float) (n) / (1 << UGPU_DECIMAL_POS))

#define UGPU_FIXED_MUL(a, b) ((((uint64_t) a) * (uint64_t(b))) >> (UGPU_DECIMAL_POS * 2))

#endif
