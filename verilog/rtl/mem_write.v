module mem_write_m(
    input wire clk_i,
    input wire nrst_i,

    output wire busy_o,

    input  wire [`STREAM_SIPORT(`FRAGMENT_WIDTH)] sstream_i,
    output wire [`STREAM_SOPORT(`FRAGMENT_WIDTH)] sstream_o,

    input  wire [`BUS_MIPORT] mport_i,
    output reg  [`BUS_MOPORT] mport_o,

    input wire fb_i
);

    `DL_DEFINE(logger, "mem_write_m", `DL_MAGENTA, 1);

    wire [`BUS_ADDR_PORT] fb_addr;
    assign fb_addr = fb_i ? `ADDR_FB1 : `ADDR_FB0;

    reg [`WORD] color_ex;
    wire [`COLOR] color = color_ex;
    reg [`WORD] posx_ex, posy_ex;
    wire [`SC_WIDTH - 1:0] posx = posx_ex, posy = posy_ex;

    reg [7:0] state;

    always @(posedge clk_i, negedge nrst_i) begin
        if (!nrst_i) begin
            state <= 0;

            mport_o <= 0;
        end
        else if (clk_i) begin
            case (state)
                0: begin
                    if (sstream_i[`STREAM_SI_VALID(`FRAGMENT_WIDTH)]) begin
                        state <= 1;

                        { posx_ex, posy_ex, color_ex } <= sstream_i[`STREAM_SI_DATA(`FRAGMENT_WIDTH)];
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

                default: ;
            endcase
        end
    end

    assign sstream_o[`STREAM_SO_READY(`FRAGMENT_WIDTH)] = state == 0;

    assign busy_o = state != 0;

endmodule

