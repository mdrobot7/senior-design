#ifndef _DEMOS_H
#define _DEMOS_H

#include "matrix/matrix4.h"
#include "ugpu.h"

#include <stdint.h>

// SRAM0 is broken on MemoryVGAPmod
#define FB0_PK_ADDR   (QSPI1_MEM_ADDR_DEFAULT + 320 * 240 * 1)
#define FB1_PK_ADDR   (QSPI1_MEM_ADDR_DEFAULT + 320 * 240 * 2)
#define DEPTH_PK_ADDR (QSPI2_MEM_ADDR_DEFAULT)

extern uint32_t _svertex_shader;
extern uint32_t _evertex_shader;
extern uint32_t _sfragment_shader;
extern uint32_t _efragment_shader;
extern uint32_t _sfragment_shader_phong;
extern uint32_t _efragment_shader_phong;

extern uint32_t * vertex_shader;
extern uint32_t vertex_shader_len; // in words
extern uint32_t * fragment_shader;
extern uint32_t fragment_shader_len; // in words
extern uint32_t * fragment_shader_phong;
extern uint32_t fragment_shader_phong_len; // in words

extern volatile int vblank_reached;

typedef struct __attribute__((aligned(4))) {
  uint32_t ind[3];
} triangle_t;

typedef struct __packed __attribute__((aligned(4))) {
  ugpu_fp_t x;
  ugpu_fp_t y;
  ugpu_fp_t z;
  ugpu_fp_t tx;
  ugpu_fp_t ty;
  ugpu_fp_t nx;
  ugpu_fp_t ny;
  ugpu_fp_t nz;
} vertex_t;

void demos_init();
void demos_copy_mvp(mat4_t m); // Copy MVP to g0 - g15

void demo_clear_buffers(uint32_t fbuf_addr);
void demo_clear_buffers_start(uint32_t fbuf_addr);
void demo_clear_buffers_end(void);
void demo_draw_buffer(uint32_t vbuf_addr, uint32_t ibuf_addr, uint32_t fbuf_addr, uint32_t triangle_count, mat4_t mvp);
void demo_draw_buffer_start(uint32_t vbuf_addr, uint32_t ibuf_addr, uint32_t fbuf_addr, uint32_t triangle_count, mat4_t mvp);
void demo_draw_buffer_normal_start(uint32_t vbuf_addr, uint32_t ibuf_addr, uint32_t fbuf_addr, uint32_t triangle_count, mat4_t mvp, mat4_t norm);
void demo_draw_buffer_sync(void);

void rtl_demo();
void duwe_cube();
// Duwe cube model is missing vertex normals, so no shadows
void bunny();
void bunny_shadows();
void cheburashka();
void cheburashka_shadows();
void cow();
void cow_shadows();
void craft();
void craft_shadows();
void dingus();
void dingus_shadows();
void duwe();
void duwe_shadows();
void earth();
void earth_shadows();
void suzanne();
void suzanne_shadows();
void teapot();
void teapot_shadows();
void truck();
void truck_shadows();

#endif
