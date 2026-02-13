module shared_div_m #(
    parameter WIDTH = 32,
    parameter [WIDTH - 1:0] STAGE_LOCS = 0,

    parameter USERS = 1,

    parameter EXTRA_WIDTH = $clog2(USERS),

    parameter IN_SIZE = 2 * WIDTH + EXTRA_WIDTH,
    parameter OUT_SIZE = WIDTH + EXTRA_WIDTH
) (
    input  wire clk_i,
    input  wire nrst_i,

    input  wire [`STREAM_SIPORT(IN_SIZE)] sstream_i,
    output wire [`STREAM_SOPORT(IN_SIZE)] sstream_o,

    input  wire [`STREAM_MIPORT(OUT_SIZE)] mstream_i,
    output wire [`STREAM_MOPORT(OUT_SIZE)] mstream_o
);

    endmodule

endmodule
