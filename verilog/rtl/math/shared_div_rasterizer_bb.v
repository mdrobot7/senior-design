module shared_div_rasterizer_m(
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground


    input wire clk_i,
    input wire nrst_i,

    input  wire [391:0] sstreams_i,
    output wire [3:0] sstreams_o,

    input  wire [3:0] mstreams_i,
    output wire [199:0] mstreams_o
);
endmodule

