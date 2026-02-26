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
  input wire wbs_stb_imem_i,
  output reg wbs_ack_imem_o,
  output reg [`WORD_WIDTH-1:0] wbs_dat_imem_o,

  // IRQs
  output reg irq_jobdone_o,
  output reg irq_batchdone_o,

  // PKBus
  input wire [`BUS_MIPORT] mport_i,
  output reg [`BUS_MOPORT] mport_o,

  // Shaded vertex cache
  output wire [`WORD] vertcache_test_index_o,
  output wire         vertcache_test_valid_o,
  input  wire         vertcache_test_found_i,

  // Vertex order buffer
  input  wire [`STREAM_SOPORT(`NUM_CORES_WIDTH)] vertorder_sstreamo_i,
  output wire [`STREAM_SIPORT(`NUM_CORES_WIDTH)] vertorder_sstreami_o,
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

  reg  [NUM_REGS-1:0]    wbs_stbN;
  wire [NUM_REGS-1:0]    wbs_ackN;
  wire [`WORD_WIDTH-1:0] wbs_datN [NUM_REGS-1:0];

  wire                         imem_rw;
  wire [`WORD]                 imem_do;
  wire [`WORD]                 imem_di;
  wire [`IMEM_ADDR_WIDTH-1:0]  imem_addr;
  wire [`REG_SOURCE_WIDTH-1:0] global_regfile_addr;
  wire                         global_regfile_write_en;
  wire [`WORD]                 global_regfile_write_data;
  wire [`WORD]                 global_regfile_read_data;
  wire [`IMEM_ADDR_WIDTH-1:0]  pc_vertex_shading;
  wire [`IMEM_ADDR_WIDTH-1:0]  pc_fragment_shading;
  wire [`IMEM_ADDR_WIDTH-1:0]  pc_gpgpu_compute;
  wire [`NUM_CORES-1:0]        core_enable;
  wire [1:0]                   cmd;
  wire                         pause_at_halt;
  wire [`WORD]                 index_buffer_addr;
  wire [1:0]                   dispatch_ctrl;
  wire [`WORD]                 num_dispatches;
  wire                         job_done_clr;
  reg                          job_done;
  wire                         batch_done_clr;
  reg                          batch_done;
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
  wire global_regs_wb_we;
  wire global_regs_wb_ack;
  wire global_regs_wb_stb                      = (wbs_stbN & ({`NUM_GLOBAL_REGS{1'b1}} << NUM_CONTROL_REGS));

  // Mux between the registers (similar to user_project_wrapper's addressing)
  wire [$clog2(NUM_REGS)-1:0] word_offset = {2'b00, wbs_adr_i[31:2]};
  always @ (*) begin
    wbs_stbN = wbs_stb_control_i << word_offset; // Only one at a time
    if (word_offset >= NUM_CONTROL_REGS) begin
      wbs_ack_control_o = global_regs_wb_ack;
      wbs_dat_control_o = global_regfile_read_data;
    end
    else begin
      wbs_ack_control_o = wbs_ackN[word_offset];
      wbs_dat_control_o = wbs_datN[word_offset];
    end
  end

  // Global regfile
  lib_wishbone_helper global_regs_wb_helper (
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
  lib_wishbone_helper imem_wb_helper (
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
  input  wire [`IMEM_ADDR_WIDTH-1:0] imem_addr_i,

  // Global regfile
  input  wire [`REG_SOURCE_WIDTH-1:0] global_regfile_addr_i,
  input  wire                         global_regfile_write_en_i,
  input  wire [`WORD]                 global_regfile_write_data_i,
  output wire [`WORD]                 global_regfile_read_data_o,

  // PCs
  input wire [`IMEM_ADDR_WIDTH-1:0] pc_vertex_shading_i,
  input wire [`IMEM_ADDR_WIDTH-1:0] pc_fragment_shading_i,
  input wire [`IMEM_ADDR_WIDTH-1:0] pc_gpgpu_compute_i,

  // PKBus
  input  wire [`BUS_MIPORT] mport_i,
  output wire [`BUS_MOPORT] mport_o,

  // Shaded vertex cache
  output wire [`WORD] vertcache_test_index_o,
  output wire         vertcache_test_valid_o,
  input  wire         vertcache_test_found_i,

  // Vertex order buffer
  input  wire [`STREAM_SOPORT(`NUM_CORES_WIDTH)] vertorder_sstreamo_i,
  output wire [`STREAM_SIPORT(`NUM_CORES_WIDTH)] vertorder_sstreami_o,
  input  wire                                    vertorder_full_i,
  input  wire                                    vertorder_empty_i,

  // Rasterizer fragment output FIFO
  input wire                        fragfifo_full_i,
  input wire [`NUM_CORES_WIDTH-1:0] fragfifo_cores_dispatched_i, // Number of cores with a fragment in their inbox

  // Config/control
  input  wire [`NUM_CORES-1:0] core_enable_i,
  input  wire [1:0]            cmd_i,
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
  output wire [`WORD]           global_regfile_rs1_data_o,
  output wire [`WORD]           global_regfile_rs2_data_o
);

  localparam CALL_STACK_BITS = $clog2(CALL_STACK_LEN);

  localparam INST_NOP        = 32'h04000000;

  localparam HALT_STAGE     = 3; // 1 = decode, 4 = writeback
  localparam JUMP_STAGE     = 2; // 1 = decode, 2 = exec
  localparam JUMP_TYPE_JUMP = 0;
  localparam JUMP_TYPE_JAL  = 1;

  localparam STATE_STOPPED          = 0; // Waiting for program to start from beginning
  localparam STATE_DISPATCHING      = 1; // Dispatching jobs
  localparam STATE_VERTEX_SHADING   = 2;
  localparam STATE_FRAGMENT_SHADING = 3;
  localparam STATE_GPGPU_COMPUTE    = 4;
  localparam STATE_PAUSED           = 5; // Manual pause by management core or step-through
  localparam STATE_DONE             = 6;

  integer i;

  reg [2:0] state;

  // Cur/next programs (vertex shade, fragment shade, gpgpu compute)
  reg [2:0] cur_prog;
  reg [2:0] next_prog;

  reg last_cmd_step; // 1: last command was a step

  // PC, in *words*
  reg [`IMEM_ADDR_WIDTH-1:0] pc;

  // Call stack
  reg [`IMEM_ADDR_WIDTH-1:0] call_stack[CALL_STACK_LEN-1:0];
  reg [CALL_STACK_BITS-1:0]  call_stack_idx;

  // Tracking jumps and halts through the core pipeline
  reg  [1:0]                  halt_counter;
  reg  [`IMEM_ADDR_WIDTH-1:0] jump_bases [JUMP_STAGE-1:0]; // PC at the time the jump was taken
  reg  [`JUMP_WIDTH-1:0]      jump_offsets [JUMP_STAGE-1:0]; // Jump offset from instruction
  reg  [JUMP_STAGE-1:0]       jump_type;
  wire [`IMEM_ADDR_WIDTH-1:0] jump_jal_offset = jump_bases[1] + $signed(jump_offsets[1][22:2]) + 1; // Add word offset, not byte offset

  // IMEM
  wire [`WORD_WIDTH-1:0]      imem_do;
  wire [`IMEM_ADDR_WIDTH-1:0] imem_addr = (state == STATE_STOPPED) ? imem_addr_i : pc; // In *words*
  wire                        imem_rw   = (state == STATE_STOPPED) ? imem_rw_i   : 1;
`ifndef FPGA
  CF_SRAM_1024x32_macro imem (
`ifdef USE_POWER_PINS
    .vpwrac(vpwrac),
    .vpwrpc(vpwrpc),
`endif

    .CLKin(clk_i),
    .DO(imem_do),
    .DI(imem_di_i),
    .BEN(32'hFFFFFFFF), // Write mask
    .AD(imem_addr),
    .EN(1'b1),
    .R_WB(imem_rw),

    // Test signals
    .WLBI(1'b0),
    .WLOFF(1'b0),
    .TM(1'b0),
    .SM(1'b0),
    .ScanInCC(1'b0),
    .ScanInDL(1'b0),
    .ScanInDR(1'b0),
    .ScanOutCC()
  );
`else
  (* ram_style = "block" *) reg [`WORD] imem [1023:0];
  assign imem_do = imem[imem_addr];

  always @(negedge nrst_i, posedge clk_i) begin
    if (!nrst_i) begin
      for (i = 0; i < 1024; i=i+1)
        imem[i] <= 0;
    end
    else if (clk_i) begin
      if (!imem_rw)
        imem[imem_addr] <= imem_di_i;
    end
  end
`endif

  // Instruction decode
  wire [`OPCODE_WIDTH-1:0]     inst_opcode      = imem_do[`OPCODE_IDX];
  wire [`REG_SOURCE_WIDTH-1:0] inst_rs1         = imem_do[`R1_IDX];
  wire [`REG_SOURCE_WIDTH-1:0] inst_rs2         = imem_do[`R2_IDX];
  wire [`JUMP_WIDTH-1:0]       inst_jump_offset = imem_do[`JUMP_IDX];

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

  // Global regfile
  wire                         global_regfile_write_en    = (state == STATE_STOPPED)     ? global_regfile_write_en_i  : 0;
  wire [`REG_SOURCE_WIDTH-1:0] global_regfile_r1_addr     = (state == STATE_STOPPED)     ? global_regfile_addr_i : inst_rs1;
  wire [`WORD_WIDTH-1:0]       global_regfile_r1_data;
  assign                       global_regfile_read_data_o = (state == STATE_STOPPED)     ? global_regfile_r1_data     : 0;
  assign                       global_regfile_rs1_data_o  = (state == STATE_DISPATCHING) ? dispatch_thread_id         : global_regfile_r1_data;
  regfile_m #(
    `WORD_WIDTH,
    `NUM_GLOBAL_REGS,
    `NUM_LOCAL_REGS,
    1,
    `REG_SOURCE_WIDTH
  ) global_regfile (
    .clk_i(clk_i),
    .nrst_i(nrst_i),

    .wr_en_i(global_regfile_write_en),
    .wr_addr_i(global_regfile_addr_i),
    .wr_data_i(global_regfile_write_data_i),

    .r1_addr_i(global_regfile_r1_addr),  // Muxed between the shader cores and wishbone interface
    .r2_addr_i(inst_rs2),
    .r1_data_o(global_regfile_r1_data),  // Muxed between the shader cores and wishbone interface
    .r2_data_o(global_regfile_rs2_data_o),

    .inbox_write_i(1'b0),
    .inbox_i({`WORD_WIDTH * `CORE_MAILBOX_HEIGHT{1'b0}}),
    .outbox_o()
  );

  assign imem_do_o = (state == STATE_STOPPED) ? imem_do : 0;
  assign state_o  = state;

  wire is_rasterization = (dispatch_ctrl_i == `CORE_CTRL_DISPATCH_INDEX);
  wire should_dispatch  = (dispatch_ctrl_i != `CORE_CTRL_DISPATCH_DISABLE && next_prog != STATE_FRAGMENT_SHADING);

  always @(posedge clk_i, negedge nrst_i) begin
    if (!nrst_i) begin
      job_done_o <= 0;
      batch_done_o <= 0;

      halt_counter <= 0;
      for (i = 0; i < JUMP_STAGE; i = i + 1) begin
        jump_bases[i] <= 0;
        jump_offsets[i] <= 0;
      end
      jump_type <= 0;

      pc <= 0;

      for (i = 0; i < CALL_STACK_LEN; i = i + 1)
        call_stack[i] <= 0;
      call_stack_idx <= 0;

      dispatch_enable <= 0;

      cur_prog      <= STATE_STOPPED;
      state         <= STATE_STOPPED;
      last_cmd_step <= 0;
    end
    else if (clk_i) begin
      if (job_done_clr_i)
        job_done_o <= 0;
      if (batch_done_clr_i)
        batch_done_o <= 0;

      case (state)
        STATE_STOPPED: begin
          if (cmd_i == `CORE_CTRL_CMD_RUN || cmd_i == `CORE_CTRL_CMD_STEP) begin
            last_cmd_step = (cmd_i == `CORE_CTRL_CMD_STEP);

            if (is_rasterization) begin
              cur_prog <= STATE_VERTEX_SHADING;
              pc <= pc_vertex_shading_i;
            end
            else begin
              cur_prog <= STATE_GPGPU_COMPUTE;
              pc <= pc_gpgpu_compute_i;
            end

            if (should_dispatch) begin
              dispatch_enable <= 1;
              state <= STATE_DISPATCHING;
            end
            else
              state <= STATE_GPGPU_COMPUTE;
          end
        end
        STATE_DISPATCHING: begin
          if (dispatch_done) begin
            case (next_prog)
              STATE_VERTEX_SHADING:
                pc <= pc_vertex_shading_i;
              STATE_FRAGMENT_SHADING:
                pc <= pc_fragment_shading_i;
              STATE_GPGPU_COMPUTE:
                pc <= pc_gpgpu_compute_i;
            endcase

            dispatch_enable <= 0;
            state <= next_prog;
          end
        end
        STATE_VERTEX_SHADING, STATE_FRAGMENT_SHADING, STATE_GPGPU_COMPUTE: begin
          case (cmd_i)
            `CORE_CTRL_CMD_STOP:  state <= STATE_STOPPED;
            `CORE_CTRL_CMD_PAUSE: state <= STATE_PAUSED;
            `CORE_CTRL_CMD_RUN, `CORE_CTRL_CMD_STEP: begin
              if (!core_stall_i && ((cmd_i == `CORE_CTRL_CMD_STEP && last_cmd_step) || cmd_i == `CORE_CTRL_CMD_RUN)) begin
                pc <= pc + 1;

                if (last_cmd_step)
                  last_cmd_step <= 0;

                // Handle halt and program switchover
                if (inst_opcode == `HALT_OPCODE || halt_counter)
                  halt_counter <= halt_counter + 1;
                if (halt_counter == HALT_STAGE - 1)
                  state <= STATE_DONE;

                // Handle jump, jal: Record jump offsets and wait for jump sig
                // from any core. If jal, push to call stack.
                jump_bases[1]   <= jump_bases[0];
                jump_offsets[1] <= jump_offsets[0];
                jump_type[1]    <= jump_type[0];
                if (inst_opcode == `JUMP_OPCODE || inst_opcode == `JAL_OPCODE) begin
                  jump_bases[0]   <= pc;
                  jump_offsets[0] <= inst_jump_offset;
                  jump_type[0]    <= (inst_opcode == `JAL_OPCODE) ? JUMP_TYPE_JAL : JUMP_TYPE_JUMP;
                end
                else begin
                  jump_bases[0]   <= 0;
                  jump_offsets[0] <= 0;
                  jump_type[0]    <= 0;
                end
                if (core_jump_i) begin
                  halt_counter <= 0; // jump/jal was taken before halt reaches writeback, no halt
                  if (jump_type[1] == JUMP_TYPE_JAL && call_stack_idx != CALL_STACK_LEN - 1) begin
                    // Call stack overflow is a nop
                    pc <= jump_jal_offset;
                    call_stack[call_stack_idx] <= pc - 1;
                    call_stack_idx <= call_stack_idx + 1;
                  end
                  else if (jump_type[1] == JUMP_TYPE_JUMP)
                    pc <= jump_jal_offset;
                end

                // Handle jret: Jump immediately, jret can't be predicated.
                // If there are jumps in the previous 2 cycles, make sure they
                // clear exec stage and aren't taken.
                if (inst_opcode == `JRET_OPCODE && call_stack_idx != 0 && !jump_offsets[0] && !jump_offsets[1]) begin
                  // Call stack underflow is a nop
                  pc <= call_stack[call_stack_idx - 1];
                  call_stack_idx <= call_stack_idx - 1;
                end
              end
            end
          endcase
        end
        STATE_PAUSED: begin
          case (cmd_i)
            `CORE_CTRL_CMD_RUN, `CORE_CTRL_CMD_STEP: begin
              last_cmd_step <= (cmd_i == `CORE_CTRL_CMD_STEP);
              state <= cur_prog;
            end
            `CORE_CTRL_CMD_STOP: begin
              state <= STATE_STOPPED;
            end
          endcase
        end
        STATE_DONE: begin
          job_done_o <= 1;
          if (dispatch_model_done)
            batch_done_o <= 1;

          cur_prog <= next_prog;
          if (pause_at_halt_i || next_prog == STATE_STOPPED)
            state <= STATE_STOPPED;
          else if (should_dispatch)
            state <= STATE_DISPATCHING;
          else
            state <= next_prog;

          if (cmd_i == `CORE_CTRL_CMD_STOP)
            state <= STATE_STOPPED;
        end
      endcase
    end
  end

  always @(*) begin
    // Instruction muxing
    if (state == STATE_STOPPED || halt_counter || state == STATE_DONE)
      // Feed nops after a halt
      inst_o = INST_NOP;
    else if (state == STATE_DISPATCHING)
      inst_o = dispatch_inst;
    else if (core_jump_i)
      inst_o = INST_NOP; // Flush "fetch" stage on a jump
    else
      inst_o = imem_do;

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
  end

endmodule
