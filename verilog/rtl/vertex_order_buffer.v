module vertex_order_buffer_m #(
    parameter ENTRIES = 1,
    parameter INDEX_WIDTH = `VERTEX_ORDER_WIDTH
) (
    input wire clk_i,
    input wire nrst_i,

    input  wire [`STREAM_SIPORT(INDEX_WIDTH)] sstream_i,
    output wire [`STREAM_SOPORT(INDEX_WIDTH)] sstream_o,

    input  wire [`STREAM_MIPORT(INDEX_WIDTH)] mstream_i,
    output wire [`STREAM_MOPORT(INDEX_WIDTH)] mstream_o,

    input  wire clear_i,
    output wire full_o,
    output wire empty_o
);

    reg [`STREAM_MIPORT(INDEX_WIDTH)] mstreami;

    wire [`STREAM_MIPORT(INDEX_WIDTH)] fifo_mstreami;
    wire [`STREAM_MOPORT(INDEX_WIDTH)] fifo_mstreamo;
    stream_fifo_m #(
        INDEX_WIDTH,
        ENTRIES
    ) fifo (
        .clk_i(clk_i),
        .nrst_i(nrst_i),

        .sstream_i(sstream_i),
        .sstream_o(sstream_o),

        .mstream_i(fifo_mstreami),
        .mstream_o(fifo_mstreamo)
    );

    assign mstream_o     = (clear_i ? 0        : fifo_mstreamo);
    assign fifo_mstreami = (clear_i ? mstreami : mstream_i);

    assign full_o = !sstream_o[`STREAM_SO_READY(INDEX_WIDTH)];

    assign empty_o = !mstream_o[`STREAM_MO_VALID(INDEX_WIDTH)];

    always @(*) begin
      if (clear_i)
        mstreami[`STREAM_MI_READY(INDEX_WIDTH)] <= 1;
    end

endmodule
