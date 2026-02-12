module depth_test_m(
    input wire clk_i,
    input wire nrst_i,

    input  wire [`STREAM_SIPORT(`RAST_WAVG_OUT_WIDTH)] sstream_i,
    output wire [`STREAM_SOPORT(`RAST_WAVG_OUT_WIDTH)] sstream_o,

    input  wire [`STREAM_MIPORT(`RAST_DT_OUT_WIDTH)] mstream_i,
    output wire [`STREAM_MOPORT(`RAST_DT_OUT_WIDTH)] mstream_o,

    input  wire [`BUS_MIPORT] mport_i,
    output reg  [`BUS_MOPORT] mport_o,

    output wire busy_o
);

    `DL_DEFINE(logger, "depth_test_m", `DL_MAGENTA, 1);

    reg [`SC_WIDTH - 1:0] posx, posy;
    reg [`WORD_WIDTH - 1:0] tx, ty;
    reg [`WORD_WIDTH - 1:0] depth;

    reg [7:0] state;

    reg out_ready;

    assign mstream_o[`STREAM_MO_VALID(`RAST_DT_OUT_WIDTH)] = out_ready;
    assign mstream_o[`STREAM_MO_DATA(`RAST_DT_OUT_WIDTH)]  = { posx, posy, tx, ty, depth };

    always @(posedge clk_i, negedge nrst_i) begin
        if (!nrst_i) begin
            state <= 0;

            mport_o <= 0;
            // fixed point
            `define FP(x) (($signed((x) * (64'b1 << `DECIMAL_POS))) & 32'hFFFFFFFF)
            
            `define FP_MUL(a, b) (($signed({ {`WORD_WIDTH{a[`WORD_WIDTH - 1]}}, (a) }) * $signed({ {`WORD_WIDTH{b[`WORD_WIDTH - 1]}}, (b) })) >>> `DECIMAL_POS)
            `define FP_DIV(a, b) ((($signed({ {`WORD_WIDTH{a[`WORD_WIDTH - 1]}}, (a) }) << `DECIMAL_POS) / $signed({ {`WORD_WIDTH{b[`WORD_WIDTH - 1]}}, (b) })))
        end
        else if (clk_i) begin
            case (state)
                0: begin
                    if (sstream_i[`STREAM_SI_VALID(`RAST_WAVG_OUT_WIDTH)]) begin
                        state <= 1;

                        { posx, posy, tx, ty, depth } <= sstream_i[`STREAM_SI_DATA(`RAST_WAVG_OUT_WIDTH)];
                    end
                end

                1: begin
                    if (mport_i[`BUS_MI_ACK]) begin
                        state <= 2;
                    end

                    mport_o[`BUS_MO_ADDR] <= `ADDR_DEPTH_BUFFER + 4 * (posy * `WIDTH + posx);

                    mport_o[`BUS_MO_RW]   <= `BUS_READ;
                    mport_o[`BUS_MO_SIZE] <= `BUS_SIZE_WORD;

                    mport_o[`BUS_MO_REQ]  <= 1;
                end

                2: begin
                    if (!mport_i[`BUS_MI_ACK]) begin
                        if (mport_i[`BUS_MO_DATA] > depth) state <= 3;
                        else begin
                            state <= 0;
                        end
                    
                        mport_o[`BUS_MO_REQ]  <= 0;
                    end
                end

                3: begin
                    if (mport_i[`BUS_MI_ACK]) begin
                        state <= 4;
                    end

                    mport_o[`BUS_MO_ADDR] <= `ADDR_DEPTH_BUFFER + 4 * (posy * `WIDTH + posx);
                    mport_o[`BUS_MO_DATA] <= depth;

                    mport_o[`BUS_MO_RW]   <= `BUS_WRITE;
                    mport_o[`BUS_MO_SIZE] <= `BUS_SIZE_WORD;

                    mport_o[`BUS_MO_REQ]  <= 1;
                end

                4: begin
                    if (!mport_i[`BUS_MI_ACK]) begin
                        state <= 5;

                        out_ready <= 1;
                    
                        mport_o[`BUS_MO_REQ]  <= 0;
                    end
                end

                5: begin
                    if (mstream_i[`STREAM_MI_READY(`RAST_WAVG_OUT_WIDTH)]) begin
                        out_ready <= 0;

                        state <= 0;
                    end
                end

                default: ;
            endcase
        end
    end

    assign sstream_o[`STREAM_SO_READY(`RAST_DT_OUT_WIDTH)] = state == 0;

    assign busy_o = state != 0;

endmodule