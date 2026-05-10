module depth_interp_m(
    input wire clk_i,
    input wire nrst_i,

    input wire signed [`WORD_WIDTH - 1:0] v0z,
    input wire signed [`WORD_WIDTH - 1:0] v1z,
    input wire signed [`WORD_WIDTH - 1:0] v2z,

    input  wire [`STREAM_SIPORT(`SC_WIDTH * 2 + `WORD_WIDTH * 3)] sstream_i,
    output reg  [`STREAM_SOPORT(`SC_WIDTH * 2 + `WORD_WIDTH * 3)] sstream_o,

    input  wire [`STREAM_MIPORT(`RAST_INTERP_OUT_WIDTH)] mstream_i,
    output reg  [`STREAM_MOPORT(`RAST_INTERP_OUT_WIDTH)] mstream_o
);

    reg  signed [`WORD_WIDTH - 1:0] a1a; reg  signed [`WORD_WIDTH - 1:0] a1b;
    wire signed [`WORD_WIDTH - 1:0] a1y;
    add_m #(`WORD_WIDTH) add1( .a_i(a1a), .b_i(a1b), .y_o(a1y) );

    reg  signed [`WORD_WIDTH - 1:0] m1a; reg  signed [`WORD_WIDTH - 1:0] m1b;
    wire signed [`WORD_WIDTH - 1:0] m1y;
    mul_m #(`WORD_WIDTH) mul1( .a_i(m1a), .b_i(m1b), .y_o(m1y) );

    reg [`SC_WIDTH - 1:0] posx, posy;
    reg [`WORD_WIDTH - 1:0] l0, l1, l2;

    reg [2:0] state;

    always @(posedge clk_i, negedge nrst_i) begin
        if (!nrst_i) begin
            state <= 0;
        end
        else if (clk_i) begin
            case (state)
                0: begin
                    if (sstream_i[`STREAM_SI_VALID(`SC_WIDTH * 2 + `WORD_WIDTH * 3)]) begin
                        state <= state + 1;

                        { posx, posy, l0, l1, l2 } <= sstream_i[`STREAM_SI_DATA(`SC_WIDTH * 2 + `WORD_WIDTH * 3)];
                    end
                end

                1: begin
                    state <= state + 1;

                    m1a <= l0;
                    m1b <= v0z;
                end

                2: begin
                    state <= state + 1;

                    a1a <= m1y;

                    m1a <= l1;
                    m1b <= v1z;
                end

                3: begin
                    state <= state + 1;

                    a1b <= m1y;

                    m1a <= l2;
                    m1b <= v2z;
                end

                4: begin
                    state <= state + 1;

                    a1a <= a1y;
                    a1b <= m1y;
                end

                5: begin
                    if (mstream_i[`STREAM_MI_READY(`RAST_INTERP_OUT_WIDTH)]) begin
                        state <= 0;
                    end
                end
            endcase
        end
    end

    always @(*) begin
        sstream_o[`STREAM_SO_READY(`SC_WIDTH * 2 + `WORD_WIDTH * 3)] = state == 0;

        mstream_o <= 0;
        mstream_o[`STREAM_MO_DATA(`RAST_INTERP_OUT_WIDTH)] <= { posx, posy, l0, l1, l2, a1y };

        if (state == 5) begin
            mstream_o[`STREAM_MO_VALID(`RAST_INTERP_OUT_WIDTH)] <= 1;
        end
    end

endmodule

