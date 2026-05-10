module lerpinator_out_m(
    input wire clk_i,
    input wire nrst_i,

    input  wire [`STREAM_SIPORT(`DIVIDER_WIDTH)] div_sstream_i,
    output wire [`STREAM_SOPORT(`DIVIDER_WIDTH)] div_sstream_o,

    input  wire [`STREAM_MIPORT(`LERPINATOR_OUT_WIDTH)] mstream_i,
    output wire [`STREAM_MOPORT(`LERPINATOR_OUT_WIDTH)] mstream_o
);

    assign div_sstream_o[`STREAM_SO_READY(`DIVIDER_WIDTH)] = mstream_i[`STREAM_MI_READY(`LERPINATOR_OUT_WIDTH)];
    assign mstream_o[`STREAM_MO_DATA(`LERPINATOR_OUT_WIDTH)] = div_sstream_i[`STREAM_SI_DATA(`DIVIDER_WIDTH)];
    assign mstream_o[`STREAM_MO_VALID(`LERPINATOR_OUT_WIDTH)] = div_sstream_i[`STREAM_SI_VALID(`DIVIDER_WIDTH)];
    assign mstream_o[`STREAM_MO_LAST(`LERPINATOR_OUT_WIDTH)] = div_sstream_i[`STREAM_SI_LAST(`DIVIDER_WIDTH)];

endmodule

