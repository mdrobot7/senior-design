module serializing_mailman #(
    parameter PARALLEL_SIZE  = `FRAGMENT_WIDTH,
    parameter SERIAL_SIZE  = `MAILBOX_STREAM_SIZE,
    parameter DEPTH = 10
) (
    input  wire clk_i,
    input  wire nrst_i,
    input  wire clear_i,

    input  wire [`STREAM_SIPORT(PARALLEL_SIZE)] sstream_i,
    output wire [`STREAM_SOPORT(PARALLEL_SIZE)] sstream_o,
    input  wire [`STREAM_MIPORT_SIZE(SERIAL_SIZE) * `NUM_CORES - 1:0] mstream_i,
    output wire [`STREAM_MOPORT_SIZE(SERIAL_SIZE) * `NUM_CORES - 1:0] mstream_o,

    output wire  empty_o,
    output wire  full_o,
    output wire  done_mailing_o
);

wire [`STREAM_MIPORT_SIZE(PARALLEL_SIZE) * `NUM_CORES - 1:0] parallel_mstream_i;
wire [`STREAM_MOPORT_SIZE(PARALLEL_SIZE) * `NUM_CORES - 1:0] parallel_mstream_o;


fragment_fifo_m #(
    .SIZE(PARALLEL_SIZE),
    .DEPTH(DEPTH)
)frag_fifo(
    .clk_i(clk_i),
    .nrst_i(nrst_i),
    .clear_i(clear_i),
    .sstream_i(sstream_i),
    .sstream_o(sstream_o),
    .mstream_i(parallel_mstream_i),
    .mstream_o(parallel_mstream_o),
    .empty_o(empty_o),
    .full_o(full_o),
    .done_mailing_o(done_mailing_o)
);

vertex_serializer_m #(.PARALLEL_SIZE(PARALLEL_SIZE), .SERIAL_SIZE(SERIAL_SIZE)) serializer[`NUM_CORES-1:0](
    .clk_i(clk_i),
    .nrst_i(nrst_i),
    .sstream_i(parallel_mstream_o),
    .sstream_o(parallel_mstream_i),
    .mstream_i(mstream_i),
    .mstream_o(mstream_o)
);

endmodule