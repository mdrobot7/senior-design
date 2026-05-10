module top_level_m(
`ifdef USE_POWER_PINS
    inout wire vccd1,
    inout wire vssd1,
`endif

    input  wire wb_clk_i,
    input  wire wb_rst_i,
    input  wire wbs_stb_i,
    input  wire wbs_cyc_i,
    input  wire wbs_we_i,
    input  wire [3:0] wbs_sel_i,
    input  wire [31:0] wbs_dat_i,
    input  wire [31:0] wbs_adr_i,
    output reg  wbs_ack_o,
    output reg  [31:0] wbs_dat_o,

    output wire [2:0] user_irq,

    output wire spi0_clk_o,
    output wire spi0_cs_o,
    output wire [3:0] spi0_mosi_o,
    input  wire [3:0] spi0_miso_i,
    input  wire spi0_dqsm_i,
    output wire spi0_dqsm_o,
    output wire [3:0] spi0_sio_en_o,
    output wire spi0_dqsm_en_o,

    output wire spi1_clk_o,
    output wire spi1_cs_o,
    output wire [3:0] spi1_mosi_o,
    input  wire [3:0] spi1_miso_i,
    input  wire spi1_dqsm_i,
    output wire spi1_dqsm_o,
    output wire [3:0] spi1_sio_en_o,
    output wire spi1_dqsm_en_o,

    output wire spi2_clk_o,
    output wire spi2_cs_o,
    output wire [3:0] spi2_mosi_o,
    input  wire [3:0] spi2_miso_i,
    input  wire spi2_dqsm_i,
    output wire spi2_dqsm_o,
    output wire [3:0] spi2_sio_en_o,
    output wire spi2_dqsm_en_o,

    output wire [1:0] blue_o,
    output wire [2:0] green_o,
    output wire [2:0] red_o,
    output wire hsync_o,
    output wire vsync_o
);
endmodule

