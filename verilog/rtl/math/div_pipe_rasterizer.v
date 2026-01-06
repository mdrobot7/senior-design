module div_pipe_rasterizer_m(
    input wire clk_i,
    input wire nrst_i,

    input  wire [`STREAM_SIPORT(2 * (`DECIMAL_POS + `WORD_WIDTH))] sstream_i,
    output wire [`STREAM_SOPORT(2 * (`DECIMAL_POS + `WORD_WIDTH))] sstream_o,

    input  wire [`STREAM_MIPORT(`DECIMAL_POS + `WORD_WIDTH)] mstream_i,
    output wire [`STREAM_MOPORT(`DECIMAL_POS + `WORD_WIDTH)] mstream_o
);

    localparam DIV_WIDTH = `DECIMAL_POS + `WORD_WIDTH;

`ifdef FPGA
    div_pipe_m #(DIV_WIDTH, 42'b00_00001000_10010010_01010010_10010101_01010101) div_pipe(
        .clk_i(clk_i),
        .nrst_i(nrst_i),

        .sstream_i(sstream_i),
        .sstream_o(sstream_o),

        .mstream_i(mstream_i),
        .mstream_o(mstream_o)
    );
`else
    div_pipe_m #(DIV_WIDTH, 42'b00_00001000_00000000_01000001_00001000_00010001) div_pipe(
        .clk_i(clk_i),
        .nrst_i(nrst_i),

        .sstream_i(sstream_i),
        .sstream_o(sstream_o),

        .mstream_i(mstream_i),
        .mstream_o(mstream_o)
    );
`endif

endmodule
