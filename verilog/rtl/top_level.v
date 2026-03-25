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

    localparam integer NUM_ADDRS = 2;
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
        `address_map(1, 32'h30000000, 32'hF8000000);
    end

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

    reg  [`WORD] inst;

    reg  [`WORD] global_r1, global_r2;

    wire jump_request;
    reg  fds;

    reg  stalli;
    wire stallo;

    reg nsync_rst;

    wire [`STREAM_MIPORT(`MAILBOX_STREAM_SIZE)] cc_mstreami;
    reg  [`STREAM_MOPORT(`MAILBOX_STREAM_SIZE)] cc_mstreamo;

    wire [`STREAM_MIPORT(`MAILBOX_STREAM_SIZE)] core_mstreami;
    wire [`STREAM_MOPORT(`MAILBOX_STREAM_SIZE)] core_mstreamo;

    wire [`STREAM_MIPORT(`SHADED_VERTEX_WIDTH)] core_deser_mstreami;
    wire [`STREAM_MOPORT(`SHADED_VERTEX_WIDTH)] core_deser_mstreamo;

    reg svc_clear;

    reg  [`WORD] test_index;
    reg  test_valid;
    wire test_found;

    reg  [`SHADED_VERTEX] store_vertex;
    reg  [`WORD] store_index;
    reg  store_valid;

    wire [`STREAM_MIPORT(`SHADED_VERTEX_WIDTH)] svc_mstreami;
    wire [`STREAM_MOPORT(`SHADED_VERTEX_WIDTH)] svc_mstreamo;

    wire [`STREAM_MIPORT(1)] order_mstreami;
    wire [`STREAM_MOPORT(1)] order_mstreamo;

    wire [`STREAM_MIPORT(3 * `SHADED_VERTEX_WIDTH)] vrc_mstreami;
    wire [`STREAM_MOPORT(3 * `SHADED_VERTEX_WIDTH)] vrc_mstreamo;

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

    core_m #(.SP(0)) core(
        .clk_i(clk),
        .nrst_i(nrst),

        .inst_i(inst),
        .global_r1_data_i(global_r1),
        .global_r2_data_i(global_r2),

        .jump_request_o(jump_request),
        .flush_dec_stage_i(fds),

        .stall_i(stalli),
        .stall_o(stallo),

        .nsync_rst_i(nsync_rst),

        .inbox_sstream_i(cc_mstreamo),
        .inbox_sstream_o(cc_mstreami),

        .outbox_mstream_i(core_mstreami),
        .outbox_mstream_o(core_mstreamo)
    );

    vertex_deserializer_m core_deserializer(
        .clk_i(clk),
        .nrst_i(nrst),

        .sstream_i(core_mstreamo),
        .sstream_o(core_mstreami),

        .mstream_i(core_deser_mstreami),
        .mstream_o(core_deser_mstreamo)
    );

    shaded_vertex_cache_m #(6) svc(
        .clk_i(clk),
        .nrst_i(nrst),

        .clear_i(svc_clear),

        .test_index_i(test_index),
        .test_valid_i(test_valid),
        .test_found_o(test_found),

        .store_vertex_i(store_vertex),
        .store_index_i(store_index),
        .store_valid_i(store_valid),

        .mstream_i(svc_mstreami),
        .mstream_o(svc_mstreamo)
    );

    vertex_reorder_controller_m #(2) vrc(
        .clk_i(clk),
        .nrst_i(nrst),

        .order_sstream_i(order_mstreamo),
        .order_sstream_o(order_mstreami),

        .sstreams_i({ svc_mstreamo, core_deser_mstreamo }),
        .sstreams_o({ svc_mstreami, core_deser_mstreami }),

        .mstream_i(vrc_mstreami),
        .mstream_o(vrc_mstreamo)
    );

    rasterizer_wrapper_m rasterizer(
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .wbs_stb_i(wbs_stbN_i[1]),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_we_i(wbs_we_i),
        .wbs_sel_i(wbs_sel_i),
        .wbs_dat_i(wbs_dat_i),
        .wbs_adr_i(wbs_adr_i),
        .wbs_ack_o(wbs_ackN_o[1]),
        .wbs_dat_o(wbs_datN_o[1]),

        .sstream_i(vrc_mstreamo),
        .sstream_o(vrc_mstreami),

        .depth_mport_i(rast1_mporti),
        .depth_mport_o(rast1_mporto),

        .pix_mport_i(rast2_mporti),
        .pix_mport_o(rast2_mporto),

        .tex_mport_i(rast3_mporti),
        .tex_mport_o(rast3_mporto)
    );

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

    initial begin
        inst = 0;

        global_r2 = 0;

        jump_request = 0;
        fds = 0;

        stalli = 0;
        stallo = 0;

        nsync_rst = 0;

        svc_clear = 0;

        test_index = 0;
        test_valid = 0;

        store_vertex = 0;
        store_index = 0;
        store_valid = 0;

        #1000;

    end


endmodule
