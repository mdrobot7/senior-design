/**
* Core job dispatcher. Assigns $tid to each core using a bunch
* of addi instructions and a fake global register.
*
* Dispatches either increasing integers or indices from the index
* buffer. If dispatching indices, first checks the shaded vertex
* cache. If present, sends `NUM_CORES to the vertex order buffer.
* Otherwise, dispatches the index to a core and sends the core number
* to the vertex order buffer.
*/

module dispatch_m #(
  parameter INDEX_FETCH_CACHE_LEN_WORDS = 64
) (
  input wire clk_i,
  input wire nrst_i,

  // PKBus
  input  wire [`BUS_MIPORT] mport_i,
  output wire [`BUS_MOPORT] mport_o,

  // Shaded vertex cache
  output wire [`WORD] vertcache_test_index_o,
  output  reg         vertcache_test_valid_o,
  input  wire         vertcache_test_found_i,

  // Vertex order buffer
  input wire [`STREAM_MIPORT(`VERTEX_ORDER_WIDTH)] vertorder_mstream_i,
  output reg [`STREAM_MOPORT(`VERTEX_ORDER_WIDTH)] vertorder_mstream_o,
  input wire                                       vertorder_full_i,

  // Index fetcher
  input  wire [`WORD] index_buffer_addr_i,
  input  wire         index_fetch_enable_i,
  input  wire         index_fetch_clear_i,
  output wire         index_fetch_clear_done_o,

  input wire                  reset_dispatch_i,   // Reset dispatch counter and state machine
  input wire                  enable_i,           // Start dispatching, stop when all cores OR vertex order buf is full
  input wire                  dispatch_indices_i, // Dispatch using index buffer and shaded vertex cache
  input wire [`WORD]          num_dispatches_i,
  input wire [`NUM_CORES-1:0] core_enable_i,      // Core enabled/disabled flag. Don't dispatch to disabled cores.

  output  reg [`WORD]          thread_id_o, // Transmitted over global regs r1 data lines, pretending to be $g0
  output wire [`WORD]          inst_o,
  output  reg [`NUM_CORES-1:0] core_stall_o,

  output reg  dispatch_done_o, // 1: This round of dispatching is done
  output wire model_done_o     // 1: Model or compute job is complete (dispatched num_dispatches_i jobs/indices)
);

  localparam STATE_DISABLED            = 0;
  localparam STATE_DISPATCHING_INDICES = 1;
  localparam STATE_DISPATCHING_INTS    = 2;
  localparam STATE_DISPATCH_DONE       = 3;
  localparam STATE_MODEL_DONE          = 4;

  localparam THREAD_ID_REG       = `REG_DEST_WIDTH'd0;  // $tid, $r0
  localparam THREAD_ID_DUMMY_REG = `REG_SOURCE_WIDTH'd16; // $g0, $r16
  localparam ZERO_REG            = `REG_SOURCE_WIDTH'd63; // $zero, $r63

  // inst_o = (000) add $tid, $g0, $zero
  assign inst_o = {`ADD_OPCODE,
                   `PREDICATE_BITS_WIDTH'b0,
                   THREAD_ID_REG,
                   THREAD_ID_DUMMY_REG,
                   ZERO_REG,
                   7'b0};

  wire                               index_fetch_model_done;
  reg  [`STREAM_MIPORT(`WORD_WIDTH)] index_fetch_mstreami;
  wire [`STREAM_MOPORT(`WORD_WIDTH)] index_fetch_mstreamo;
  wire                               index_fetch_empty = !index_fetch_mstreamo[`STREAM_MO_VALID(`WORD_WIDTH)];
  index_fetch_m #(
    INDEX_FETCH_CACHE_LEN_WORDS
  ) index_fetch (
    .clk_i(clk_i),
    .nrst_i(nrst_i),

    .mport_i(mport_i),
    .mport_o(mport_o),

    .enable_i(index_fetch_enable_i),
    .index_buffer_addr_i(index_buffer_addr_i),
    .num_dispatches_i(num_dispatches_i),
    .model_done_clr_i(reset_dispatch_i),
    .model_done_o(index_fetch_model_done),
    .clear_i(index_fetch_clear_i),
    .clear_done_o(index_fetch_clear_done_o),

    .mstream_i(index_fetch_mstreami),
    .mstream_o(index_fetch_mstreamo)
  );

  reg [3:0] state;

  reg [`WORD] thread_id;

  reg [`NUM_CORES_WIDTH-1:0] core_idx;

  wire [`NUM_CORES-1:0] core_stall              = ~(1 << core_idx);
  wire [`NUM_CORES-1:0] core_stall_undispatched = {`NUM_CORES{1'b1}} << core_idx; // Handle partial dispatch by stalling cores without jobs

  assign model_done_o           = dispatch_indices_i
                                  ? (index_fetch_model_done && index_fetch_empty)
                                  : (thread_id == num_dispatches_i);
  assign vertcache_test_index_o = index_fetch_mstreamo[`STREAM_MO_DATA(`WORD_WIDTH)];

  always @(posedge clk_i, negedge nrst_i) begin
    if (!nrst_i) begin
      vertcache_test_valid_o <= 0;
      vertorder_mstream_o <= 0;
      thread_id_o <= 0;
      core_stall_o <= {`NUM_CORES{1'b1}};
      dispatch_done_o <= 0;

      index_fetch_mstreami <= 0;
      state <= STATE_DISABLED;
      thread_id <= 0;
      core_idx <= 0;
    end
    else if (clk_i) begin
      case (state)
        STATE_DISABLED: begin
          if (reset_dispatch_i)
            thread_id <= 0;

          if (enable_i) begin
            core_idx <= 0;
            core_stall_o <= {`NUM_CORES{1'b1}};
            if (dispatch_indices_i) begin
              state <= STATE_DISPATCHING_INDICES;
              index_fetch_mstreami[`STREAM_MI_READY(`WORD_WIDTH)] <= 1;
              vertcache_test_valid_o <= 1;
            end
            else
              state <= STATE_DISPATCHING_INTS;
          end
        end
        STATE_DISPATCHING_INDICES: begin
          core_stall_o <= {`NUM_CORES{1'b1}};
          index_fetch_mstreami[`STREAM_MI_READY(`WORD_WIDTH)] <= 1;
          vertorder_mstream_o[`STREAM_MO_VALID(`VERTEX_ORDER_WIDTH)] <= 0;

          // Fetch index buffer, check cache, and assign to $tid accordingly.
          if (!core_enable_i[core_idx]) begin
            core_idx <= core_idx + 1; // Skip disabled cores
            index_fetch_mstreami[`STREAM_MI_READY(`WORD_WIDTH)] <= 0;
          end
          else if (!index_fetch_empty) begin
            // Check against shaded vertex cache. If present, the cache will
            // automatically forward the index to the vertex order buffer.
            // If missing, assign to a core.
            if (!vertcache_test_found_i) begin
              // Dispatch to core
              thread_id_o <= index_fetch_mstreamo[`STREAM_MO_DATA(`WORD_WIDTH)];
              vertorder_mstream_o[`STREAM_SI_DATA(`VERTEX_ORDER_WIDTH)] <= core_idx;
              vertorder_mstream_o[`STREAM_MO_VALID(`VERTEX_ORDER_WIDTH)] <= 1;
              core_stall_o <= core_stall;
              core_idx <= core_idx + 1;
            end
            else begin
              // Grab from cache
              vertorder_mstream_o[`STREAM_SI_DATA(`VERTEX_ORDER_WIDTH)] <= `NUM_CORES;
              vertorder_mstream_o[`STREAM_MO_VALID(`VERTEX_ORDER_WIDTH)] <= 1;
              index_fetch_mstreami[`STREAM_MI_READY(`WORD_WIDTH)] <= 0;
            end
          end

          // Dumb but whatever
          if (core_idx == `NUM_CORES - 1 && !index_fetch_empty)
            index_fetch_mstreami[`STREAM_MI_READY(`WORD_WIDTH)] <= 0;
          if (core_idx == `NUM_CORES || vertorder_full_i) begin
            vertcache_test_valid_o <= 0;
            index_fetch_mstreami[`STREAM_MI_READY(`WORD_WIDTH)] <= 0;
            core_stall_o <= {`NUM_CORES{1'b1}};
            dispatch_done_o <= 1;
            state <= STATE_DISPATCH_DONE;
          end
          if (index_fetch_model_done && index_fetch_empty) begin
            vertcache_test_valid_o <= 0;
            index_fetch_mstreami[`STREAM_MI_READY(`WORD_WIDTH)] <= 0;
            core_stall_o <= {`NUM_CORES{1'b1}};
            dispatch_done_o <= 1;
            state <= STATE_MODEL_DONE;
          end
        end
        STATE_DISPATCHING_INTS: begin
          // Fill in $tid with increasing numbers
          if (core_idx == `NUM_CORES) begin
            core_stall_o <= {`NUM_CORES{1'b1}};
            dispatch_done_o <= 1;
            state <= STATE_DISPATCH_DONE;
          end
          else if (thread_id == num_dispatches_i) begin
            core_stall_o <= {`NUM_CORES{1'b1}};
            dispatch_done_o <= 1;
            state <= STATE_MODEL_DONE;
          end
          else if (!core_enable_i[core_idx]) begin
            core_stall_o <= {`NUM_CORES{1'b1}};
            core_idx <= core_idx + 1; // Skip disabled cores
          end
          else begin
            core_stall_o <= core_stall;
            thread_id_o <= thread_id;
            thread_id <= thread_id + 1;
            core_idx <= core_idx + 1;
          end
        end
        STATE_DISPATCH_DONE: begin
          core_stall_o <= core_stall_undispatched;
          vertorder_mstream_o[`STREAM_MO_VALID(`VERTEX_ORDER_WIDTH)] <= 0;
          dispatch_done_o <= 1;
          if (!enable_i) begin
            dispatch_done_o <= 0;
            core_idx <= 0;
            state <= STATE_DISABLED;
          end
        end
        STATE_MODEL_DONE: begin
          core_stall_o <= core_stall_undispatched;
          vertorder_mstream_o[`STREAM_MO_VALID(`VERTEX_ORDER_WIDTH)] <= 0;
          dispatch_done_o <= 1;
          if (reset_dispatch_i && !enable_i) begin
            dispatch_done_o <= 0;
            thread_id <= 0;
            core_idx <= 0;
            state <= STATE_DISABLED;
          end
        end
      endcase
    end
  end

endmodule
