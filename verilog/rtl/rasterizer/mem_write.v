module mem_write_m(
    input wire clk_i,
    input wire nrst_i,

    input  wire [`STREAM_SIPORT(`COLOR_WIDTH + `SC_WIDTH * 2 + `WORD_WIDTH * 3)] sstream_i,
    output wire [`STREAM_SOPORT(`COLOR_WIDTH + `SC_WIDTH * 2 + `WORD_WIDTH * 3)] sstream_o,

    input  wire [`BUS_MIPORT] mport_i,
    output reg  [`BUS_MOPORT] mport_o,

    input wire fb_i
);

    `DL_DEFINE(logger, "mem_write_m", `DL_MAGENTA, 1);

    wire [`BUS_ADDR_PORT] fb_addr;
    assign fb_addr = fb_i ? `ADDR_FB1 : `ADDR_FB0;

    reg [`COLOR] color;
    reg [`SC_WIDTH - 1:0] posx, posy;
    reg [`WORD_WIDTH - 1:0] tx, ty;
    reg [`WORD_WIDTH - 1:0] depth;

    reg [7:0] state;

    always @(posedge clk_i, negedge nrst_i) begin
        if (!nrst_i) begin
            state <= 0;

            mport_o <= 0;
        end
        else if (clk_i) begin
            case (state)
                0: begin
                    if (sstream_i[`STREAM_SI_VALID(`COLOR_WIDTH + `SC_WIDTH * 2 + `WORD_WIDTH * 3)]) begin
                        state <= 1;

                        { color, posx, posy, tx, ty, depth } <= sstream_i[`STREAM_SI_DATA(`COLOR_WIDTH + `SC_WIDTH * 2 + `WORD_WIDTH * 3)];
                    end
                end

                1: begin
                    if (mport_i[`BUS_MI_ACK]) begin
                        state <= 2;
                    end

                    mport_o[`BUS_MO_ADDR] <= fb_addr + posy * `WIDTH + posx;
                    mport_o[`BUS_MO_DATA] <= color;

                    mport_o[`BUS_MO_RW]   <= `BUS_WRITE;
                    mport_o[`BUS_MO_SIZE] <= `BUS_SIZE_BYTE;

                    mport_o[`BUS_MO_REQ]  <= 1;
                end

                2: begin
                    if (!mport_i[`BUS_MI_ACK]) begin
                        state <= 0;
                    
                        mport_o[`BUS_MO_REQ]  <= 0;
                    end
                end
            endcase
        end
    end

    assign sstream_o[`STREAM_SO_READY(`COLOR_WIDTH + `SC_WIDTH * 2 + `WORD_WIDTH * 3)] = state == 0;

endmodule