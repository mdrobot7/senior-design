module shared_div_rasterizer_m(
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif

    input wire clk_i,
    input wire nrst_i,

    input  wire [`STREAM_SIPORT_SIZE(2 * `DIVIDER_WIDTH) * `DIVIDER_USERS - 1:0] sstreams_i,
    output wire [`STREAM_SOPORT_SIZE(2 * `DIVIDER_WIDTH) * `DIVIDER_USERS - 1:0] sstreams_o,

    input  wire [`STREAM_MIPORT_SIZE(`DIVIDER_WIDTH) * `DIVIDER_USERS - 1:0] mstreams_i,
    output wire [`STREAM_MOPORT_SIZE(`DIVIDER_WIDTH) * `DIVIDER_USERS - 1:0] mstreams_o
);

// `define FPGA

localparam FIFO_SIZE = 1;

wire [`STREAM_MIPORT_SIZE(`DIVIDER_WIDTH) * `DIVIDER_USERS - 1:0] mstreamsi;
wire [`STREAM_MOPORT_SIZE(`DIVIDER_WIDTH) * `DIVIDER_USERS - 1:0] mstreamso;

`ifdef FPGA
    shared_div_m #(`DIVIDER_WIDTH, 48'b10001001_00100100_10010101_01010101_01111111_11111111, `DIVIDER_USERS) shared_div(
        .clk_i(clk_i),
        .nrst_i(nrst_i),

        .sstreams_i(sstreams_i),
        .sstreams_o(sstreams_o),

        .mstreams_i(mstreamsi),
        .mstreams_o(mstreamso)
    );
`else
    shared_div_m #(`DIVIDER_WIDTH, 48'b10001000_10001001_00100100_10010010_01010101_01010111, `DIVIDER_USERS) shared_div(
        .clk_i(clk_i),
        .nrst_i(nrst_i),

        .sstreams_i(sstreams_i),
        .sstreams_o(sstreams_o),

        .mstreams_i(mstreamsi),
        .mstreams_o(mstreamso)
    );
`endif

generate
    if (FIFO_SIZE > 0) begin
        genvar i;

        for (i = 0; i < `DIVIDER_USERS; i = i + 1) begin
            stream_fifo_m #(`DIVIDER_WIDTH, FIFO_SIZE) fifo(
                .clk_i(clk_i),
                .nrst_i(nrst_i),

                .sstream_i(mstreamso[`STREAM_MOPORT_SIZE(`DIVIDER_WIDTH) * i+:`STREAM_MOPORT_SIZE(`DIVIDER_WIDTH)]),
                .sstream_o(mstreamsi[`STREAM_MIPORT_SIZE(`DIVIDER_WIDTH) * i+:`STREAM_MIPORT_SIZE(`DIVIDER_WIDTH)]),

                .mstream_i(mstreams_i[`STREAM_MIPORT_SIZE(`DIVIDER_WIDTH) * i+:`STREAM_MIPORT_SIZE(`DIVIDER_WIDTH)]),
                .mstream_o(mstreams_o[`STREAM_MOPORT_SIZE(`DIVIDER_WIDTH) * i+:`STREAM_MOPORT_SIZE(`DIVIDER_WIDTH)])
            );
        end
    end
    else begin
        assign mstreamsi = mstreams_i;
        assign mstreams_o = mstreamso;
    end
endgenerate

endmodule
