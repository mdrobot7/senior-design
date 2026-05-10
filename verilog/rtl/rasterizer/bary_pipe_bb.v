module bary_pipe_m(
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground


    input wire clk_i,
    input wire nrst_i,

    input wire run_i,
    output reg init_o,
    output reg discard_o,
    output wire busy_o,

    input  wire [19:0] sstream_i,
    output wire  sstream_o,

    input  wire  mstream_i,
    output reg  [115:0] mstream_o,

    input wire [31:0] v0x,
    input wire [31:0] v0y,
    input wire [31:0] v1x,
    input wire [31:0] v1y,
    input wire [31:0] v2x,
    input wire [31:0] v2y,

    input  wire div_mstream_i,
    output wire [97:0] div_mstream_o,

    input  wire [49:0] div_sstream_i,
    output wire div_sstream_o
);
endmodule
