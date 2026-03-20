#ifndef _UGPU_QSPI_H
#define _UGPU_QSPI_H

#include <cstdint>
#include <stdint.h>

#define QSPI_CTRL_QSPIEN  (1UL << 0)
#define QSPI_CTRL_CACHEEN (1UL << 1)
typedef union {
  struct {
    uint32_t QSPIEN  : 1;
    uint32_t CACHEEN : 1;
    uint32_t         : 30;
  } bit;
  uint32_t reg;
} QSPI_CTRL_t;

#define QSPI_BASEADDR_ADDR_Pos    (0)
#define QSPI_BASEADDR_ADDR_Msk    (0xFFFFFFFFUL << QSPI_BASEADDR_ADDR_Pos)
#define QSPI_BASEADDR_ADDR(value) (QSPI_BASEADDR_ADDR_Msk & ((value) << QSPI_BASEADDR_ADDR_Pos))
typedef union {
  struct {
    uint32_t ADDR : 32;
  } bit;
  uint32_t reg;
} QSPI_BASEADDR_t;

typedef struct {
  QSPI_CTRL_t CTRL;
  QSPI_BASEADDR_t BASEADDR;
} QSPI_t;

#define QSPIDATA_STATUS_STATUS_Pos    (0)
#define QSPIDATA_STATUS_STATUS_Msk    (0x7UL << QSPIDATA_STATUS_STATUS_Pos)
#define QSPIDATA_STATUS_STATUS(value) (QSPI_BASEADDR_ADDR_Msk & ((value) << QSPIDATA_STATUS_STATUS_Pos))
#define QSPIDATA_STATUS_STATUS_READY  QSPIDATA_STATUS_STATUS(0x0)
#define QSPIDATA_STATUS_STATUS_ARB    QSPIDATA_STATUS_STATUS(0x1)
#define QSPIDATA_STATUS_STATUS_WRITE  QSPIDATA_STATUS_STATUS(0x2)
#define QSPIDATA_STATUS_STATUS_READ   QSPIDATA_STATUS_STATUS(0x3)
#define QSPIDATA_STATUS_STATUS_ERROR  QSPIDATA_STATUS_STATUS(0x4)
#define QSPIDATA_STATUS_ADDRERR_Pos   (3)
#define QSPIDATA_STATUS_ADDRERR       (1UL << QSPIDATA_STATUS_ADDRERR_Pos)
typedef union {
  struct {
    uint32_t STATUS  : 3;
    uint32_t ADDRERR : 1;
    uint32_t         : 28;
  } bit;
  uint32_t reg;
} QSPIDATA_STATUS_t;

#define QSPIDATA_ADDR_ADDR_Pos    (0)
#define QSPIDATA_ADDR_ADDR_Msk    (0xFFFFFFFFUL << QSPIDATA_ADDR_ADDR_Pos)
#define QSPIDATA_ADDR_ADDR(value) (QSPIDATA_ADDR_ADDR_Msk & ((value) << QSPIDATA_ADDR_ADDR_Pos))
typedef union {
  struct {
    uint32_t ADDR : 32;
  } bit;
  uint32_t reg;
} QSPIDATA_ADDR_t;

#define QSPIDATA_WDATA_DATA_Pos    (0)
#define QSPIDATA_WDATA_DATA_Msk    (0xFFFFFFFFUL << QSPIDATA_WDATA_DATA_Pos)
#define QSPIDATA_WDATA_DATA(value) (QSPIDATA_WDATA_DATA_Msk & ((value) << QSPIDATA_WDATA_DATA_Pos))
typedef union {
  struct {
    uint32_t DATA : 32;
  } bit;
  uint32_t reg;
} QSPIDATA_WDATA_t;

#define QSPIDATA_WCOUNT_COUNT_Pos    (0)
#define QSPIDATA_WCOUNT_COUNT_Msk    (0xFFFFFFFFUL << QSPIDATA_WCOUNT_COUNT_Pos)
#define QSPIDATA_WCOUNT_COUNT(value) (QSPIDATA_WCOUNT_COUNT_Msk & ((value) << QSPIDATA_WCOUNT_COUNT_Pos))
typedef union {
  struct {
    uint32_t COUNT : 32;
  } bit;
  uint32_t reg;
} QSPIDATA_WCOUNT_t;

#define QSPIDATA_RDATA_DATA_Pos    (0)
#define QSPIDATA_RDATA_DATA_Msk    (0xFFFFFFFFUL << QSPIDATA_RDATA_DATA_Pos)
#define QSPIDATA_RDATA_DATA(value) (QSPIDATA_RDATA_DATA_Msk & ((value) << QSPIDATA_RDATA_DATA_Pos))
typedef union {
  struct {
    uint32_t DATA : 32;
  } bit;
  uint32_t reg;
} QSPIDATA_RDATA_t;

typedef struct {
  QSPIDATA_STATUS_t STATUS;
  QSPIDATA_ADDR_t ADDR;
  QSPIDATA_WDATA_t WDATA;
  QSPIDATA_WCOUNT_t WCOUNT;
  QSPIDATA_RDATA_t RDATA;
} QSPIDATA_t;

#endif
