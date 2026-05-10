module spi_block_m(
    input wire clk_i,
    input wire nrst_i,

    input  wire [68:0] sport0_i,
    output wire [33:0] sport0_o,
    input  wire [68:0] sport1_i,
    output wire [33:0] sport1_o,
    input  wire [68:0] sport2_i,
    output wire [33:0] sport2_o,

    output wire       spi0_clk_o,
    output wire       spi0_cs_o,
    output wire [3:0] spi0_mosi_o,
    input  wire [3:0] spi0_miso_i,
    input  wire       spi0_dqsm_i,
    output wire       spi0_dqsm_o,

    output wire [3:0] spi0_sio_en_o,
    output wire       spi0_dqsm_en_o,

    output wire       spi1_clk_o,
    output wire       spi1_cs_o,
    output wire [3:0] spi1_mosi_o,
    input  wire [3:0] spi1_miso_i,
    input  wire       spi1_dqsm_i,
    output wire       spi1_dqsm_o,

    output wire [3:0] spi1_sio_en_o,
    output wire       spi1_dqsm_en_o,

    output wire       spi2_clk_o,
    output wire       spi2_cs_o,
    output wire [3:0] spi2_mosi_o,
    input  wire [3:0] spi2_miso_i,
    input  wire       spi2_dqsm_i,
    output wire       spi2_dqsm_o,

    output wire [3:0] spi2_sio_en_o,
    output wire       spi2_dqsm_en_o
);
endmodule

