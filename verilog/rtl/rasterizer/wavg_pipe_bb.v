module wavg_pipe_m(
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground


    input wire clk_i,
    input wire nrst_i,

    input wire [3:0] user_count_i,

    input  wire [115:0] sstream_i,
    output wire  sstream_o,

    input  wire  mstream_i,
    output wire [275:0] mstream_o,

    input wire [31:0] t0x,
    input wire [31:0] t0y,
    input wire [31:0] t1x,
    input wire [31:0] t1y,
    input wire [31:0] t2x,
    input wire [31:0] t2y,

    input wire [31:0] v0z,
    input wire [31:0] v1z,
    input wire [31:0] v2z,

    input wire [31:0] u0a_i,
    input wire [31:0] u0b_i,
    input wire [31:0] u0c_i,
    input wire [31:0] u0d_i,
    input wire [31:0] u0e_i,
    input wire [31:0] u0f_i,

    input wire [31:0] u1a_i,
    input wire [31:0] u1b_i,
    input wire [31:0] u1c_i,
    input wire [31:0] u1d_i,
    input wire [31:0] u1e_i,
    input wire [31:0] u1f_i,

    input wire [31:0] u2a_i,
    input wire [31:0] u2b_i,
    input wire [31:0] u2c_i,
    input wire [31:0] u2d_i,
    input wire [31:0] u2e_i,
    input wire [31:0] u2f_i,

    input  wire  div0_mstream_i,
    output wire [97:0] div0_mstream_o,

    input  wire [49:0] div0_sstream_i,
    output wire  div0_sstream_o,

    input  wire  div1_mstream_i,
    output wire [97:0] div1_mstream_o,

    input  wire [49:0] div1_sstream_i,
    output wire  div1_sstream_o
);
endmodule
