module pre_rasterizer_m(
    input wire clk_i,
    input wire nrst_i,

    output wire vob_full_o,
    output wire vob_empty_o,
    input  wire vob_clear_i,

    output wire vrc_busy_o,

    input  wire [3:0] order_sstream_i,
    output wire [0:0] order_sstream_o,

    input  wire [101:0] outbox_sstream_i,
    output wire [2:0] outbox_sstream_o,

    input  wire [0:0] mstream_i,
    output wire [1153:0] mstream_o
);
endmodule

