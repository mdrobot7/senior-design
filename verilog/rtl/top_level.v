module top_level_m(
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

    wire clk, nrst;
    assign clk = wb_clk_i;
    assign nrst = !wb_rst_i;

    wire [`BUS_MIPORT] vga_mporti;
    wire [`BUS_MOPORT] vga_mporto;

    wire [`BUS_MIPORT] rast1_mporti;
    wire [`BUS_MOPORT] rast1_mporto;

    wire [`BUS_MIPORT] rast2_mporti;
    wire [`BUS_MOPORT] rast2_mporto;

    wire [`BUS_MIPORT] rast3_mporti;
    wire [`BUS_MOPORT] rast3_mporto;

    wire [`BUS_SIPORT] spi1_sporti;
    wire [`BUS_SOPORT] spi1_sporto;

    wire [`BUS_SIPORT] spi2_sporti;
    wire [`BUS_SOPORT] spi2_sporto;

    assign rast1_mporto = 0;
    assign rast2_mporto = 0;
    assign rast3_mporto = 0;

    busarb_m #(4, 2, 2) arbiter(
        .clk_i(clk),
        .nrst_i(nrst),

        .mports_i({ rast3_mporto, rast2_mporto, rast1_mporto, vga_mporto }),
        .mports_o({ rast3_mporti, rast2_mporti, rast1_mporti, vga_mporti }),

        .sports_i({ spi1_sporto, spi2_sporto }),
        .sports_o({ spi1_sporti, spi2_sporti })
    );

    spi_mem_m #(0, `SPI_MEM_SIZE) spi_mem1(
        .clk_i(clk),
        .nrst_i(nrst),

        .sport_i(spi1_sporti),
        .sport_o(spi1_sporto),

        .spi_clk_o(spi1_clk_o),
        .spi_cs_o(spi1_cs_o),
        .spi_mosi_o(spi1_mosi_o),
        .spi_miso_i(spi1_miso_i),
        .spi_dqsm_i(spi1_dqsm_i),
        .spi_dqsm_o(spi1_dqsm_o),

        .spi_sio_en_o(spi1_sio_en_o),
        .spi_dqsm_en_o(spi1_dqsm_en_o)
    );

    spi_mem_m #(`SPI_MEM_SIZE, `SPI_MEM_SIZE) spi_mem2(
        .clk_i(clk),
        .nrst_i(nrst),

        .sport_i(spi2_sporti),
        .sport_o(spi2_sporto),

        .spi_clk_o(spi2_clk_o),
        .spi_cs_o(spi2_cs_o),
        .spi_mosi_o(spi2_mosi_o),
        .spi_miso_i(spi2_miso_i),
        .spi_dqsm_i(spi2_dqsm_i),
        .spi_dqsm_o(spi2_dqsm_o),

        .spi_sio_en_o(spi2_sio_en_o),
        .spi_dqsm_en_o(spi2_dqsm_en_o)
    );

    localparam integer NUM_ADDRS = 1;
    wire [31:0] wbs_datN_o [NUM_ADDRS:0];
    wire wbs_ackN_o [NUM_ADDRS-1:0];
    reg wbs_stbN_i [NUM_ADDRS-1:0];

    `define address_map(n, address, mask) \
        wbs_stbN_i[n] = 0; \
        if ((wbs_adr_i & mask) == address) begin \
            wbs_dat_o = wbs_datN_o[n]; \
            wbs_ack_o = wbs_ackN_o[n]; \
            wbs_stbN_i[n] = wbs_stb_i; \
        end

    always @(*) begin
        wbs_dat_o = 0;
        wbs_ack_o = 0;

        `address_map(0, 32'h38000000, 32'hF8000000);
    end


    vga_wrapper_m vga (
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .wbs_stb_i(wbs_stbN_i[0]),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_we_i(wbs_we_i),
        .wbs_sel_i(wbs_sel_i),
        .wbs_dat_i(wbs_dat_i),
        .wbs_adr_i(wbs_adr_i),
        .wbs_ack_o(wbs_ackN_o[0]),
        .wbs_dat_o(wbs_datN_o[0]),

        .mport_i(vga_mporti),
        .mport_o(vga_mporto),

        .pixel_o({ blue_o, green_o, red_o }),
        .hsync_o(hsync_o),
        .vsync_o(vsync_o)
    );
    

endmodule

