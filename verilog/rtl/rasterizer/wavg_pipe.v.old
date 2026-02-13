module wavg_pipe_m(
    input wire clk_i,
    input wire nrst_i,

    input  wire [`STREAM_SIPORT(`SC_WIDTH * 2 + `WORD_WIDTH * 3)] sstream_i,
    output wire [`STREAM_SOPORT(`SC_WIDTH * 2 + `WORD_WIDTH * 3)] sstream_o,

    input  wire [`STREAM_MIPORT(`RAST_WAVG_OUT_WIDTH)] mstream_i,
    output wire [`STREAM_MOPORT(`RAST_WAVG_OUT_WIDTH)] mstream_o,

    input wire [`WORD_WIDTH - 1:0] t0x,
    input wire [`WORD_WIDTH - 1:0] t0y,
    input wire [`WORD_WIDTH - 1:0] t1x,
    input wire [`WORD_WIDTH - 1:0] t1y,
    input wire [`WORD_WIDTH - 1:0] t2x,
    input wire [`WORD_WIDTH - 1:0] t2y,

    input wire signed [`WORD_WIDTH - 1:0] v0z,
    input wire signed [`WORD_WIDTH - 1:0] v1z,
    input wire signed [`WORD_WIDTH - 1:0] v2z
);

    reg signed [`WORD_WIDTH - 1:0] m0a; reg signed [`WORD_WIDTH - 1:0] m0b;
    wire signed [`WORD_WIDTH - 1:0] m0y;
    mul_m #(`WORD_WIDTH) mul0 ( .a_i(m0a), .b_i(m0b), .y_o(m0y) );

    reg signed [`WORD_WIDTH - 1:0] m1a; reg signed [`WORD_WIDTH - 1:0] m1b;
    wire signed [`WORD_WIDTH - 1:0] m1y;
    mul_m #(`WORD_WIDTH) mul1 ( .a_i(m1a), .b_i(m1b), .y_o(m1y) );

    reg signed [`WORD_WIDTH - 1:0] a0a; reg signed [`WORD_WIDTH - 1:0] a0b;
    wire signed [`WORD_WIDTH - 1:0] a0y;
    add_m #(`WORD_WIDTH) add0 ( .a_i(a0a), .b_i(a0b), .y_o(a0y) );

    reg signed [`WORD_WIDTH - 1:0] temp;

    reg [`SC_WIDTH * 2 + `WORD_WIDTH * 3 - 1:0] in_data;
    wire [`SC_WIDTH - 1:0] posx, posy;
    wire signed [`WORD_WIDTH - 1:0] l0, l1, l2;

    reg [`SC_WIDTH * 2 + `WORD_WIDTH * 3 - 1:0] out_data;

    reg last;

    assign { posx, posy, l0, l1, l2 } = in_data;

    reg signed [`WORD_WIDTH - 1:0] tx;
    reg signed [`WORD_WIDTH - 1:0] ty;
    reg [`WORD_WIDTH - 1:0] depth;

    localparam STATE_READY = 4'b0000;
    localparam STATE_RUN0  = 4'b0001;
    localparam STATE_RUN1  = 4'b0010;
    localparam STATE_RUN2  = 4'b0011;
    localparam STATE_RUN3  = 4'b0100;
    localparam STATE_RUN4  = 4'b0101;
    localparam STATE_RUN5  = 4'b0110;
    localparam STATE_RUN6  = 4'b0111;
    localparam STATE_RUN7  = 4'b1000;
    localparam STATE_DONE  = 4'b1001;

    reg [3:0] state;

    assign sstream_o[`STREAM_SO_READY(`SC_WIDTH * 2 + `WORD_WIDTH * 3)] = state == STATE_READY;

    always @(posedge clk_i, negedge nrst_i) begin
        if (!nrst_i) begin
            state <= STATE_READY;

            out_data <= 0;

            last <= 0;
        end
        else if (clk_i) begin
            case (state)
                STATE_READY: begin
                    if (sstream_i[`STREAM_SI_VALID(`SC_WIDTH * 2 + `WORD_WIDTH * 3)]) begin
                        state <= STATE_RUN0;

                        in_data <= sstream_i[`STREAM_SI_DATA(`SC_WIDTH * 2 + `WORD_WIDTH * 3)];

                        last <= sstream_i[`STREAM_SI_LAST(`SC_WIDTH * 2 + `WORD_WIDTH * 3)];
                    end
                end

                STATE_RUN0: begin
                    state <= STATE_RUN1;

                    m0a <= l0;
                    m0b <= v0z;

                    m1a <= l1;
                    m1b <= v1z;
                end

                STATE_RUN1: begin
                    state <= STATE_RUN2;

                    a0a <= m0y;
                    a0b <= m1y;

                    m0a <= l2;
                    m0b <= v2z;

                    m1a <= l0;
                    m1b <= t0x;
                end

                STATE_RUN2: begin
                    state <= STATE_RUN3;

                    temp <= m1y;

                    a0a <= a0y;
                    a0b <= m0y;

                    m0a <= l1;
                    m0b <= t1x;

                    m1a <= l2;
                    m1b <= t2x;
                end

                STATE_RUN3: begin
                    state <= STATE_RUN4;

                    depth <= a0y;

                    a0a <= m0y;
                    a0b <= m1y;

                    m0a <= l0;
                    m0b <= t0y;

                    m1a <= l1;
                    m1b <= t1y;
                end

                STATE_RUN4: begin
                    state <= STATE_RUN5;

                    temp <= m0y;

                    a0a <= a0y;
                    a0b <= temp;

                    m0a <= l2;
                    m0b <= t2y;
                end

                STATE_RUN5: begin
                    state <= STATE_RUN6;

                    tx <= a0y >>> `DECIMAL_POS;

                    a0a <= temp;
                    a0b <= m1y;
                end

                STATE_RUN6: begin
                    state <= STATE_RUN7;

                    a0a <= m0y;
                    a0b <= a0y;
                end

                STATE_RUN7: begin
                    state <= STATE_DONE;
                    ty = a0y >>> `DECIMAL_POS;

                    out_data <= { posx, posy, tx, ty, depth };
                end

                STATE_DONE: begin
                    if (mstream_i[`STREAM_MI_READY(`SC_WIDTH * 2 + `WORD_WIDTH * 3)]) begin
                        state <= STATE_READY;
                    end
                end
            endcase
        end
    end

    assign mstream_o[`STREAM_MO_DATA(`RAST_WAVG_OUT_WIDTH)] = out_data;
    assign mstream_o[`STREAM_MO_VALID(`RAST_WAVG_OUT_WIDTH)] = state == STATE_DONE;
    assign mstream_o[`STREAM_MO_LAST(`RAST_WAVG_OUT_WIDTH)] = last;


endmodule