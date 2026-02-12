module tex_sample_m(
    input wire clk_i,
    input wire nrst_i,

    input  wire [`STREAM_SIPORT(`RAST_DT_OUT_WIDTH)] sstream_i,
    output wire [`STREAM_SOPORT(`RAST_DT_OUT_WIDTH)] sstream_o,

    input  wire [`STREAM_MIPORT(`RAST_TS_OUT_WIDTH)] mstream_i,
    output wire [`STREAM_MOPORT(`RAST_TS_OUT_WIDTH)] mstream_o,

    input  wire [`BUS_MIPORT] mport_i,
    output reg  [`BUS_MOPORT] mport_o,

    input  wire [`BUS_ADDR_PORT] tex_addr_i,
    input  wire [`TEX_DIM] tex_width_i
);

    `DL_DEFINE(logger, "tex_sample_m", `DL_MAGENTA, 1);

    reg out_ready;
    reg [`COLOR] color;
    reg [`SC_WIDTH - 1:0] posx, posy;
    reg [`WORD_WIDTH - 1:0] tx, ty;
    reg [`WORD_WIDTH - 1:0] depth;

    reg [`BUS_ADDR_PORT] addr;
    reg [`BUS_ADDR_PORT] prev_addr;

    assign mstream_o[`STREAM_MO_VALID(`RAST_TS_OUT_WIDTH)] = out_ready;
    assign mstream_o[`STREAM_MO_DATA(`RAST_TS_OUT_WIDTH)]  = { color, posx, posy, tx, ty, depth };

    reg [7:0] state;

    always @(posedge clk_i, negedge nrst_i) begin
        if (!nrst_i) begin
            state <= 0;

            mport_o <= 0;

            addr       <= 32'hFFFFFFFE;
            prev_addr  <= 32'hFFFFFFFF;

            out_ready <= 0;
        end
        else if (clk_i) begin
            case (state)
                0: begin
                    if (sstream_i[`STREAM_SI_VALID(`RAST_DT_OUT_WIDTH)]) begin
                        state <= 1;

                        { posx, posy, tx, ty, depth } = sstream_i[`STREAM_SI_DATA(`RAST_DT_OUT_WIDTH)];

                        addr <= tex_addr_i + tx;
                    end
                end

                1: begin
                    addr = addr + ty * tex_width_i;
                    
                    // if (prev_addr == addr) begin
                    //     state <= 4;

                    //     out_ready <= 1;
                    // end
                    // else begin
                        state <= 2;

                        mport_o[`BUS_MO_ADDR] <= addr;

                        mport_o[`BUS_MO_RW]   <= `BUS_READ;
                        mport_o[`BUS_MO_SIZE] <= `BUS_SIZE_BYTE;

                        mport_o[`BUS_MO_REQ]  <= 1;
                    // end
                end

                2: begin
                    if (mport_i[`BUS_MI_ACK]) begin
                        state <= 3;
                    end
                end

                3: begin
                    if (!mport_i[`BUS_MI_ACK]) begin
                        state <= 4;

                        prev_addr <= addr;

                        color <= mport_i[`BUS_MI_DATA];
                        out_ready <= 1;
                    
                        mport_o[`BUS_MO_REQ]  <= 0;
                    end
                end

                4: begin
                    if (mstream_i[`STREAM_MI_READY(`RAST_TS_OUT_WIDTH)]) begin
                        state <= 0;

                        out_ready <= 0;
                    end
                end

                default: ;
            endcase
        end
    end

    assign sstream_o[`STREAM_SO_READY(`RAST_DT_OUT_WIDTH)] = state == 0;

endmodule
