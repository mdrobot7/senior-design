module vertex_reorder_controller_m #(
    parameter INPUT_COUNT = 4
) (
    input  wire clk_i,
    input  wire nrst_i,

    input  wire [`STREAM_SIPORT(`WORD_WIDTH)] order_sstream_i,
    output wire [`STREAM_SOPORT(`WORD_WIDTH)] order_sstream_o,

    input  wire [(`STREAM_SIPORT_SIZE(`SHADED_VERTEX) * INPUT_COUNT) - 1:0] sstreams_i,
    output wire [(`STREAM_SOPORT_SIZE(`SHADED_VERTEX) * INPUT_COUNT) - 1:0] sstreams_o,

    output reg  valid_o,
    output reg  [`SHADED_VERTEX] v1_o,
    output reg  [`SHADED_VERTEX] v2_o,
    output reg  [`SHADED_VERTEX] v3_o
);

    always @(posedge clk_i, negedge nrst_i) begin
        if (!nrst_i) begin
            valid_o <= 0;
            v1_o    <= 0;
            v2_o    <= 0;
            v3_o    <= 0;
        end
        else if (clk_i) begin
            if (order_sstream_i[`STREAM_SI_VALID]) begin
            end
        end
    end

endmodule