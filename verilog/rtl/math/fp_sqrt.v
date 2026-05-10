module fp_sqrt_m #(
    parameter WIDTH = 32
) (
    input wire clk_i,
    input wire nrst_i,

    input  wire [`STREAM_SIPORT(WIDTH)] sstream_i,
    output wire [`STREAM_SOPORT(WIDTH)] sstream_o,

    input  wire [`STREAM_MIPORT(WIDTH)] mstream_i,
    output reg  [`STREAM_MOPORT(WIDTH)] mstream_o
);

    localparam ROOT_WIDTH = WIDTH / 2;

    reg  [`STREAM_MIPORT(ROOT_WIDTH)] mstreami;
    wire [`STREAM_MOPORT(ROOT_WIDTH)] mstreamo;

    sqrt_m #(WIDTH) sqrt(
        .clk_i(clk_i),
        .nrst_i(nrst_i),

        .sstream_i(sstream_i),
        .sstream_o(sstream_o),

        .mstream_i(mstreami),
        .mstream_o(mstreamo)
    );

    always @(*) begin
        mstream_o[`STREAM_MO_DATA(WIDTH)] = mstreamo[`STREAM_MO_DATA(ROOT_WIDTH)] << (`DECIMAL_POS / 2);
        mstream_o[`STREAM_MO_VALID(WIDTH)] = mstreamo[`STREAM_MO_VALID(ROOT_WIDTH)];
        mstream_o[`STREAM_MO_LAST(WIDTH)] = mstreamo[`STREAM_MO_LAST(ROOT_WIDTH)];

        mstreami[`STREAM_MI_READY(ROOT_WIDTH)] = mstream_i[`STREAM_MI_READY(WIDTH)];
    end

endmodule
