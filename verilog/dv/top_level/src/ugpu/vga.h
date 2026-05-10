#ifndef _UGPU_VGA_H_
#define _UGPU_VGA_H_

#include <stdint.h>

#define VGA_CTRL_ENABLE           (1UL << 0)
#define VGA_CTRL_PRESCALER_Pos    (1)
#define VGA_CTRL_PRESCALER_Msk    (0xFUL << VGA_CTRL_PRESCALER_Pos)
#define VGA_CTRL_PRESCALER(value) (VGA_CTRL_PRESCALER_Msk & ((value) << VGA_CTRL_PRESCALER_Pos))
#define VGA_CTRL_RES_Pos          (5)
#define VGA_CTRL_RES_Msk          (0xFUL << VGA_CTRL_RES_Pos)
#define VGA_CTRL_RES(value)       (VGA_CTRL_RES_Msk & ((value) << VGA_CTRL_RES_Pos))
#define VGA_CTRL_RES_320x240      VGA_CTRL_RES(0x2)
#define VGA_CTRL_RES_160x120      VGA_CTRL_RES(0x4)
#define VGA_CTRL_RES_80x60        VGA_CTRL_RES(0x8)
#define VGA_CTRL_INVBLANK         (1UL << 9)
#define VGA_CTRL_INHBLANK         (1UL << 10)
typedef union {
  struct __packed {
    uint32_t ENABLE    : 1;
    uint32_t PRESCALER : 4;
    uint32_t RES       : 4;
    uint32_t INVBLANK  : 1;
    uint32_t INHBLANK  : 1;
    uint32_t           : 21;
  } bit;
  uint32_t reg;
} VGA_CTRL_t;

#define VGA_HTIMING_FPORCH_Pos    (0)
#define VGA_HTIMING_FPORCH_Msk    (0xFFUL << VGA_HTIMING_FPORCH_Pos)
#define VGA_HTIMING_FPORCH(value) (VGA_HTIMING_FPORCH_Msk & ((value) << VGA_HTIMING_FPORCH_Pos))
#define VGA_HTIMING_HSYNC_Pos     (8)
#define VGA_HTIMING_HSYNC_Msk     (0xFFUL << VGA_HTIMING_HSYNC_Pos)
#define VGA_HTIMING_HSYNC(value)  (VGA_HTIMING_HSYNC_Msk & ((value) << VGA_HTIMING_HSYNC_Pos))
#define VGA_HTIMING_BPORCH_Pos    (16)
#define VGA_HTIMING_BPORCH_Msk    (0xFFUL << VGA_HTIMING_BPORCH_Pos)
#define VGA_HTIMING_BPORCH(value) (VGA_HTIMING_BPORCH_Msk & ((value) << VGA_HTIMING_BPORCH_Pos))
typedef union {
  struct __packed {
    uint32_t FPORCH : 8;
    uint32_t HSYNC  : 8;
    uint32_t BPORCH : 8;
    uint32_t        : 8;
  } bit;
  uint32_t reg;
} VGA_HTIMING_t;

#define VGA_VTIMING_FPORCH_Pos    (0)
#define VGA_VTIMING_FPORCH_Msk    (0xFFUL << VGA_VTIMING_FPORCH_Pos)
#define VGA_VTIMING_FPORCH(value) (VGA_VTIMING_FPORCH_Msk & ((value) << VGA_VTIMING_FPORCH_Pos))
#define VGA_VTIMING_HSYNC_Pos     (8)
#define VGA_VTIMING_HSYNC_Msk     (0xFFUL << VGA_VTIMING_HSYNC_Pos)
#define VGA_VTIMING_HSYNC(value)  (VGA_VTIMING_HSYNC_Msk & ((value) << VGA_VTIMING_HSYNC_Pos))
#define VGA_VTIMING_BPORCH_Pos    (16)
#define VGA_VTIMING_BPORCH_Msk    (0xFFUL << VGA_VTIMING_BPORCH_Pos)
#define VGA_VTIMING_BPORCH(value) (VGA_VTIMING_BPORCH_Msk & ((value) << VGA_VTIMING_BPORCH_Pos))
typedef union {
  struct __packed {
    uint32_t FPORCH : 8;
    uint32_t HSYNC  : 8;
    uint32_t BPORCH : 8;
    uint32_t        : 8;
  } bit;
  uint32_t reg;
} VGA_VTIMING_t;

#define VGA_FBADDR_Pos    (0)
#define VGA_FBADDR_Msk    (0xFFFFFFFFUL << VGA_FBADDR_Pos)
#define VGA_FBADDR(value) (VGA_FBADDR_Msk & ((value) VGA_FBADDR_Pos))
typedef union {
  struct __packed {
    uint32_t ADDR : 32;
  } bit;
  uint32_t reg;
} VGA_FBADDR_t;

#define VGA_INTMASK_VBLANK (1UL << 0)
#define VGA_INTMASK_HBLANK (1UL << 1)
typedef union {
  struct __packed {
    uint32_t VBLANK : 1;
    uint32_t HBLANK : 1;
    uint32_t        : 30;
  } bit;
  uint32_t reg;
} VGA_INTMASK_t;

#define VGA_INTFLAG_VBLANK (1UL << 0)
#define VGA_INTFLAG_HBLANK (1UL << 1)
typedef union {
  struct __packed {
    uint32_t VBLANK : 1;
    uint32_t HBLANK : 1;
    uint32_t        : 30;
  } bit;
  uint32_t reg;
} VGA_INTFLAG_t;

typedef struct __packed {
  VGA_CTRL_t CTRL;
  VGA_HTIMING_t HTIMING;
  VGA_VTIMING_t VTIMING;
  VGA_FBADDR_t FBADDR;
  VGA_INTMASK_t INTMASK;
  VGA_INTFLAG_t INTFLAG;
} VGA_t;

#endif
