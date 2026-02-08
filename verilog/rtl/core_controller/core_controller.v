module core_controller_wrapper_m #() (
`ifdef USE_POWER_PINS
    inout vpwrac,
    input vpwrpc,
`endif

    // Wishbone
    input wire wb_clk_i,
    input wire wb_rst_i,
    input wire wbs_stb_i,
    input wire wbs_cyc_i,
    input wire wbs_we_i,
    input wire [3:0] wbs_sel_i,
    input wire [`WORD_WIDTH-1:0] wbs_dat_i,
    input wire [`WORD_WIDTH-1:0] wbs_adr_i,
    output reg wbs_ack_o,
    output reg [`WORD_WIDTH-1:0] wbs_dat_o,

    // PKBus
    input wire [`BUS_MIPORT] mport_i, // For pixel data only
    output reg [`BUS_MOPORT] mport_o,
);


endmodule

/*
* Core controller module (aka meta-core, mc, master chief, minecraft, emcee...)
* Handles the PC, instruction fetch, global regfile, job dispatch,
* vertex/fragment shading switchover, index prefetching, and interfacing
* between the management core and the shader cores.
*
* Will always alternate between
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
  input  wire [IMEM_ADDR_WIDTH-1:0] imem_addr_i,

  // Global regfile
  input  wire [`REG_SOURCE_WIDTH-1:0] global_regfile_write_addr_i,
  input  wire [`REG_SOURCE_WIDTH-1:0] global_regfile_read_addr_i,
  input  wire                         global_regfile_write_en_i,
  input  wire [`WORD]                 global_regfile_write_data_i,
  output wire [`WORD]                 global_regfile_read_data_o,

  // PCs
  input wire [IMEM_ADDR_WIDTH-1:0] pc_vertex_shading_i,
  input wire [IMEM_ADDR_WIDTH-1:0] pc_fragment_shading_i,
  input wire [IMEM_ADDR_WIDTH-1:0] pc_gpgpu_compute_i,

  // PKBus
  input  wire [`BUS_MIPORT] mport_i,
  output wire [`BUS_MOPORT] mport_o,

  // Shaded vertex cache
  output wire [`WORD] vertcache_test_index_o,
  output wire         vertcache_test_valid_o,
  input  wire         vertcache_test_found_i,

  // Vertex order buffer
  input  wire [`STREAM_SIPORT(`NUM_CORES_WIDTH)] vertorder_sstream_i,
  output wire [`STREAM_SOPORT(`NUM_CORES_WIDTH)] vertorder_sstream_o,
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
  input  wire                  dispatch_en_i,
  input  wire                  dispatch_indices_i,  // 0: $tid set to increasing ints, 1: $tid set using index buffer
  input  wire [`WORD]          num_dispatches_i,    // Number of jobs (indices or ints) to dispatch
  input  wire                  batch_done_clr_i,    // 1: clear batch done flag
  output  reg                  batch_done_o,        // 1: finished a shader program (i.e. reached a halt)
  input  wire                  model_done_clr_i,    // 1: clear model done flag
  output  reg                  model_done_o,        // 1: finished num_dispatches_i jobs.
  output wire [2:0]            status_o,

  // Shader core interface
  output wire [`WORD]           inst_o,
  output wire [`NUM_CORES-1:0]  core_reset_o, // Core soft reset
  input  wire [`NUM_CORES-1:0]  core_stall_i,
  output wire [`NUM_CORES-1:0]  core_stall_o, // Per-core stall control
  input  wire [`NUM_CORES-1:0]  core_flush_i,
  output wire                   core_flush_o, // Flushes all stages on all cores
  input  wire [`NUM_CORES-1:0]  core_jump_i,
  output wire                   core_jump_o,  // Flushes decode on all cores
  output wire [`WORD]           global_regfile_rs1_data_o,
  output wire [`WORD]           global_regfile_rs2_data_o
);

  localparam CALL_STACK_BITS = $clog2(CALL_STACK_LEN);

  localparam IMEM_ADDR_WIDTH = 10;
  localparam IMEM_ADDR_MAX   = (1 << IMEM_ADDR_MAX) - 1;
  localparam INST_NOP        = 32'h08000000;

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
  localparam STATE_HALTING          = 6; // Used for pause on halt and when a model finishes

  // IMEM
  wire [`WORD_WIDTH-1:0] imem_do;
  wire                   imem_addr = (state == STATE_STOPPED) ? imem_addr_i : pc; // In *words*
  wire                   imem_rw   = (state == STATE_STOPPED) ? imem_rw_i   : 1;
`ifndef FPGA
  sram_ip_wrapper imem(`WORD_WIDTH, IMEM_ADDR_WIDTH) (
    .CLKin(clk_i),
    .DO(imem_do),
    .DI(imem_di_i),
    .BEN(32'hFFFFFFFF), // Write mask
    .AD(imem_addr),
    .EN(1),
    .R_WB(imem_rw),

    // Test signals
    .WLBI(0),
    .WLOFF(0),
    .TM(0),
    .SM(0),
    .ScanInCC(0),
    .ScanInDL(0),
    .ScanInDR(0),
    .ScanOutCC(),

`ifdef USE_POWER_PINS
    .vpwrac(vpwrac),
    .vpwrpc(vpwrpc)
`endif
  );
`else FPGA
  (* ram_style = "block" *) reg [`WORD] imem [1023:0];
  assign imem_do = imem[imem_addr];

  always @(negedge nrst_i, posedge clk_i) begin
    if (!nrst_i) begin
      for (i = 0; i < 1024; i++)
        imem <= 0;
    end
    else if (clk_i) begin
      if (!imem_rw)
        imem[imem_addr] <= imem_di_i;
    end
`endif

  // Instruction decode
  wire [`OPCODE_WIDTH-1:0]     inst_opcode      = imem_do[`OPCODE_IDX];
  wire [`REG_SOURCE_WIDTH-1:0] inst_rs1         = imem_do[`R1_IDX];
  wire [`REG_SOURCE_WIDTH-1:0] inst_rs2         = imem_do[`R2_IDX];
  wire [`JUMP_WIDTH-1:0]       inst_jump_offset = imem_do[`JUMP_IDX];

  // Tracking jumps and halts through the core pipeline
  reg  [1:0]                  halt_counter;
  reg  [`JUMP_WIDTH-1:0]      jump_offsets [JUMP_STAGE];
  reg  [JUMP_STAGE-1:0]       jump_type;
  wire [`IMEM_ADDR_WIDTH-1:0] jump_jal_offset = pc + jump_offsets[1][22:2]; // Add word offset, not byte offset
  wire [`IMEM_ADDR_WIDTH-1:0] jret_offset     = pc + call_stack[call_stack_idx][22:2];

  // PC, in *words*
  reg [IMEM_ADDR_WIDTH-1:0] pc;

  // Call stack
  reg [CALL_STACK_LEN-1:0]  call_stack[`IMEM_ADDR_WIDTH-1:0];
  reg [CALL_STACK_BITS-1:0] call_stack_idx;

  // Global regfile
  wire                         global_regfile_write_en    = (state == STATE_STOPPED)     ? global_regfile_write_en_i  : 0;
  wire [`REG_SOURCE_WIDTH-1:0] global_regfile_r1_addr     = (state == STATE_STOPPED)     ? global_regfile_read_addr_i : inst_rs1;
  wire [`WORD_WIDTH-1:0]       global_regfile_r1_data;
  assign                       global_regfile_read_data_o = (state == STATE_STOPPED)     ? global_regfile_r1_data     : 0;
  assign                       global_regfile_rs1_data_o  = (state == STATE_DISPATCHING) ? dispatch_thread_id         : global_regfile_r1_data;
  regfile_m global_regfile(`WORD_WIDTH, 48, 16, 1, 6) (
    .clk_i(clk_i),
    .nrst_i(nrst_i),

    .wr_en_i(global_regfile_write_en),
    .wr_addr_i(global_regfile_write_addr_i),
    .wr_data_i(global_regfile_write_data_i),

    .r1_addr_i(global_regfile_r1_addr),  // Muxed between the shader cores and wishbone interface
    .r2_addr_i(inst_rs2),
    .r1_data_o(global_regfile_r1_data),  // Muxed between the shader cores and wishbone interface
    .r2_data_o(global_regfile_rs2_data_o)
  );

  // Dispatch
  wire         dispatch_index_fetch_enable = (state != STATE_STOPPED);
  wire         dispatch_reset              = (state == STATE_STOPPED);
  reg          dispatch_enable;
  wire [`WORD] dispatch_thread_id;
  wire [`WORD] dispatch_inst;
  wire [`WORD] dispatch_core_stall;
  wire         dispatch_done;
  wire         dispatch_model_done;
  dispatch_m #(
    INDEX_BUFFER_ADDR
  ) (
    .clk_i(clk_i),
    .nrst_i(nrst_i),

    .mport_i(mport_i),
    .mport_o(mport_o),

    .vertcache_test_index_o(vertcache_test_index_o),
    .vertcache_test_valid_o(vertcache_test_valid_o),
    .vertcache_test_found_i(vertcache_test_found_i),

    .vertorder_sstream_i(vertorder_sstream_i),
    .vertorder_sstream_o(vertorder_sstream_o),
    .vertorder_full_i(vertorder_full_i),

    .index_buffer_addr_i(index_buffer_addr_i),
    .index_fetch_enable_i(dispatch_index_fetch_enable),

    .reset_dispatch_i(reset_dispatch_i),
    .enable_i(dispatch_enable),
    .dispatch_indices_i(dispatch_indices_i),
    .num_dispatches_i(num_dispatches_i),
    .core_enable_i(core_enable_i),

    .thread_id_o(dispatch_thread_id),
    .inst_o(dispatch_inst),
    .core_stall_o(dispatch_core_stall),

    .dispatch_done_o(dispatch_done),
    .model_done_o(dispatch_model_done),
  );

  assign imem_do_o = (state == STATE_STOPPED) ? imem_do : 0;
  assign status_o  = state;

  reg  [2:0] state;
  reg  [2:0] cur_prog;
  wire [2:0] next_prog;

  reg last_cmd_step; // 1: last command was a step

  wire is_rasterization = (dispatch_en_i && dispatch_indices_i);
  wire should_dispatch  = (dispatch_en_i && next_prog != STATE_FRAGMENT_SHADING);

  integer i;

  always @(posedge clk_i, negedge nrst_i) begin
    if (!nrst_i) begin
      batch_done_o <= 0;
      model_done_o <= 0;

      halt_counter <= 0;
      for (i = 0; i < JUMP_IDX; i++)
        jump_offsets[i] <= 0;
      jump_type <= 0;

      pc <= 0;

      for (i = 0; i < CALL_STACK_LEN; i++)
        call_stack[i] <= 0;
      call_stack_idx <= 0;

      dispatch_enable <= 0;

      cur_prog      <= STATE_STOPPED;
      state         <= STATE_STOPPED;
      last_cmd_step <= 0;
    end
    else if (clk_i) begin
      if (batch_done_clr_i)
        batch_done_o <= 0;
      if (model_done_clr_i)
        model_done_o <= 0;

      case (state) begin
        STATE_STOPPED: begin
          if (cmd_i == CORE_CTRL_CMD_RUN || cmd_i == CORE_CTRL_CMD_STEP) begin
            last_cmd_step = (cmd_i == CORE_CTRL_CMD_STEP);

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
            case (next_prog) begin
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
        STATE_VERTEX_SHADING, STATE_FRAGMENT_SHADING, STATE_GPGPU_COMPUTE: begin
          case (cmd_i) begin
            CORE_CTRL_CMD_STOP: begin
              state <= STATE_STOPPED;
            end
            CORE_CTRL_CMD_PAUSE: begin
              state <= STATE_PAUSED;
            end
            CORE_CTRL_CMD_RUN, CORE_CTRL_CMD_STEP: begin
              if (!core_stall_i && last_cmd_step) begin
                pc <= pc + 1;

                if (last_cmd_step)
                  last_cmd_step <= 0;

                // Handle halt and program switchover
                if (inst_opcode == OPCODE_HALT) begin
                  batch_done_o <= 1;
                  cur_prog <= next_prog;
                  if (pause_at_halt_i || next_prog == STATE_STOPPED)
                    state <= STATE_HALTING;
                  else if (should_dispatch)
                    state <= STATE_DISPATCHING;
                  else
                    state <= next_prog;
                end

                // Handle jump, jal: Record jump offsets and wait for jump sig
                // from any core. If jal, push to call stack.
                jump_offsets[1] <= jump_offsets[0];
                jump_type[1] <= jump_type[0];
                if (inst_opcode == OPCODE_JUMP || inst_opcode == OPCODE_JAL) begin
                  jump_offsets[0] <= inst_jump_offset;
                  jump_type[0] <= (inst_opcode == OPCODE_JAL) ? JUMP_TYPE_JAL : JUMP_TYPE_JUMP;
                end
                if (core_jump_i) begin
                  if (jump_type[1] == JUMP_TYPE_JAL && call_stack_idx != CALL_STACK_LEN - 1) begin
                    // Call stack overflow is a nop
                    pc <= jump_jal_offset;
                    call_stack[call_stack_idx] <= jump_jal_offset;
                    call_stack_idx <= call_stack_idx + 1;
                  end
                  else if (jump_type[1] == JUMP_TYPE_JUMP)
                    pc <= jump_jal_offset;
                end

                // Handle jret: Jump immediately, jret can't be predicated
                if (inst_opcode == OPCODE_JRET && call_stack_idx != 0) begin
                  // Call stack underflow is a nop
                  pc <= call_stack[call_stack_idx];
                  call_stack_idx <= call_stack_idx - 1;
                end
              end
            end
          endcase
        end
        STATE_PAUSED: begin
          case (cmd_i) begin
            CORE_CTRL_CMD_RUN, CORE_CTRL_CMD_STEP: begin
              last_cmd_step <= (cmd_i == CORE_CTRL_CMD_STEP);
              state <= cur_prog;
            end
            CORE_CTRL_CMD_STOP: begin
              state <= STATE_STOPPED;
            end
          end
        end
        STATE_HALTING: begin
          if (halt_counter == HALT_STAGE - 1) begin
            // Halt inst has reached writeback, decide what to do next
            if (dispatch_model_done)
              model_done_o <= 1;
            if (pause_at_halt_i) begin
              if (cmd_i == CORE_CTRL_CMD_RUN || cmd_i == CORE_CTRL_CMD_STEP)
                state <= (should_dispatch ? STATE_DISPATCHING : next_prog);
            end
            else
              state <= STATE_STOPPED;
          end
          else
            halt_counter <= halt_counter + 1;
          if (cmd_i == CORE_CTRL_CMD_STOP)
            state <= STATE_STOPPED;
        end
      endcase
    end
  end

  always @(*) begin
    // Instruction muxing
    if (state == STATE_STOPPED || halt_counter != 0)
      // Feed nops after a halt
      inst_o = INST_NOP;
    else if (state == STATE_DISPATCHING)
      inst_o = dispatch_inst;
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
    core_flush_o = (core_flush_i ? 1 : 0);
    core_jump_o  = (core_jump_o  ? 1 : 0);

    // Next program selection
    if (cur_prog == STATE_GPGPU_COMPUTE)
      if (dispatch_model_done)
        next_prog = STATE_STOPPED;
      else
        next_prog = STATE_GPGPU_COMPUTE;
    end
    else if (cur_prog == STATE_VERTEX_SHADING)
      if (fragfifo_cores_dispatched_i == `NUM_CORES - 1 ||
          fragfifo_full_i ||
          dispatch_model_done)
        next_prog = STATE_FRAGMENT_SHADING;
      else
        next_prog = STATE_VERTEX_SHADING;
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
