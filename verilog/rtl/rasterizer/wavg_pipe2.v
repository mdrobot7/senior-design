module wavg_pipe1_m(
    input wire clk_i,
    input wire nrst_i,

    input  wire [`STREAM_SIPORT(`SC_WIDTH * 2 + `WORD_WIDTH)] sstream_i,
    output reg  [`STREAM_SOPORT(`SC_WIDTH * 2 + `WORD_WIDTH)] sstream_o,

    input  wire [`STREAM_MIPORT(`RAST_WAVG_OUT_WIDTH)] mstream_i,
    output reg  [`STREAM_MOPORT(`RAST_WAVG_OUT_WIDTH)] mstream_o,

    input  wire [`STREAM_SIPORT(`DIVIDER_WIDTH)] div_sstream_i,
    output wire [`STREAM_SOPORT(`DIVIDER_WIDTH)] div_sstream_o
);

endmodule