#ifndef _UGPU_RASTERIZER_H
#define _UGPU_RASTERIZER_H

#include <stdint.h>

#define RAST_TEXADDR_ADDR_Pos    (0)
#define RAST_TEXADDR_ADDR_Msk    (0xFFFFFFFFUL << RAST_TEXADDR_ADDR_Pos)
#define RAST_TEXADDR_ADDR(value) (RAST_TEXADDR_ADDR_Msk & ((value) << RAST_TEXADDR_ADDR_Pos))
typedef union {
  struct __packed {
    uint32_t ADDR : 32;
  } bit;
  uint32_t reg;
} RAST_TEXADDR_t;

#define RAST_TEXWIDTH_Pos    (0)
#define RAST_TEXWIDTH_Msk    (0xFFFFUL << RAST_TEXDIM_WIDTH_Pos)
#define RAST_TEXWIDTH(value) (RAST_TEXDIM_WIDTH_Msk & ((value) << RAST_TEXDIM_WIDTH_Pos))
typedef union {
  struct __packed {
    uint32_t WIDTH : 16;
  } bit;
  uint32_t reg;
} RAST_TEXWIDTH_t;

#define RAST_TEXHEIGHT_Pos    (0)
#define RAST_TEXHEIGHT_Msk    (0xFFFFUL << RAST_TEXDIM_HEIGHT_Pos)
#define RAST_TEXHEIGHT(value) (RAST_TEXDIM_HEIGHT_Msk & ((value) << RAST_TEXDIM_HEIGHT_Pos))
typedef union {
  struct __packed {
    uint32_t HEIGHT : 16;
  } bit;
  uint32_t reg;
} RAST_TEXHEIGHT_t;

typedef union {
  struct __packed {
    uint32_t BUSY            : 1;
    uint32_t BARY_BUSY       : 1;
    uint32_t DEPTH_BUSY      : 1;
    uint32_t BARY_CHECK_BUSY : 1;
    uint32_t                 : 12;
    uint32_t FRAGS_IN_FLIGHT : 1;
  } bit;
  uint32_t reg;
} RAST_STATUS_t;

typedef union {
  struct __packed {
    uint32_t ADDR : 32;
  } bit;
  uint32_t reg;
} RAST_DEPTHADDR_t;

typedef union {
  struct __packed {
    uint32_t COUNT : 3;
    uint32_t       : 29;
  } bit;
  uint32_t reg;
} RAST_USERCOUNT_t;

typedef struct __packed {
  RAST_TEXADDR_t TEXADDR;
  RAST_TEXWIDTH_t TEXWIDTH;
  RAST_TEXHEIGHT_t TEXHEIGHT;
  RAST_STATUS_t STATUS;
  RAST_DEPTHADDR_t DEPTHADDR;
  RAST_USERCOUNT_t USERCOUNT;
} RAST_t;

#endif
