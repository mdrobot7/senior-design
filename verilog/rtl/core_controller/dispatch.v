/**
* Core job dispatcher. Assigns $tid to each core using a bunch
* of addi instructions and a fake global register.
*/

module dispatch_m #(
  parameter INDEX_BUFFER_ADDR = 0
) (
  input wire clk_i,
  input wire nrst_i,

  // PKBus
  input wire [`BUS_MIPORT] mport_i,
  output reg [`BUS_MOPORT] mport_o,

  // Shaded vertex cache
  output wire [`WORD] vertcache_test_index_o,
  output reg          vertcache_test_valid_o,
  input  wire         vertcache_test_found_i,

  // Vertex order buffer
  input wire vertorder_full_i,

  input wire reset_dispatch_i,      // Software reset
  input wire enable_i,              // Start dispatching, stop when all cores OR vertex order buf is full
  input wire dispatch_indices_i,   // Dispatch using index buffer and shaded vertex cache
  input wire [`WORD] num_dispatches_i,

  output reg [`WORD] thread_id_o, // Transmitted over global regs r1 data lines, pretending to be $g0
  output wire [`WORD] inst_o,
  output reg [`NUM_CORES-1:0] core_stall_o,

  output reg dispatch_done_o, // 1: This round of dispatching is done
  output reg model_done_o,    // 1: Model or compute job is complete (dispatched num_dispatches_i jobs/indices)
);

  localparam STATE_DISABLED            = 0;
  localparam STATE_CLRP                = 1;
  localparam STATE_DISPATCHING_INDICES = 2;
  localparam STATE_DISPATCHING_INTS    = 3;
  localparam STATE_DISPATCH_DONE       = 4;
  localparam STATE_MODEL_DONE          = 5;

  localparam THREAD_ID_REG       = 0; // $tid, $r0
  localparam THREAD_ID_DUMMY_REG = 16; // $g0, $r16
  localparam ZERO_REG            = 63; // $zero, $r63

  // if (inst_clrp) inst_o = clrp (111)
  // else           inst_o = (000) add $tid, $g0, $zero
  assign inst_o = (inst_clrp)
                ? {`OPCODE_CLRP, `PREDICATE_BITS_WIDTH'0, 4'b0111, 19'b0}
                : {`OPCODE_WIDTH'`OPCODE_ADD,
                   `PREDICATE_BITS_WIDTH'b0,
                   `REG_DEST_WIDTH'THREAD_ID_REG,
                   `REG_SOURCE_WIDTH'THREAD_ID_DUMMY_REG,
                   `REG_SOURCE_WIDTH'ZERO_REG,
                   7'0};

  reg  index_fetch_pause;
  reg  index_fetch_model_done;
  reg  [`STREAM_MIPORT(`WORD_WIDTH)] index_fetch_mstreami;
  wire [`STREAM_MOPORT(`WORD_WIDTH)] index_fetch_mstreamo;
  wire index_fetch_empty = index_fetch_mstreamo[`STREAM_MO_VALID];

  assign model_done_o = dispatch_indices_i ? index_fetch_model_done : (thread_id == num_dispatches_i);
  assign vertcache_test_index_o = index_fetch_mstreamo[`STREAM_MO_DATA(`WORD_WIDTH)];

  index_fetch_m #(
    INDEX_BUFFER_ADDR
  ) index_fetch (
    .clk_i(clk_i),
    .nrst_i(nrst_i),

    .mport_i(mport_i),
    .mport_o(mport_o),

    .pause_i(index_fetch_pause),
    .num_dispatches_i(num_dispatches_i),
    .model_done_clr_i(reset_dispatch_i),
    .model_done_o(index_fetch_model_done),

    .mstream_i(index_fetch_mstreami),
    .mstream_o(index_fetch_mstreamo)
  );

  reg [3:0] state;

  reg [`WORD] thread_id;

  reg [$clog2(`NUM_CORES)-1:0] core_idx;

  always @(posedge clk_i, negedge nrst_i) begin
    if (nrst_i) begin
      inst_clrp <= 0;
      state <= STATE_DISABLED;
      thread_id <= 0;
      core_idx <= 0;
    end
    else if (clk_i) begin
      case (state)
        STATE_DISABLED: begin
          inst_clrp <= 0;

          if (reset_dispatch_i)
            thread_id <= 0;

          if (enable_i)
            state <= STATE_CLRP;
        end
        STATE_CLRP: begin
          // Send out clrp instruction
          core_stall_o <= 0;
          inst_clrp <= 1;

          if (dispatch_indices_i) begin
            state <= STATE_DISPATCHING_INDICES;
            index_fetch_mstreami[`STREAM_MI_READY(`WORD_WIDTH)] <= 1;
            vertcache_test_valid_o <= 1;
          end
          else
            state <= STATE_DISPATCHING_INTS;
        end
        STATE_DISPATCHING_INDICES: begin
          inst_clrp <= 0;

          // Fetch index buffer, check cache, and assign to $tid accordingly.
          if (!index_fetch_empty) begin
            // Check against sahded vertex cache. If present, the cache will
            // automatically forward the index to the vertex order buffer.
            // If missing, assign to a core.
            if (!vertcache_test_found_i) begin
              // Dispatch to core
              thread_id_o <= index_fetch_mstreamo[`STREAM_MO_DATA(`WORD_WIDTH)];
              core_stall_o <= ~(1 << core_idx);
              core_idx <= core_idx + 1;
            end
            else
              core_stall_o <= {`NUM_CORES{1'b1}};
          end

          if (core_idx == `NUM_CORES - 1 || vertorder_full_i) begin
            core_stall_o <= {`NUM_CORES{1'b1}};
            vertcache_test_valid_o <= 0;
            index_fetch_mstreami[`STREAM_MI_READY(`WORD_WIDTH)] <= 0;
            dispatch_done_o <= 1;
            state <= STATE_DISPATCH_DONE;
          end
          if (index_fetch_model_done) begin
            core_stall_o <= {`NUM_CORES{1'b1}};
            vertcache_test_valid_o <= 0;
            index_fetch_mstreami[`STREAM_MI_READY(`WORD_WIDTH)] <= 0;
            dispatch_done_o <= 1;
            state <= STATE_MODEL_DONE;
          end
        end
        case STATE_DISPATCHING_INTS: begin
          inst_clrp <= 0;

          // Fill in $tid with increasing numbers
          if (core_idx == `NUM_CORES - 1) begin
            core_stall_o <= {`NUM_CORES{1'b1}};
            core_idx <= 0;
            dispatch_done_o <= 1;
            state <= STATE_DISPATCH_DONE;
          end
          else if (thread_id == num_dispatches_i - 1) begin
            core_stall_o <= {`NUM_CORES{1'b1}};
            core_idx <= 0;
            dispatch_done_o <= 1;
            state <= STATE_MODEL_DONE;
          else begin
            core_stall_o <= ~(1 << core_idx);
            thread_id_o <= thread_id;
            thread_id <= thread_id + 1;
            core_idx <= core_idx + 1;
          end
        end
        case STATE_DISPATCH_DONE: begin
          if (!enable_i) begin
            dispatch_done_o <= 0;
            state <= STATE_DISABLED;
          end
        end
        case STATE_MODEL_DONE: begin
          if (reset_dispatch_i && !enable_i) begin
            dispatch_done_o <= 0;
            thread_id <= 0;
            state <= STATE_DISABLED;
          end
        end
      endcase
    end
  end

endmodule
