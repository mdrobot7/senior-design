`default_nettype none

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

    wire clk, nrst;
    assign clk = wb_clk_i;
    assign nrst = !wb_rst_i;

    localparam integer NUM_ADDRS = 10;
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

        `address_map(0, 32'h30000000, 32'hFF000000); // VGA
        `address_map(1, 32'h31000000, 32'hFF000000); // Rasterizer
        `address_map(2, 32'h32000000, 32'hFF000000); // Core Control
        `address_map(3, 32'h33000000, 32'hFF000000); // Core IMem
        `address_map(4, 32'h34000000, 32'hFF000000); // QSPI Mem Data 1 (bridge)
        `address_map(5, 32'h37000000, 32'hFF000000); // QSPI Mem Data 2 (bridge)
        `address_map(6, 32'h38000000, 32'hFF000000); // QSPI Mem Data 3 (bridge)
        `address_map(7, 32'h35000000, 32'hFF000000); // Corespy
        `address_map(8, 32'h36000000, 32'hFF000000); // Multinator
        `address_map(9, 32'h39000000, 32'hFF000000); // cache
    end

    wire [`BUS_MIPORT] vga_mporti;
    wire [`BUS_MOPORT] vga_mporto;

    wire [`BUS_MIPORT] rast1_mporti;
    wire [`BUS_MOPORT] rast1_mporto;

    wire [`BUS_MIPORT] rast2_mporti;
    wire [`BUS_MOPORT] rast2_mporto;

    wire [(`BUS_MIPORT_SIZE * `NUM_CORES)-1:0] core_mporti;
    wire [(`BUS_MOPORT_SIZE * `NUM_CORES)-1:0] core_mporto;
    wire [(`BUS_MIPORT_SIZE * `NUM_CORES)-1:0] core_coal_mporti;
    wire [(`BUS_MOPORT_SIZE * `NUM_CORES)-1:0] core_coal_mporto;

    wire [`BUS_MIPORT] cache_mporti;
    wire [`BUS_MOPORT] cache_mporto;
    wire [`BUS_SIPORT] cache_sporti;
    wire [`BUS_SOPORT] cache_sporto;

    wire [`BUS_MIPORT] cc_mporti;
    wire [`BUS_MOPORT] cc_mporto;

    wire [`BUS_MIPORT] bridge1_mporti;
    wire [`BUS_MOPORT] bridge1_mporto;
    wire [`BUS_MIPORT] bridge2_mporti;
    wire [`BUS_MOPORT] bridge2_mporto;
    wire [`BUS_MIPORT] bridge3_mporti;
    wire [`BUS_MOPORT] bridge3_mporto;

    wire [`BUS_SIPORT] spi0_sporti;
    wire [`BUS_SOPORT] spi0_sporto;

    wire [`BUS_SIPORT] spi1_sporti;
    wire [`BUS_SOPORT] spi1_sporto;

    wire [`BUS_SIPORT] spi2_sporti;
    wire [`BUS_SOPORT] spi2_sporto;

    wire [`BUS_SIPORT] dummy_sporti;
    wire [`BUS_SOPORT] dummy_sporto;

    // Core Controller - Cores
    wire [`WORD]          inst;
    wire [`WORD]          global_r1, global_r2;
    wire [`NUM_CORES-1:0] jump_request;
    wire                  fds;
    wire [`NUM_CORES-1:0] stalli;
    wire [`NUM_CORES-1:0] stallo;
    wire [`NUM_CORES-1:0] nsync_rst;
    wire [`NUM_CORES-1:0] nsync_rst_mailbox;

    wire [(`STREAM_MIPORT_SIZE(`MAILBOX_STREAM_SIZE) * `NUM_CORES)-1:0] inbox_mstreami;
    wire [(`STREAM_MOPORT_SIZE(`MAILBOX_STREAM_SIZE) * `NUM_CORES)-1:0] inbox_mstreamo;

    wire [(`STREAM_MIPORT_SIZE(`MAILBOX_STREAM_SIZE) * `NUM_CORES)-1:0] outbox_mstreami;
    wire [(`STREAM_MOPORT_SIZE(`MAILBOX_STREAM_SIZE) * `NUM_CORES)-1:0] outbox_mstreamo;

    wire [(`STREAM_MIPORT_SIZE(`SHADED_VERTEX_WIDTH) * `NUM_CORES)-1:0] core_deser_mstreami;
    wire [(`STREAM_MOPORT_SIZE(`SHADED_VERTEX_WIDTH) * `NUM_CORES)-1:0] core_deser_mstreamo;

    wire         svc_clear;
    wire [`WORD] svc_test_index;
    wire         svc_test_valid;
    wire         svc_test_found;

    wire [`SHADED_VERTEX] svc_store_vertex;
    wire [`WORD]          svc_store_index;
    wire                  svc_store_valid;

    wire vob_full;
    wire vob_empty;
    wire vob_clear;

    wire rast_busy;
    wire mem_busy;
    wire vrc_busy;

    wire [`STREAM_MIPORT(`SHADED_VERTEX_WIDTH)] svc_mstreami;
    wire [`STREAM_MOPORT(`SHADED_VERTEX_WIDTH)] svc_mstreamo;
    wire [`STREAM_MIPORT(`SHADED_VERTEX_WIDTH)] svb_mstreami;
    wire [`STREAM_MOPORT(`SHADED_VERTEX_WIDTH)] svb_mstreamo;

    wire [`STREAM_MIPORT(`VERTEX_ORDER_WIDTH)] order_mstreami;
    wire [`STREAM_MOPORT(`VERTEX_ORDER_WIDTH)] order_mstreamo;
    wire [`STREAM_MIPORT(`VERTEX_ORDER_WIDTH)] vob_mstreami;
    wire [`STREAM_MOPORT(`VERTEX_ORDER_WIDTH)] vob_mstreamo;

    wire [`STREAM_MIPORT(3 * `SHADED_VERTEX_WIDTH)] vrc_mstreami;
    wire [`STREAM_MOPORT(3 * `SHADED_VERTEX_WIDTH)] vrc_mstreamo;

    wire [`STREAM_MIPORT(`FRAGMENT_WIDTH)] frag_mstreami;
    wire [`STREAM_MOPORT(`FRAGMENT_WIDTH)] frag_mstreamo;

    wire [`STREAM_MIPORT(`WORD_WIDTH)] index_mstreami, buf_index_mstreami;
    wire [`STREAM_MOPORT(`WORD_WIDTH)] index_mstreamo, buf_index_mstreamo;

    // Core Controller - Fragment FIFO
    wire fragfifo_full;
    wire fragfifo_empty;
    wire fragfifo_clear;

    reg [`NUM_CORES-1:0] core_outbox_mstream_valid;

    wire core_cont_batchdone_irq;
    wire core_cont_jobdone_irq;
    wire core_cont_irq = core_cont_batchdone_irq | core_cont_jobdone_irq;
    wire vga_hblank_irq;
    wire vga_vblank_irq;
    wire vga_irq = vga_hblank_irq | vga_vblank_irq;

    assign user_irq = {1'b0, core_cont_irq, vga_irq};

    main_busarb_m arb_main (
        .clk_i(clk),
        .nrst_i(nrst),

        .mports_i({ cc_mporto, cache_mporto, rast2_mporto, rast1_mporto, bridge3_mporto, bridge2_mporto, bridge1_mporto, vga_mporto }),
        .mports_o({ cc_mporti, cache_mporti, rast2_mporti, rast1_mporti, bridge3_mporti, bridge2_mporti, bridge1_mporti, vga_mporti }),

        .sports_i({ spi0_sporto, spi1_sporto, spi2_sporto }),
        .sports_o({ spi0_sporti, spi1_sporti, spi2_sporti })
    );

    core_busarb_m arb_cores (
        .clk_i(clk),
        .nrst_i(nrst),

        .mports_i(core_coal_mporto),
        .mports_o(core_coal_mporti),

        .sports_i(cache_sporto),
        .sports_o(cache_sporti)
    );

    spi_block_m spi_block(
        .clk_i(clk),
        .nrst_i(nrst),

        .sport0_i(spi0_sporti),
        .sport0_o(spi0_sporto),
        .sport1_i(spi1_sporti),
        .sport1_o(spi1_sporto),
        .sport2_i(spi2_sporti),
        .sport2_o(spi2_sporto),

        .spi0_clk_o(spi0_clk_o),
        .spi0_cs_o(spi0_cs_o),
        .spi0_mosi_o(spi0_mosi_o),
        .spi0_miso_i(spi0_miso_i),
        .spi0_dqsm_i(spi0_dqsm_i),
        .spi0_dqsm_o(spi0_dqsm_o),

        .spi0_sio_en_o(spi0_sio_en_o),
        .spi0_dqsm_en_o(spi0_dqsm_en_o),

        .spi1_clk_o(spi1_clk_o),
        .spi1_cs_o(spi1_cs_o),
        .spi1_mosi_o(spi1_mosi_o),
        .spi1_miso_i(spi1_miso_i),
        .spi1_dqsm_i(spi1_dqsm_i),
        .spi1_dqsm_o(spi1_dqsm_o),

        .spi1_sio_en_o(spi1_sio_en_o),
        .spi1_dqsm_en_o(spi1_dqsm_en_o),

        .spi2_clk_o(spi2_clk_o),
        .spi2_cs_o(spi2_cs_o),
        .spi2_mosi_o(spi2_mosi_o),
        .spi2_miso_i(spi2_miso_i),
        .spi2_dqsm_i(spi2_dqsm_i),
        .spi2_dqsm_o(spi2_dqsm_o),

        .spi2_sio_en_o(spi2_sio_en_o),
        .spi2_dqsm_en_o(spi2_dqsm_en_o)
    );


    // spi_mem_m #(2 * `SPI_MEM_SIZE, `SPI_MEM_SIZE) spi_mem0(
        // .clk_i(clk),
        // .nrst_i(nrst),

        // .sport_i(spi0_sporti),
        // .sport_o(spi0_sporto),

        // .spi_clk_o(spi0_clk_o),
        // .spi_cs_o(spi0_cs_o),
        // .spi_mosi_o(spi0_mosi_o),
        // .spi_miso_i(spi0_miso_i),
        // .spi_dqsm_i(spi0_dqsm_i),
        // .spi_dqsm_o(spi0_dqsm_o),

        // .spi_sio_en_o(spi0_sio_en_o),
        // .spi_dqsm_en_o(spi0_dqsm_en_o)
    // );

    // spi_mem_m #(0 * `SPI_MEM_SIZE, `SPI_MEM_SIZE) spi_mem1(
        // .clk_i(clk),
        // .nrst_i(nrst),

        // .sport_i(spi1_sporti),
        // .sport_o(spi1_sporto),

        // .spi_clk_o(spi1_clk_o),
        // .spi_cs_o(spi1_cs_o),
        // .spi_mosi_o(spi1_mosi_o),
        // .spi_miso_i(spi1_miso_i),
        // .spi_dqsm_i(spi1_dqsm_i),
        // .spi_dqsm_o(spi1_dqsm_o),

        // .spi_sio_en_o(spi1_sio_en_o),
        // .spi_dqsm_en_o(spi1_dqsm_en_o)
    // );

    // spi_mem_m #(1 * `SPI_MEM_SIZE, `SPI_MEM_SIZE) spi_mem2(
        // .clk_i(clk),
        // .nrst_i(nrst),

        // .sport_i(spi2_sporti),
        // .sport_o(spi2_sporto),

        // .spi_clk_o(spi2_clk_o),
        // .spi_cs_o(spi2_cs_o),
        // .spi_mosi_o(spi2_mosi_o),
        // .spi_miso_i(spi2_miso_i),
        // .spi_dqsm_i(spi2_dqsm_i),
        // .spi_dqsm_o(spi2_dqsm_o),

        // .spi_sio_en_o(spi2_sio_en_o),
        // .spi_dqsm_en_o(spi2_dqsm_en_o)
    // );

    // dummy_slave_m #(`SPI_MEM_SIZE * 3, 32'hFFFFFFFF - `SPI_MEM_SIZE * 3) dummy_slave(
    //     .clk_i(clk),
    //     .nrst_i(nrst),

    //     .sport_i(dummy_sporti),
    //     .sport_o(dummy_sporto)
    // );

    wire busy;
    assign busy = rast_busy;
    reg  _delayed_busy;
    wire delayed_busy;
    assign delayed_busy = _delayed_busy || busy;
    reg [9:0] timer;

    always @(posedge clk, negedge nrst) begin
        if (!nrst) begin
            _delayed_busy <= 0;
            timer         <= 0;
        end
        else if (clk) begin
            if (busy) begin
                _delayed_busy <= 1;

                timer <= 0;
            end
            else begin
                if (timer == 1023) begin
                    _delayed_busy <= 0;
                end
                else begin
                    timer <= timer + 1;
                end
            end
        end
    end

    // cache_wrapper_m #(16) cache (
        // .wb_clk_i(wb_clk_i),
        // .wb_rst_i(wb_rst_i),
        // .wbs_stb_i(wbs_stbN_i[9]),
        // .wbs_cyc_i(wbs_cyc_i),
        // .wbs_we_i(wbs_we_i),
        // .wbs_sel_i(wbs_sel_i),
        // .wbs_dat_i(wbs_dat_i),
        // .wbs_adr_i(wbs_adr_i),
        // .wbs_ack_o(wbs_ackN_o[9]),
        // .wbs_dat_o(wbs_datN_o[9]),

        // .s_core_i(cache_sporti),
        // .s_core_o(cache_sporto),

        // .m_mem_i(cache_mporti),
        // .m_mem_o(cache_mporto)
    // );
    assign wbs_ackN_o[9] = 0;
    assign wbs_datN_o[9] = 0;
    assign cache_mporto = cache_sporti;
    assign cache_sporto = cache_mporti;

    core_controller_wrapper_m core_cont (
`ifdef USE_POWER_PINS
    	.vccd1(vccd1),
    	.vssd1(vssd1),
`endif

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

        .irq_jobdone_o(core_cont_jobdone_irq),
        .irq_batchdone_o(core_cont_batchdone_irq),

        .mport_i(cc_mporti),
        .mport_o(cc_mporto),

        .vertcache_test_index_o(svc_test_index),
        .vertcache_test_valid_o(svc_test_valid),
        .vertcache_test_found_i(svc_test_found),
        .vertcache_clear_o(svc_clear),

        .index_mstream_i(index_mstreami),
        .index_mstream_o(index_mstreamo),

        .vertorder_mstream_i(order_mstreami),
        .vertorder_mstream_o(order_mstreamo),
        .vertorder_full_i(vob_full),
        .vertorder_empty_i(vob_empty),
        .vertorder_clear_o(vob_clear),

        .vertcont_busy_i(vrc_busy),

        .fragfifo_full_i(fragfifo_full),
        .fragfifo_empty_i(fragfifo_empty),
        .fragfifo_clear_o(fragfifo_clear),

        .rast_busy_i(delayed_busy),

        .inst_o(inst),
        .core_reset_o(nsync_rst), // Core soft reset
        .core_reset_mailbox_o(nsync_rst_mailbox),
        .core_stall_i(stallo),
        .core_stall_o(stalli), // Per-core stall control
        .core_jump_i(jump_request),
        .core_jump_o(fds),  // Flushes decode on all cores
        .global_regfile_rs1_data_o(global_r1),
        .global_regfile_rs2_data_o(global_r2),

        .core_inbox_mstream_i(inbox_mstreami),
        .core_outbox_mstream_valid_i(core_outbox_mstream_valid)
    );

    always @(*) begin : CORE_STREAM_COMB
        integer i;
        for (i = 0; i < `NUM_CORES; i = i + 1) begin
            core_outbox_mstream_valid[i] = outbox_mstreamo[`STREAM_MOPORT_SIZE(`MAILBOX_STREAM_SIZE) * i + `STREAM_MO_VALID(`MAILBOX_STREAM_SIZE)];
        end
    end

    address_coalescer_m coal (
        .core_port_i(core_mporto),
        .core_port_o(core_mporti),
        .arb_port_i(core_coal_mporti),
        .arb_port_o(core_coal_mporto)
    );

    generate begin : CORES
        genvar i;
        for (i = 0; i < `NUM_CORES; i = i + 1) begin : CORES_GENLOOP
            // core_m #(.SP(32'h00000400 * i)) core (
            core_m core (
                .clk_i(clk),
                .nrst_i(nrst),

                .SP_i(32'h00000400 * i),

                .inst_i(inst),
                .global_r1_data_i(global_r1),
                .global_r2_data_i(global_r2),

                .jump_request_o(jump_request[i]),
                .flush_dec_stage_i(fds),

                .stall_i(stalli[i]),
                .stall_o(stallo[i]),

                .nsync_rst_i(nsync_rst[i]),
                .nsync_rst_mailbox_i(nsync_rst_mailbox[i]),

                .inbox_sstream_i(inbox_mstreamo[`STREAM_MOPORT_SIZE(`MAILBOX_STREAM_SIZE) * i +: `STREAM_MOPORT_SIZE(`MAILBOX_STREAM_SIZE)]),
                .inbox_sstream_o(inbox_mstreami[`STREAM_MIPORT_SIZE(`MAILBOX_STREAM_SIZE) * i +: `STREAM_MIPORT_SIZE(`MAILBOX_STREAM_SIZE)]),

                .outbox_mstream_i(outbox_mstreami[`STREAM_MIPORT_SIZE(`MAILBOX_STREAM_SIZE) * i +: `STREAM_MIPORT_SIZE(`MAILBOX_STREAM_SIZE)]),
                .outbox_mstream_o(outbox_mstreamo[`STREAM_MOPORT_SIZE(`MAILBOX_STREAM_SIZE) * i +: `STREAM_MOPORT_SIZE(`MAILBOX_STREAM_SIZE)]),

                .mport_i(core_mporti[`BUS_MIPORT_SIZE * i +: `BUS_MIPORT_SIZE]),
                .mport_o(core_mporto[`BUS_MOPORT_SIZE * i +: `BUS_MOPORT_SIZE])
            );
        end
    end endgenerate

    pre_rasterizer_m pre_rasterizer(
        .clk_i(clk),
        .nrst_i(nrst),

        .vob_full_o(vob_full),
        .vob_empty_o(vob_empty),
        .vob_clear_i(vob_clear),

        .vrc_busy_o(vrc_busy),

        .order_sstream_i(order_mstreamo),
        .order_sstream_o(order_mstreami),

        .outbox_sstream_i(outbox_mstreamo),
        .outbox_sstream_o(outbox_mstreami),

        .mstream_i(vrc_mstreami),
        .mstream_o(vrc_mstreamo)
    );

    // vertex_deserializer_m core_deserializer [`NUM_CORES-1:0] (
        // .clk_i(clk),
        // .nrst_i(nrst),

        // .sstream_i(outbox_mstreamo),
        // .sstream_o(outbox_mstreami),

        // .mstream_i(core_deser_mstreami),
        // .mstream_o(core_deser_mstreamo)
    // );

    // assign svc_mstreamo = 0;
    // assign svc_test_found = 0;
    // assign svc_store_valid = 0;
    // assign buf_index_mstreami[`STREAM_MI_READY(`WORD_WIDTH)] = svc_store_valid;
    // assign svc_store_index = buf_index_mstreamo[`STREAM_MO_DATA(`WORD_WIDTH)];
    // assign svb_mstreamo = 0;

    // vertex_order_buffer_m #(`VOB_SIZE, `VERTEX_ORDER_WIDTH) vob(
        // .clk_i(clk),
        // .nrst_i(nrst),

        // .sstream_i(order_mstreamo),
        // .sstream_o(order_mstreami),

        // .mstream_i(vob_mstreami),
        // .mstream_o(vob_mstreamo),

        // .full_o(vob_full),
        // .empty_o(vob_empty),
        // .clear_i(vob_clear)
    // );

    // vertex_reorder_controller_m #(`NUM_CORES + 1) vrc(
        // .clk_i(clk),
        // .nrst_i(nrst),

        // .busy_o(vrc_busy),

        // .order_sstream_i(vob_mstreamo),
        // .order_sstream_o(vob_mstreami),

        // .sstreams_i({ svb_mstreamo, core_deser_mstreamo }),
        // .sstreams_o({ svb_mstreami, core_deser_mstreami }),

        // .mstream_i(vrc_mstreami),
        // .mstream_o(vrc_mstreamo),

        // .svc_store_vertex_o(svc_store_vertex),
        // .svc_store_valid_o()
    // );

    serializing_mailman_m mailman (
        .clk_i(clk),
        .nrst_i(nrst),

        .sstream_i(frag_mstreamo),
        .sstream_o(frag_mstreami),
        .mstream_i(inbox_mstreami),
        .mstream_o(inbox_mstreamo),

        .empty_o(fragfifo_empty),
        .full_o(fragfifo_full),
        .done_mailing_o(),
        .selind_o(),

        .clear_i(fragfifo_clear)
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

        .rast_busy_o(rast_busy),

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

        .irq_hblank_o(vga_hblank_irq),
        .irq_vblank_o(vga_vblank_irq),

        .mport_i(vga_mporti),
        .mport_o(vga_mporto),

        .pixel_o({ blue_o, green_o, red_o }),
        .hsync_o(hsync_o),
        .vsync_o(vsync_o)
    );

    wb_to_pk_m bridge1
    (
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),

        .wbs_stb_i(wbs_stbN_i[4]),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_sel_i(wbs_sel_i),
        .wbs_ack_o(wbs_ackN_o[4]),
        .wbs_dat_i(wbs_dat_i),
        .wbs_adr_i(wbs_adr_i),
        .wbs_dat_o(wbs_datN_o[4]),
        .wbs_we_i(wbs_we_i),

        .mport_i(bridge1_mporti),
        .mport_o(bridge1_mporto)
    );

    wb_to_pk_m bridge2
    (
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),

        .wbs_stb_i(wbs_stbN_i[5]),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_sel_i(wbs_sel_i),
        .wbs_ack_o(wbs_ackN_o[5]),
        .wbs_dat_i(wbs_dat_i),
        .wbs_adr_i(wbs_adr_i),
        .wbs_dat_o(wbs_datN_o[5]),
        .wbs_we_i(wbs_we_i),

        .mport_i(bridge2_mporti),
        .mport_o(bridge2_mporto)
    );

    wb_to_pk_m bridge3
    (
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),

        .wbs_stb_i(wbs_stbN_i[6]),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_sel_i(wbs_sel_i),
        .wbs_ack_o(wbs_ackN_o[6]),
        .wbs_dat_i(wbs_dat_i),
        .wbs_adr_i(wbs_adr_i),
        .wbs_dat_o(wbs_datN_o[6]),
        .wbs_we_i(wbs_we_i),

        .mport_i(bridge3_mporti),
        .mport_o(bridge3_mporto)
    );

    // `ifdef FPGA
    // `CORE_SPY(0, wbs_stbN_i[7], wbs_ackN_o[7], wbs_datN_o[7]);
    // `endif
    assign wbs_ackN_o[7] = 0;
    assign wbs_datN_o[7] = 0;

    wb_mul_accel_m mul_accel(
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),

        .wbs_stb_i(wbs_stbN_i[8]),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_sel_i(wbs_sel_i),
        .wbs_ack_o(wbs_ackN_o[8]),
        .wbs_dat_i(wbs_dat_i),
        .wbs_adr_i(wbs_adr_i),
        .wbs_dat_o(wbs_datN_o[8]),
        .wbs_we_i(wbs_we_i)
    );

endmodule
