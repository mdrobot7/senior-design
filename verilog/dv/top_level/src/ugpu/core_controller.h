#ifndef _UGPU_CORE_CONTROLLER_H
#define _UGPU_CORE_CONTROLLER_H

#include <stdint.h>

#define CC_CTRL_CMD_Pos         (0)
#define CC_CTRL_CMD_Msk         (0x3UL << CC_CTRL_CMD_Pos)
#define CC_CTRL_CMD(value)      (CC_CTRL_CMD_Msk & ((value) << CC_CTRL_CMD_Pos))
#define CC_CTRL_CMD_STOP        CC_CTRL_CMD(0x0)
#define CC_CTRL_CMD_PAUSE       CC_CTRL_CMD(0x1)
#define CC_CTRL_CMD_RUN         CC_CTRL_CMD(0x2)
#define CC_CTRL_CMD_STEP        CC_CTRL_CMD(0x3)
#define CC_CTRL_DISPATCH_Pos    (2)
#define CC_CTRL_DISPATCH_Msk    (0x3UL << CC_CTRL_DISPATCH_Pos)
#define CC_CTRL_DISPATCH(value) (CC_CTRL_DISPATCH_Msk & ((value) << CC_CTRL_DISPATCH_Pos))
#define CC_CTRL_DISPATCH_NONE   CC_CTRL_DISPATCH(0x0)
#define CC_CTRL_DISPATCH_INT    CC_CTRL_DISPATCH(0x1)
#define CC_CTRL_DISPATCH_INDEX  CC_CTRL_DISPATCH(0x2)
#define CC_CTRL_HALTPAUSE       (1UL << 4)
typedef union {
  struct {
    uint32_t CMD       : 2;
    uint32_t DISPATCH  : 2;
    uint32_t HALTPAUSE : 1;
    uint32_t           : 27;
  } bit;
  uint32_t reg;
} CC_CTRL_t;

#define CC_STATE_STATE_Pos              (0)
#define CC_STATE_STATE_Msk              (0xFUL << CC_STATE_STATE_Pos)
#define CC_STATE_STATE(value)           (CC_STATE_STATE_Msk & ((value) << CC_STATE_STATE_Pos))
#define CC_STATE_STATE_STOPPED          CC_STATE_STATE(0x0)
#define CC_STATE_STATE_DISPATCHING      CC_STATE_STATE(0x1)
#define CC_STATE_STATE_VERTEX_SHADING   CC_STATE_STATE(0x3)
#define CC_STATE_STATE_FRAGMENT_SHADING CC_STATE_STATE(0x4)
#define CC_STATE_STATE_GPGPU_COMPUTE    CC_STATE_STATE(0x5)
#define CC_STATE_STATE_PAUSED           CC_STATE_STATE(0x6)
#define CC_STATE_STATE_DONE             CC_STATE_STATE(0x7)
#define CC_STATE_STATE_STOPPING         CC_STATE_STATE(0x8)
typedef union {
  struct {
    uint32_t STATE : 4;
    uint32_t       : 28;
  } bit;
  uint32_t reg;
} CC_STATE_t;

#define CC_COREEN_EN_Pos    (0)
#define CC_COREEN_EN_Msk    (0x3FUL << CC_COREEN_EN_Pos)
#define CC_COREEN_EN(value) (CC_COREEN_EN_Msk & ((value) << CC_COREEN_EN_Pos))
#define CC_COREEN_EN_ENABLE (1UL)
#define CC_COREEN_EN_DISALE (0UL)
typedef union {
  struct {
    uint32_t ENABLE : 6;
    uint32_t        : 26;
  } bit;
  uint32_t reg;
} CC_COREEN_t;

#define CC_INTMASK_JOBDONE   (1UL << 0)
#define CC_INTMASK_BATCHDONE (1UL << 1)
typedef union {
  struct {
    uint32_t JOBDONE   : 1;
    uint32_t BATCHDONE : 1;
    uint32_t           : 30;
  } bit;
  uint32_t reg;
} CC_INTMASK_t;

#define CC_INTFLAG_JOBDONE   (1UL << 0)
#define CC_INTFLAG_BATCHDONE (1UL << 1)
typedef union {
  struct {
    uint32_t JOBDONE   : 1;
    uint32_t BATCHDONE : 1;
    uint32_t           : 30;
  } bit;
  uint32_t reg;
} CC_INTFLAG_t;

#define CC_COMPPC_ADDR_Pos    (0)
#define CC_COMPPC_ADDR_Msk    (0xFFFUL << CC_COMPPC_ADDR_Pos)
#define CC_COMPPC_ADDR(value) (CC_COMPPC_ADDR_Msk & ((value) << CC_COMPPC_ADDR_Pos))
typedef union {
  struct {
    uint32_t ADDR : 12;
    uint32_t      : 20;
  } bit;
  uint32_t reg;
} CC_COMPPC_t;

#define CC_VSHADEPC_ADDR_Pos    (0)
#define CC_VSHADEPC_ADDR_Msk    (0xFFFUL << CC_VSHADEPC_ADDR_Pos)
#define CC_VSHADEPC_ADDR(value) (CC_VSHADEPC_ADDR_Msk & ((value) << CC_VSHADEPC_ADDR_Pos))
typedef union {
  struct {
    uint32_t ADDR : 12;
    uint32_t      : 20;
  } bit;
  uint32_t reg;
} CC_VSHADEPC_t;

#define CC_FSHADEPC_ADDR_Pos    (0)
#define CC_FSHADEPC_ADDR_Msk    (0xFFFUL << CC_FSHADEPC_ADDR_Pos)
#define CC_FSHADEPC_ADDR(value) (CC_FSHADEPC_ADDR_Msk & ((value) << CC_FSHADEPC_ADDR_Pos))
typedef union {
  struct {
    uint32_t ADDR : 12;
    uint32_t      : 20;
  } bit;
  uint32_t reg;
} CC_FSHADEPC_t;

#define CC_INDEXADDR_ADDR_Pos    (0)
#define CC_INDEXADDR_ADDR_Msk    (0xFFFFFFFFUL << CC_INDEXADDR_ADDR_Pos)
#define CC_INDEXADDR_ADDR(value) (CC_INDEXADDR_ADDR_Msk & ((value) << CC_INDEXADDR_ADDR_Pos))
typedef union {
  struct {
    uint32_t ADDR : 32;
  } bit;
  uint32_t reg;
} CC_INDEXADDR_t;

#define CC_JOBS_JOBS_Pos    (0)
#define CC_JOBS_JOBS_Msk    (0xFFFFFFFFUL << CC_JOBS_JOBS_Pos)
#define CC_JOBS_JOBS(value) (CC_JOBS_JOBS_Msk & ((value) << CC_JOBS_JOBS_Pos))
typedef union {
  struct {
    uint32_t JOBS : 32;
  } bit;
  uint32_t reg;
} CC_JOBS_t;

#define CC_GLOBAL_REGFILE_SIZE (48UL)
typedef union {
  struct {
    uint32_t VAL : 32;
  } bit;
  uint32_t reg;
} CC_GR_t;

typedef struct {
  CC_CTRL_t CTRL;
  CC_STATE_t STATE;
  CC_COREEN_t COREEN;
  CC_INTMASK_t INTMASK;
  CC_INTFLAG_t INTFLAG;
  CC_COMPPC_t COMPPC;
  CC_VSHADEPC_t VSHADEPC;
  CC_FSHADEPC_t FSHADEPC;
  CC_INDEXADDR_t INDEXADDR;
  CC_JOBS_t JOBS;
  CC_GR_t GR[CC_GLOBAL_REGFILE_SIZE];
} CC_t;

#define CC_IMEM_ADDR (0x33000000UL)
#define CC_IMEM_SIZE (0x00001000UL)
#define CC_IMEM      ((void *) CC_IMEM_ADDR)

#define CC_NUM_CORES (6UL)

#endif
