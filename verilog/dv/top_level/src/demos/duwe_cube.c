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

void duwe_cube() {
  // memcpy(CC_IMEM, vertex_shader, vertex_shader_len);
  // memcpy(CC_IMEM + vertex_shader_len, fragment_shader, fragment_shader_len);

  // ugpu_wb_pk_memcpy(VERTEX_BUFFER_PK_ADDR, vertices, NUM_VERTICES);
  // ugpu_wb_pk_memcpy(INDEX_BUFFER_PK_ADDR, indices, NUM_INDICES);

  RAST->TEXADDR.reg = 320 * 240;
  RAST->TEXWIDTH.reg = 60;
  RAST->TEXHEIGHT.reg = 60;

  CC->VSHADEPC.reg  = 0;
  CC->FSHADEPC.reg  = 512;
  CC->INDEXADDR.reg = INDEX_BUFFER_PK_ADDR;
  CC->JOBS.reg      = NUM_INDICES;

  CC->GR[0].reg     = 0x00008000;
  CC->GR[1].reg     = 0;
  CC->GR[2].reg     = 0;
  CC->GR[3].reg     = 0;

  CC->GR[4].reg     = 0;
  CC->GR[5].reg     = 0x00008000;
  CC->GR[6].reg     = 0;
  CC->GR[7].reg     = 0;

  CC->GR[8].reg     = 0;
  CC->GR[9].reg     = 0;
  CC->GR[10].reg    = 0x00008000;
  CC->GR[11].reg    = 0;

  CC->GR[12].reg    = 0;
  CC->GR[13].reg    = 0;
  CC->GR[14].reg    = 0;
  CC->GR[15].reg    = 0x00010000;


  CC->GR[46].reg    = VERTEX_BUFFER_PK_ADDR;

  CC->CTRL.reg      = CC_CTRL_DISPATCH_INDEX | CC_CTRL_CMD_RUN;

  while (!(CC->INTFLAG.reg & CC_INTFLAG_BATCHDONE)) {}
}

void duwe_cube_spin() {
}

void duwe_cube_light() {
}
