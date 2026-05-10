#ifndef _TRIG_H
#define _TRIG_H

#include "ugpu.h"

// Return the value of sin(x), cos(x), and tan(x). Uses a lookup table
// and rounds down if needed (no interpolation between LUT entries).
// x must be in the range [0, 2pi).
static inline ugpu_fp_t sin_fp(ugpu_fp_t x);
static inline ugpu_fp_t cos_fp(ugpu_fp_t x);
static inline ugpu_fp_t tan_fp(ugpu_fp_t x);

#define TRIG_LUT_LEN (6434)
#define TRIG_LUT_SHIFT (6) // LUT is in 1/1024 steps, UGPU_FLOAT_TO_FIXED(1/1024) = 64, aka shift 6

extern const ugpu_fp_t sin_lut[TRIG_LUT_LEN];
extern const ugpu_fp_t cos_lut[TRIG_LUT_LEN];
extern const ugpu_fp_t tan_lut[TRIG_LUT_LEN];

static inline ugpu_fp_t sin_fp(ugpu_fp_t x) {
  if (x >= UGPU_2_PI || x < 0)
    return 0;
  return sin_lut[x >> TRIG_LUT_SHIFT];
}

static inline ugpu_fp_t cos_fp(ugpu_fp_t x) {
  if (x >= UGPU_2_PI || x < 0)
    return 1;
  return cos_lut[x >> TRIG_LUT_SHIFT];
}

static inline ugpu_fp_t tan_fp(ugpu_fp_t x) {
  if (x >= UGPU_2_PI || x < 0)
    return 0;
  return tan_lut[x >> TRIG_LUT_SHIFT];
}

#endif
