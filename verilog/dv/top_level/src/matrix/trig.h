#ifndef _TRIG_H
#define _TRIG_H

#include "ugpu.h"

// Return the value of sin(x), cos(x), and tan(x). Uses a lookup table
// and rounds down if needed (no interpolation between LUT entries).
// x must be in the range [0, 2pi).
ugpu_fp_t sin_fp(ugpu_fp_t x);
ugpu_fp_t cos_fp(ugpu_fp_t x);
ugpu_fp_t tan_fp(ugpu_fp_t x);

#endif
