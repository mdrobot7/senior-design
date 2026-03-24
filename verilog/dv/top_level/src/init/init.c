#include "init.h"

#include "ugpu.h"

#include <defs.h>
#include <stub.h>

static void init_io() {
  reg_gpio_mode1 = 1;
  reg_gpio_mode0 = 0;
  reg_gpio_ien   = 1;
  reg_gpio_oe    = 1;

  reg_mprj_io_0 = GPIO_MODE_MGMT_STD_ANALOG; // JTAG

  // Changing configuration for IO[1-4] will interfere with programming flash. if you change them,
  // You may need to hold reset while powering up the board and initiating flash to keep the process
  // configuring these IO from their default values.

  reg_mprj_io_1 = GPIO_MODE_MGMT_STD_OUTPUT;       // MGMT SPI SDO
  reg_mprj_io_2 = GPIO_MODE_MGMT_STD_INPUT_NOPULL; // MGMT SPI SDI
  reg_mprj_io_3 = GPIO_MODE_MGMT_STD_INPUT_NOPULL; // MGMT SPI CSB
  reg_mprj_io_4 = GPIO_MODE_MGMT_STD_INPUT_NOPULL; // MGMT SPI SCK

  reg_mprj_io_5 = GPIO_MODE_MGMT_STD_INPUT_NOPULL; // UART Rx
  reg_mprj_io_6 = GPIO_MODE_MGMT_STD_OUTPUT;       // UART Tx

  // -----------------------------------------------

  GPIO_QSPI0_SCK  = GPIO_MODE_USER_STD_OUTPUT;
  GPIO_QSPI0_CS   = GPIO_MODE_USER_STD_OUTPUT;
  GPIO_QSPI0_DQSM = GPIO_MODE_USER_STD_BIDIRECTIONAL;
  GPIO_QSPI0_SIO0 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
  GPIO_QSPI0_SIO1 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
  GPIO_QSPI0_SIO2 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
  GPIO_QSPI0_SIO3 = GPIO_MODE_USER_STD_BIDIRECTIONAL;

  GPIO_QSPI1_SCK  = GPIO_MODE_USER_STD_OUTPUT;
  GPIO_QSPI1_CS   = GPIO_MODE_USER_STD_OUTPUT;
  GPIO_QSPI1_DQSM = GPIO_MODE_USER_STD_BIDIRECTIONAL;
  GPIO_QSPI1_SIO0 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
  GPIO_QSPI1_SIO1 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
  GPIO_QSPI1_SIO2 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
  GPIO_QSPI1_SIO3 = GPIO_MODE_USER_STD_BIDIRECTIONAL;

  GPIO_VGA_R0    = GPIO_MODE_USER_STD_OUTPUT;
  GPIO_VGA_R1    = GPIO_MODE_USER_STD_OUTPUT;
  GPIO_VGA_R2    = GPIO_MODE_USER_STD_OUTPUT;
  GPIO_VGA_G0    = GPIO_MODE_USER_STD_OUTPUT;
  GPIO_VGA_G1    = GPIO_MODE_USER_STD_OUTPUT;
  GPIO_VGA_G2    = GPIO_MODE_USER_STD_OUTPUT;
  GPIO_VGA_B0    = GPIO_MODE_USER_STD_OUTPUT;
  GPIO_VGA_B1    = GPIO_MODE_USER_STD_OUTPUT;
  GPIO_VGA_HSYNC = GPIO_MODE_USER_STD_OUTPUT;
  GPIO_VGA_VSYNC = GPIO_MODE_USER_STD_OUTPUT;

  // Initiate the serial transfer to configure IO
  reg_mprj_xfer = 1;
  while (reg_mprj_xfer == 1);
}

static void init_qspi() {
  QSPI0->CTRL.reg     = QSPI_CTRL_CACHEEN | QSPI_CTRL_QSPIEN;
  QSPI0->BASEADDR.reg = QSPI0_MEM_ADDR_DEFAULT;
  QSPI1->CTRL.reg     = QSPI_CTRL_CACHEEN | QSPI_CTRL_QSPIEN;
  QSPI1->BASEADDR.reg = QSPI1_MEM_ADDR_DEFAULT;
  QSPI2->CTRL.reg     = QSPI_CTRL_CACHEEN | QSPI_CTRL_QSPIEN;
  QSPI2->BASEADDR.reg = QSPI2_MEM_ADDR_DEFAULT;
}

static void init_cores() {
  CC->COREEN.reg = 0b111111;
  // Dispatch, PCs, jobs, index buffer, global regfile set in each demo
}

static void init_vga() {
  VGA->CTRL.reg = VGA_CTRL_RES_320x240 | VGA_CTRL_PRESCALER(2) | VGA_CTRL_ENABLE;
  // FBADDR set in each demo
}

void init() {
  reg_wb_enable   = 1;
  reg_uart_enable = 1;

  init_io();
  init_qspi();
  init_cores();
  init_vga();
}
