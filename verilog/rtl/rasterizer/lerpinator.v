module lerpinator_m(
    input wire clk_i,
    input wire nrst_i,

    input wire signed [`WORD_WIDTH - 1:0] v0z,
    input wire signed [`WORD_WIDTH - 1:0] v1z,
    input wire signed [`WORD_WIDTH - 1:0] v2z,

    input  wire [`STREAM_SIPORT(`LERPINATOR_IN_WIDTH)] sstream_i,
    output wire [`STREAM_SOPORT(`LERPINATOR_IN_WIDTH)] sstream_o,

    input  wire [`STREAM_MIPORT(`LERPINATOR_OUT_WIDTH)] mstream_i,
    output wire [`STREAM_MOPORT(`LERPINATOR_OUT_WIDTH)] mstream_o,

    input  wire [`STREAM_MIPORT(2 * `DIVIDER_WIDTH)] div0_mstream_i,
    output wire [`STREAM_MOPORT(2 * `DIVIDER_WIDTH)] div0_mstream_o,

    input  wire [`STREAM_SIPORT(`DIVIDER_WIDTH)] div0_sstream_i,
    output wire [`STREAM_SOPORT(`DIVIDER_WIDTH)] div0_sstream_o,

    input  wire [`STREAM_MIPORT(2 * `DIVIDER_WIDTH)] div1_mstream_i,
    output wire [`STREAM_MOPORT(2 * `DIVIDER_WIDTH)] div1_mstream_o,

    input  wire [`STREAM_SIPORT(`DIVIDER_WIDTH)] div1_sstream_i,
    output wire [`STREAM_SOPORT(`DIVIDER_WIDTH)] div1_sstream_o
);

    wire [`STREAM_MIPORT(3 * `WORD_WIDTH)] mstreami;
    wire [`STREAM_MOPORT(3 * `WORD_WIDTH)] mstreamo;

    lerpinator_in_m in(
        .clk_i(clk_i),
        .nrst_i(nrst_i),

        .v0z(v0z),
        .v1z(v1z),
        .v2z(v2z),

        .sstream_i(sstream_i),
        .sstream_o(sstream_o),

        .mstream_i(mstreami),
        .mstream_o(mstreamo),

        .div_mstream_i(div0_mstream_i),
        .div_mstream_o(div0_mstream_o)
    );

    lerpinator_mid_m mid(
        .clk_i(clk_i),
        .nrst_i(nrst_i),

        .sstream_i(mstreamo),
        .sstream_o(mstreami),

        .div_sstream_i(div0_sstream_i),
        .div_sstream_o(div0_sstream_o),

        .div_mstream_i(div1_mstream_i),
        .div_mstream_o(div1_mstream_o)
    );

    lerpinator_out_m out(
        .clk_i(clk_i),
        .nrst_i(nrst_i),

        .div_sstream_i(div1_sstream_i),
        .div_sstream_o(div1_sstream_o),

        .mstream_i(mstream_i),
        .mstream_o(mstream_o)
    );

endmodule

