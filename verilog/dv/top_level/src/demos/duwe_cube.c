#include "demos.h"
#include "ugpu.h"

#include <stdint.h>
#include <string.h>

#define VERTEX_BUFFER_PK_ADDR (QSPI0_MEM_ADDR_DEFAULT + 0x20000)
#define INDEX_BUFFER_PK_ADDR  (QSPI0_MEM_ADDR_DEFAULT + 0x30000)

#define NUM_VERTICES (8)
#define NUM_INDICES  (12)
static const uint32_t vertices[NUM_VERTICES] = {}; // TODO
static const uint32_t indices[NUM_INDICES]   = {}; // TODO

void duwe_cube() {
  memcpy(CC_IMEM, vertex_shader, vertex_shader_len);
  memcpy(CC_IMEM + vertex_shader_len, fragment_shader, fragment_shader_len);

  ugpu_wb_pk_memcpy(VERTEX_BUFFER_PK_ADDR, vertices, NUM_VERTICES);
  ugpu_wb_pk_memcpy(INDEX_BUFFER_PK_ADDR, indices, NUM_INDICES);

  CC->VSHADEPC.reg  = (uint32_t) CC_IMEM;
  CC->FSHADEPC.reg  = ((uint32_t) CC_IMEM) + vertex_shader_len;
  CC->INDEXADDR.reg = INDEX_BUFFER_PK_ADDR;
  CC->JOBS.reg      = NUM_INDICES;
  CC->GR[46].reg    = INDEX_BUFFER_PK_ADDR;
  CC->CTRL.reg      = CC_CTRL_DISPATCH_INDEX | CC_CTRL_CMD_RUN;

  while (!(CC->INTFLAG.reg & CC_INTFLAG_BATCHDONE)) {}
}

void duwe_cube_spin() {
}

void duwe_cube_light() {
}
