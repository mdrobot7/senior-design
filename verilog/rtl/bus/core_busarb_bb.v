module core_busarb_m(
    input  wire clk_i,
    input  wire nrst_i,

    input  wire [206:0] mports_i,
    output reg  [101:0] mports_o,

    input  wire [33:0] sports_i,
    output reg  [68:0] sports_o
);
endmodule

