#ifndef _UGPU_UTIL_H
#define _UGPU_UTIL_H

#include <stdint.h>

static inline int ugpu_wb_pk_memcpy(uint32_t pk_destaddr, uint32_t * wb_srcaddr, uint32_t len_words) {
  QSPIDATA->WCOUNT.reg = 1;
  for (uint32_t byte = 0; byte < len_words << 2; byte += 4) {
    QSPIDATA->ADDR.reg  = pk_destaddr + byte;
    QSPIDATA->WDATA.reg = *(uint32_t *) ((uint32_t) wb_srcaddr + byte);
    while (QSPIDATA->STATUS.reg != QSPIDATA_STATUS_STATUS_READY) {
      if (QSPIDATA->STATUS.reg & QSPIDATA_STATUS_ADDRERR)
        return 1;
    }
  }
  return 0;
}

static inline int ugpu_pk_wb_memcpy(uint32_t * wb_destaddr, uint32_t pk_srcaddr, uint32_t len_words) {
  for (uint32_t byte = 0; byte < len_words << 2; byte += 4) {
    QSPIDATA->ADDR.reg                            = pk_srcaddr + byte;
    *(uint32_t *) ((uint32_t) wb_destaddr + byte) = QSPIDATA->RDATA.reg;
    if (QSPIDATA->STATUS.reg & QSPIDATA_STATUS_ADDRERR)
      return 1;
  }
  return 0;
}

static inline int ugpu_pk_memset(uint32_t pk_destaddr, uint32_t val, uint32_t len_words) {
  QSPIDATA->ADDR.reg   = pk_destaddr;
  QSPIDATA->WCOUNT.reg = len_words;
  QSPIDATA->WDATA.reg  = val;
  while (QSPIDATA->STATUS.reg != QSPIDATA_STATUS_STATUS_READY) {
    if (QSPIDATA->STATUS.reg & QSPIDATA_STATUS_ADDRERR)
      return 1;
  }
  return 0;
}

#endif
