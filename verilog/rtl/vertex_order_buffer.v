module vertex_order_buffer_m #(
    parameter ENTRIES = 1,
    parameter INDEX_WIDTH = 3
) (
    input wire clk_i,
    input wire nrst_i,

    input  wire [`STREAM_SIPORT(INDEX_WIDTH)] sstream_i,
    output wire [`STREAM_SOPORT(INDEX_WIDTH)] sstream_o,

    input  wire [`STREAM_MIPORT(INDEX_WIDTH)] mstream_i,
    output wire [`STREAM_MOPORT(INDEX_WIDTH)] mstream_o,

    output wire full_o,
    output wire empty_o
);

    stream_fifo_m #(
        INDEX_WIDTH,
        ENTRIES
    ) fifo (
        .clk_i(clk_i),
        .nrst_i(nrst_i),

        .sstream_i(sstream_i),
        .sstream_o(sstream_o),

        .mstream_i(mstream_i),
        .mstream_o(mstream_o)
    );

    assign full_o = !sstream_o[`STREAM_SO_READY(INDEX_WIDTH)];
    
    assign empty_o = mstream_o[`STREAM_MO_VALID(INDEX_WIDTH)];

endmodule