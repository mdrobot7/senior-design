#include <defs.h>
#include <stub.h>

#include "io.h"

#define VGA_IO_R0 (reg_mprj_io_24)
#define VGA_IO_R1 (reg_mprj_io_25)
#define VGA_IO_R2 (reg_mprj_io_26)
#define VGA_IO_G0 (reg_mprj_io_27)
#define VGA_IO_G1 (reg_mprj_io_28)
#define VGA_IO_G2 (reg_mprj_io_29)
#define VGA_IO_B0 (reg_mprj_io_30)
#define VGA_IO_B1 (reg_mprj_io_31)
#define VGA_IO_HSYNC (reg_mprj_io_22)
#define VGA_IO_VSYNC (reg_mprj_io_23)

void main() {
    reg_gpio_mode1 = 1;
    reg_gpio_mode0 = 0;
    reg_gpio_ien = 1;
    reg_gpio_oe = 1;

    reg_wb_enable = 1;

    init_io();

    reg_uart_enable = 1;

    // Set everything to user area output
    reg_mprj_io_20 = GPIO_MODE_USER_STD_OUTPUT; // debug
    reg_mprj_io_21 = GPIO_MODE_USER_STD_OUTPUT; // debug
    VGA_IO_R0 = GPIO_MODE_USER_STD_OUTPUT;
    VGA_IO_R1 = GPIO_MODE_USER_STD_OUTPUT;
    VGA_IO_R2 = GPIO_MODE_USER_STD_OUTPUT;
    VGA_IO_G0 = GPIO_MODE_USER_STD_OUTPUT;
    VGA_IO_G1 = GPIO_MODE_USER_STD_OUTPUT;
    VGA_IO_G2 = GPIO_MODE_USER_STD_OUTPUT;
    VGA_IO_B0 = GPIO_MODE_USER_STD_OUTPUT;
    VGA_IO_B1 = GPIO_MODE_USER_STD_OUTPUT;
    VGA_IO_HSYNC = GPIO_MODE_USER_STD_OUTPUT;
    VGA_IO_VSYNC = GPIO_MODE_USER_STD_OUTPUT;

    reg_mprj_xfer = 1;
    while (reg_mprj_xfer == 1);

    // The VGA module isn't wishbone-compatible and we don't have a wishbone-to-PKBus
    // adapter yet. Just let it run for a while and let the verilog TB control everything
    // Meanwhile, blinky
    while(1) {
      reg_gpio_out = 1;
      delay_ms(1000);
      reg_gpio_out = 0;
      delay_ms(1000);
    }
}
