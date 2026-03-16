module core_controller_wrapper_m #(
  parameter INDEX_FETCH_CACHE_LEN_WORDS = 0,
  parameter CALL_STACK_LEN = 8
) (
`ifdef USE_POWER_PINS
  inout vpwrac,
  input vpwrpc,
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

  // Vertex order buffer
  input  wire [`STREAM_SOPORT(`VERTEX_ORDER_WIDTH)] vertorder_sstreamo_i,
  output wire [`STREAM_SIPORT(`VERTEX_ORDER_WIDTH)] vertorder_sstreami_o,
  input  wire                                    vertorder_full_i,
  input  wire                                    vertorder_empty_i,

  // Rasterizer fragment output FIFO
  input wire                        fragfifo_full_i,
  input wire [`NUM_CORES_WIDTH-1:0] fragfifo_cores_dispatched_i, // Number of cores with a fragment in their inbox

  // Shader core interface
  output wire [`WORD]           inst_o,
  output wire [`NUM_CORES-1:0]  core_reset_o, // Core soft reset
  input  wire [`NUM_CORES-1:0]  core_stall_i,
  output wire [`NUM_CORES-1:0]  core_stall_o, // Per-core stall control
  input  wire [`NUM_CORES-1:0]  core_jump_i,
  output wire                   core_jump_o,  // Flushes decode on all cores
  output wire [`WORD]           global_regfile_rs1_data_o,
  output wire [`WORD]           global_regfile_rs2_data_o
);

  localparam NUM_CONTROL_REGS = 10;
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
  wire [2:0]                   cc_state;
  core_controller_m #(
    .INDEX_FETCH_CACHE_LEN_WORDS(INDEX_FETCH_CACHE_LEN_WORDS),
    .CALL_STACK_LEN(CALL_STACK_LEN)
  ) core_controller (
    `ifdef USE_POWER_PINS
      .vpwrac(vpwrac),
      .vpwrpc(vpwrpc),
    `endif

    .clk_i(wb_clk_i),
    .nrst_i(!wb_rst_i),

    .imem_rw_i(imem_rw),
    .imem_do_o(imem_do),
    .imem_di_i(imem_di),
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

    .vertorder_sstreamo_i(vertorder_sstreamo_i),
    .vertorder_sstreami_o(vertorder_sstreami_o),
    .vertorder_full_i(vertorder_full_i),
    .vertorder_empty_i(vertorder_empty_i),

    .fragfifo_full_i(fragfifo_full_i),
    .fragfifo_cores_dispatched_i(fragfifo_cores_dispatched_i),

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
    .core_stall_i(core_stall_i),
    .core_stall_o(core_stall_o),
    .core_jump_i(core_jump_i),
    .core_jump_o(core_jump_o),
    .global_regfile_rs1_data_o(global_regfile_rs1_data_o),
    .global_regfile_rs2_data_o(global_regfile_rs2_data_o)
  );

  wire core_controller_enabled = (cc_state ? 1 : 0);

  wire [`WORD] ctrl_reg;
  assign {pause_at_halt, dispatch_ctrl, cmd} = ctrl_reg[3:0];
  always @(posedge wb_clk_i, posedge wb_rst_i) begin
    reg prev_wbs_stbN0;
    if (wb_rst_i) begin
      cmd_written <= 0;
      prev_wbs_stbN0 <= 0;
    end
    else if (wb_clk_i) begin
      prev_wbs_stbN0 <= wbs_stbN[0];
      if (!prev_wbs_stbN0 && wbs_stbN[0])
        cmd_written <= 1;
      else
        cmd_written <= 0;
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

    .access_read_mask_i(32'h00000007),
    .access_write_mask_i(32'h00000000),
    .periph_read_mask_i(32'h00000007),

    .enable_prot_i(0),
    .enable_i(0),

    .reg_i({29'h0, cc_state}),
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

  // Convoluted thing to make Write 1 pulse the *_clr_i flag clear lines.
  // Can't use W1C mode for this since it'll only write to the reg in
  // wishbone_reg. W1T will toggle the wishbone reg when a 1 is written
  wire [`WORD] intflag_reg;
  reg [`WORD] last_intflag_reg;
  assign batch_done_clr = (last_intflag_reg[0] != intflag_reg[0]);
  assign job_done_clr   = (last_intflag_reg[1] != intflag_reg[1]);
  always @ (posedge wb_clk_i, posedge wb_rst_i) begin
    if (wb_rst_i)
      last_intflag_reg <= 0;
    else if (wb_clk_i) begin
      last_intflag_reg <= intflag_reg;
    end
  end
  wishbone_register_m #(32'h00000000, 1, `WBREG_TYPE_W1T) intflag (
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
    .access_write_mask_i(32'h00000003),
    .periph_read_mask_i(32'h00000003),

    .enable_prot_i(32'hFFFFFFFC),
    .enable_i(core_controller_enabled),

    .reg_i({30'h0, batch_done, job_done}),
    .reg_o(intflag_reg)
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





/*
* Core controller module (aka meta-core, mc, master chief, minecraft, emcee...)
* Handles the PC, instruction fetch, global regfile, job dispatch,
* vertex/fragment shading switchover, index prefetching, and interfacing
* between the management core and the shader cores.
*/
module core_controller_m #(
  parameter INDEX_FETCH_CACHE_LEN_WORDS = 0,
  parameter CALL_STACK_LEN = 8
) (
`ifdef USE_POWER_PINS
  inout vpwrac,
  inout vpwrpc,
`endif

  input wire clk_i,
  input wire nrst_i,

  // IMEM
  input  wire                       imem_rw_i, // 1 = read, 0 = write
  output wire [`WORD]               imem_do_o,
  input  wire [`WORD]               imem_di_i,
  input  wire [`SRAM_1024x32_ADDR_WIDTH-1:0] imem_addr_i,

  // Global regfile
  input  wire [`REG_SOURCE_WIDTH-1:0] global_regfile_addr_i,
  input  wire                         global_regfile_write_en_i,
  input  wire [`WORD]                 global_regfile_write_data_i,
  output wire [`WORD]                 global_regfile_read_data_o,

  // PCs
  input wire [`SRAM_1024x32_ADDR_WIDTH-1:0] pc_vertex_shading_i,
  input wire [`SRAM_1024x32_ADDR_WIDTH-1:0] pc_fragment_shading_i,
  input wire [`SRAM_1024x32_ADDR_WIDTH-1:0] pc_gpgpu_compute_i,

  // PKBus
  input  wire [`BUS_MIPORT] mport_i,
  output wire [`BUS_MOPORT] mport_o,

  // Shaded vertex cache
  output wire [`WORD] vertcache_test_index_o,
  output wire         vertcache_test_valid_o,
  input  wire         vertcache_test_found_i,

  // Vertex order buffer
  input  wire [`STREAM_SOPORT(`VERTEX_ORDER_WIDTH)] vertorder_sstreamo_i,
  output wire [`STREAM_SIPORT(`VERTEX_ORDER_WIDTH)] vertorder_sstreami_o,
  input  wire                                    vertorder_full_i,
  input  wire                                    vertorder_empty_i,

  // Rasterizer fragment output FIFO
  input wire                        fragfifo_full_i,
  input wire [`NUM_CORES_WIDTH-1:0] fragfifo_cores_dispatched_i, // Number of cores with a fragment in their inbox

  // Config/control
  input  wire [`NUM_CORES-1:0] core_enable_i,
  input  wire [1:0]            cmd_i,
  input  wire                  cmd_written_i,
  input  wire                  pause_at_halt_i,     // 0: continue to next state after halt. 1: pause at halt instruction
  input  wire [`WORD]          index_buffer_addr_i,
  input  wire [1:0]            dispatch_ctrl_i,
  input  wire [`WORD]          num_dispatches_i,    // Number of jobs (indices or ints) to dispatch
  input  wire                  job_done_clr_i,      // 1: clear job done flag
  output  reg                  job_done_o,          // 1: finished a shader program (i.e. reached a halt)
  input  wire                  batch_done_clr_i,    // 1: clear batch done flag
  output  reg                  batch_done_o,        // 1: finished num_dispatches_i jobs.
  output wire [2:0]            state_o,

  // Shader core interface
  output reg  [`WORD]           inst_o,
  output reg  [`NUM_CORES-1:0]  core_reset_o, // Core soft reset
  input  wire [`NUM_CORES-1:0]  core_stall_i,
  output reg  [`NUM_CORES-1:0]  core_stall_o, // Per-core stall control
  input  wire [`NUM_CORES-1:0]  core_jump_i,
  output reg                    core_jump_o,  // Flushes decode on all cores
  output reg  [`WORD]           global_regfile_rs1_data_o,
  output wire [`WORD]           global_regfile_rs2_data_o
);

  localparam INST_NOP        = 32'h04000000;

  localparam STATE_STOPPED          = 0; // Waiting for program to start from beginning
  localparam STATE_DISPATCHING      = 1; // Dispatching jobs
  localparam STATE_DISPATCH_DELAY   = 2;
  localparam STATE_VERTEX_SHADING   = 3;
  localparam STATE_FRAGMENT_SHADING = 4;
  localparam STATE_GPGPU_COMPUTE    = 5;
  localparam STATE_PAUSED           = 6; // Manual pause by management core or step-through
  localparam STATE_DONE             = 7;

  reg [2:0] state;

  // Cur/next programs (vertex shade, fragment shade, gpgpu compute)
  reg [2:0] cur_prog;
  reg [2:0] next_prog;

  reg step_handled;

  // Dispatch
  wire         dispatch_index_fetch_enable = (state != STATE_STOPPED);
  wire         dispatch_reset              = (state == STATE_STOPPED);
  reg          dispatch_enable;
  wire         dispatch_indices            = (dispatch_ctrl_i == `CORE_CTRL_DISPATCH_INDEX);
  wire [`WORD] dispatch_thread_id;
  wire [`WORD] dispatch_inst;
  wire [`NUM_CORES-1:0] dispatch_core_stall;
  wire         dispatch_done;
  wire         dispatch_model_done;
  dispatch_m #(
    INDEX_FETCH_CACHE_LEN_WORDS
  ) dispatch (
    .clk_i(clk_i),
    .nrst_i(nrst_i),

    .mport_i(mport_i),
    .mport_o(mport_o),

    .vertcache_test_index_o(vertcache_test_index_o),
    .vertcache_test_valid_o(vertcache_test_valid_o),
    .vertcache_test_found_i(vertcache_test_found_i),

    .vertorder_sstreamo_i(vertorder_sstreamo_i),
    .vertorder_sstreami_o(vertorder_sstreami_o),
    .vertorder_full_i(vertorder_full_i),

    .index_buffer_addr_i(index_buffer_addr_i),
    .index_fetch_enable_i(dispatch_index_fetch_enable),

    .reset_dispatch_i(dispatch_reset),
    .enable_i(dispatch_enable),
    .dispatch_indices_i(dispatch_indices),
    .num_dispatches_i(num_dispatches_i),
    .core_enable_i(core_enable_i),

    .thread_id_o(dispatch_thread_id),
    .inst_o(dispatch_inst),
    .core_stall_o(dispatch_core_stall),

    .dispatch_done_o(dispatch_done),
    .model_done_o(dispatch_model_done)
  );

  reg [`SRAM_1024x32_ADDR_WIDTH-1:0] instfetch_prog_entry;
  reg                                instfetch_enable;
  reg                                instfetch_reset_prog;
  wire                               instfetch_step_done;
  wire                               instfetch_prog_done;
  wire [`WORD]                       instfetch_inst;
  wire [`WORD]                       instfetch_global_regfile_rs1_data;
  inst_fetch_m #(
    CALL_STACK_LEN
  ) inst_fetch (
    .clk_i(clk_i),
    .nrst_i(nrst_i),

    .imem_rw_i(imem_rw_i),
    .imem_do_o(imem_do_o),
    .imem_di_i(imem_di_i),
    .imem_addr_i(imem_addr_i),

    .global_regfile_addr_i(global_regfile_addr_i),
    .global_regfile_write_en_i(global_regfile_write_en_i),
    .global_regfile_write_data_i(global_regfile_write_data_i),
    .global_regfile_read_data_o(global_regfile_read_data_o),

    .prog_entry_i(instfetch_prog_entry),

    .enable_i(instfetch_enable),
    .reset_prog_i(instfetch_reset_prog),
    .step_done_o(instfetch_step_done),
    .prog_done_o(instfetch_prog_done),

    .inst_o(instfetch_inst),
    .core_stall_i(core_stall_i),
    .core_jump_i(core_jump_i),
    .global_regfile_rs1_data_o(instfetch_global_regfile_rs1_data),
    .global_regfile_rs2_data_o(global_regfile_rs2_data_o)
  );

  assign state_o  = state;

  wire is_rasterization = (dispatch_ctrl_i == `CORE_CTRL_DISPATCH_INDEX);
  wire should_dispatch  = (dispatch_ctrl_i != `CORE_CTRL_DISPATCH_DISABLE && next_prog != STATE_FRAGMENT_SHADING);

  always @(posedge clk_i, negedge nrst_i) begin
    if (!nrst_i) begin : RESET
      integer i;
      job_done_o <= 0;
      batch_done_o <= 0;

      dispatch_enable <= 0;

      instfetch_enable <= 0;
      instfetch_reset_prog <= 0;

      cur_prog      <= STATE_STOPPED;
      state         <= STATE_STOPPED;
      step_handled  <= 0;
    end
    else if (clk_i) begin
      if (job_done_clr_i)
        job_done_o <= 0;
      if (batch_done_clr_i)
        batch_done_o <= 0;
      if (cmd_written_i)
        step_handled <= 0;

      case (state)
        STATE_STOPPED: begin
          instfetch_reset_prog <= 1;
          if (cmd_i == `CORE_CTRL_CMD_RUN || cmd_i == `CORE_CTRL_CMD_STEP) begin
            if (is_rasterization)
              cur_prog <= STATE_VERTEX_SHADING;
            else
              cur_prog <= STATE_GPGPU_COMPUTE;

            if (should_dispatch) begin
              dispatch_enable <= 1;
              state <= STATE_DISPATCHING;
            end
            else
              state <= STATE_DISPATCH_DELAY;
          end
        end
        STATE_DISPATCH_DELAY: begin
          instfetch_reset_prog <= 0;
          instfetch_enable <= 1;
          state <= cur_prog;
        end
        STATE_DISPATCHING: begin
          instfetch_reset_prog <= 0;

          if (cmd_i == `CORE_CTRL_CMD_STOP) begin
            dispatch_enable <= 0;
            state <= STATE_STOPPED;
          end
          else if (dispatch_done) begin
            dispatch_enable <= 0;
            instfetch_enable <= 1;
            state <= cur_prog;
          end
        end
        STATE_VERTEX_SHADING, STATE_FRAGMENT_SHADING, STATE_GPGPU_COMPUTE: begin
          instfetch_enable <= 0;
          case (cmd_i)
            `CORE_CTRL_CMD_STOP:
              state <= STATE_STOPPED;
            `CORE_CTRL_CMD_PAUSE:
              state <= STATE_PAUSED;
            `CORE_CTRL_CMD_RUN: begin
              if (instfetch_prog_done) begin
                instfetch_reset_prog <= 1;
                state <= STATE_DONE;
              end
              else
                instfetch_enable <= 1;
            end
            `CORE_CTRL_CMD_STEP: begin
              if (instfetch_step_done)
                state <= STATE_PAUSED;
              else
                instfetch_enable <= 1;
            end
          endcase
        end
        STATE_PAUSED: begin
          case (cmd_i)
            `CORE_CTRL_CMD_RUN:
              state <= cur_prog;
            `CORE_CTRL_CMD_STEP: begin
              if (!step_handled) begin
                step_handled <= 1;
                state <= cur_prog;
              end
            end
            `CORE_CTRL_CMD_STOP:
              state <= STATE_STOPPED;
          endcase
        end
        STATE_DONE: begin
          job_done_o <= 1;
          if (dispatch_model_done)
            batch_done_o <= 1;

          instfetch_reset_prog <= 0;

          cur_prog <= next_prog;
          if (pause_at_halt_i || next_prog == STATE_STOPPED)
            state <= STATE_STOPPED;
          else if (should_dispatch)
            state <= STATE_DISPATCHING;
          else begin
            instfetch_enable <= 1;
            state <= next_prog;
          end

          if (cmd_i == `CORE_CTRL_CMD_STOP)
            state <= STATE_STOPPED;
        end
      endcase
    end
  end

  always @(*) begin
    // Instruction muxing
    if (state == STATE_STOPPED || state == STATE_DONE)
      inst_o = INST_NOP;
    else if (state == STATE_DISPATCHING)
      inst_o = dispatch_inst;
    else
      inst_o = instfetch_inst;

    // Core control signals
    if (state == STATE_STOPPED)
      core_reset_o = {`NUM_CORES{1'b1}};
    else
      // Hold disabled and undispatched cores in reset during execution
      core_reset_o = core_enable_i | dispatch_core_stall;
    if (state == STATE_DISPATCHING)
      core_stall_o = dispatch_core_stall;
    else if (state == STATE_PAUSED || core_stall_i)
      core_stall_o = {`NUM_CORES{1'b1}};
    else
      core_stall_o = 0;
    core_jump_o  = (core_jump_i  ? 1 : 0);

    // Next program selection
    if (cur_prog == STATE_GPGPU_COMPUTE) begin
      if (dispatch_model_done)
        next_prog = STATE_STOPPED;
      else
        next_prog = STATE_GPGPU_COMPUTE;
    end
    else if (cur_prog == STATE_VERTEX_SHADING) begin
      if (fragfifo_cores_dispatched_i == `NUM_CORES - 1 ||
          fragfifo_full_i ||
          dispatch_model_done)
        next_prog = STATE_FRAGMENT_SHADING;
      else
        next_prog = STATE_VERTEX_SHADING;
    end
    else if (cur_prog == STATE_FRAGMENT_SHADING) begin
      if ((!fragfifo_cores_dispatched_i || vertorder_empty_i) && !dispatch_model_done)
        next_prog = STATE_VERTEX_SHADING;
      else if (fragfifo_cores_dispatched_i && dispatch_model_done)
        next_prog = STATE_FRAGMENT_SHADING;
      else
        next_prog = STATE_STOPPED;
    end
    else
      next_prog = STATE_STOPPED;

    // Entry point
    case (cur_prog)
      STATE_GPGPU_COMPUTE:
        instfetch_prog_entry = pc_gpgpu_compute_i;
      STATE_VERTEX_SHADING:
        instfetch_prog_entry = pc_vertex_shading_i;
      STATE_FRAGMENT_SHADING:
        instfetch_prog_entry = pc_fragment_shading_i;
      default:
        instfetch_prog_entry = 0;
    endcase

    // Global regfile/thread ID
    if (state == STATE_DISPATCHING)
      global_regfile_rs1_data_o = dispatch_thread_id;
    else
      global_regfile_rs1_data_o = instfetch_global_regfile_rs1_data;
  end

endmodule
