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
  output wire         vertcache_test_valid_o,
  input  wire         vertcache_test_found_i,

  // Vertex order buffer
  input wire [`STREAM_MIPORT(`VERTEX_ORDER_WIDTH)] vertorder_mstream_i,
  output reg [`STREAM_MOPORT(`VERTEX_ORDER_WIDTH)] vertorder_mstream_o,
  input wire                                       vertorder_full_i,

  // index buffer
  input  wire [`STREAM_MIPORT(`WORD_WIDTH)] index_mstream_i,
  output wire [`STREAM_MOPORT(`WORD_WIDTH)] index_mstream_o,

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
  localparam STATE_WAIT_FOR_INDICES    = 1;
  localparam STATE_DISPATCHING_INDICES = 2;
  localparam STATE_DISPATCHING_INTS    = 3;
  localparam STATE_DISPATCH_DONE       = 4;
  localparam STATE_MODEL_DONE          = 5;

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
  wire                               index_fetch_full;
  wire                               index_fetch_empty;
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

    .full_o(index_fetch_full),
    .empty_o(index_fetch_empty),

    .mstream_i(index_fetch_mstreami),
    .mstream_o(index_fetch_mstreamo)
  );

  reg [3:0] state;

  reg [`WORD] thread_id;

  reg [`NUM_CORES_WIDTH:0] core_idx;

  wire [`NUM_CORES-1:0] core_stall              = ~(1 << core_idx);
  wire [`NUM_CORES-1:0] core_stall_undispatched = {`NUM_CORES{1'b1}} << core_idx; // Handle partial dispatch by stalling cores without jobs

  assign model_done_o           = dispatch_indices_i
                                  ? (index_fetch_model_done && index_fetch_empty)
                                  : (thread_id == num_dispatches_i);
  assign vertcache_test_index_o = index_fetch_mstreamo[`STREAM_MO_DATA(`WORD_WIDTH)];
  assign vertcache_test_valid_o = (state == STATE_DISPATCHING_INDICES && !index_fetch_empty);

  assign index_mstream_o[`STREAM_MO_DATA(`WORD_WIDTH)]  = vertcache_test_index_o;
  assign index_mstream_o[`STREAM_MO_LAST(`WORD_WIDTH)]  = 0;
  assign index_mstream_o[`STREAM_MO_VALID(`WORD_WIDTH)] = vertcache_test_valid_o;

  always @(posedge clk_i, negedge nrst_i) begin
    if (!nrst_i) begin
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
            if (dispatch_indices_i)
              state <= STATE_WAIT_FOR_INDICES;
            else
              state <= STATE_DISPATCHING_INTS;
          end
        end
        STATE_WAIT_FOR_INDICES: begin
          if (index_fetch_full || index_fetch_model_done)
            state <= STATE_DISPATCHING_INDICES;
        end
        STATE_DISPATCHING_INDICES: begin
          // Fetch index buffer, check cache, and assign to $tid accordingly.

          if (!core_enable_i[core_idx] || (!index_fetch_empty && !vertcache_test_found_i)) begin
            // Skip disabled cores, and if we found a vertex that isn't in the
            // cache then give it to a core.
            core_idx <= core_idx + 1;
          end

          if (((core_idx == `NUM_CORES - 1 && !vertcache_test_found_i) || vertorder_full_i) ||
              (index_fetch_model_done && index_fetch_empty)) begin
            state <= STATE_DISPATCH_DONE;
          end
        end
        STATE_DISPATCHING_INTS: begin
          // Fill in $tid with increasing numbers
          if (core_idx == `NUM_CORES || thread_id == num_dispatches_i) begin
            state <= STATE_DISPATCH_DONE;
          end
          else if (!core_enable_i[core_idx]) begin
            core_idx <= core_idx + 1; // Skip disabled cores
          end
          else begin
            thread_id <= thread_id + 1;
            core_idx <= core_idx + 1;
          end
        end
        STATE_DISPATCH_DONE: begin
          if (!enable_i) begin
            if (thread_id == num_dispatches_i || (index_fetch_model_done && index_fetch_empty))
              state <= STATE_MODEL_DONE;
            else
              state <= STATE_DISABLED;
          end
        end
        STATE_MODEL_DONE: begin
          if (reset_dispatch_i) begin
            thread_id <= 0;
            state <= STATE_DISABLED;
          end
        end
      endcase
    end
  end

  always @(*) begin
    case (state)
      STATE_DISABLED:            core_stall_o = core_stall_undispatched;
      STATE_DISPATCHING_INDICES: begin
        if (core_enable_i[core_idx] && !index_fetch_empty && !vertcache_test_found_i)
          core_stall_o = core_stall;
        else
          core_stall_o = {`NUM_CORES{1'b1}};
      end
      STATE_DISPATCHING_INTS: begin
        if (core_enable_i[core_idx])
          core_stall_o = core_stall;
      end
      STATE_DISPATCH_DONE:       core_stall_o = enable_i ? {`NUM_CORES{1'b1}} : core_stall_undispatched;
      STATE_MODEL_DONE:          core_stall_o = core_stall_undispatched;
    endcase

    case (state)
      STATE_DISPATCHING_INDICES: thread_id_o = index_fetch_mstreamo[`STREAM_MO_DATA(`WORD_WIDTH)];
      STATE_DISPATCHING_INTS:    thread_id_o = thread_id;
      default:                   thread_id_o = thread_id;
    endcase

    vertorder_mstream_o = 0;
    index_fetch_mstreami = 0;

    if (state == STATE_DISPATCHING_INDICES && core_enable_i[core_idx]) begin
      if (!(index_fetch_model_done && index_fetch_empty))
        vertorder_mstream_o[`STREAM_MO_VALID(`VERTEX_ORDER_WIDTH)] = 1;
      index_fetch_mstreami[`STREAM_MI_READY(`WORD_WIDTH)] = 1;
    end

    if (vertcache_test_found_i)
      // Grab from cache
      vertorder_mstream_o[`STREAM_MO_DATA(`VERTEX_ORDER_WIDTH)] = `NUM_CORES;
    else
      // Grab from core
      vertorder_mstream_o[`STREAM_MO_DATA(`VERTEX_ORDER_WIDTH)] = core_idx;

    dispatch_done_o = (state == STATE_DISPATCH_DONE || state == STATE_MODEL_DONE);
  end

endmodule
