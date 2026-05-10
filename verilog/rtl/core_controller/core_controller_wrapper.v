module core_controller_wrapper_m #(
    parameter INDEX_FETCH_CACHE_LEN_WORDS = 2 * `NUM_CORES,
    parameter CALL_STACK_LEN = 8
) (
`ifdef USE_POWER_PINS
    inout wire vccd1,
    inout wire vssd1,
`endif

    // Wishbone (common)
    input wire wb_clk_i,
    input wire wb_rst_i,
    input wire wbs_cyc_i,
    input wire wbs_we_i,
    input wire [3:0] wbs_sel_i,
    input wire [`WORD_WIDTH-1:0] wbs_dat_i,
    input wire [`WORD_WIDTH-1:0] wbs_adr_i,

    // Wishbone (control registers)
    input wire wbs_stb_control_i,
    output reg wbs_ack_control_o,
    output reg [`WORD_WIDTH-1:0] wbs_dat_control_o,

    // Wishbone (IMEM)
    input  wire wbs_stb_imem_i,
    output wire wbs_ack_imem_o,
    output wire [`WORD_WIDTH-1:0] wbs_dat_imem_o,

    // IRQs
    output wire irq_jobdone_o,
    output wire irq_batchdone_o,

    // PKBus
    input  wire [`BUS_MIPORT] mport_i,
    output wire [`BUS_MOPORT] mport_o,

    // Shaded vertex cache
    output wire [`WORD] vertcache_test_index_o,
    output wire         vertcache_test_valid_o,
    input  wire         vertcache_test_found_i,
    output wire         vertcache_clear_o,

    // Vertex order buffer
    input  wire [`STREAM_MIPORT(`VERTEX_ORDER_WIDTH)] vertorder_mstream_i,
    output wire [`STREAM_MOPORT(`VERTEX_ORDER_WIDTH)] vertorder_mstream_o,
    input  wire                                       vertorder_full_i,
    input  wire                                       vertorder_empty_i,
    output wire                                       vertorder_clear_o,

    // Vertex reorder controller
    input wire vertcont_busy_i,

    // index buffer
    input  wire [`STREAM_MIPORT(`WORD_WIDTH)] index_mstream_i,
    output wire [`STREAM_MOPORT(`WORD_WIDTH)] index_mstream_o,

    // Rasterizer fragment output FIFO
    input  wire fragfifo_full_i,
    input  wire fragfifo_empty_i,
    output wire fragfifo_clear_o,

    // Rasterizer
    input wire rast_busy_i,

    // Shader core interface
    output wire [`WORD]           inst_o,
    output wire [`NUM_CORES-1:0]  core_reset_o,         // Core soft reset
    output wire [`NUM_CORES-1:0]  core_reset_mailbox_o, // Core mailbox soft reset
    input  wire [`NUM_CORES-1:0]  core_stall_i,
    output wire [`NUM_CORES-1:0]  core_stall_o,         // Per-core stall control
    input  wire [`NUM_CORES-1:0]  core_jump_i,
    output wire                   core_jump_o,          // Flushes decode on all cores
    output wire [`WORD]           global_regfile_rs1_data_o,
    output wire [`WORD]           global_regfile_rs2_data_o,

    input  wire [`STREAM_MIPORT_SIZE(`MAILBOX_STREAM_SIZE) * `NUM_CORES - 1:0] core_inbox_mstream_i,
    input  wire [`NUM_CORES-1:0] core_outbox_mstream_valid_i
);

    localparam NUM_CONTROL_REGS = 16;
    localparam NUM_REGS         = NUM_CONTROL_REGS + `NUM_GLOBAL_REGS;

    reg  [NUM_CONTROL_REGS-1:0] wbs_stbN;
    wire [NUM_CONTROL_REGS-1:0] wbs_ackN;
    wire [`WORD_WIDTH-1:0]      wbs_datN [NUM_CONTROL_REGS-1:0];

    wire                         imem_rw;
    wire [`WORD]                 imem_do;
    wire [`WORD]                 imem_di;
    wire [`SRAM_1024x32_ADDR_WIDTH-1:0]  imem_addr;
    wire [`REG_SOURCE_WIDTH-1:0] global_regfile_addr;
    wire                         global_regfile_write_en;
    wire [`WORD]                 global_regfile_write_data;
    wire [`WORD]                 global_regfile_read_data;
    wire [`SRAM_1024x32_ADDR_WIDTH-1:0]  pc_vertex_shading;
    wire [`SRAM_1024x32_ADDR_WIDTH-1:0]  pc_fragment_shading;
    wire [`SRAM_1024x32_ADDR_WIDTH-1:0]  pc_gpgpu_compute;
    wire [`NUM_CORES-1:0]        core_enable;
    wire [1:0]                   cmd;
    reg                          cmd_written;
    wire                         pause_at_halt;
    wire [`WORD]                 index_buffer_addr;
    wire [1:0]                   dispatch_ctrl;
    wire [`WORD]                 num_dispatches;
    wire                         job_done_clr;
    wire                         job_done;
    wire                         batch_done_clr;
    wire                         batch_done;
    wire [3:0]                   cc_state;
    wire [`WORD]                 perf_num_vshades;
    wire [`WORD]                 perf_num_fshades;
    wire [`WORD]                 perf_vshade_cycles;
    wire [`WORD]                 perf_fshade_cycles;
    core_controller_m #(
        .INDEX_FETCH_CACHE_LEN_WORDS(INDEX_FETCH_CACHE_LEN_WORDS),
        .CALL_STACK_LEN(CALL_STACK_LEN)
    ) core_controller (
`ifdef USE_POWER_PINS
    	.vccd1(vccd1),
    	.vssd1(vssd1),
`endif

        .clk_i(wb_clk_i),
        .nrst_i(!wb_rst_i),

        .imem_rw_i(imem_rw),
        .imem_do_o({ imem_do[7:0], imem_do[15:8], imem_do[23:16], imem_do[31:24] }),
        .imem_di_i({ imem_di[7:0], imem_di[15:8], imem_di[23:16], imem_di[31:24] }),
        .imem_addr_i(imem_addr),

        .global_regfile_addr_i(global_regfile_addr),
        .global_regfile_write_en_i(global_regfile_write_en),
        .global_regfile_write_data_i(global_regfile_write_data),
        .global_regfile_read_data_o(global_regfile_read_data),

        .pc_vertex_shading_i(pc_vertex_shading),
        .pc_fragment_shading_i(pc_fragment_shading),
        .pc_gpgpu_compute_i(pc_gpgpu_compute),

        .mport_i(mport_i),
        .mport_o(mport_o),

        .vertcache_test_index_o(vertcache_test_index_o),
        .vertcache_test_valid_o(vertcache_test_valid_o),
        .vertcache_test_found_i(vertcache_test_found_i),
        .vertcache_clear_o(vertcache_clear_o),

        .vertorder_mstream_i(vertorder_mstream_i),
        .vertorder_mstream_o(vertorder_mstream_o),
        .vertorder_full_i(vertorder_full_i),
        .vertorder_empty_i(vertorder_empty_i),
        .vertorder_clear_o(vertorder_clear_o),

        .vertcont_busy_i(vertcont_busy_i),

        .index_mstream_i(index_mstream_i),
        .index_mstream_o(index_mstream_o),

        .fragfifo_full_i(fragfifo_full_i),
        .fragfifo_empty_i(fragfifo_empty_i),
        .fragfifo_clear_o(fragfifo_clear_o),

        .rast_busy_i(rast_busy_i),

        .core_enable_i(core_enable),
        .cmd_i(cmd),
        .cmd_written_i(cmd_written),
        .pause_at_halt_i(pause_at_halt),
        .index_buffer_addr_i(index_buffer_addr),
        .dispatch_ctrl_i(dispatch_ctrl),
        .num_dispatches_i(num_dispatches),
        .job_done_clr_i(job_done_clr),
        .job_done_o(job_done),
        .batch_done_clr_i(batch_done_clr),
        .batch_done_o(batch_done),
        .state_o(cc_state),

        .inst_o(inst_o),
        .core_reset_o(core_reset_o),
        .core_reset_mailbox_o(core_reset_mailbox_o),
        .core_stall_i(core_stall_i),
        .core_stall_o(core_stall_o),
        .core_jump_i(core_jump_i),
        .core_jump_o(core_jump_o),
        .global_regfile_rs1_data_o(global_regfile_rs1_data_o),
        .global_regfile_rs2_data_o(global_regfile_rs2_data_o),

        .core_inbox_mstream_i(core_inbox_mstream_i),
        .core_outbox_mstream_valid_i(core_outbox_mstream_valid_i),

        .perf_num_vshades_o(perf_num_vshades),
        .perf_num_fshades_o(perf_num_fshades),
        .perf_vshade_cycles_o(perf_vshade_cycles),
        .perf_fshade_cycles_o(perf_fshade_cycles)
    );

    wire core_controller_enabled = (cc_state ? 1 : 0);

    reg cmd_written_delay;

    wire [`WORD] ctrl_reg;
    assign {pause_at_halt, dispatch_ctrl, cmd} = ctrl_reg[3:0];
    always @(posedge wb_clk_i, posedge wb_rst_i) begin : CTRL_REG
        reg prev_wbs_stbN0;
        if (wb_rst_i) begin
            cmd_written <= 0;
            cmd_written_delay <= 0;
            prev_wbs_stbN0 <= 0;
        end
        else if (wb_clk_i) begin
            prev_wbs_stbN0 <= wbs_stbN[0];
            cmd_written <= cmd_written_delay;
            if (!prev_wbs_stbN0 && wbs_stbN[0])
                cmd_written_delay <= 1;
            else
                cmd_written_delay <= 0;
        end
    end
    wishbone_register_m #(32'h00000000, 1, `WBREG_TYPE_REG) ctrl (
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .wbs_stb_i(wbs_stbN[0]),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_we_i(wbs_we_i),
        .wbs_sel_i(wbs_sel_i),
        .wbs_dat_i(wbs_dat_i),
        .wbs_adr_i(wbs_adr_i),
        .wbs_ack_o(wbs_ackN[0]),
        .wbs_dat_o(wbs_datN[0]),

        .access_read_mask_i(32'h0000001C),
        .access_write_mask_i(32'h0000001F),
        .periph_read_mask_i(0),

        .enable_prot_i(32'hFFFFFFFC),
        .enable_i(core_controller_enabled),

        .reg_i(0),
        .reg_o(ctrl_reg)
    );

    wishbone_register_m #(32'h00000000, 1, `WBREG_TYPE_REG) state (
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .wbs_stb_i(wbs_stbN[1]),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_we_i(wbs_we_i),
        .wbs_sel_i(wbs_sel_i),
        .wbs_dat_i(wbs_dat_i),
        .wbs_adr_i(wbs_adr_i),
        .wbs_ack_o(wbs_ackN[1]),
        .wbs_dat_o(wbs_datN[1]),

        .access_read_mask_i(32'h0000000F),
        .access_write_mask_i(32'h00000000),
        .periph_read_mask_i(32'h0000000F),

        .enable_prot_i(0),
        .enable_i(0),

        .reg_i({28'h0, cc_state}),
        .reg_o()
    );

    wire [`WORD] coreen_reg;
    assign {core_enable} = coreen_reg[`NUM_CORES-1:0];
    wishbone_register_m #(32'h00000000, 1, `WBREG_TYPE_REG) coreen (
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .wbs_stb_i(wbs_stbN[2]),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_we_i(wbs_we_i),
        .wbs_sel_i(wbs_sel_i),
        .wbs_dat_i(wbs_dat_i),
        .wbs_adr_i(wbs_adr_i),
        .wbs_ack_o(wbs_ackN[2]),
        .wbs_dat_o(wbs_datN[2]),

        .access_read_mask_i({`NUM_CORES{1'b1}}),
        .access_write_mask_i({`NUM_CORES{1'b1}}),
        .periph_read_mask_i(0),

        .enable_prot_i(32'hFFFFFFFF),
        .enable_i(core_controller_enabled),

        .reg_i(0),
        .reg_o(coreen_reg)
    );

    wire [`WORD] intmask_reg;
    assign irq_jobdone_o   = (intmask_reg[0] ? job_done   : 0);
    assign irq_batchdone_o = (intmask_reg[1] ? batch_done : 0);
    wishbone_register_m #(32'h00000000, 1, `WBREG_TYPE_REG) intmask (
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .wbs_stb_i(wbs_stbN[3]),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_we_i(wbs_we_i),
        .wbs_sel_i(wbs_sel_i),
        .wbs_dat_i(wbs_dat_i),
        .wbs_adr_i(wbs_adr_i),
        .wbs_ack_o(wbs_ackN[3]),
        .wbs_dat_o(wbs_datN[3]),

        .access_read_mask_i(32'h00000007),
        .access_write_mask_i(32'h00000007),
        .periph_read_mask_i(0),

        .enable_prot_i(32'hFFFFFFFF),
        .enable_i(core_controller_enabled),

        .reg_i(0),
        .reg_o(intmask_reg)
    );

    // Hacky thing to make INTFLAG be write-1-clear.
    assign batch_done_clr = (wbs_ackN[4] && wbs_we_i && wbs_dat_i[1]);
    assign job_done_clr   = (wbs_ackN[4] && wbs_we_i && wbs_dat_i[0]);
    wishbone_register_m #(32'h00000000, 1, `WBREG_TYPE_REG) intflag (
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .wbs_stb_i(wbs_stbN[4]),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_we_i(wbs_we_i),
        .wbs_sel_i(wbs_sel_i),
        .wbs_dat_i(wbs_dat_i),
        .wbs_adr_i(wbs_adr_i),
        .wbs_ack_o(wbs_ackN[4]),
        .wbs_dat_o(wbs_datN[4]),

        .access_read_mask_i(32'h00000003),
        .access_write_mask_i(32'h00000000),
        .periph_read_mask_i(32'h00000003),

        .enable_prot_i(32'h00000000),
        .enable_i(),

        .reg_i({30'h0, batch_done, job_done}),
        .reg_o()
    );

    wire [`WORD] comppc_reg;
    assign pc_gpgpu_compute = comppc_reg[11:2]; // Byte addr -> word addr
    wishbone_register_m #(32'h00000000, 1, `WBREG_TYPE_REG) comppc (
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .wbs_stb_i(wbs_stbN[5]),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_we_i(wbs_we_i),
        .wbs_sel_i(wbs_sel_i),
        .wbs_dat_i(wbs_dat_i),
        .wbs_adr_i(wbs_adr_i),
        .wbs_ack_o(wbs_ackN[5]),
        .wbs_dat_o(wbs_datN[5]),

        .access_read_mask_i(32'h00000FFF),
        .access_write_mask_i(32'h00000FFF),
        .periph_read_mask_i(0),

        .enable_prot_i(32'hFFFFFFFF),
        .enable_i(core_controller_enabled),

        .reg_i(0),
        .reg_o(comppc_reg)
    );

    wire [`WORD] vshadepc_reg;
    assign pc_vertex_shading = vshadepc_reg[11:2]; // Byte addr -> word addr
    wishbone_register_m #(32'h00000000, 1, `WBREG_TYPE_REG) vshadepc (
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .wbs_stb_i(wbs_stbN[6]),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_we_i(wbs_we_i),
        .wbs_sel_i(wbs_sel_i),
        .wbs_dat_i(wbs_dat_i),
        .wbs_adr_i(wbs_adr_i),
        .wbs_ack_o(wbs_ackN[6]),
        .wbs_dat_o(wbs_datN[6]),

        .access_read_mask_i(32'h00000FFF),
        .access_write_mask_i(32'h00000FFF),
        .periph_read_mask_i(0),

        .enable_prot_i(32'hFFFFFFFF),
        .enable_i(core_controller_enabled),

        .reg_i(0),
        .reg_o(vshadepc_reg)
    );

    wire [`WORD] fshadepc_reg;
    assign pc_fragment_shading = fshadepc_reg[11:2]; // Byte addr -> word addr
    wishbone_register_m #(32'h00000000, 1, `WBREG_TYPE_REG) fshadepc (
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .wbs_stb_i(wbs_stbN[7]),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_we_i(wbs_we_i),
        .wbs_sel_i(wbs_sel_i),
        .wbs_dat_i(wbs_dat_i),
        .wbs_adr_i(wbs_adr_i),
        .wbs_ack_o(wbs_ackN[7]),
        .wbs_dat_o(wbs_datN[7]),

        .access_read_mask_i(32'h00000FFF),
        .access_write_mask_i(32'h00000FFF),
        .periph_read_mask_i(0),

        .enable_prot_i(32'hFFFFFFFF),
        .enable_i(core_controller_enabled),

        .reg_i(0),
        .reg_o(fshadepc_reg)
    );

    wire [`WORD] indexaddr_reg;
    assign index_buffer_addr = indexaddr_reg;
    wishbone_register_m #(32'h00000000, 1, `WBREG_TYPE_REG) indexaddr (
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .wbs_stb_i(wbs_stbN[8]),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_we_i(wbs_we_i),
        .wbs_sel_i(wbs_sel_i),
        .wbs_dat_i(wbs_dat_i),
        .wbs_adr_i(wbs_adr_i),
        .wbs_ack_o(wbs_ackN[8]),
        .wbs_dat_o(wbs_datN[8]),

        .access_read_mask_i(32'hFFFFFFFF),
        .access_write_mask_i(32'hFFFFFFFF),
        .periph_read_mask_i(0),

        .enable_prot_i(32'hFFFFFFFF),
        .enable_i(core_controller_enabled),

        .reg_i(0),
        .reg_o(indexaddr_reg)
    );

    wire [`WORD] jobs_reg;
    assign num_dispatches = jobs_reg;
    wishbone_register_m #(32'h00000000, 1, `WBREG_TYPE_REG) jobs (
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .wbs_stb_i(wbs_stbN[9]),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_we_i(wbs_we_i),
        .wbs_sel_i(wbs_sel_i),
        .wbs_dat_i(wbs_dat_i),
        .wbs_adr_i(wbs_adr_i),
        .wbs_ack_o(wbs_ackN[9]),
        .wbs_dat_o(wbs_datN[9]),

        .access_read_mask_i(32'hFFFFFFFF),
        .access_write_mask_i(32'hFFFFFFFF),
        .periph_read_mask_i(0),

        .enable_prot_i(32'hFFFFFFFF),
        .enable_i(core_controller_enabled),

        .reg_i(0),
        .reg_o(jobs_reg)
    );

    wishbone_register_m #(32'h00000000, 1, `WBREG_TYPE_REG) pc (
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .wbs_stb_i(wbs_stbN[10]),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_we_i(wbs_we_i),
        .wbs_sel_i(wbs_sel_i),
        .wbs_dat_i(wbs_dat_i),
        .wbs_adr_i(wbs_adr_i),
        .wbs_ack_o(wbs_ackN[10]),
        .wbs_dat_o(wbs_datN[10]),

        .access_read_mask_i(32'hFFFFFFFF),
        .access_write_mask_i(32'h00000000),
        .periph_read_mask_i(32'hFFFFFFFF),

        .enable_prot_i(32'h00000000),
        .enable_i(1'b0),

        .reg_i(core_controller.inst_fetch.pc),
        .reg_o()
    );

    reg [`WORD] inst_reg;
    always @ (posedge wb_clk_i, posedge wb_rst_i) begin
        if (wb_rst_i)
        inst_reg <= 0;
        else if (wb_clk_i) begin
            case (cc_state)
                3, 4, 5, 6: inst_reg <= inst_o; // Active execution states
                default: inst_reg <= inst_reg;
            endcase
        end
    end
    // Holds the last instruction the core executed before pausing
    // (the instruction currently in decode)
    wishbone_register_m #(32'h00000000, 1, `WBREG_TYPE_REG) inst (
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .wbs_stb_i(wbs_stbN[11]),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_we_i(wbs_we_i),
        .wbs_sel_i(wbs_sel_i),
        .wbs_dat_i(wbs_dat_i),
        .wbs_adr_i(wbs_adr_i),
        .wbs_ack_o(wbs_ackN[11]),
        .wbs_dat_o(wbs_datN[11]),

        .access_read_mask_i(32'hFFFFFFFF),
        .access_write_mask_i(32'h00000000),
        .periph_read_mask_i(32'hFFFFFFFF),

        .enable_prot_i(32'h00000000),
        .enable_i(1'b0),

        .reg_i(inst_reg),
        .reg_o()
    );

    wishbone_register_m #(32'h00000000, 1, `WBREG_TYPE_REG) nvshades (
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .wbs_stb_i(wbs_stbN[12]),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_we_i(wbs_we_i),
        .wbs_sel_i(wbs_sel_i),
        .wbs_dat_i(wbs_dat_i),
        .wbs_adr_i(wbs_adr_i),
        .wbs_ack_o(wbs_ackN[12]),
        .wbs_dat_o(wbs_datN[12]),

        .access_read_mask_i(32'hFFFFFFFF),
        .access_write_mask_i(32'h00000000),
        .periph_read_mask_i(32'hFFFFFFFF),

        .enable_prot_i(32'h00000000),
        .enable_i(1'b0),

        .reg_i(perf_num_vshades),
        .reg_o()
    );

    wishbone_register_m #(32'h00000000, 1, `WBREG_TYPE_REG) nfshades (
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .wbs_stb_i(wbs_stbN[13]),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_we_i(wbs_we_i),
        .wbs_sel_i(wbs_sel_i),
        .wbs_dat_i(wbs_dat_i),
        .wbs_adr_i(wbs_adr_i),
        .wbs_ack_o(wbs_ackN[13]),
        .wbs_dat_o(wbs_datN[13]),

        .access_read_mask_i(32'hFFFFFFFF),
        .access_write_mask_i(32'h00000000),
        .periph_read_mask_i(32'hFFFFFFFF),

        .enable_prot_i(32'h00000000),
        .enable_i(1'b0),

        .reg_i(perf_num_fshades),
        .reg_o()
    );

    wishbone_register_m #(32'h00000000, 1, `WBREG_TYPE_REG) nvcycles (
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .wbs_stb_i(wbs_stbN[14]),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_we_i(wbs_we_i),
        .wbs_sel_i(wbs_sel_i),
        .wbs_dat_i(wbs_dat_i),
        .wbs_adr_i(wbs_adr_i),
        .wbs_ack_o(wbs_ackN[14]),
        .wbs_dat_o(wbs_datN[14]),

        .access_read_mask_i(32'hFFFFFFFF),
        .access_write_mask_i(32'h00000000),
        .periph_read_mask_i(32'hFFFFFFFF),

        .enable_prot_i(32'h00000000),
        .enable_i(1'b0),

        .reg_i(perf_vshade_cycles),
        .reg_o()
    );

    wishbone_register_m #(32'h00000000, 1, `WBREG_TYPE_REG) nfcycles (
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .wbs_stb_i(wbs_stbN[15]),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_we_i(wbs_we_i),
        .wbs_sel_i(wbs_sel_i),
        .wbs_dat_i(wbs_dat_i),
        .wbs_adr_i(wbs_adr_i),
        .wbs_ack_o(wbs_ackN[15]),
        .wbs_dat_o(wbs_datN[15]),

        .access_read_mask_i(32'hFFFFFFFF),
        .access_write_mask_i(32'h00000000),
        .periph_read_mask_i(32'hFFFFFFFF),

        .enable_prot_i(32'h00000000),
        .enable_i(1'b0),

        .reg_i(perf_fshade_cycles),
        .reg_o()
    );

    // Global regfile defs
    wire global_regs_wb_ack;
    reg  global_regs_wb_stb;

    // Mux between the registers (similar to user_project_wrapper's addressing)
    wire [$clog2(NUM_REGS)-1:0] word_offset = {2'b00, wbs_adr_i[31:2]};
    always @ (*) begin
        if (word_offset >= NUM_CONTROL_REGS) begin
            global_regs_wb_stb = wbs_stb_control_i;
            wbs_stbN = 0;
            wbs_ack_control_o = global_regs_wb_ack;
            wbs_dat_control_o = global_regfile_read_data;
        end
        else begin
            wbs_stbN = wbs_stb_control_i << word_offset; // Only one at a time
            global_regs_wb_stb = 0;
            wbs_ack_control_o = wbs_ackN[word_offset];
            wbs_dat_control_o = wbs_datN[word_offset];
        end
    end

    // Global regfile
    wire global_regs_wb_we;
    wishbone_helper_m global_regs_wb_helper (
        .wb_clk_i(wb_clk_i),
        .wbs_we_i(wbs_we_i),
        .wbs_stb_i(global_regs_wb_stb),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_sel_i(wbs_sel_i),
        .wbs_effective_we_o(global_regs_wb_we),
        .wbs_ack_o(global_regs_wb_ack)
    );

    assign global_regfile_addr       = (word_offset - NUM_CONTROL_REGS + `NUM_LOCAL_REGS);
    assign global_regfile_write_en   = global_regs_wb_we;
    assign global_regfile_write_data = wbs_dat_i;

    // IMEM (handled separately from config registers, but still included here
    // so everything's in one place)
    wire imem_wb_we;
    wishbone_helper_m imem_wb_helper (
        .wb_clk_i(wb_clk_i),
        .wbs_we_i(wbs_we_i),
        .wbs_stb_i(wbs_stb_imem_i),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_sel_i(wbs_sel_i),
        .wbs_effective_we_o(imem_wb_we),
        .wbs_ack_o(wbs_ack_imem_o)
    );

    assign imem_rw        = !imem_wb_we;
    assign imem_di        = wbs_dat_i;
    assign imem_addr      = wbs_adr_i[12:2]; // byte address -> word address
    assign wbs_dat_imem_o = imem_do;

endmodule
