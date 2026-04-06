#ifndef _DEMOS_H
#define _DEMOS_H

#include "ugpu.h"

#include <stdint.h>

#define FB0_PK_ADDR   (QSPI0_MEM_ADDR_DEFAULT + 0x00000000)
#define FB1_PK_ADDR   (QSPI1_MEM_ADDR_DEFAULT + 0x00000000)
#define DEPTH_PK_ADDR (QSPI2_MEM_ADDR_DEFAULT + 0x00000000)

extern uint32_t _svertex_shader;
extern uint32_t _evertex_shader;
extern uint32_t _sfragment_shader;
extern uint32_t _efragment_shader;

extern uint32_t * vertex_shader;
extern uint32_t vertex_shader_len;
extern uint32_t * fragment_shader;
extern uint32_t fragment_shader_len;

void demos_init();

// Standard vertex shade, passthrough fragment shade
void duwe_cube();
void duwe_cube_spin();
void cow();

// Standard vertex shade, global illumination fragment shade
void duwe_cube_light();
void cow_light();

#endif
