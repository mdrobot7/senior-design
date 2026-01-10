module mem_write_m(
    input wire clk_i,
    input wire nrst_i,

    input  wire [`STREAM_SIPORT(`SC_WIDTH * 2 + `WORD_WIDTH * 3)] sstream_i,
    output wire [`STREAM_SOPORT(`SC_WIDTH * 2 + `WORD_WIDTH * 3)] sstream_o,

    input  wire [`BUS_MIPORT] mport_i,
    output reg  [`BUS_MOPORT] mport_o,

    input wire [7:0] color_i
);

    `DL_DEFINE(logger, "mem_write_m", `DL_MAGENTA, 1);

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
                    if (sstream_i[`STREAM_SI_VALID(`SC_WIDTH * 2 + `WORD_WIDTH * 3)]) begin
                        state <= 1;

                        { posx, posy, tx, ty, depth } <= sstream_i[`STREAM_SI_DATA(`SC_WIDTH * 2 + `WORD_WIDTH * 3)];
                    end
                end

                1: begin
                    if (mport_i[`BUS_MI_ACK]) begin
                        state <= 2;

                        `DL(logger, ("(%d, %d): 0x%h", posx, posy, `ADDR_DEPTH_BUFFER + 4 * (posy * `WIDTH + posx)));
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

                        `DL(logger, ("(%d, %d): 0x%h", posx, posy, `ADDR_DEPTH_BUFFER + 4 * (posy * `WIDTH + posx)));
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
                    
                        mport_o[`BUS_MO_REQ]  <= 0;
                    end
                end


                5: begin
                    if (mport_i[`BUS_MI_ACK]) begin
                        state <= 6;
                    end

                    mport_o[`BUS_MO_ADDR] <= posy * `WIDTH + posx;
                    mport_o[`BUS_MO_DATA] <= color_i;

                    mport_o[`BUS_MO_RW]   <= `BUS_WRITE;
                    mport_o[`BUS_MO_SIZE] <= `BUS_SIZE_BYTE;

                    mport_o[`BUS_MO_REQ]  <= 1;
                end

                6: begin
                    if (!mport_i[`BUS_MI_ACK]) begin
                        state <= 0;
                    
                        mport_o[`BUS_MO_REQ]  <= 0;
                    end
                end
            endcase
        end
    end

    assign sstream_o[`STREAM_SO_READY(`SC_WIDTH * 2 + `WORD_WIDTH * 3)] = state == 0;

endmodule