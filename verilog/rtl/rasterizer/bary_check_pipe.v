module bary_check_pipe_m(
    input wire clk_i,
    input wire nrst_i,

    input  wire [`STREAM_SIPORT(`SC_WIDTH * 2 + `WORD_WIDTH * 3)] sstream_i,
    output wire [`STREAM_SOPORT(`SC_WIDTH * 2 + `WORD_WIDTH * 3)] sstream_o,

    input  wire [`STREAM_MIPORT(`SC_WIDTH * 2 + `WORD_WIDTH * 3)] mstream_i,
    output reg  [`STREAM_MOPORT(`SC_WIDTH * 2 + `WORD_WIDTH * 3)] mstream_o,

    output wire busy_o
);

    wire [2 * `SC_WIDTH + 3 * `WORD_WIDTH - 1:0] in_data;
    wire [`SC_WIDTH - 1:0] posx, posy;
    wire signed [`WORD_WIDTH - 1:0] l0, l1, l2;

    assign in_data = sstream_i[`STREAM_SI_DATA(`SC_WIDTH * 2 + `WORD_WIDTH * 3)];
    assign { posx, posy, l0, l1, l2 } = in_data;

    assign sstream_o = mstream_i;

    always @(posedge clk_i, negedge nrst_i) begin
        if (!nrst_i) begin
            mstream_o <= 0;
        end
        else if (clk_i) begin
            if (l0 >= 0 && l1 >= 0 && l2 >= 0) begin
                mstream_o <= sstream_i;
            end
            else begin
                mstream_o <= 0;
            end
        end
    end

    assign busy_o =
        mstream_o[`STREAM_MO_VALID(`SC_WIDTH * 2 + `WORD_WIDTH * 3)] ||
        sstream_i[`STREAM_SI_VALID(`SC_WIDTH * 2 + `WORD_WIDTH * 3)];

endmodule
