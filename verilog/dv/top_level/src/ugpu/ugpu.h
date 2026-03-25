#ifndef _UGPU_H_
#define _UGPU_H_

#include "core_controller.h"
#include "gpio.h"
#include "math.h"
#include "qspi.h"
#include "rasterizer.h"
#include "vga.h"

#define CC       ((volatile CC_t *)       0x32000000)
#define RAST     ((volatile RAST_t *)     0x31000000)
#define QSPI0    ((volatile QSPI_t *)     0x30000000)
#define QSPI1    ((volatile QSPI_t *)     0x30000000)
#define QSPI2    ((volatile QSPI_t *)     0x30000000)
#define QSPIDATA ((volatile QSPIDATA_t *) 0x30000000)
#define VGA      ((volatile VGA_t *)      0x30000000)

// Must be included after peripheral defines
#include "util.h"

#endif
