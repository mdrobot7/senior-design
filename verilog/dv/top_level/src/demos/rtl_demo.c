#include "demos.h"
#include "models/cube.h"
#include "ugpu.h"

#include <stdint.h>

#define VERTEX_BUFFER_PK_ADDR (QSPI2_MEM_ADDR_DEFAULT + 0x90000)
#define INDEX_BUFFER_PK_ADDR  (QSPI2_MEM_ADDR_DEFAULT + 0x80000)
#define TEX_BUFFER_PK_ADDR    (QSPI2_MEM_ADDR_DEFAULT + 0xA0000)

void rtl_demo() {
  RAST->TEXADDR.reg   = TEX_BUFFER_PK_ADDR;
  RAST->TEXWIDTH.reg  = 60;
  RAST->TEXHEIGHT.reg = 60;
  RAST->DEPTHADDR.reg = DEPTH_PK_ADDR;
  RAST->USERCOUNT.reg = 0;

  ugpu_wb_pk_memcpy(VERTEX_BUFFER_PK_ADDR, (uint32_t *) cube_vertices, (CUBE_VERTICES * sizeof(vertex_t)) / 4);
  ugpu_wb_pk_memcpy(INDEX_BUFFER_PK_ADDR, (uint32_t *) cube_triangles, (CUBE_TRIANGLES * sizeof(triangle_t)) / 4);

  ugpu_shader_copy(CC_IMEM, vertex_shader, vertex_shader_len);
  ugpu_shader_copy(&CC_IMEM[64], fragment_shader, fragment_shader_len);
  CC->VSHADEPC.reg = 0;
  CC->FSHADEPC.reg = 256;

  mat4_t mvp = {
    {
      7864320,
      0,
      -10485760,
      36700160,
    },
    {
      0,
      7864320,
      -7864320,
      15728640,
    },
    {
      0,
      0,
      -65544,
      122896,
    },
    {
      0,
      0,
      -65536,
      131072,
    },
  };

  demo_draw_buffer_start(
    VERTEX_BUFFER_PK_ADDR,
    INDEX_BUFFER_PK_ADDR,
    FB0_PK_ADDR,
    CUBE_TRIANGLES,
    mvp);

  demo_draw_buffer_sync();
}
