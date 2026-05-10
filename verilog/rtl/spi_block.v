module spi_block_m(
    input wire clk_i,
    input wire nrst_i,

    input  wire [`BUS_SIPORT] sport0_i,
    output wire [`BUS_SOPORT] sport0_o,
    input  wire [`BUS_SIPORT] sport1_i,
    output wire [`BUS_SOPORT] sport1_o,
    input  wire [`BUS_SIPORT] sport2_i,
    output wire [`BUS_SOPORT] sport2_o,

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

    spi_mem_m #(0 * `SPI_MEM_SIZE, `SPI_MEM_SIZE) spi_mem0(
        .clk_i(clk_i),
        .nrst_i(nrst_i),

        .sport_i(sport0_i),
        .sport_o(sport0_o),

        .spi_clk_o(spi0_clk_o),
        .spi_cs_o(spi0_cs_o),
        .spi_mosi_o(spi0_mosi_o),
        .spi_miso_i(spi0_miso_i),
        .spi_dqsm_i(spi0_dqsm_i),
        .spi_dqsm_o(spi0_dqsm_o),

        .spi_sio_en_o(spi0_sio_en_o),
        .spi_dqsm_en_o(spi0_dqsm_en_o)
    );

    spi_mem_m #(1 * `SPI_MEM_SIZE, `SPI_MEM_SIZE) spi_mem1(
        .clk_i(clk_i),
        .nrst_i(nrst_i),

        .sport_i(sport1_i),
        .sport_o(sport1_o),

        .spi_clk_o(spi1_clk_o),
        .spi_cs_o(spi1_cs_o),
        .spi_mosi_o(spi1_mosi_o),
        .spi_miso_i(spi1_miso_i),
        .spi_dqsm_i(spi1_dqsm_i),
        .spi_dqsm_o(spi1_dqsm_o),

        .spi_sio_en_o(spi1_sio_en_o),
        .spi_dqsm_en_o(spi1_dqsm_en_o)
    );

    spi_mem_m #(2 * `SPI_MEM_SIZE, `SPI_MEM_SIZE) spi_mem2(
        .clk_i(clk_i),
        .nrst_i(nrst_i),

        .sport_i(sport2_i),
        .sport_o(sport2_o),

        .spi_clk_o(spi2_clk_o),
        .spi_cs_o(spi2_cs_o),
        .spi_mosi_o(spi2_mosi_o),
        .spi_miso_i(spi2_miso_i),
        .spi_dqsm_i(spi2_dqsm_i),
        .spi_dqsm_o(spi2_dqsm_o),

        .spi_sio_en_o(spi2_sio_en_o),
        .spi_dqsm_en_o(spi2_dqsm_en_o)
    );

endmodule

