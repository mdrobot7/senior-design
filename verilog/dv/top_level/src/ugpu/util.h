#ifndef _UGPU_UTIL_H
#define _UGPU_UTIL_H

#include "core_controller.h"

#include <stdint.h>

static inline int ugpu_wb_pk_memcpy(uint32_t pk_destaddr, uint32_t * wb_srcaddr, uint32_t len_words) {
  QSPIDATA1->WCOUNT.reg = 1;
  for (uint32_t byte = 0; byte < len_words << 2; byte += 4) {
    QSPIDATA1->ADDR.reg  = pk_destaddr + byte;
    QSPIDATA1->WDATA.reg = *(uint32_t *) ((uint32_t) wb_srcaddr + byte);
    while (QSPIDATA1->STATUS.reg != QSPIDATA_STATUS_STATUS_READY) {
      if (QSPIDATA1->STATUS.reg & QSPIDATA_STATUS_ADDRERR)
        return 1;
    }
  }
  return 0;
}

static inline int ugpu_pk_wb_memcpy(uint32_t * wb_destaddr, uint32_t pk_srcaddr, uint32_t len_words) {
  for (uint32_t byte = 0; byte < len_words << 2; byte += 4) {
    QSPIDATA1->ADDR.reg                           = pk_srcaddr + byte;
    *(uint32_t *) ((uint32_t) wb_destaddr + byte) = QSPIDATA1->RDATA.reg;
    if (QSPIDATA1->STATUS.reg & QSPIDATA_STATUS_ADDRERR)
      return 1;
  }
  return 0;
}

static inline int ugpu_pk_memset(uint32_t pk_destaddr, uint32_t val, uint32_t len_words) {
  QSPIDATA1->ADDR.reg   = pk_destaddr;
  QSPIDATA1->WCOUNT.reg = len_words;
  QSPIDATA1->WDATA.reg  = val;
  while (QSPIDATA1->STATUS.reg != QSPIDATA_STATUS_STATUS_READY) {
    if (QSPIDATA1->STATUS.reg & QSPIDATA_STATUS_ADDRERR)
      return 1;
  }
  return 0;
}

static inline void ugpu_pk_memset_start(volatile QSPIDATA_t * qspidata, uint32_t pk_destaddr, uint32_t val, uint32_t len_words) {
  qspidata->ADDR.reg   = pk_destaddr;
  qspidata->WCOUNT.reg = len_words;
  qspidata->WDATA.reg  = val;
}

static inline int ugpu_pk_memset_wait(volatile QSPIDATA_t * qspidata) {
  while (QSPIDATA1->STATUS.reg != QSPIDATA_STATUS_STATUS_READY) {
    if (QSPIDATA1->STATUS.reg & QSPIDATA_STATUS_ADDRERR)
      return 1;
  }
  return 0;
}

static inline int ugpu_shader_copy(uint32_t * dest, uint32_t * shader, uint32_t len_words) {
  // Must be done with aligned word writes because IMEM only supports word access

  if (len_words > (CC_IMEM_SIZE >> 2)) {
    return 1;
  }
  for (int i = 0; i < len_words; i++) {
    dest[i] = shader[i];
  }
}

#endif
