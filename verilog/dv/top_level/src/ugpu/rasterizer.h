#ifndef _UGPU_RASTERIZER_H
#define _UGPU_RASTERIZER_H

#include <stdint.h>

#define RAST_TEXADDR_ADDR_Pos    (0)
#define RAST_TEXADDR_ADDR_Msk    (0xFFFFFFFFUL << RAST_TEXADDR_ADDR_Pos)
#define RAST_TEXADDR_ADDR(value) (RAST_TEXADDR_ADDR_Msk & ((value) << RAST_TEXADDR_ADDR_Pos))
typedef union {
  struct {
    uint32_t ADDR : 32;
  } bit;
  uint32_t reg;
} RAST_TEXADDR_t;

#define RAST_TEXDIM_WIDTH_Pos     (0)
#define RAST_TEXDIM_WIDTH_Msk     (0xFFFFUL << RAST_TEXDIM_WIDTH_Pos)
#define RAST_TEXDIM_WIDTH(value)  (RAST_TEXDIM_WIDTH_Msk & ((value) << RAST_TEXDIM_WIDTH_Pos))
#define RAST_TEXDIM_HEIGHT_Pos    (16)
#define RAST_TEXDIM_HEIGHT_Msk    (0xFFFFUL << RAST_TEXDIM_HEIGHT_Pos)
#define RAST_TEXDIM_HEIGHT(value) (RAST_TEXDIM_HEIGHT_Msk & ((value) << RAST_TEXDIM_HEIGHT_Pos))
typedef union {
  struct {
    uint32_t WIDTH  : 16;
    uint32_t HEIGHT : 16;
  } bit;
  uint32_t reg;
} RAST_TEXDIM_t;

typedef struct {
  RAST_TEXADDR_t TEXADDR;
  RAST_TEXDIM_t TEXDIM;
} RAST_t;

#endif
