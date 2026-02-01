#include <defs.h>
#include <stub.h>

static inline void init_io() {
    reg_mprj_io_0 = GPIO_MODE_MGMT_STD_ANALOG;

    // Changing configuration for IO[1-4] will interfere with programming flash. if you change them,
    // You may need to hold reset while powering up the board and initiating flash to keep the process
    // configuring these IO from their default values.

    reg_mprj_io_1 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_2 = GPIO_MODE_MGMT_STD_INPUT_NOPULL;
    reg_mprj_io_3 = GPIO_MODE_MGMT_STD_INPUT_NOPULL;
    reg_mprj_io_4 = GPIO_MODE_MGMT_STD_INPUT_NOPULL;

    // -------------------------------------------

    reg_mprj_io_5 = GPIO_MODE_MGMT_STD_INPUT_NOPULL;     // UART Rx
    reg_mprj_io_6 = GPIO_MODE_MGMT_STD_OUTPUT;           // UART Tx
    reg_mprj_io_7 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_8 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_9 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_10 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_11 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_12 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_13 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_14 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_15 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_16 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_17 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_18 = GPIO_MODE_MGMT_STD_OUTPUT;

    reg_mprj_io_19 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_20 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_21 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_22 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_23 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_24 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_25 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_26 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_27 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_28 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_29 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_30 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_31 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_32 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_33 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_34 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_35 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_36 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_37 = GPIO_MODE_MGMT_STD_OUTPUT;

    // Initiate the serial transfer to configure IO
    reg_mprj_xfer = 1;
    while (reg_mprj_xfer == 1);
}

#define MEM_IO_CTRL_SCK   (reg_mprj_io_12)
#define MEM_IO_CTRL_CS    (reg_mprj_io_7)
#define MEM_IO_CTRL_DQSM  (reg_mprj_io_13)
#define MEM_IO_CTRL_DEBUG (reg_mprj_io_15)
#define MEM_IO_CTRL_SIO0  (reg_mprj_io_8)
#define MEM_IO_CTRL_SIO1  (reg_mprj_io_9)
#define MEM_IO_CTRL_SIO2  (reg_mprj_io_10)
#define MEM_IO_CTRL_SIO3  (reg_mprj_io_11)

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

    set_la_dir(0, true);

    set_la_data(0, false);

    reg_uart_enable = 1;

    MEM_IO_CTRL_SCK  = GPIO_MODE_USER_STD_OUTPUT;
    MEM_IO_CTRL_CS   = GPIO_MODE_USER_STD_OUTPUT;

    MEM_IO_CTRL_DQSM = GPIO_MODE_USER_STD_BIDIRECTIONAL;

    MEM_IO_CTRL_SIO0 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    MEM_IO_CTRL_SIO1 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    MEM_IO_CTRL_SIO2 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    MEM_IO_CTRL_SIO3 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    
    MEM_IO_CTRL_DEBUG = GPIO_MODE_USER_STD_BIDIRECTIONAL;

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

    reg_mprj_io_16 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_17 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_18 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_19 = GPIO_MODE_USER_STD_OUTPUT;

    reg_mprj_io_20 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_21 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_22 = GPIO_MODE_USER_STD_OUTPUT;

    reg_mprj_xfer = 1;
    while (reg_mprj_xfer == 1);

    delay_ms(1000);

    set_la_data(0, true);

    delay_ms(1000);

    while (1) {
        reg_gpio_out   = 1; // LED on
        delay_ms(1000);

        reg_gpio_out   = 0; // LED off
        delay_ms(1000);
    }
}