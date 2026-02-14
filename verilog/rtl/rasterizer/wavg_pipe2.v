module wavg_pipe2_m(
    input wire clk_i,
    input wire nrst_i,

    input  wire [`STREAM_SIPORT(`SC_WIDTH * 2 + `WORD_WIDTH)] sstream_i,
    output reg  [`STREAM_SOPORT(`SC_WIDTH * 2 + `WORD_WIDTH)] sstream_o,

    input  wire [`STREAM_MIPORT(`RAST_WAVG_OUT_WIDTH)] mstream_i,
    output reg  [`STREAM_MOPORT(`RAST_WAVG_OUT_WIDTH)] mstream_o,

    input  wire [`STREAM_SIPORT(`DIVIDER_WIDTH)] div_sstream_i,
    output reg  [`STREAM_SOPORT(`DIVIDER_WIDTH)] div_sstream_o
);

    reg [`WORD] depth;
    reg [`SC_WIDTH - 1:0] posx, posy;
    reg [`WORD] tx, ty;

    reg [1:0] state;

    always @(posedge clk_i, negedge nrst_i) begin
        if (!nrst_i) begin
            state <= 0;

            depth <= 0;
            posx  <= 0;
            posy  <= 0;
            tx    <= 0;
            ty    <= 0;
        end
        else if (clk_i) begin
            case (state)
                0: begin
                    if (sstream_i[`STREAM_SI_VALID(`SC_WIDTH * 2 + `WORD_WIDTH)]) begin
                        state <= state + 1;

                        { depth, posx, posy } <= sstream_i[`STREAM_SI_DATA(`SC_WIDTH * 2 + `WORD_WIDTH)];
                    end
                end

                1: begin
                    if (div_sstream_i[`STREAM_SI_VALID(`DIVIDER_WIDTH)]) begin
                        state <= state + 1;

                        tx <= div_sstream_i[`STREAM_SI_DATA(`DIVIDER_WIDTH)] >>> `DECIMAL_POS;
                    end
                end

                2: begin
                    if (div_sstream_i[`STREAM_SI_VALID(`DIVIDER_WIDTH)]) begin
                        state <= state + 1;

                        ty <= div_sstream_i[`STREAM_SI_DATA(`DIVIDER_WIDTH)] >>> `DECIMAL_POS;
                    end
                end

                3: begin
                    if (mstream_i[`STREAM_MI_READY(`RAST_WAVG_OUT_WIDTH)]) begin
                        state <= 0;
                    end
                end
            endcase
        end
    end

    always @(*) begin
        case (state)
            0: begin
                sstream_o[`STREAM_SO_READY(`SC_WIDTH * 2 + `WORD_WIDTH)] <= 1;
            end

            default: begin
                sstream_o[`STREAM_SO_READY(`SC_WIDTH * 2 + `WORD_WIDTH)] <= 0;
            end
        endcase

        case (state)
            1, 2: begin
                div_sstream_o[`STREAM_SO_READY(`DIVIDER_WIDTH)] <= 1;
            end

            default: begin
                div_sstream_o[`STREAM_SO_READY(`DIVIDER_WIDTH)] <= 0;
            end
        endcase

        mstream_o[`STREAM_MO_DATA(`RAST_WAVG_OUT_WIDTH)] <= { posx, posy, tx, ty, depth };
        mstream_o[`STREAM_MO_LAST(`RAST_WAVG_OUT_WIDTH)] <= 0;

        case (state)
            3: begin
                mstream_o[`STREAM_MO_VALID(`RAST_WAVG_OUT_WIDTH)] <= 1;
            end

            default: begin
                mstream_o[`STREAM_MO_VALID(`RAST_WAVG_OUT_WIDTH)] <= 0;
            end
        endcase
    end

endmodule