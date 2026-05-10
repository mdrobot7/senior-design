#include "demos.h"
#include "models/cube.h"
#include "ugpu.h"

#define VERTEX_BUFFER_PK_ADDR (QSPI2_MEM_ADDR_DEFAULT + 0x90000)
#define INDEX_BUFFER_PK_ADDR  (QSPI2_MEM_ADDR_DEFAULT + 0x80000)
#define TEX_BUFFER_PK_ADDR    (QSPI2_MEM_ADDR_DEFAULT + 0xA0000)

static void duwe_cube_setup() {
  ugpu_wb_pk_memcpy(TEX_BUFFER_PK_ADDR, (uint32_t *) duwe_react_t, DUWE_REACT_SIZE_X * DUWE_REACT_SIZE_Y / 4);
  RAST->TEXADDR.reg   = TEX_BUFFER_PK_ADDR;
  RAST->TEXWIDTH.reg  = 60;
  RAST->TEXHEIGHT.reg = 60;
  RAST->DEPTHADDR.reg = DEPTH_PK_ADDR;
  RAST->USERCOUNT.reg = 3;

  ugpu_wb_pk_memcpy(VERTEX_BUFFER_PK_ADDR, (uint32_t *) cube_vertices, (CUBE_VERTICES * sizeof(vertex_t)) / 4);
  ugpu_wb_pk_memcpy(INDEX_BUFFER_PK_ADDR, (uint32_t *) cube_triangles, (CUBE_TRIANGLES * sizeof(triangle_t)) / 4);
}

static void duwe_cube_loop() {
  mat4_t mvp;

  mat4_t rot;

  mat4_t trans;
  mat4_trans(trans, UGPU_FIXED(1) / 3, 0, UGPU_FIXED(-1));

  mat4_t trans2;
  mat4_trans(trans2, -UGPU_FIXED(1) / 3, 0, UGPU_FIXED(-1));

  mat4_t persp;
  mat4_perspective(persp, UGPU_FIXED_DIV(UGPU_FIXED(320), UGPU_FIXED(240)), UGPU_FIXED_MUL(UGPU_FIXED(90), UGPU_PI_180), UGPU_FIXED(1) / 16, UGPU_FIXED(10));

  mat4_t screen;
  mat4_screen(screen, 320, 240);

  mat4_t post_rot;
  mat4_identity(post_rot);
  mat4_mul(post_rot, screen);
  mat4_mul(post_rot, persp);
  mat4_mul(post_rot, trans);

  mat4_t post_rot2;
  mat4_identity(post_rot2);
  mat4_mul(post_rot2, screen);
  mat4_mul(post_rot2, persp);
  mat4_mul(post_rot2, trans2);

  int x = 5;

  int swap = 0;

  mat4_rotated(rot, UGPU_FIXED(x), UGPU_FIXED(0), UGPU_FIXED(x));

  mat4_muld(mvp, post_rot, rot);

  while (1) {
    demo_clear_buffers_start(swap ? FB1_PK_ADDR : FB0_PK_ADDR);

    demo_clear_buffers_end();

    demo_draw_buffer_start(
      VERTEX_BUFFER_PK_ADDR,
      INDEX_BUFFER_PK_ADDR,
      swap ? FB1_PK_ADDR : FB0_PK_ADDR,
      CUBE_TRIANGLES,
      mvp);

    mat4_muld(mvp, post_rot2, rot);

    demo_draw_buffer_sync();

    demo_draw_buffer_start(
      VERTEX_BUFFER_PK_ADDR,
      INDEX_BUFFER_PK_ADDR,
      swap ? FB1_PK_ADDR : FB0_PK_ADDR,
      CUBE_TRIANGLES,
      mvp);

    if (x < 359)
      x++;
    else
      x = 0;

    mat4_rotated(rot, UGPU_FIXED(x), UGPU_FIXED(0), UGPU_FIXED(x));
    mat4_muld(mvp, post_rot, rot);

    demo_draw_buffer_sync();

    if (swap)
      VGA->FBADDR.reg = FB1_PK_ADDR;
    else
      VGA->FBADDR.reg = FB0_PK_ADDR;

    while (!VGA->CTRL.bit.INVBLANK);

    swap = !swap;
  }
}

void duwe_cube() {
  duwe_cube_setup();
  ugpu_shader_copy(CC_IMEM, vertex_shader, vertex_shader_len);
  ugpu_shader_copy(&CC_IMEM[64], fragment_shader, fragment_shader_len);
  CC->VSHADEPC.reg = 0;
  CC->FSHADEPC.reg = 256;

  duwe_cube_loop();
}
