module wavg_pipe_m(
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif

    input wire clk_i,
    input wire nrst_i,

    input wire [3:0] user_count_i,

    input  wire [`STREAM_SIPORT(`RAST_DT_OUT_WIDTH)] sstream_i,
    output wire [`STREAM_SOPORT(`RAST_DT_OUT_WIDTH)] sstream_o,

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

    input wire [`WORD] u0a_i,
    input wire [`WORD] u0b_i,
    input wire [`WORD] u0c_i,
    input wire [`WORD] u0d_i,
    input wire [`WORD] u0e_i,
    input wire [`WORD] u0f_i,

    input wire [`WORD] u1a_i,
    input wire [`WORD] u1b_i,
    input wire [`WORD] u1c_i,
    input wire [`WORD] u1d_i,
    input wire [`WORD] u1e_i,
    input wire [`WORD] u1f_i,

    input wire [`WORD] u2a_i,
    input wire [`WORD] u2b_i,
    input wire [`WORD] u2c_i,
    input wire [`WORD] u2d_i,
    input wire [`WORD] u2e_i,
    input wire [`WORD] u2f_i,

    input  wire [`STREAM_MIPORT(2 * `DIVIDER_WIDTH)] div0_mstream_i,
    output wire [`STREAM_MOPORT(2 * `DIVIDER_WIDTH)] div0_mstream_o,

    input  wire [`STREAM_SIPORT(`DIVIDER_WIDTH)] div0_sstream_i,
    output wire [`STREAM_SOPORT(`DIVIDER_WIDTH)] div0_sstream_o,

    input  wire [`STREAM_MIPORT(2 * `DIVIDER_WIDTH)] div1_mstream_i,
    output wire [`STREAM_MOPORT(2 * `DIVIDER_WIDTH)] div1_mstream_o,

    input  wire [`STREAM_SIPORT(`DIVIDER_WIDTH)] div1_sstream_i,
    output wire [`STREAM_SOPORT(`DIVIDER_WIDTH)] div1_sstream_o
);

    // assign sstream_o[`STREAM_SO_READY(`RAST_DT_OUT_WIDTH)] = mstream_i[`STREAM_MI_READY(`RAST_WAVG_OUT_WIDTH)];
    // assign mstream_o[`STREAM_MO_VALID(`RAST_WAVG_OUT_WIDTH)] = sstream_i[`STREAM_SI_VALID(`RAST_DT_OUT_WIDTH)];
    // assign mstream_o[`STREAM_MO_LAST(`RAST_WAVG_OUT_WIDTH)] = sstream_i[`STREAM_SI_LAST(`RAST_DT_OUT_WIDTH)];

    // wire [`SC_WIDTH - 1:0] posx, posy;
    // wire [`WORD] l0, l1, l2;

    // assign { posx, posy, l0, l1, l2 } = sstream_i[`STREAM_SI_DATA(`RAST_DT_OUT_WIDTH)];

    // assign mstream_o[`STREAM_MO_DATA(`RAST_WAVG_OUT_WIDTH)] = { posx, posy, 32'hF, 32'hF, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0 };

    wire [`STREAM_SIPORT(`LERPINATOR_IN_WIDTH)] lerp_sstreami;
    wire [`STREAM_SOPORT(`LERPINATOR_IN_WIDTH)] lerp_sstreamo;
    wire [`STREAM_MIPORT(`LERPINATOR_OUT_WIDTH)] lerp_mstreami;
    wire [`STREAM_MOPORT(`LERPINATOR_OUT_WIDTH)] lerp_mstreamo;
    
    wire [`STREAM_MIPORT(2 * `SC_WIDTH)] mstreami;
    wire [`STREAM_MOPORT(2 * `SC_WIDTH)] mstreamo;
    
    wavg_pipe_in_m wavg_pipe_in(
        .clk_i(clk_i),
        .nrst_i(nrst_i),

        .user_count_i(user_count_i),

        .sstream_i(sstream_i),
        .sstream_o(sstream_o),

        .mstream_i(mstreami),
        .mstream_o(mstreamo),

        .t0x(t0x),
        .t0y(t0y),
        .t1x(t1x),
        .t1y(t1y),
        .t2x(t2x),
        .t2y(t2y),

        .v0z(v0z),
        .v1z(v1z),
        .v2z(v2z),

        .u0a_i(u0a_i),
        .u0b_i(u0b_i),
        .u0c_i(u0c_i),
        .u0d_i(u0d_i),
        .u0e_i(u0e_i),
        .u0f_i(u0f_i),

        .u1a_i(u1a_i),
        .u1b_i(u1b_i),
        .u1c_i(u1c_i),
        .u1d_i(u1d_i),
        .u1e_i(u1e_i),
        .u1f_i(u1f_i),

        .u2a_i(u2a_i),
        .u2b_i(u2b_i),
        .u2c_i(u2c_i),
        .u2d_i(u2d_i),
        .u2e_i(u2e_i),
        .u2f_i(u2f_i),

        .lerp_mstream_i(lerp_sstreamo),
        .lerp_mstream_o(lerp_sstreami)
    );

    wavg_pipe_out_m wavg_pipe_out(
        .clk_i(clk_i),
        .nrst_i(nrst_i),

        .user_count_i(user_count_i),

        .u0a_i(u0a_i),
        .u0b_i(u0b_i),
        .u0c_i(u0c_i),
        .u0d_i(u0d_i),
        .u0e_i(u0e_i),
        .u0f_i(u0f_i),

        .sstream_i(mstreamo),
        .sstream_o(mstreami),

        .mstream_i(mstream_i),
        .mstream_o(mstream_o),

        .lerp_sstream_i(lerp_mstreamo),
        .lerp_sstream_o(lerp_mstreami)
    );

    lerpinator_m lerpinator(
        .clk_i(clk_i),
        .nrst_i(nrst_i),

        .v0z(v0z),
        .v1z(v1z),
        .v2z(v2z),

        .sstream_i(lerp_sstreami),
        .sstream_o(lerp_sstreamo),

        .mstream_i(lerp_mstreami),
        .mstream_o(lerp_mstreamo),

        .div0_mstream_i(div0_mstream_i),
        .div0_mstream_o(div0_mstream_o),
        .div0_sstream_i(div0_sstream_i),
        .div0_sstream_o(div0_sstream_o),

        .div1_mstream_i(div1_mstream_i),
        .div1_mstream_o(div1_mstream_o),
        .div1_sstream_i(div1_sstream_i),
        .div1_sstream_o(div1_sstream_o)
    );

endmodule
