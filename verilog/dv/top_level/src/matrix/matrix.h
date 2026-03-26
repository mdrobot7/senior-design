#ifndef _MATRIX_H
#define _MATRIX_H

#include "ugpu.h"

#include <stdint.h>

#define MAT4_SIZE (4 * 4 * sizeof(ugpu_fp_t))

// 4x4 fixed point matrix. Indices are mat4_t[ROW][COL]
typedef ugpu_fp_t mat4_t[4][4];

// Matrix constructors: overwrites the matrix m with a identity, translation, rotation... matrix
void mat4_identity(mat4_t m);
void mat4_trans(mat4_t m, ugpu_fp_t x, ugpu_fp_t y, ugpu_fp_t z);
void mat4_scale(mat4_t m, ugpu_fp_t sx, ugpu_fp_t sy, ugpu_fp_t sz);
void mat4_rotate(mat4_t m, ugpu_fp_t rad_x, ugpu_fp_t rad_y, ugpu_fp_t rad_z); // Applies x, then y, then z
void mat4_rotated(mat4_t m, ugpu_fp_t deg_x, ugpu_fp_t deg_y, ugpu_fp_t deg_z);

// MVP matrix constructors
void mat4_view(mat4_t m, ugpu_fp_t cam_x, ugpu_fp_t cam_y, ugpu_fp_t cam_z, ugpu_fp_t cam_rad_x, ugpu_fp_t cam_rad_y, ugpu_fp_t cam_rad_z); // Creates a view matrix using a camera position and rotation
void mat4_perspective(mat4_t m, ugpu_fp_t fov_radians, ugpu_fp_t z_near, ugpu_fp_t z_far);
void mat4_screen(mat4_t m, uint32_t screen_width, uint32_t screen_height);

// Matrix multiplication
void mat4_mul(mat4_t a, mat4_t b);
void mat4_muld(mat4_t dest, mat4_t a, mat4_t b);

// Misc matrix operations
void mat4_inv(mat4_t dest, mat4_t m);

#endif
