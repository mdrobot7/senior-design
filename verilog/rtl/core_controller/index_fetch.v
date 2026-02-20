/*
* Index buffer (pre)fetcher. When enabled, it will
* immediately start fetching indices from the index
* buffer and caching them in a FIFO. As the dispatcher
* pulls indices out, the index fetcher will attempt
* to refill them.
*
* The dispatcher dispatches at 1 index per clock cycle
* and will always be ahead of the index fetcher. The
* index fetcher will try to refill the FIFO, but due
* to PKBus arbitration and memory chip setup time it
* won't ever be able to catch up. TLDR we shouldn't
* thrash PKBus, it should be one continuous stream read.
*/

module index_fetch_m #(
  parameter CACHE_LEN_WORDS = 64
) (
  input wire clk_i,
  input wire nrst_i,

  // PKBus
  input wire [`BUS_MIPORT] mport_i,
  output reg [`BUS_MOPORT] mport_o,

  input wire         enable_i,            // 1: enable index fetching
  input wire [`WORD] index_buffer_addr_i,
  input wire [`WORD] num_dispatches_i,
  input wire         model_done_clr_i,    // 1: Clear model done flag
  output reg         model_done_o,        // 1: Fetched all indices in this model

  // Index output stream
  input  wire [`STREAM_MIPORT(`WORD_WIDTH)] mstream_i,
  output wire [`STREAM_MOPORT(`WORD_WIDTH)] mstream_o
);

  localparam STATE_READY        = 0;
  localparam STATE_PREP         = 1;
  localparam STATE_READ         = 2;
  localparam STATE_WAIT_FOR_ACK = 3;
  localparam STATE_DONE         = 4;

  reg  [`STREAM_SIPORT(`WORD_WIDTH)] sstreami;
  wire [`STREAM_SOPORT(`WORD_WIDTH)] sstreamo;
  wire                               fifo_full  = !sstreamo[`STREAM_SO_READY(`WORD_WIDTH)];
  wire                               fifo_empty = !mstream_o[`STREAM_MO_VALID(`WORD_WIDTH)];
  stream_fifo_m #(
      `WORD_WIDTH,
      CACHE_LEN_WORDS
  ) fifo (
      .clk_i(clk_i),
      .nrst_i(nrst_i),

      .sstream_i(sstreami),
      .sstream_o(sstreamo),

      .mstream_i(mstream_i),
      .mstream_o(mstream_o)
  );

  reg [`WORD] index_buffer_offset;
  reg [2:0]   state;

  always @(posedge clk_i, negedge nrst_i) begin
    if (!nrst_i) begin
      mport_o <= 0;
      model_done_o <= 0;

      sstreami <= 0;
      index_buffer_offset <= 0;
      state <= STATE_READY;
    end
    else if (clk_i) begin
      case (state)
        STATE_READY: begin
          if (enable_i && !fifo_full && !model_done_o)
            state <= STATE_PREP;
        end
        STATE_PREP: begin
          mport_o[`BUS_MO_ADDR] <= index_buffer_addr_i + index_buffer_offset;
          mport_o[`BUS_MO_RW] <= `BUS_READ;
          mport_o[`BUS_MO_SIZE] <= `BUS_SIZE_STREAM;
          mport_o[`BUS_MO_REQ] <= 1;
          if (mport_i[`BUS_MI_ACK])
            state <= STATE_READ;
        end
        STATE_READ: begin
          if (fifo_full || index_buffer_offset >= num_dispatches_i) begin
            // Stop on fifo overrun, or index buffer overrun
            sstreami[`STREAM_SI_VALID(`WORD_WIDTH)] <= 0;
            mport_o[`BUS_MO_SEQMST] <= 1;
            state <= STATE_WAIT_FOR_ACK;
          end
          else begin
            if (mport_i[`BUS_MI_SEQSLV]) begin
              sstreami[`STREAM_SI_DATA(`WORD_WIDTH)] <= mport_i[`BUS_MI_DATA];
              sstreami[`STREAM_SI_VALID(`WORD_WIDTH)] <= 1;

              index_buffer_offset <= index_buffer_offset + 1;
            end
            else
              sstreami[`STREAM_SI_VALID(`WORD_WIDTH)] <= 0;
          end
        end
        STATE_WAIT_FOR_ACK: begin
          if (!mport_i[`BUS_MI_ACK]) begin
            state <= STATE_DONE;
          end
        end
        STATE_DONE: begin
          state <= STATE_READY;

          if (index_buffer_offset >= num_dispatches_i)
            model_done_o <= 1;

          mport_o[`BUS_MO_REQ] <= 0;
          mport_o[`BUS_MO_SEQMST] <= 0;
        end
      endcase

      if (model_done_clr_i)
        model_done_o <= 0;
    end
  end
endmodule
