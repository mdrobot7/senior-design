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


module core_controller_m #(
  parameter INDEX_BUFFER_ADDR = 0
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
  input  wire [`WORD_WIDTH-1:0]       global_regfile_write_data_i,
  output wire [`WORD_WIDTH-1:0]       global_regfile_read_data_o,

  // PKBus
  input wire [`BUS_MIPORT] mport_i,
  output reg [`BUS_MOPORT] mport_o,

  // Shaded vertex cache
  output wire [`WORD] vertcache_test_index_o,
  output wire         vertcache_test_valid_o,
  input  wire         vertcache_test_found_i,

  // Vertex order buffer
  input wire vertorder_full_i,

  // Config/control
  input wire reset_core_i,    // 1: reset shader cores
  input wire run_i,           // 0: pause, 1: play
  input wire pause_at_halt_i, // 0: continue to next PC in PC list after halt. 1: pause after halt
  input wire halt_reached_clr_i, // 1: clear halt reached flag
  output reg halt_reached_o,
  output reg error_o,
  input wire dispatch_indices_i,       // 0: $tid set to increasing ints, 1: $tid set using index buffer
  input wire [`WORD] num_dispatches_i, // Number of jobs (indices or ints) to dispatch
  output wire model_done_o;

  // Shader core interface
  output wire [`WORD]           inst_o,
  input  wire [`NUM_CORES-1:0]  core_stall_i,
  output wire [`NUM_CORES-1:0]  core_stall_o, // Per-core stall control
  input  wire [`NUM_CORES-1:0]  core_flush_i,
  output wire                   core_flush_o, // Flushes all stages on all cores
  input  wire [`NUM_CORES-1:0]  core_jump_i,
  output wire                   core_jump_o,  // Flushes decode on all cores
  output wire [`WORD_WIDTH-1:0] global_regfile_rs1_data_o,
  output wire [`WORD_WIDTH-1:0] global_regfile_rs2_data_o
);

  localparam PC_LIST_LEN = 8;
  localparam PC_LIST_BITS = 3;

  localparam CALL_STACK_LEN = 8;
  localparam CALL_STACK_BITS = 3;

  localparam IMEM_ADDR_WIDTH = 10;
  localparam IMEM_ADDR_MAX = (1 << IMEM_ADDR_MAX) - 1;
  localparam INST_NOP = 32'h08000000;

  localparam HALT_STAGE = 3; // 1 = decode, 4 = writeback
  localparam JUMP_STAGE = 2; // 1 = decode, 4 = exec
  localparam JUMP_TYPE_JUMP = 0;
  localparam JUMP_TYPE_JAL = 1;

  localparam STATE_STOPPED = 0; // Waiting for program to start from beginning
  localparam STATE_DISPATCHING = 1; // Dispatching jobs
  localparam STATE_VERTEX_SHADING = 2;
  localparam STATE_FRAGMENT_SHADING = 3;
  localparam STATE_RUNNING = 1;
  localparam STATE_PAUSED = 2; // Manual pause by management core
  localparam STATE_HALTED = 3; // Halt instruction reached writeback
  localparam STATE_ERROR = 4;

  // IMEM
  wire [`WORD_WIDTH-1:0] imem_do;
  assign imem_do_o = (state == STATE_STOPPED) ? imem_do : 0;
  wire imem_addr   = (state == STATE_STOPPED) ? imem_addr_i : pc; // In *words*
  wire imem_rw     = (state == STATE_STOPPED) ? imem_rw_i : 1;
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

  // Instruction decode
  wire [`OPCODE_WIDTH-1:0] inst_opcode    = imem_do[`OPCODE_IDX];
  wire [`REG_SOURCE_WIDTH-1:0] inst_rs1   = imem_do[`R1_IDX];
  wire [`REG_SOURCE_WIDTH-1:0] inst_rs2   = imem_do[`R2_IDX];
  wire [`JUMP_WIDTH-1:0] inst_jump_offset = imem_do[`JUMP_IDX];

  // Tracking jumps and halts through the core pipeline
  reg [1:0] halt_counter;
  assign inst_o = (halt_counter != 0) ? INST_NOP : imem_do; // Feed the core NOPs after a halt
  reg [`JUMP_WIDTH-1:0] jump_offsets [JUMP_STAGE];
  reg [JUMP_STAGE-1:0] jump_type;
  wire [`IMEM_ADDR_WIDTH-1:0] jump_jal_offset = pc + jump_offsets[1][22:2]; // Add word offset, not byte offset
  wire [`IMEM_ADDR_WIDTH-1:0] jret_offset     = pc + call_stack[call_stack_idx][22:2];

  // Core control signals
  reg core_stall;
  assign core_stall_o = (state == STATE_RUNNING) ? (core_stall_i ? 1'b1 : 0) : core_stall;
  reg core_flush;
  assign core_flush_o = (state == STATE_RUNNING) ? (core_flush_i ? 1'b1 : 0) : core_flush;
  assign core_jump_o = core_jump_i ? 1'b1 : 1'b0

  // PC, in *words*
  reg [PC_LIST_LEN-1:0] pc_list[`IMEM_ADDR_WIDTH-1:0];
  reg [PC_LIST_BITS-1:0] pc_list_idx;
  wire pc = pc_list[pc_list_idx];

  // Call stack
  reg [CALL_STACK_LEN-1:0] call_stack[`IMEM_ADDR_WIDTH-1:0];
  reg [CALL_STACK_BITS-1:0] call_stack_idx;

  // Global regfile
  wire global_regfile_write_en                   = (state == STATE_RUNNING) ? 0        : global_regfile_write_en_i;
  wire [`REG_SOURCE_WIDTH-1:0] global_regfile_r1 = (state == STATE_RUNNING) ? inst_rs1 : global_regfile_read_addr_i;
  wire [`WORD_WIDTH-1:0] global_regfile_r1_data;
  assign global_regfile_rs1_data_o = global_regfile_r1_data;
  assign global_regfile_read_data_o = global_regfile_r1_data;
  regfile_m global_regfile(`WORD_WIDTH, 48, 16, 1, 6) (
    .clk_i(clk_i),
    .nrst_i(nrst_i),
    .wr_en_i(global_regfile_write_en),
    .wr_addr_i(global_regfile_write_addr_i),
    .wr_data_i(global_regfile_write_data_i),
    .r1_addr_i(global_regfile_r1),
    .r2_addr_i(inst_rs2),
    .r1_data_o(global_regfile_r1_data),
    .r2_data_o(global_regfile_rs2_data_o)
  );

  // Dispatch
  reg dispatch_enable;
  wire [`WORD] dispatch_thread_id;
  wire [`WORD] dispatch_inst;
  wire [`WORD] dispatch_core_stall;
  wire dispatch_done;
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

    .vertorder_full_i(vertorder_full_i),

    .reset_dispatch_i(reset_dispatch_i),
    .enable_i(dispatch_enable),
    .dispatch_indices_i(dispatch_indices_i),
    .num_dispatches_i(num_dispatches_i),

    .thread_id_o(dispatch_thread_id),
    .inst_o(dispatch_inst),
    .core_stall_o(dispatch_core_stall),

    .dispatch_done_o(dispatch_done),
    .model_done_o(model_done_o), //  TODO fix
  )

  reg [3:0] state;

  integer i;

  always @(posedge clk_i, negedge nrst_i) begin
    if (!nrst_i) begin
      halt_reached_o <= 0;
      error_o <= 0;

      halt_counter <= 0;
      for (i = 0; i < JUMP_IDX; i++)
        jump_offsets[i] <= 0;
      jump_type <= 0;

      core_stall <= 0;
      core_flush <= 1;

      for (i = 0; i < PC_LIST_LEN; i++)
        pc_list[i] <= 0;
      pc_list_idx <= 0;

      for (i = 0; i < CALL_STACK_LEN; i++)
        call_stack[i] <= 0;
      call_stack_idx <= 0;

      state <= STATE_STOPPED;
    end
    else if (clk_i) begin
      if (reset_core_i) begin
        // Shader core soft reset
        state <= STATE_STOPPED;
        core_flush <= 1;
        core_stall <= 1;
        error_o <= 0;
      end
      else begin
        case (state) begin
          STATE_STOPPED: begin
            if (run_i) begin
              core_stall <= 0;
              core_flush <= 0;
              state <= STATE_RUNNING;
            end
          end
          STATE_RUNNING: begin
            if (!run_i) begin
              core_stall <= 1;
              state <= STATE_PAUSED;
            end

            if (!core_stall_i) begin
              if (pc == IMEM_ADDR_MAX - 1)
                state <= STATE_ERROR; // Overran end of IMEM
              else
                pc <= pc + 1;

              // Handle halt: Wait until halt instruction reaches writeback
              if (inst_opcode == OPCODE_HALT || halt_counter)
                halt_counter <= halt_counter + 1;
              if (halt_counter == HALT_STAGE - 1) begin
                core_stall <= 1;
                core_flush <= 1;
                halt_reached_o <= 1;
                state <= STATE_HALTED;
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
          STATE_PAUSED: begin
            if (run_i) begin
              core_stall <= 0;
              state <= STATE_RUNNING;
            end
          end
          STATE_HALTED: begin
            halt_counter <= 0;
            if (pause_at_halt_i) begin
              if (!run_i)
                state <= STATE_STOPPED;
            end
            else begin
              pc_list_idx <= pc_list_idx + 1;
              core_stall <= 0;
              core_flush <= 0;
              state <= STATE_RUNNING;
            end
          end
          STATE_ERROR: begin
            error_o <= 1;
            if (!run_i)
              state <= STATE_STOPPED;
          end
        endcase
      end

      if (halt_reached_clr_i)
        halt_reached_o <= 0;
    end
  end

endmodule
