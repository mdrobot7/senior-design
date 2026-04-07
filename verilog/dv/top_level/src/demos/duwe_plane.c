#include "demos.h"
#include "ugpu.h"

#include <stdint.h>
#include <string.h>

#define VERTEX_BUFFER_PK_ADDR (QSPI0_MEM_ADDR_DEFAULT + 0x90000)
#define INDEX_BUFFER_PK_ADDR  (QSPI0_MEM_ADDR_DEFAULT + 0x80000)

#define NUM_VERTICES  (6)
#define NUM_TRIANGLES (4)
static const vertex_t vertices[NUM_VERTICES] = {
  {
    .x  = -UGPU_FIXED(1) / 4,
    .y  = -UGPU_FIXED(1) / 4,
    .z  = UGPU_FIXED(1) / 4,
    .tx = UGPU_FIXED(0),
    .ty = UGPU_FIXED(0),
  },
  {
    .x  = UGPU_FIXED(1) / 4,
    .y  = -UGPU_FIXED(1) / 4,
    .z  = UGPU_FIXED(1) / 4,
    .tx = UGPU_FIXED(60),
    .ty = UGPU_FIXED(0),
  },
  {
    .x  = -UGPU_FIXED(1) / 4,
    .y  = UGPU_FIXED(1) / 4,
    .z  = UGPU_FIXED(1) / 4,
    .tx = UGPU_FIXED(0),
    .ty = UGPU_FIXED(60),
  },
  {
    .x  = UGPU_FIXED(1) / 4,
    .y  = UGPU_FIXED(1) / 4,
    .z  = UGPU_FIXED(1) / 4,
    .tx = UGPU_FIXED(60),
    .ty = UGPU_FIXED(60),
  },
  {
    .x  = -UGPU_FIXED(1) / 4,
    .y  = -UGPU_FIXED(1) / 4,
    .z  = -UGPU_FIXED(1) / 4,
    .tx = UGPU_FIXED(60),
    .ty = UGPU_FIXED(0),
  },
  {
    .x  = -UGPU_FIXED(1) / 4,
    .y  = UGPU_FIXED(1) / 4,
    .z  = -UGPU_FIXED(1) / 4,
    .tx = UGPU_FIXED(60),
    .ty = UGPU_FIXED(60),
  },
};

static const triangle_t triangles[NUM_TRIANGLES] = {
  { 0, 2, 1 },
  { 1, 2, 3 },
  { 0, 4, 5 },
  { 0, 5, 2 },
};

void duwe_plane() {
  // memcpy(CC_IMEM, vertex_shader, vertex_shader_len);
  // memcpy(CC_IMEM + vertex_shader_len, fragment_shader, fragment_shader_len);

  // Texture buffer set in verilog because we need to load an image
  // Commenting out because they're slow in RTL
  // ugpu_pk_memset(DEPTH_PK_ADDR, 0xFFFFFFFF, 320 * 240);
  // ugpu_pk_memset(FB0_PK_ADDR, 0, 320 * 240 / 4);

  ugpu_wb_pk_memcpy(VERTEX_BUFFER_PK_ADDR, (uint32_t *) vertices, (NUM_VERTICES * sizeof(vertex_t)) / 4);
  ugpu_wb_pk_memcpy(INDEX_BUFFER_PK_ADDR, (uint32_t *) triangles, (NUM_TRIANGLES * sizeof(triangle_t)) / 4);

  RAST->TEXADDR.reg   = 320 * 240;
  RAST->TEXWIDTH.reg  = 60;
  RAST->TEXHEIGHT.reg = 60;

  CC->VSHADEPC.reg  = 0;
  CC->FSHADEPC.reg  = 2048;
  CC->INDEXADDR.reg = INDEX_BUFFER_PK_ADDR;
  CC->JOBS.reg      = NUM_TRIANGLES * 3;

#define PI_180_FIXED 1144

  mat4_t mvp = { { 7864320, 0, -10485760, 36700160, }, { 0, 7864320, -7864320, 15728640, }, { 0, 0, -65544, 122896, }, { 0, 0, -65536, 131072, }, };

  // mat4_t rot;
  // mat4_rotated(rot, 0, UGPU_FIXED(20), 0);

  // mat4_t trans;
  // mat4_trans(trans, 0, 0, UGPU_FIXED(-1));

  // mat4_t persp;
  // mat4_perspective(persp, UGPU_FIXED_DIV(UGPU_FIXED(320), UGPU_FIXED(240)), UGPU_FIXED_MUL(UGPU_FIXED(90), PI_180_FIXED), UGPU_FIXED(1) / 16, UGPU_FIXED(1000));

  // mat4_t screen;
  // mat4_screen(screen, 320, 240);

  // mat4_muld(mvp, rot, trans);
  // mat4_muld(mvp, mvp, persp);
  // mat4_muld(mvp, mvp, screen);

  for (int i = 0; i < 4; i++) {
    for (int j = 0; j < 4; j++) {
      CC->GR[i * 4 + j].reg = mvp[i][j];
    }
  }

  CC->GR[46].reg = VERTEX_BUFFER_PK_ADDR;

  CC->CTRL.reg = CC_CTRL_DISPATCH_INDEX | CC_CTRL_CMD_RUN;

  while (!(CC->INTFLAG.reg & CC_INTFLAG_BATCHDONE)) {}
}
