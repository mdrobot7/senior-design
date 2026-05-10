#ifndef _MATRIX_H
#define _MATRIX_H

#include "trig.h"
#include "ugpu.h"
#include "vec3.h"

#include <math.h>
#include <stdint.h>
#include <string.h>

#define MAT4_SIZE (4 * 4 * sizeof(ugpu_fp_t))

// 4x4 fixed point matrix. Indices are mat4_t[ROW][COL]
typedef ugpu_fp_t mat4_t[4][4];

// Matrix constructors: overwrites the matrix m with a identity, translation, rotation... matrix
static inline void mat4_identity(mat4_t m);
static inline void mat4_trans(mat4_t m, ugpu_fp_t x, ugpu_fp_t y, ugpu_fp_t z);
static inline void mat4_scale(mat4_t m, ugpu_fp_t sx, ugpu_fp_t sy, ugpu_fp_t sz);
static inline void mat4_rotate(mat4_t m, ugpu_fp_t rad_x, ugpu_fp_t rad_y, ugpu_fp_t rad_z); // Applies x, then y, then z
static inline void mat4_rotated(mat4_t m, ugpu_fp_t deg_x, ugpu_fp_t deg_y, ugpu_fp_t deg_z);

// MVP matrix constructors
static inline void mat4_view(mat4_t m, vec3_t cam_pos, ugpu_fp_t cam_pitch, ugpu_fp_t cam_yaw); // Pitch must be [-pi/2, pi/2], yaw must be [0, 2pi]
static inline void mat4_look_at(mat4_t m, vec3_t eye, vec3_t center, vec3_t up);
static inline void mat4_perspective(mat4_t m, ugpu_fp_t aspect_ratio, ugpu_fp_t fov_radians, ugpu_fp_t z_near, ugpu_fp_t z_far);
static inline void mat4_screen(mat4_t m, uint32_t screen_width, uint32_t screen_height);

// Matrix multiplication
static inline void mat4_mul(mat4_t a, mat4_t b); // a = a * b
static inline void mat4_muld(mat4_t dest, mat4_t a, mat4_t b);

// Misc matrix operations
static inline void mat4_copy(mat4_t dest, mat4_t src);
static inline void mat4_inv(mat4_t dest, mat4_t m);

static inline void mat4_copy(mat4_t dest, mat4_t src) {
  memcpy(dest, src, MAT4_SIZE);
}

static inline void mat4_identity(mat4_t m) {
  memset(m, 0, MAT4_SIZE);
  m[0][0] = UGPU_FIXED(1);
  m[1][1] = UGPU_FIXED(1);
  m[2][2] = UGPU_FIXED(1);
  m[3][3] = UGPU_FIXED(1);
}

static inline void mat4_trans(mat4_t m, ugpu_fp_t x, ugpu_fp_t y, ugpu_fp_t z) {
  mat4_identity(m);
  m[0][3] = x;
  m[1][3] = y;
  m[2][3] = z;
}

static inline void mat4_scale(mat4_t m, ugpu_fp_t sx, ugpu_fp_t sy, ugpu_fp_t sz) {
  memset(m, 0, MAT4_SIZE);
  m[0][0] = sx;
  m[1][1] = sy;
  m[2][2] = sz;
  m[3][3] = UGPU_FIXED(1);
}

static inline void mat4_rotate(mat4_t m, ugpu_fp_t rad_x, ugpu_fp_t rad_y, ugpu_fp_t rad_z) {
  // Taken from here https://sites.google.com/site/glennmurray/glenn-murray-ph-d/rotation-matrices-and-formulas/rotation-about-an-arbitrary-axis-in-3-dimensions#h.ody1q8jzvr8u
  // TODO: Rotation around an arbitrary axis (quaternions)?
  memset(m, 0, MAT4_SIZE);

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
  m[1][1] = UGPU_FIXED_MUL(UGPU_FIXED_MUL(sin_x, sin_y), sin_z) + UGPU_FIXED_MUL(cos_x, cos_z);
  m[1][2] = UGPU_FIXED_MUL(UGPU_FIXED_MUL(cos_x, sin_y), sin_z) - UGPU_FIXED_MUL(sin_x, cos_z);

  m[2][0] = -sin_y;
  m[2][1] = UGPU_FIXED_MUL(sin_x, cos_y);
  m[2][2] = UGPU_FIXED_MUL(cos_x, cos_y);

  m[3][3] = UGPU_FIXED(1);
}

static inline void mat4_rotated(mat4_t m, ugpu_fp_t deg_x, ugpu_fp_t deg_y, ugpu_fp_t deg_z) {
  // Should be enough precision.... hopefully
  mat4_rotate(m, UGPU_FIXED_MUL(deg_x, UGPU_PI_180), UGPU_FIXED_MUL(deg_y, UGPU_PI_180), UGPU_FIXED_MUL(deg_z, UGPU_PI_180));
}

static inline void mat4_view(mat4_t m, vec3_t cam_pos, ugpu_fp_t cam_pitch, ugpu_fp_t cam_yaw) {
  // Credit to LearnOpenGL: https://learnopengl.com/code_viewer_gh.php?code=src/1.getting_started/7.3.camera_mouse_zoom/camera_mouse_zoom.cpp
  // https://learnopengl.com/Getting-started/Camera
  // MD: Extracted the important bits and modified to our system
  static const vec3_t up = { 0, UGPU_FIXED(1), 0 };

  ugpu_fp_t cos_pitch = cos_fp(cam_pitch);
  ugpu_fp_t sin_pitch = sin_fp(cam_pitch);
  ugpu_fp_t cos_yaw   = cos_fp(cam_yaw);
  ugpu_fp_t sin_yaw   = sin_fp(cam_yaw);

  vec3_t front, front_norm;
  front[0] = UGPU_FIXED_MUL(cos_yaw, cos_pitch);
  front[1] = sin_pitch;
  front[2] = UGPU_FIXED_MUL(sin_yaw, cos_pitch);
  vec3_norm(front_norm, front);

  vec3_t center;
  vec3_add(center, cam_pos, front_norm);

  mat4_look_at(m, cam_pos, center, up);
}

static inline void mat4_look_at(mat4_t m, vec3_t eye, vec3_t center, vec3_t up) {
  // Credit to OpenGL/GLM: https://github.com/g-truc/glm/blob/master/glm/ext/matrix_transform.inl#L153
  // MD: Modified to be row-major and use our matrix utils.
  vec3_t center_eye, front;
  vec3_sub(center_eye, center, eye);
  vec3_norm(front, center_eye);

  vec3_t f_cross_up, right;
  vec3_cross(f_cross_up, front, up);
  vec3_norm(right, f_cross_up);

  vec3_t real_up; // Recalculate to make sure right/front/up are orthogonal
  vec3_cross(real_up, right, front);

  m[0][0] = right[0];
  m[0][1] = right[1];
  m[0][2] = right[2];
  m[0][3] = 0;
  m[1][0] = real_up[0];
  m[1][1] = real_up[1];
  m[1][2] = real_up[2];
  m[1][3] = 0;
  m[2][0] = -front[0];
  m[2][1] = -front[1];
  m[2][2] = -front[2];
  m[2][3] = 0;
  m[3][0] = -vec3_dot(right, eye);
  m[3][1] = -vec3_dot(real_up, eye);
  m[3][2] = vec3_dot(front, eye);
  m[3][3] = UGPU_FIXED(1);
}

static inline void mat4_perspective(mat4_t m, ugpu_fp_t aspect_ratio, ugpu_fp_t fov_radians, ugpu_fp_t z_near, ugpu_fp_t z_far) {
  // ugpu_fp_t s = tan_fp(fov_radians >> 1);
  ugpu_fp_t s = UGPU_FIXED(1);

  memset(m, 0, MAT4_SIZE);
  m[0][0] = UGPU_FIXED_DIV(UGPU_FIXED(1), _UGPU_FIXED_MUL(s, aspect_ratio));
  m[1][1] = UGPU_FIXED_DIV(UGPU_FIXED(1), s);
  m[2][2] = -UGPU_FIXED_DIV(z_far + z_near, z_far - z_near);
  m[2][3] = -UGPU_FIXED_DIV(2 * _UGPU_FIXED_MUL(z_far, z_near), z_far - z_near);
  m[3][2] = -UGPU_FIXED(1);
}

static inline void mat4_screen(mat4_t m, uint32_t screen_width, uint32_t screen_height) {
  uint32_t half_width         = screen_width >> 1;
  uint32_t half_height        = screen_height >> 1;
  ugpu_fp_t half_width_fixed  = UGPU_FIXED(half_width);
  ugpu_fp_t half_height_fixed = UGPU_FIXED(half_height);

  mat4_identity(m);
  m[0][0] = half_width_fixed;
  m[0][3] = half_width_fixed;
  m[1][1] = -half_height_fixed;
  m[1][3] = half_height_fixed;
}

static inline void mat4_mul(mat4_t a, mat4_t b) {
  mat4_t dest;
  mat4_muld(dest, a, b);
  memcpy(a, dest, MAT4_SIZE);
}

static inline void mat4_muld(mat4_t dest, mat4_t a, mat4_t b) {
  for (int i = 0; i < 4; i++) {
    for (int j = 0; j < 4; j++) {
      dest[i][j] = 0;
      for (int k = 0; k < 4; k++) {
        dest[i][j] += UGPU_FIXED_MUL(a[i][k], b[k][j]);
      }
    }
  }
}

static inline void mat4_inv(mat4_t dest, mat4_t m) {
  // Source - https://stackoverflow.com/a/1148405
  // Posted by shoosh, modified by community. See post 'Timeline' for change history
  // Retrieved 2026-03-26, License - CC BY-SA 3.0
  // MD: convert to fixed point

  // fixed point: 48 integer, 16 fractional. please be big enough for these calcs
  int64_t inv[4][4];
  int64_t det;

  // clang-format off
  // This mess is done without macros because it's the only spot that uses int64s.
  // Good luck, management core.
  inv[0][0] = (((int64_t)m[1][1] * m[2][2] * m[3][3]) >> (2*UGPU_DECIMAL_POS)) -
              (((int64_t)m[1][1] * m[2][3] * m[3][2]) >> (2*UGPU_DECIMAL_POS)) -
              (((int64_t)m[2][1] * m[1][2] * m[3][3]) >> (2*UGPU_DECIMAL_POS)) +
              (((int64_t)m[2][1] * m[1][3] * m[3][2]) >> (2*UGPU_DECIMAL_POS)) +
              (((int64_t)m[3][1] * m[1][2] * m[2][3]) >> (2*UGPU_DECIMAL_POS)) -
              (((int64_t)m[3][1] * m[1][3] * m[2][2]) >> (2*UGPU_DECIMAL_POS));

  inv[1][0] = -(((int64_t)m[1][0] * m[2][2] * m[3][3]) >> (2*UGPU_DECIMAL_POS)) +
               (((int64_t)m[1][0] * m[2][3] * m[3][2]) >> (2*UGPU_DECIMAL_POS)) +
               (((int64_t)m[2][0] * m[1][2] * m[3][3]) >> (2*UGPU_DECIMAL_POS)) -
               (((int64_t)m[2][0] * m[1][3] * m[3][2]) >> (2*UGPU_DECIMAL_POS)) -
               (((int64_t)m[3][0] * m[1][2] * m[2][3]) >> (2*UGPU_DECIMAL_POS)) +
               (((int64_t)m[3][0] * m[1][3] * m[2][2]) >> (2*UGPU_DECIMAL_POS));

  inv[2][0] = (((int64_t)m[1][0] * m[2][1] * m[3][3]) >> (2*UGPU_DECIMAL_POS)) -
              (((int64_t)m[1][0] * m[2][3] * m[3][1]) >> (2*UGPU_DECIMAL_POS)) -
              (((int64_t)m[2][0] * m[1][1] * m[3][3]) >> (2*UGPU_DECIMAL_POS)) +
              (((int64_t)m[2][0] * m[1][3] * m[3][1]) >> (2*UGPU_DECIMAL_POS)) +
              (((int64_t)m[3][0] * m[1][1] * m[2][3]) >> (2*UGPU_DECIMAL_POS)) -
              (((int64_t)m[3][0] * m[1][3] * m[2][1]) >> (2*UGPU_DECIMAL_POS));

  inv[3][0] = -(((int64_t)m[1][0] * m[2][1] * m[3][2]) >> (2*UGPU_DECIMAL_POS)) +
               (((int64_t)m[1][0] * m[2][2] * m[3][1]) >> (2*UGPU_DECIMAL_POS)) +
               (((int64_t)m[2][0] * m[1][1] * m[3][2]) >> (2*UGPU_DECIMAL_POS)) -
               (((int64_t)m[2][0] * m[1][2] * m[3][1]) >> (2*UGPU_DECIMAL_POS)) -
               (((int64_t)m[3][0] * m[1][1] * m[2][2]) >> (2*UGPU_DECIMAL_POS)) +
               (((int64_t)m[3][0] * m[1][2] * m[2][1]) >> (2*UGPU_DECIMAL_POS));

  inv[0][1] = -(((int64_t)m[0][1] * m[2][2] * m[3][3]) >> (2*UGPU_DECIMAL_POS)) +
               (((int64_t)m[0][1] * m[2][3] * m[3][2]) >> (2*UGPU_DECIMAL_POS)) +
               (((int64_t)m[2][1] * m[0][2] * m[3][3]) >> (2*UGPU_DECIMAL_POS)) -
               (((int64_t)m[2][1] * m[0][3] * m[3][2]) >> (2*UGPU_DECIMAL_POS)) -
               (((int64_t)m[3][1] * m[0][2] * m[2][3]) >> (2*UGPU_DECIMAL_POS)) +
               (((int64_t)m[3][1] * m[0][3] * m[2][2]) >> (2*UGPU_DECIMAL_POS));

  inv[1][1] = (((int64_t)m[0][0] * m[2][2] * m[3][3]) >> (2*UGPU_DECIMAL_POS)) -
              (((int64_t)m[0][0] * m[2][3] * m[3][2]) >> (2*UGPU_DECIMAL_POS)) -
              (((int64_t)m[2][0] * m[0][2] * m[3][3]) >> (2*UGPU_DECIMAL_POS)) +
              (((int64_t)m[2][0] * m[0][3] * m[3][2]) >> (2*UGPU_DECIMAL_POS)) +
              (((int64_t)m[3][0] * m[0][2] * m[2][3]) >> (2*UGPU_DECIMAL_POS)) -
              (((int64_t)m[3][0] * m[0][3] * m[2][2]) >> (2*UGPU_DECIMAL_POS));

  inv[2][1] = -(((int64_t)m[0][0] * m[2][1] * m[3][3]) >> (2*UGPU_DECIMAL_POS)) +
               (((int64_t)m[0][0] * m[2][3] * m[3][1]) >> (2*UGPU_DECIMAL_POS)) +
               (((int64_t)m[2][0] * m[0][1] * m[3][3]) >> (2*UGPU_DECIMAL_POS)) -
               (((int64_t)m[2][0] * m[0][3] * m[3][1]) >> (2*UGPU_DECIMAL_POS)) -
               (((int64_t)m[3][0] * m[0][1] * m[2][3]) >> (2*UGPU_DECIMAL_POS)) +
               (((int64_t)m[3][0] * m[0][3] * m[2][1]) >> (2*UGPU_DECIMAL_POS));

  inv[3][1] = (((int64_t)m[0][0] * m[2][1] * m[3][2]) >> (2*UGPU_DECIMAL_POS)) -
              (((int64_t)m[0][0] * m[2][2] * m[3][1]) >> (2*UGPU_DECIMAL_POS)) -
              (((int64_t)m[2][0] * m[0][1] * m[3][2]) >> (2*UGPU_DECIMAL_POS)) +
              (((int64_t)m[2][0] * m[0][2] * m[3][1]) >> (2*UGPU_DECIMAL_POS)) +
              (((int64_t)m[3][0] * m[0][1] * m[2][2]) >> (2*UGPU_DECIMAL_POS)) -
              (((int64_t)m[3][0] * m[0][2] * m[2][1]) >> (2*UGPU_DECIMAL_POS));

  inv[0][2] = (((int64_t)m[0][1] * m[1][2] * m[3][3]) >> (2*UGPU_DECIMAL_POS)) -
              (((int64_t)m[0][1] * m[1][3] * m[3][2]) >> (2*UGPU_DECIMAL_POS)) -
              (((int64_t)m[1][1] * m[0][2] * m[3][3]) >> (2*UGPU_DECIMAL_POS)) +
              (((int64_t)m[1][1] * m[0][3] * m[3][2]) >> (2*UGPU_DECIMAL_POS)) +
              (((int64_t)m[3][1] * m[0][2] * m[1][3]) >> (2*UGPU_DECIMAL_POS)) -
              (((int64_t)m[3][1] * m[0][3] * m[1][2]) >> (2*UGPU_DECIMAL_POS));

  inv[1][2] = -(((int64_t)m[0][0] * m[1][2] * m[3][3]) >> (2*UGPU_DECIMAL_POS)) +
               (((int64_t)m[0][0] * m[1][3] * m[3][2]) >> (2*UGPU_DECIMAL_POS)) +
               (((int64_t)m[1][0] * m[0][2] * m[3][3]) >> (2*UGPU_DECIMAL_POS)) -
               (((int64_t)m[1][0] * m[0][3] * m[3][2]) >> (2*UGPU_DECIMAL_POS)) -
               (((int64_t)m[3][0] * m[0][2] * m[1][3]) >> (2*UGPU_DECIMAL_POS)) +
               (((int64_t)m[3][0] * m[0][3] * m[1][2]) >> (2*UGPU_DECIMAL_POS));

  inv[2][2] = (((int64_t)m[0][0] * m[1][1] * m[3][3]) >> (2*UGPU_DECIMAL_POS)) -
              (((int64_t)m[0][0] * m[1][3] * m[3][1]) >> (2*UGPU_DECIMAL_POS)) -
              (((int64_t)m[1][0] * m[0][1] * m[3][3]) >> (2*UGPU_DECIMAL_POS)) +
              (((int64_t)m[1][0] * m[0][3] * m[3][1]) >> (2*UGPU_DECIMAL_POS)) +
              (((int64_t)m[3][0] * m[0][1] * m[1][3]) >> (2*UGPU_DECIMAL_POS)) -
              (((int64_t)m[3][0] * m[0][3] * m[1][1]) >> (2*UGPU_DECIMAL_POS));

  inv[3][2] = -(((int64_t)m[0][0] * m[1][1] * m[3][2]) >> (2*UGPU_DECIMAL_POS)) +
               (((int64_t)m[0][0] * m[1][2] * m[3][1]) >> (2*UGPU_DECIMAL_POS)) +
               (((int64_t)m[1][0] * m[0][1] * m[3][2]) >> (2*UGPU_DECIMAL_POS)) -
               (((int64_t)m[1][0] * m[0][2] * m[3][1]) >> (2*UGPU_DECIMAL_POS)) -
               (((int64_t)m[3][0] * m[0][1] * m[1][2]) >> (2*UGPU_DECIMAL_POS)) +
               (((int64_t)m[3][0] * m[0][2] * m[1][1]) >> (2*UGPU_DECIMAL_POS));

  inv[0][3] = -(((int64_t)m[0][1] * m[1][2] * m[2][3]) >> (2*UGPU_DECIMAL_POS)) +
               (((int64_t)m[0][1] * m[1][3] * m[2][2]) >> (2*UGPU_DECIMAL_POS)) +
               (((int64_t)m[1][1] * m[0][2] * m[2][3]) >> (2*UGPU_DECIMAL_POS)) -
               (((int64_t)m[1][1] * m[0][3] * m[2][2]) >> (2*UGPU_DECIMAL_POS)) -
               (((int64_t)m[2][1] * m[0][2] * m[1][3]) >> (2*UGPU_DECIMAL_POS)) +
               (((int64_t)m[2][1] * m[0][3] * m[1][2]) >> (2*UGPU_DECIMAL_POS));

  inv[1][3] = (((int64_t)m[0][0] * m[1][2] * m[2][3]) >> (2*UGPU_DECIMAL_POS)) -
              (((int64_t)m[0][0] * m[1][3] * m[2][2]) >> (2*UGPU_DECIMAL_POS)) -
              (((int64_t)m[1][0] * m[0][2] * m[2][3]) >> (2*UGPU_DECIMAL_POS)) +
              (((int64_t)m[1][0] * m[0][3] * m[2][2]) >> (2*UGPU_DECIMAL_POS)) +
              (((int64_t)m[2][0] * m[0][2] * m[1][3]) >> (2*UGPU_DECIMAL_POS)) -
              (((int64_t)m[2][0] * m[0][3] * m[1][2]) >> (2*UGPU_DECIMAL_POS));

  inv[2][3] = -(((int64_t)m[0][0] * m[1][1] * m[2][3]) >> (2*UGPU_DECIMAL_POS)) +
               (((int64_t)m[0][0] * m[1][3] * m[2][1]) >> (2*UGPU_DECIMAL_POS)) +
               (((int64_t)m[1][0] * m[0][1] * m[2][3]) >> (2*UGPU_DECIMAL_POS)) -
               (((int64_t)m[1][0] * m[0][3] * m[2][1]) >> (2*UGPU_DECIMAL_POS)) -
               (((int64_t)m[2][0] * m[0][1] * m[1][3]) >> (2*UGPU_DECIMAL_POS)) +
               (((int64_t)m[2][0] * m[0][3] * m[1][1]) >> (2*UGPU_DECIMAL_POS));

  inv[3][3] = (((int64_t)m[0][0] * m[1][1] * m[2][2]) >> (2*UGPU_DECIMAL_POS)) -
              (((int64_t)m[0][0] * m[1][2] * m[2][1]) >> (2*UGPU_DECIMAL_POS)) -
              (((int64_t)m[1][0] * m[0][1] * m[2][2]) >> (2*UGPU_DECIMAL_POS)) +
              (((int64_t)m[1][0] * m[0][2] * m[2][1]) >> (2*UGPU_DECIMAL_POS)) +
              (((int64_t)m[2][0] * m[0][1] * m[1][2]) >> (2*UGPU_DECIMAL_POS)) -
              (((int64_t)m[2][0] * m[0][2] * m[1][1]) >> (2*UGPU_DECIMAL_POS));

  det = (((int64_t)m[0][0] * inv[0][0]) >> UGPU_DECIMAL_POS) +
        (((int64_t)m[0][1] * inv[1][0]) >> UGPU_DECIMAL_POS) +
        (((int64_t)m[0][2] * inv[2][0]) >> UGPU_DECIMAL_POS) +
        (((int64_t)m[0][3] * inv[3][0]) >> UGPU_DECIMAL_POS);
  // clang-format on

  for (int i = 0; i < 4; i++) {
    for (int j = 0; j < 4; j++) {
      dest[i][j] = (inv[i][j] << UGPU_DECIMAL_POS) / det;
    }
  }
}

#endif
