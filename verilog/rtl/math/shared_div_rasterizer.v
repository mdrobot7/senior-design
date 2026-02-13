module shared_div_rasterizer_m(
    input wire clk_i,
    input wire nrst_i,

    input  wire [`STREAM_SIPORT_SIZE(2 * `DIVIDER_WIDTH) * `DIVIDER_USERS - 1:0] sstreams_i,
    output wire [`STREAM_SOPORT_SIZE(2 * `DIVIDER_WIDTH) * `DIVIDER_USERS - 1:0] sstreams_o,

    input  wire [`STREAM_MIPORT_SIZE(`DIVIDER_WIDTH) * `DIVIDER_USERS - 1:0] mstreams_i,
    output wire [`STREAM_MOPORT_SIZE(`DIVIDER_WIDTH) * `DIVIDER_USERS - 1:0] mstreams_o
);

`define FPGA

`ifdef FPGA
    shared_div_m #(`DIVIDER_WIDTH, 42'b00_00001000_10010010_01010010_10010101_01010101, `DIVIDER_USERS) shared_div(
        .clk_i(clk_i),
        .nrst_i(nrst_i),

        .sstreams_i(sstreams_i),
        .sstreams_o(sstreams_o),

        .mstreams_i(mstreams_i),
        .mstreams_o(mstreams_o)
    );
`else
    shared_div_m #(`DIVIDER_WIDTH, 42'b00_00001000_00000000_01000001_00001000_00010001, `DIVIDER_USERS) shared_div(
        .clk_i(clk_i),
        .nrst_i(nrst_i),

        .sstreams_i(sstreams_i),
        .sstreams_o(sstreams_o),

        .mstreams_i(mstreams_i),
        .mstreams_o(mstreams_o)
    );
`endif

endmodule
