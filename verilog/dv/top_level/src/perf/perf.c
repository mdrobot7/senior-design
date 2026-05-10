#include "perf.h"

#include "ugpu.h"

#include <defs.h>
#include <stdint.h>
#include <stub.h>

#if 1

#define VERTEX_BUFFER_PK_ADDR (QSPI2_MEM_ADDR_DEFAULT + 0x080000)
#define INDEX_BUFFER_PK_ADDR  (QSPI2_MEM_ADDR_DEFAULT + 0x180000)
#define TEX_BUFFER_PK_ADDR    (QSPI2_MEM_ADDR_DEFAULT + 0x280000)

#define PERF_TEST_STEPS (16)

static void timer_start() {
  // Max run time of 2^32 / 50 MHz = 85 seconds
  reg_timer0_load   = 0xFFFFFFFF;
  reg_timer0_reload = 0; // One-shot mode
  reg_timer0_en     = 1;
}

static void timer_stop() {
  reg_timer0_update_value = 1; // Update reg_timer0_value with the current value of the timer BEFORE YOU STOP IT
  reg_timer0_en = 0;
}

static uint32_t timer_get_elapsed() {
  return 0xFFFFFFFF - reg_timer0_value;
}

static void print_frame_time(uint32_t frame, uint32_t time) {
  print("Frame ");
  print_hex(frame, 2);
  print(" time: 0x");
  print_hex(time, 8);
  print("\n");
}

uint32_t perf_test(vertex_t * vertices, uint32_t num_vertices, triangle_t * triangles, uint32_t num_triangles, uint32_t z_shift) {
  static const uint32_t tex = 0xFFFFFFFF;

  ugpu_wb_pk_memcpy(TEX_BUFFER_PK_ADDR, &tex, 1);

  RAST->TEXADDR.reg   = TEX_BUFFER_PK_ADDR;
  RAST->TEXWIDTH.reg  = 1;
  RAST->TEXHEIGHT.reg = 1;
  RAST->DEPTHADDR.reg = DEPTH_PK_ADDR;
  RAST->USERCOUNT.reg = 0;

  ugpu_wb_pk_memcpy(VERTEX_BUFFER_PK_ADDR, (uint32_t *) vertices, (num_vertices * sizeof(vertex_t)) / 4);
  ugpu_wb_pk_memcpy(INDEX_BUFFER_PK_ADDR, (uint32_t *) triangles, (num_triangles * sizeof(triangle_t)) / 4);

  ugpu_shader_copy(CC_IMEM, vertex_shader, vertex_shader_len);
  ugpu_shader_copy(&CC_IMEM[64], fragment_shader, fragment_shader_len);
  CC->VSHADEPC.reg = 0;
  CC->FSHADEPC.reg = 256;

  mat4_t mvp;
  mat4_t rot;
  mat4_t post_rot;
  mat4_t trans;
  mat4_t persp;
  mat4_t screen;

  mat4_trans(trans, 0, 0, UGPU_FIXED(z_shift));
  mat4_perspective(persp, UGPU_FIXED_DIV(UGPU_FIXED(320), UGPU_FIXED(240)), UGPU_FIXED_MUL(UGPU_FIXED(90), UGPU_PI_180), UGPU_FIXED(1) / 16, UGPU_FIXED(10));
  mat4_screen(screen, 320, 240);

  mat4_identity(post_rot);
  mat4_mul(post_rot, screen);
  mat4_mul(post_rot, persp);
  mat4_mul(post_rot, trans);

  int model_angle = 0;
  int swap        = 0;

  mat4_rotated(rot, 0, 0, 0);

  mat4_muld(mvp, post_rot, rot);

  uint32_t avg_frame_time = 0;
  for (int i = 0; i < PERF_TEST_STEPS; i++) {
    timer_start();

    demo_clear_buffers_start(swap ? FB1_PK_ADDR : FB0_PK_ADDR);
    demo_clear_buffers_end();
    demo_draw_buffer_start(
      VERTEX_BUFFER_PK_ADDR,
      INDEX_BUFFER_PK_ADDR,
      swap ? FB1_PK_ADDR : FB0_PK_ADDR,
      num_triangles,
      mvp);
    demo_draw_buffer_sync();

    timer_stop();

    if (swap)
      VGA->FBADDR.reg = FB1_PK_ADDR;
    else
      VGA->FBADDR.reg = FB0_PK_ADDR;

    while (!VGA->CTRL.bit.INVBLANK);

    uint32_t foo = timer_get_elapsed();
    avg_frame_time += foo;
    print_frame_time(i, foo);

    model_angle += 360 / PERF_TEST_STEPS;
    mat4_rotated(rot, 0, UGPU_FIXED(model_angle), 0);
    mat4_muld(mvp, post_rot, rot);

    swap = !swap;
  }

  avg_frame_time /= PERF_TEST_STEPS;

  print("Average frame time: 0x");
  print_hex(avg_frame_time, 8);
  print("\n");

  return avg_frame_time;
}

#endif
