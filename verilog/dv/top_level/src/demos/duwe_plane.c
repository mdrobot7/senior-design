#include "demos.h"
#include "ugpu.h"

#include <stdint.h>
#include <string.h>

#define VERTEX_BUFFER_PK_ADDR (QSPI0_MEM_ADDR_DEFAULT + 0x90000)
#define INDEX_BUFFER_PK_ADDR  (QSPI0_MEM_ADDR_DEFAULT + 0x80000)

#define NUM_VERTICES (4)
#define NUM_INDICES  (6)
static const uint32_t vertices[NUM_VERTICES] = {}; // TODO
static const uint32_t indices[NUM_INDICES]   = {}; // TODO

void duwe_plane() {
  // memcpy(CC_IMEM, vertex_shader, vertex_shader_len);
  // memcpy(CC_IMEM + vertex_shader_len, fragment_shader, fragment_shader_len);

  // ugpu_wb_pk_memcpy(VERTEX_BUFFER_PK_ADDR, vertices, NUM_VERTICES);
  // ugpu_wb_pk_memcpy(INDEX_BUFFER_PK_ADDR, indices, NUM_INDICES);

  RAST->TEXADDR.reg   = 320 * 240;
  RAST->TEXWIDTH.reg  = 60;
  RAST->TEXHEIGHT.reg = 60;

  CC->VSHADEPC.reg  = 0;
  CC->FSHADEPC.reg  = 2048;
  CC->INDEXADDR.reg = INDEX_BUFFER_PK_ADDR;
  CC->JOBS.reg      = NUM_INDICES;

#define PI_180_FIXED UGPU_FLOAT_TO_FIXED(3.14159265f / 180.0f)

  mat4_t mvp;

  // mat4_t rot;
  // mat4_rotated(rot, 0, UGPU_FIXED(20), 0);

  mat4_t persp;
  mat4_perspective(persp, UGPU_FIXED_DIV(UGPU_FIXED(320), UGPU_FIXED(240)), UGPU_FIXED_MUL(UGPU_FIXED(90), PI_180_FIXED), UGPU_FIXED(1) / 16, UGPU_FIXED(1000));

  mat4_t screen;
  mat4_screen(screen, 320, 240);

  mat4_muld(mvp, persp, screen);

  for (int i = 0; i < 4; i++) {
    for (int j = 0; j < 4; j++) {
      CC->GR[i * 4 + j].reg = mvp[i][j];
    }
  }

  CC->GR[46].reg = VERTEX_BUFFER_PK_ADDR;

  CC->CTRL.reg = CC_CTRL_DISPATCH_INDEX | CC_CTRL_CMD_RUN;

  while (!(CC->INTFLAG.reg & CC_INTFLAG_BATCHDONE)) {}
}
