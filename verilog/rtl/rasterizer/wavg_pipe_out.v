module wavg_pipe_out_m(
    input wire clk_i,
    input wire nrst_i,

    input wire [3:0] user_count_i,

    input wire [`WORD] u0a_i,
    input wire [`WORD] u0b_i,
    input wire [`WORD] u0c_i,
    input wire [`WORD] u0d_i,
    input wire [`WORD] u0e_i,
    input wire [`WORD] u0f_i,

    input  wire [`STREAM_SIPORT(2 * `SC_WIDTH)] sstream_i,
    output reg  [`STREAM_SOPORT(2 * `SC_WIDTH)] sstream_o,

    input  wire [`STREAM_MIPORT(`RAST_WAVG_OUT_WIDTH)] mstream_i,
    output reg  [`STREAM_MOPORT(`RAST_WAVG_OUT_WIDTH)] mstream_o,

    input  wire [`STREAM_SIPORT(`LERPINATOR_OUT_WIDTH)] lerp_sstream_i,
    output reg  [`STREAM_SOPORT(`LERPINATOR_OUT_WIDTH)] lerp_sstream_o
);

    reg [`SC_WIDTH - 1:0] posx, posy;
    reg signed [`WORD] tx, ty;
    wire signed [`WORD] tx_shift, ty_shift;
    reg signed [`WORD] u0, u1, u2, u3, u4, u5;

    assign tx_shift = tx >>> `DECIMAL_POS;
    assign ty_shift = ty >>> `DECIMAL_POS;

    reg [3:0] state;

    always @(posedge clk_i, negedge nrst_i) begin
        if (!nrst_i) begin
            state <= 0;
        end
        else if (clk_i) begin
            case (state)
                0: begin
                    if (sstream_i[`STREAM_SI_VALID(2 * `SC_WIDTH)]) begin
                        state <= state + 1;

                        { posx, posy } <= sstream_i[`STREAM_SI_DATA(2 * `SC_WIDTH)];

                        u0 <= u0a_i;
                        u1 <= u0b_i;
                        u2 <= u0c_i;
                        u3 <= u0d_i;
                        u4 <= u0e_i;
                        u5 <= u0f_i;
                    end
                end

                1: begin
                    if (lerp_sstream_i[`STREAM_SI_VALID(`LERPINATOR_OUT_WIDTH)]) begin
                        tx <= lerp_sstream_i[`STREAM_SI_DATA(`LERPINATOR_OUT_WIDTH)];

                        if (state == user_count_i + 2) state <= 9;
                        else state <= state + 1;
                    end
                end

                2: begin
                    if (lerp_sstream_i[`STREAM_SI_VALID(`LERPINATOR_OUT_WIDTH)]) begin
                        ty <= lerp_sstream_i[`STREAM_SI_DATA(`LERPINATOR_OUT_WIDTH)];

                        if (state == user_count_i + 2) state <= 9;
                        else state <= state + 1;
                    end
                end

                3: begin
                    if (lerp_sstream_i[`STREAM_SI_VALID(`LERPINATOR_OUT_WIDTH)]) begin
                        u0 <= lerp_sstream_i[`STREAM_SI_DATA(`LERPINATOR_OUT_WIDTH)];

                        if (state == user_count_i + 2) state <= 9;
                        else state <= state + 1;
                    end
                end

                4: begin
                    if (lerp_sstream_i[`STREAM_SI_VALID(`LERPINATOR_OUT_WIDTH)]) begin
                        u1 <= lerp_sstream_i[`STREAM_SI_DATA(`LERPINATOR_OUT_WIDTH)];

                        if (state == user_count_i + 2) state <= 9;
                        else state <= state + 1;
                    end
                end

                5: begin
                    if (lerp_sstream_i[`STREAM_SI_VALID(`LERPINATOR_OUT_WIDTH)]) begin
                        u2 <= lerp_sstream_i[`STREAM_SI_DATA(`LERPINATOR_OUT_WIDTH)];

                        if (state == user_count_i + 2) state <= 9;
                        else state <= state + 1;
                    end
                end

                6: begin
                    if (lerp_sstream_i[`STREAM_SI_VALID(`LERPINATOR_OUT_WIDTH)]) begin
                        u3 <= lerp_sstream_i[`STREAM_SI_DATA(`LERPINATOR_OUT_WIDTH)];

                        if (state == user_count_i + 2) state <= 9;
                        else state <= state + 1;
                    end
                end

                7: begin
                    if (lerp_sstream_i[`STREAM_SI_VALID(`LERPINATOR_OUT_WIDTH)]) begin
                        u4 <= lerp_sstream_i[`STREAM_SI_DATA(`LERPINATOR_OUT_WIDTH)];

                        if (state == user_count_i + 2) state <= 9;
                        else state <= state + 1;
                    end
                end

                8: begin
                    if (lerp_sstream_i[`STREAM_SI_VALID(`LERPINATOR_OUT_WIDTH)]) begin
                        u5 <= lerp_sstream_i[`STREAM_SI_DATA(`LERPINATOR_OUT_WIDTH)];

                        state <= state + 1;
                    end
                end

                9: begin
                    if (mstream_i[`STREAM_MI_READY(`RAST_WAVG_OUT_WIDTH)]) begin
                        state <= 0;
                    end
                end
            endcase
        end
    end

    always @(*) begin
        sstream_o[`STREAM_SO_READY(2 * `SC_WIDTH)] = state == 0;

        case (state)
            1, 2, 3, 4, 5, 6, 7, 8: begin
                lerp_sstream_o[`STREAM_SO_READY(`LERPINATOR_OUT_WIDTH)] = 1;
            end

            default: begin
                lerp_sstream_o[`STREAM_SO_READY(`LERPINATOR_OUT_WIDTH)] = 0;
            end
        endcase

        mstream_o[`STREAM_MO_VALID(`RAST_WAVG_OUT_WIDTH)] <= state == 9;
        mstream_o[`STREAM_MO_LAST(`RAST_WAVG_OUT_WIDTH)] <= 0;
        mstream_o[`STREAM_MO_DATA(`RAST_WAVG_OUT_WIDTH)] <= {
            posx, posy, tx_shift, ty_shift, u0, u1, u2, u3, u4, u5
        };
    end

endmodule

