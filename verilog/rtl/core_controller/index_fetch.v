module index_fetch_m #(
  parameter INDEX_BUFFER_ADDR = 0
) (
  input wire clk_i,
  input wire nrst_i,

  // PKBus
  input wire [`BUS_MIPORT] mport_i,
  output reg [`BUS_MOPORT] mport_o,

  input wire pause_i,               // 1: Pause index fetching
  input wire [`WORD] num_dispatches_i,
  input wire model_done_clr_i,      // 1: Clear model done flag
  output reg model_done_o,          // 1: Fetched all indices in this model

  // Index output stream
  input  wire [`STREAM_MIPORT(`WORD_WIDTH)] mstream_i,
  output wire [`STREAM_MOPORT(`WORD_WIDTH)] mstream_o
);

  localparam CACHE_LEN_WORDS = 64;

  localparam STATE_READY = 0;
  localparam STATE_PREP = 1;
  localparam STATE_READ = 2;
  localparam STATE_DONE = 3;

  reg  [`STREAM_SIPORT(`WORD_WIDTH)] sstreami;
  wire [`STREAM_SOPORT(`WORD_WIDTH)] sstreamo;
  wire fifo_full  = !sstreamo[`STREAM_SO_READY];
  wire fifo_empty = mstreamo[`STREAM_MO_VALID];
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
  reg [2:0] state;

  always @(posedge clk_i, negedge nrst_i) begin
    if (nrst_i) begin
      mport_o <= 0;
      model_done_o <= 0;

      sstreami <= 0;
      state <= STATE_READY;
      index_buffer_offset <= 0;
    end
    else if (clk_i) begin
      case (state)
        STATE_READY: begin
          if (!fifo_full && !pause_i && !model_done_o)
            state <= STATE_PREP;
        STATE_PREP: begin
          mport_o[`BUS_MO_ADDR] <= INDEX_BUFFER_ADDR + index_buffer_offset;
          mport_o[`BUS_MO_RW] <= `BUS_READ;
          mport_o[`BUS_MO_SIZE] <= `BUS_SIZE_STREAM;
          mport_o[`BUS_MO_REQ] <= 1;
          if (mport_i[`BUS_MI_ACK])
            state <= STATE_READ;
        end
        STATE_READ: begin
          if (mport_i[`BUS_MI_SEQSLV]) begin
            sstreami[`STREAM_SI_DATA(`WORD_WIDTH)] <= mport_i[`BUS_MI_DATA]; 
            sstreami[`STREAM_SI_VALID(`WORD_WIDTH)] <= 1;

            index_buffer_offset <= index_buffer_offset + 1;
          end
          else
            sstreami[`STREAM_SI_VALID(`WORD_WIDTH)] <= 0;

          if (pause_i || fifo_full || index_buffer_offset >= num_dispatches_i - 1) begin
            // Stop on pause, fifo overrun, or index buffer overrun
            mport_o[`BUS_MO_SEQMST] <= 1;
          end

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
