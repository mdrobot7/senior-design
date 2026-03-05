/*
 * Shader core instruction fetch stage. Handles fetching
 * instructions from IMEM, jumps, the call stack, and the
 * global register file. Active while programs are executing
 * (STATE_GPGPU_COMPUTE, STATE_VERTEX_SHADING, STATE_FRAGMENT_SHADING
 * in core controller).
 */
module inst_fetch_m #(
  parameter CALL_STACK_LEN = 8
) (
  input wire clk_i,
  input wire nrst_i,

  // IMEM wishbone iface, active when enable_i = 0
  input  wire                                imem_rw_i, // 1 = read, 0 = write
  output wire [`WORD]                        imem_do_o,
  input  wire [`WORD]                        imem_di_i,
  input  wire [`SRAM_1024x32_ADDR_WIDTH-1:0] imem_addr_i,

  // Global regfile wishbone iface, active when enable_i = 0
  input  wire [`REG_SOURCE_WIDTH-1:0] global_regfile_addr_i,
  input  wire                         global_regfile_write_en_i,
  input  wire [`WORD]                 global_regfile_write_data_i,
  output wire [`WORD]                 global_regfile_read_data_o,

  input wire [`SRAM_1024x32_ADDR_WIDTH-1:0] prog_entry_i, // Program entry point, latched when program is reset

  // Core controller interface
  input  wire       enable_i,
  input  wire       reset_prog_i,
  output reg        step_done_o,
  output reg        prog_done_o,

  output reg  [`WORD]           inst_o,
  input  wire [`NUM_CORES-1:0]  core_stall_i,
  input  wire [`NUM_CORES-1:0]  core_jump_i,
  output wire [`WORD]           global_regfile_rs1_data_o,
  output wire [`WORD]           global_regfile_rs2_data_o
);

  localparam INST_NOP        = 32'h04000000;

  localparam CALL_STACK_BITS = $clog2(CALL_STACK_LEN);

  localparam HALT_STAGE     = 3; // 1 = decode, 4 = writeback
  localparam JUMP_STAGE     = 2; // 1 = decode, 2 = exec
  localparam JUMP_TYPE_JUMP = 0;
  localparam JUMP_TYPE_JAL  = 1;

  localparam STATE_READY   = 0;
  localparam STATE_EXECUTE = 1;
  localparam STATE_DONE    = 2;

  reg [1:0] state;

  // PC, in *words*
  reg [`SRAM_1024x32_ADDR_WIDTH-1:0] pc;

  // Call stack
  reg [`SRAM_1024x32_ADDR_WIDTH-1:0] call_stack[CALL_STACK_LEN-1:0];
  reg [CALL_STACK_BITS-1:0]          call_stack_idx;

  // Tracking jumps and halts through the core pipeline
  reg  [1:0]                          halt_counter;
  reg  [`SRAM_1024x32_ADDR_WIDTH-1:0] jump_bases [JUMP_STAGE-1:0]; // PC at the time the jump was taken
  reg  [`JUMP_WIDTH-1:0]              jump_offsets [JUMP_STAGE-1:0]; // Jump offset from instruction
  reg  [JUMP_STAGE-1:0]               jump_type;
  wire [`SRAM_1024x32_ADDR_WIDTH-1:0] jump_jal_offset = jump_bases[1] + $signed(jump_offsets[1][22:2]) + 1; // Add word offset, not byte offset

  // IMEM
  wire [`WORD]                        imem_do;
  wire [`SRAM_1024x32_ADDR_WIDTH-1:0] imem_addr = !enable_i ? imem_addr_i : pc; // In *words*
  wire                                imem_rw   = !enable_i ? imem_rw_i   : 1;
  reg  [`WORD]                        imem_do_latch;
  sram_1024x32_m imem (
`ifdef USE_POWER_PINS
    .vpwrac(vpwrac),
    .vpwrpc(vpwrpc),
`endif

    .clk_i(clk_i),
    .addr_i(imem_addr),
    .read_en_i(imem_rw),
    .en_i(1'b1),
    .data_i(imem_di_i),
    .data_o(imem_do)
  );

  // Instruction decode
  wire [`OPCODE_WIDTH-1:0]     inst_opcode      = imem_do_latch[`OPCODE_IDX];
  wire [`REG_SOURCE_WIDTH-1:0] inst_rs1         = imem_do_latch[`R1_IDX];
  wire [`REG_SOURCE_WIDTH-1:0] inst_rs2         = imem_do_latch[`R2_IDX];
  wire [`JUMP_WIDTH-1:0]       inst_jump_offset = imem_do_latch[`JUMP_IDX];

  // Global regfile
  wire                         global_regfile_write_en    = !enable_i ? global_regfile_write_en_i : 0;
  wire [`REG_SOURCE_WIDTH-1:0] global_regfile_r1_addr     = !enable_i ? global_regfile_addr_i     : inst_rs1;
  wire [`WORD]                 global_regfile_r1_data;
  assign                       global_regfile_read_data_o = !enable_i ? global_regfile_r1_data    : 0;
  assign                       global_regfile_rs1_data_o  = global_regfile_r1_data;
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

  assign imem_do_o = imem_do;

  always @(posedge clk_i, negedge nrst_i) begin
    if (!nrst_i) begin : RESET
      integer i;

      step_done_o <= 0;
      prog_done_o <= 0;
      inst_o <= 0;

      call_stack_idx <= 0;
      for (i = 0; i < JUMP_STAGE; i++) begin
        jump_bases[i] <= 0;
        jump_offsets[i] <= 0;
        jump_type[i] <= 0;
      end
      imem_do_latch <= INST_NOP;

      state <= STATE_READY;
    end
    else if (clk_i) begin
      case (state)
        STATE_READY: begin
          step_done_o <= 0;
          prog_done_o <= 0;
          if (enable_i)
            state <= STATE_EXECUTE;
        end
        STATE_EXECUTE: begin
          if (!enable_i)
            state <= STATE_READY;
          else if (!core_stall_i) begin
            imem_do_latch <= imem_do;
            pc <= pc + 1;

            step_done_o <= 1;

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
              imem_do_latch <= INST_NOP; // Flush IMEM latch "stage"
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
        STATE_DONE: begin
          prog_done_o <= 1;
          state <= STATE_READY;
        end
      endcase

      if (reset_prog_i || state == STATE_DONE) begin : SYNC_RESET
        integer i;

        call_stack_idx <= 0;
        for (i = 0; i < JUMP_STAGE; i++) begin
          jump_bases[i] <= 0;
          jump_offsets[i] <= 0;
          jump_type[i] <= 0;
        end
        imem_do_latch <= INST_NOP;
        pc <= prog_entry_i;
        state <= STATE_READY;
      end
    end
  end

  always @(*) begin
    if (halt_counter || core_jump_i || state != STATE_EXECUTE)
      // Feed nops after a halt and flush "fetch" stage on a jump
      inst_o = INST_NOP;
    else
      inst_o = imem_do_latch;
  end

endmodule
