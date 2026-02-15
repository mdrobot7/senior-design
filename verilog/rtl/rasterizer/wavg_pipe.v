module wavg_pipe_m(
    input wire clk_i,
    input wire nrst_i,

    input  wire [`STREAM_SIPORT(`SC_WIDTH * 2 + `WORD_WIDTH * 3)] sstream_i,
    output wire [`STREAM_SOPORT(`SC_WIDTH * 2 + `WORD_WIDTH * 3)] sstream_o,

    input  wire [`STREAM_MIPORT(`RAST_WAVG_OUT_WIDTH)] mstream_i,
    output wire [`STREAM_MOPORT(`RAST_WAVG_OUT_WIDTH)] mstream_o,

    input wire [`WORD_WIDTH - 1:0] t0x,
    input wire [`WORD_WIDTH - 1:0] t0y,
    input wire [`WORD_WIDTH - 1:0] t1x,
    input wire [`WORD_WIDTH - 1:0] t1y,
    input wire [`WORD_WIDTH - 1:0] t2x,
    input wire [`WORD_WIDTH - 1:0] t2y,

    input wire signed [`WORD_WIDTH - 1:0] v0z,
    input wire signed [`WORD_WIDTH - 1:0] v1z,
    input wire signed [`WORD_WIDTH - 1:0] v2z,

    input  wire [`STREAM_MIPORT(2 * `DIVIDER_WIDTH)] div0_mstream_i,
    output wire [`STREAM_MOPORT(2 * `DIVIDER_WIDTH)] div0_mstream_o,

    input  wire [`STREAM_SIPORT(`DIVIDER_WIDTH)] div0_sstream_i,
    output wire [`STREAM_SOPORT(`DIVIDER_WIDTH)] div0_sstream_o,

    input  wire [`STREAM_MIPORT(2 * `DIVIDER_WIDTH)] div1_mstream_i,
    output wire [`STREAM_MOPORT(2 * `DIVIDER_WIDTH)] div1_mstream_o,

    input  wire [`STREAM_SIPORT(`DIVIDER_WIDTH)] div1_sstream_i,
    output wire [`STREAM_SOPORT(`DIVIDER_WIDTH)] div1_sstream_o
);


    wire [`STREAM_MIPORT(`WORD_WIDTH + `SC_WIDTH * 2)] pipe0_streami;
    wire [`STREAM_MOPORT(`WORD_WIDTH + `SC_WIDTH * 2)] pipe0_streamo;

    wavg_pipe0_m pipe0(
        .clk_i(clk_i),
        .nrst_i(nrst_i),

        .sstream_i(sstream_i),
        .sstream_o(sstream_o),

        .mstream_i(pipe0_streami),
        .mstream_o(pipe0_streamo),

        .t0x(t0x),
        .t0y(t0y),
        .t1x(t1x),
        .t1y(t1y),
        .t2x(t2x),
        .t2y(t2y),

        .v0z(v0z),
        .v1z(v1z),
        .v2z(v2z),

        .div_mstream_i(div0_mstream_i),
        .div_mstream_o(div0_mstream_o)
    );

    wavg_pipe1_m pipe1(
        .clk_i(clk_i),
        .nrst_i(nrst_i),

        .t0x(t0x),
        .t0y(t0y),
        .t1x(t1x),
        .t1y(t1y),
        .t2x(t2x),
        .t2y(t2y),

        .v0z(v0z),
        .v1z(v1z),
        .v2z(v2z),

        .div_sstream_i(div0_sstream_i),
        .div_sstream_o(div0_sstream_o),

        .div_mstream_i(div1_mstream_i),
        .div_mstream_o(div1_mstream_o)
    );

    wavg_pipe2_m pipe2(
        .clk_i(clk_i),
        .nrst_i(nrst_i),

        .sstream_i(pipe0_streamo),
        .sstream_o(pipe0_streami),

        .mstream_i(mstream_i),
        .mstream_o(mstream_o),

        .div_sstream_i(div1_sstream_i),
        .div_sstream_o(div1_sstream_o)
    );

endmodule