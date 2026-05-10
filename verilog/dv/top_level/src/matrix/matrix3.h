#ifndef _MATRIX_H
#define _MATRIX_H

#include "trig.h"
#include "ugpu.h"

#include <math.h>
#include <stdint.h>
#include <string.h>

#define MAT3_SIZE (3 * 3 * sizeof(ugpu_fp_t))

// 3x3 fixed point matrix. Indices are mat3_t[ROW][COL]
typedef ugpu_fp_t mat3_t[3][3];

// Matrix constructors: overwrites the matrix m with a identity, translation, rotation... matrix
static inline void mat3_identity(mat3_t m);
static inline void mat3_trans(mat3_t m, ugpu_fp_t x, ugpu_fp_t y, ugpu_fp_t z);
static inline void mat3_scale(mat3_t m, ugpu_fp_t sx, ugpu_fp_t sy, ugpu_fp_t sz);
static inline void mat3_rotate(mat3_t m, ugpu_fp_t rad_x, ugpu_fp_t rad_y, ugpu_fp_t rad_z); // Applies x, then y, then z
static inline void mat3_rotated(mat3_t m, ugpu_fp_t deg_x, ugpu_fp_t deg_y, ugpu_fp_t deg_z);

// Matrix multiplication
static inline void mat3_mul(mat3_t a, mat3_t b); // a = a * b
static inline void mat3_muld(mat3_t dest, mat3_t a, mat3_t b);

// Misc matrix operations
static inline void mat3_copy(mat3_t dest, mat3_t src);
static inline void mat3_inv(mat3_t dest, mat3_t m);

static inline void mat3_copy(mat3_t dest, mat3_t src) {
  memcpy(dest, src, MAT3_SIZE);
}

static inline void mat3_identity(mat3_t m) {
  memset(m, 0, MAT3_SIZE);
  m[0][0] = UGPU_FIXED(1);
  m[1][1] = UGPU_FIXED(1);
  m[2][2] = UGPU_FIXED(1);
}

static inline void mat3_scale(mat3_t m, ugpu_fp_t sx, ugpu_fp_t sy, ugpu_fp_t sz) {
  memset(m, 0, MAT3_SIZE);
  m[0][0] = sx;
  m[1][1] = sy;
  m[2][2] = sz;
}

static inline void mat3_rotate(mat3_t m, ugpu_fp_t rad_x, ugpu_fp_t rad_y, ugpu_fp_t rad_z) {
  // Taken from here https://sites.google.com/site/glennmurray/glenn-murray-ph-d/rotation-matrices-and-formulas/rotation-about-an-arbitrary-axis-in-3-dimensions#h.ody1q8jzvr8u
  memset(m, 0, MAT3_SIZE);

  ugpu_fp_t sin_x = sin_fp(rad_x);
  ugpu_fp_t cos_x = cos_fp(rad_x);
  ugpu_fp_t sin_y = sin_fp(rad_y);
  ugpu_fp_t cos_y = cos_fp(rad_y);
  ugpu_fp_t sin_z = sin_fp(rad_z);
  ugpu_fp_t cos_z = cos_fp(rad_z);

  m[0][0] = UGPU_FIXED_MUL(cos_y, cos_z);
  m[0][1] = UGPU_FIXED_MUL(UGPU_FIXED_MUL(sin_x, sin_y), cos_z) - UGPU_FIXED_MUL(cos_x, sin_z);
  m[0][2] = UGPU_FIXED_MUL(UGPU_FIXED_MUL(cos_x, sin_y), cos_z) + UGPU_FIXED_MUL(sin_x, sin_z);

  m[1][0] = UGPU_FIXED_MUL(cos_y, sin_z);
  m[1][1] = UGPU_FIXED_MUL(UGPU_FIXED_MUL(sin_z, sin_y), sin_z) + UGPU_FIXED_MUL(cos_x, cos_z);
  m[1][2] = UGPU_FIXED_MUL(UGPU_FIXED_MUL(cos_x, sin_y), sin_z) - UGPU_FIXED_MUL(sin_x, cos_z);

  m[2][0] = -sin_y;
  m[2][1] = UGPU_FIXED_MUL(sin_x, cos_y);
  m[2][2] = UGPU_FIXED_MUL(cos_x, cos_y);
}

static inline void mat3_rotated(mat3_t m, ugpu_fp_t deg_x, ugpu_fp_t deg_y, ugpu_fp_t deg_z) {
  // Should be enough precision.... hopefully
  mat3_rotate(m, UGPU_FIXED_MUL(deg_x, UGPU_PI_180), UGPU_FIXED_MUL(deg_y, UGPU_PI_180), UGPU_FIXED_MUL(deg_z, UGPU_PI_180));
}

static inline void mat3_mul(mat3_t a, mat3_t b) {
  mat3_t dest;
  mat3_muld(dest, a, b);
  memcpy(a, dest, MAT3_SIZE);
}

static inline void mat3_muld(mat3_t dest, mat3_t a, mat3_t b) {
  for (int i = 0; i < 3; i++) {
    for (int j = 0; j < 3; j++) {
      dest[i][j] = 0;
      for (int k = 0; k < 3; k++) {
        dest[i][j] += UGPU_FIXED_MUL(a[i][k], b[k][j]);
      }
    }
  }
}

#endif
