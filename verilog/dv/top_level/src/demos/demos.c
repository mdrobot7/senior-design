#include "demos.h"

#include <irq_api.h>
#include <irq_vex.h>

uint32_t * vertex_shader;
uint32_t vertex_shader_len;
uint32_t * fragment_shader;
uint32_t fragment_shader_len;
uint32_t * fragment_shader_phong;
uint32_t fragment_shader_phong_len;

// VGA IRQ handler
void user0_handler() {
  reg_user_irq_0_ev_pending = 1; // Clear interrupt flag
}

// Core controller/cores IRQ handler
void user1_handler() {
  reg_user_irq_1_ev_pending = 1; // Clear interrupt flag
}

void demos_init() {
  vertex_shader             = &_svertex_shader;
  vertex_shader_len         = (uint32_t) (&_evertex_shader - &_svertex_shader);
  fragment_shader           = &_sfragment_shader;
  fragment_shader_len       = (uint32_t) (&_efragment_shader - &_sfragment_shader);
  fragment_shader_phong     = &_sfragment_shader_phong;
  fragment_shader_phong_len = (uint32_t) (&_efragment_shader_phong - &_sfragment_shader_phong);
}

void demos_copy_mvp(mat4_t m) {
  ugpu_fp_t * mvp = (ugpu_fp_t *) m;
  for (int i = 0; i < 16; i++) {
    CC->GR[i].reg = mvp[i];
  }
}

void demo_clear_buffers(uint32_t fbuf_addr) {
    demo_clear_buffers_start(fbuf_addr);
    demo_clear_buffers_end();
}

void demo_clear_buffers_start(uint32_t fbuf_addr) {
    ugpu_pk_memset_start(QSPIDATA2, DEPTH_PK_ADDR, 0x7FFFFFFF, 320 * 240);

    static const int fb_chunk    = 320 * 240 / 4 / 480;

    for (int i = 0; i < 480; i++) {
      asm volatile ("nop");
      asm volatile ("nop");
      asm volatile ("nop");
      asm volatile ("nop");
      asm volatile ("nop");
      asm volatile ("nop");
      asm volatile ("nop");

      /* ugpu_pk_memset(fbuf_addr + i * fb_chunk * 4, 0x00000000, fb_chunk); */
      ugpu_pk_memset(fbuf_addr + i * fb_chunk * 4, 0x52525252, fb_chunk);
    }
}

void demo_clear_buffers_end(void) {
    ugpu_pk_memset_wait(QSPIDATA2);
}

void demo_draw_buffer(uint32_t vbuf_addr, uint32_t ibuf_addr, uint32_t fbuf_addr, uint32_t triangle_count, mat4_t mvp) {
    demo_draw_buffer_start(vbuf_addr, ibuf_addr, fbuf_addr, triangle_count, mvp);
    demo_draw_buffer_sync();
}

void demo_draw_buffer_start(uint32_t vbuf_addr, uint32_t ibuf_addr, uint32_t fbuf_addr, uint32_t triangle_count, mat4_t mvp) {
    CC->INDEXADDR.reg = ibuf_addr;
    CC->JOBS.reg      = triangle_count * 3;

    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        CC->GR[i * 4 + j].reg = mvp[i][j];
      }
    }

    CC->GR[44].reg = fbuf_addr;
    CC->GR[46].reg = vbuf_addr;

    CC->CTRL.reg = CC_CTRL_DISPATCH_INDEX | CC_CTRL_CMD_RUN;
}

void demo_draw_buffer_normal_start(uint32_t vbuf_addr, uint32_t ibuf_addr, uint32_t fbuf_addr, uint32_t triangle_count, mat4_t mvp, mat4_t norm) {
    CC->INDEXADDR.reg = ibuf_addr;
    CC->JOBS.reg      = triangle_count * 3;

    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        CC->GR[i * 4 + j].reg = mvp[i][j];
      }
    }

    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        CC->GR[16 + i * 4 + j].reg = norm[i][j];
      }
    }

    CC->GR[44].reg = fbuf_addr;
    CC->GR[46].reg = vbuf_addr;

    CC->CTRL.reg = CC_CTRL_DISPATCH_INDEX | CC_CTRL_CMD_RUN;
}

void demo_draw_buffer_sync(void) {
    while (!(CC->INTFLAG.reg & CC_INTFLAG_BATCHDONE));
    CC->INTFLAG.reg = CC_INTFLAG_BATCHDONE;
}
