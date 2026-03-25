#include "matrix.h"

#include "trig.h"

#include <math.h>
#include <string.h>

#define PI_180_FIXED UGPU_FLOAT_TO_FIXED(3.14159265f / 180.0f)

void mat4_identity(mat4_t m) {
  memset(m, 0, 4 * 4 * sizeof(ugpu_fp_t));
  m[0][0] = UGPU_FIXED(1);
  m[1][1] = UGPU_FIXED(1);
  m[2][2] = UGPU_FIXED(1);
  m[3][3] = UGPU_FIXED(1);
}

void mat4_trans(mat4_t m, ugpu_fp_t x, ugpu_fp_t y, ugpu_fp_t z) {
  memset(m, 0, 4 * 4 * sizeof(ugpu_fp_t));
  m[0][3] = x;
  m[1][3] = y;
  m[2][3] = z;
  m[3][3] = UGPU_FIXED(1);
}

void mat4_scale(mat4_t m, ugpu_fp_t sx, ugpu_fp_t sy, ugpu_fp_t sz) {
  memset(m, 0, 4 * 4 * sizeof(ugpu_fp_t));
  m[0][0] = sx;
  m[1][1] = sy;
  m[2][2] = sz;
  m[3][3] = UGPU_FIXED(1);
}

void mat4_rotate(mat4_t m, ugpu_fp_t rad_x, ugpu_fp_t rad_y, ugpu_fp_t rad_z) {
  // Taken from here https://sites.google.com/site/glennmurray/glenn-murray-ph-d/rotation-matrices-and-formulas/rotation-about-an-arbitrary-axis-in-3-dimensions#h.ody1q8jzvr8u
  // TODO: Rotation around an arbitrary axis (quaternions)?
  memset(m, 0, 4 * 4 * sizeof(ugpu_fp_t));

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

  m[3][3] = UGPU_FIXED(1);
}

void mat4_rotated(mat4_t m, ugpu_fp_t deg_x, ugpu_fp_t deg_y, ugpu_fp_t deg_z) {
  // Should be enough precision.... hopefully
  mat4_rotate(m, UGPU_FIXED_MUL(deg_x, PI_180_FIXED), UGPU_FIXED_MUL(deg_y, PI_180_FIXED), UGPU_FIXED_MUL(deg_z, PI_180_FIXED));
}

void mat4_mul(mat4_t a, mat4_t b) {
  mat4_t dest;
  mat4_muld(dest, a, b);
  memcpy(a, dest, 4 * 4 * sizeof(ugpu_fp_t));
}

void mat4_muld(mat4_t dest, mat4_t a, mat4_t b) {
  for (int i = 0; i < 4; i++) {
    for (int j = 0; j < 4; j++) {
      dest[i][j] = 0;
      for (int k = 0; k < 4; k++) {
        dest[i][j] += UGPU_FIXED_MUL(a[i][k], b[k][j]);
      }
    }
  }
}
