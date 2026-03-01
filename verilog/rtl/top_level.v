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

    localparam integer NUM_ADDRS = 4;
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

        `address_map(0, 32'h38000000, 32'hF8000000); // VGA
        `address_map(1, 32'h30000000, 32'hF8000000); // Rasterizer
        `address_map(2, 32'h28000000, 32'hF8000000); // Core Control
        `address_map(3, 32'h20000000, 32'hF8000000); // Core IMem
    end

    wire [`BUS_MIPORT] vga_mporti;
    wire [`BUS_MOPORT] vga_mporto;

    wire [`BUS_MIPORT] rast1_mporti;
    wire [`BUS_MOPORT] rast1_mporto;

    wire [`BUS_MIPORT] rast2_mporti;
    wire [`BUS_MOPORT] rast2_mporto;

    wire [`BUS_MIPORT] core_mporti;
    wire [`BUS_MOPORT] core_mporto;

    wire [`BUS_MIPORT] cc_mporti;
    wire [`BUS_MOPORT] cc_mporto;

    wire [`BUS_MIPORT] write_mporti;
    wire [`BUS_MOPORT] write_mporto;

    wire [`BUS_SIPORT] spi1_sporti;
    wire [`BUS_SOPORT] spi1_sporto;

    wire [`BUS_SIPORT] spi2_sporti;
    wire [`BUS_SOPORT] spi2_sporto;

    wire [`WORD] inst;

    wire [`WORD] global_r1, global_r2;

    wire jump_request;
    wire fds;

    wire stalli;
    wire stallo;

    wire nsync_rst;

    wire [`STREAM_MIPORT(`MAILBOX_STREAM_SIZE)] cc_mstreami;
    wire [`STREAM_MOPORT(`MAILBOX_STREAM_SIZE)] cc_mstreamo;

    wire [`STREAM_MIPORT(`MAILBOX_STREAM_SIZE)] core_mstreami;
    wire [`STREAM_MOPORT(`MAILBOX_STREAM_SIZE)] core_mstreamo;

    wire [`STREAM_MIPORT(`SHADED_VERTEX_WIDTH)] core_deser_mstreami;
    wire [`STREAM_MOPORT(`SHADED_VERTEX_WIDTH)] core_deser_mstreamo;

    wire svc_clear;
    assign svc_clear = 0;

    wire [`WORD] test_index;
    wire test_valid;
    wire test_found;

    wire [`SHADED_VERTEX] store_vertex;
    wire [`WORD] store_index;
    wire store_valid;
    assign store_index = 0;

    wire vob_full, vob_empty;

    wire [`STREAM_MIPORT(`SHADED_VERTEX_WIDTH)] svc_mstreami;
    wire [`STREAM_MOPORT(`SHADED_VERTEX_WIDTH)] svc_mstreamo;
    wire [`STREAM_MIPORT(`SHADED_VERTEX_WIDTH)] svb_mstreami;
    wire [`STREAM_MOPORT(`SHADED_VERTEX_WIDTH)] svb_mstreamo;

    wire [`STREAM_MIPORT(`ORDER_STREAM_WIDTH)] order_mstreami;
    wire [`STREAM_MOPORT(`ORDER_STREAM_WIDTH)] order_mstreamo;
    wire [`STREAM_MIPORT(`ORDER_STREAM_WIDTH)] vob_mstreami;
    wire [`STREAM_MOPORT(`ORDER_STREAM_WIDTH)] vob_mstreamo;

    wire [`STREAM_MIPORT(3 * `SHADED_VERTEX_WIDTH)] vrc_mstreami;
    wire [`STREAM_MOPORT(3 * `SHADED_VERTEX_WIDTH)] vrc_mstreamo;

    wire [`STREAM_MIPORT(`FRAGMENT_WIDTH)] frag_mstreami;
    wire [`STREAM_MOPORT(`FRAGMENT_WIDTH)] frag_mstreamo;

    busarb_m #(6, 2, 2) arbiter(
        .clk_i(clk),
        .nrst_i(nrst),

        .mports_i({ cc_mporto, write_mporto, core_mporto, rast2_mporto, rast1_mporto, vga_mporto }),
        .mports_o({ cc_mporti, write_mporti, core_mporti, rast2_mporti, rast1_mporti, vga_mporti }),

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

    core_controller_wrapper_m #(
        .INDEX_FETCH_CACHE_LEN_WORDS(64),
        .CALL_STACK_LEN(8)
    ) core_cont (
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_we_i(wbs_we_i),
        .wbs_sel_i(wbs_sel_i),
        .wbs_dat_i(wbs_dat_i),
        .wbs_adr_i(wbs_adr_i),

        .wbs_stb_control_i(wbs_stbN_i[2]),
        .wbs_ack_control_o(wbs_ackN_o[2]),
        .wbs_dat_control_o(wbs_datN_o[2]),

        .wbs_stb_imem_i(wbs_stbN_i[3]),
        .wbs_ack_imem_o(wbs_ackN_o[3]),
        .wbs_dat_imem_o(wbs_datN_o[3]),

        .irq_jobdone_o(),
        .irq_batchdone_o(),

        .mport_i(cc_mporti),
        .mport_o(cc_mporto),

        .vertcache_test_index_o(test_index),
        .vertcache_test_valid_o(test_valid),
        .vertcache_test_found_i(test_found),

        .vertorder_sstreamo_i(order_mstreami),
        .vertorder_sstreami_o(order_mstreamo),
        .vertorder_full_i(vob_full),
        .vertorder_empty_i(vob_empty),

        .fragfifo_full_i(1'b0),
        .fragfifo_cores_dispatched_i(1'b0), // Number of cores with a fragment in their inbox

        .inst_o(inst),
        .core_reset_o(nsync_rst), // Core soft reset
        .core_stall_i(stallo),
        .core_stall_o(stalli), // Per-core stall control
        .core_jump_i(jump_request),
        .core_jump_o(fds),  // Flushes decode on all cores
        .global_regfile_rs1_data_o(global_r1),
        .global_regfile_rs2_data_o(global_r2)
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
        .outbox_mstream_o(core_mstreamo),

        .mport_i(core_mporti),
        .mport_o(core_mporto)
    );

    vertex_deserializer_m core_deserializer(
        .clk_i(clk),
        .nrst_i(nrst),

        .sstream_i(core_mstreamo),
        .sstream_o(core_mstreami),

        .mstream_i(core_deser_mstreami),
        .mstream_o(core_deser_mstreamo)
    );

    // assign store_valid = core_deser_mstreamo[`STREAM_MO_VALID(`SHADED_VERTEX_WIDTH)];
    assign store_valid = 0;
    assign store_vertex = core_deser_mstreamo[`STREAM_MO_DATA(`SHADED_VERTEX_WIDTH)];

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

    stream_fifo_m #(`SHADED_VERTEX_WIDTH, 10) svb(
        .clk_i(clk),
        .nrst_i(nrst),

        .sstream_i(svc_mstreamo),
        .sstream_o(svc_mstreami),

        .mstream_i(svb_mstreami),
        .mstream_o(svb_mstreamo)
    );

    vertex_order_buffer_m #(6, `ORDER_STREAM_WIDTH) vob(
        .clk_i(clk),
        .nrst_i(nrst),

        .sstream_i(order_mstreamo),
        .sstream_o(order_mstreami),

        .mstream_i(vob_mstreami),
        .mstream_o(vob_mstreamo),

        .full_o(vob_full),
        .empty_o(vob_empty)
    );

    vertex_reorder_controller_m #(`NUM_CORES + 1) vrc(
        .clk_i(clk),
        .nrst_i(nrst),

        .order_sstream_i(vob_mstreamo),
        .order_sstream_o(vob_mstreami),

        .sstreams_i({ svb_mstreamo, core_deser_mstreamo }),
        .sstreams_o({ svb_mstreami, core_deser_mstreami }),

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

        .mstream_i(frag_mstreami),
        .mstream_o(frag_mstreamo),

        .depth_mport_i(rast1_mporti),
        .depth_mport_o(rast1_mporto),

        .tex_mport_i(rast2_mporti),
        .tex_mport_o(rast2_mporto)
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

    mem_write_m mem_write(
        .clk_i(clk),
        .nrst_i(nrst),

        .busy_o(),

        .sstream_i(frag_mstreamo),
        .sstream_o(frag_mstreami),

        .mport_i(write_mporti),
        .mport_o(write_mporto),

        .fb_i(1'b0)
    );

endmodule
