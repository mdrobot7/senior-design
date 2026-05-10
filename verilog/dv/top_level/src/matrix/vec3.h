#ifndef _VEC3_H
#define _VEC3_H

#include "ugpu.h"

#include <stdint.h>

#define VEC3_SIZE (3 * sizeof(ugpu_fp_t))

typedef ugpu_fp_t vec3_t[3];

// Basic vector operations
static inline void vec3_add(vec3_t dest, vec3_t a, vec3_t b);
static inline void vec3_sub(vec3_t dest, vec3_t a, vec3_t b);
static inline void vec3_scale(vec3_t dest, vec3_t a, ugpu_fp_t scale);
static inline void vec3_cross(vec3_t dest, vec3_t a, vec3_t b);
static inline ugpu_fp_t vec3_dot(vec3_t a, vec3_t b);
static inline void vec3_norm(vec3_t dest, vec3_t a);

static inline void vec3_add(vec3_t dest, vec3_t a, vec3_t b) {
  for (int i = 0; i < 3; i++) {
    dest[i] = a[i] + b[i];
  }
}

static inline void vec3_sub(vec3_t dest, vec3_t a, vec3_t b) {
  for (int i = 0; i < 3; i++) {
    dest[i] = a[i] - b[i];
  }
}

static inline void vec3_scale(vec3_t dest, vec3_t a, ugpu_fp_t scale) {
  for (int i = 0; i < 3; i++) {
    dest[i] = UGPU_FIXED_MUL(a[i], scale);
  }
}

static inline void vec3_cross(vec3_t dest, vec3_t a, vec3_t b) {
  dest[0] = UGPU_FIXED_MUL(a[1], b[2]) - UGPU_FIXED_MUL(a[2], b[1]);
  dest[1] = UGPU_FIXED_MUL(a[2], b[0]) - UGPU_FIXED_MUL(a[0], b[2]);
  dest[2] = UGPU_FIXED_MUL(a[0], b[1]) - UGPU_FIXED_MUL(a[2], b[0]);
}

static inline ugpu_fp_t vec3_dot(vec3_t a, vec3_t b) {
  ugpu_fp_t ret = 0;
  for (int i = 0; i < 3; i++) {
    ret += UGPU_FIXED_MUL(a[i], b[i]);
  }
}

#define INV_SQRT_LUT_LEN   (4097)
#define INV_SQRT_LUT_SHIFT (12)
extern const ugpu_fp_t inv_sqrt_lut[INV_SQRT_LUT_LEN];

// magnitude(a) must be <= 16, aka magnitude(a)^2 must be <= 256
static inline void vec3_norm(vec3_t dest, vec3_t a) {
  ugpu_fp_t mag_squared = 0;
  for (int i = 0; i < 3; i++) {
    mag_squared += UGPU_FIXED_MUL(a[0], a[0]);
  }
  if (mag_squared > UGPU_FIXED(256)) {
    vec3_scale(dest, a, inv_sqrt_lut[INV_SQRT_LUT_LEN - 1]);
  } else {
    ugpu_fp_t mag = inv_sqrt_lut[mag_squared >> INV_SQRT_LUT_SHIFT];
    vec3_scale(dest, a, mag);
  }
}

#endif
