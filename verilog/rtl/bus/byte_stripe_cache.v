module byte_write_stripe_cache_m #(
    parameter STRIPE_SIZE = 8
) (
    input wire clk_i,
    input wire nrst_i,

    input  wire [`BUS_MOPORT] cached_mport_i,
    output wire [`BUS_MIPORT] cached_mport_o,

    input  wire [`BUS_MIPORT] mport_i,
    output wire [`BUS_MOPORT] mport_o
);

    wire [`BUS_MOPORT] cached_mporti;
    reg [`BUS_MIPORT] cached_mporto;

    wire [`BUS_MIPORT] mporti;
    reg [`BUS_MOPORT] mporto;

    assign mporti = cached_mport_i[`BUS_MO_SIZE] == `BUS_SIZE_BYTE ? mport_i : 0;
    assign cached_mporti = cached_mport_i[`BUS_MO_SIZE] == `BUS_SIZE_BYTE ? cached_mport_i : 0;

    assign mport_o = cached_mport_i[`BUS_MO_SIZE] == `BUS_SIZE_BYTE ? mporto : cached_mport_i;
    assign cached_mport_o = cached_mport_i[`BUS_MO_SIZE] == `BUS_SIZE_BYTE ? cached_mporto : mport_i;

    localparam STATE_READY      = 2'b00;
    localparam STATE_REQ        = 2'b01;
    localparam STATE_ACK        = 2'b10;
    localparam STATE_CACHE_DUMP = 2'b11;

    reg [1:0] state;
    reg [2:0] dump_state;

    reg [$clog2(STRIPE_SIZE + 1) - 1:0] buffer_index;
    reg [$clog2(STRIPE_SIZE) - 1:0] buffer_size;
    reg [`BUS_ADDR_PORT] buffer_addr;

    reg [7:0] buffer [STRIPE_SIZE - 1:0];

    always @(posedge clk_i, negedge nrst_i) begin
        if (!nrst_i) begin
            state <= STATE_READY;
            dump_state <= 0;

            buffer_index <= 0;
            buffer_size  <= 0;
            buffer_addr  <= 0;

            mporto <= 0;
            cached_mporto <= 0;
        end
        else if (clk_i) begin
            case (state)
                STATE_READY: begin
                    if (cached_mporti[`BUS_MO_REQ]) begin
                        if (cached_mporti[`BUS_MO_ADDR] != buffer_addr + buffer_size || buffer_size == STRIPE_SIZE) begin
                            state <= STATE_CACHE_DUMP;
                            dump_state <= 0;

                            buffer_index <= 0;
                        end
                        else begin
                            state <= STATE_REQ;
                        end

                        cached_mporto[`BUS_MI_ACK] <= 1;
                    end
                end

                STATE_REQ: begin
                    state <= STATE_ACK;

                    buffer[buffer_size] <= cached_mporti[`BUS_MO_DATA];
                    
                    buffer_size <= buffer_size + 1;

                    cached_mporto[`BUS_MI_ACK] <= 0;
                end

                STATE_ACK: begin
                    if (!cached_mporti[`BUS_MO_REQ]) state <= STATE_READY;
                end

                STATE_CACHE_DUMP: begin
                    case (dump_state)
                        0: begin
                            if (buffer_size - buffer_index == 0) begin
                                state <= STATE_READY;

                                buffer_addr <= cached_mporti[`BUS_MO_ADDR];
                                buffer_size <= 0;
                            end
                            else if (buffer_size - buffer_index >= 4) begin
                                if (mporti[`BUS_MI_ACK]) begin
                                    dump_state <= 2;

                                    buffer_index <= buffer_index + 4;
                                    buffer_addr  <= buffer_addr + 4;
                                end

                                mporto[`BUS_MO_DATA] <= {buffer[buffer_index], buffer[buffer_index + 1], buffer[buffer_index + 2], buffer[buffer_index + 3] };
                                mporto[`BUS_MO_ADDR] <= buffer_addr;

                                mporto[`BUS_MO_SIZE] <= `BUS_SIZE_STREAM;
                                mporto[`BUS_MO_RW]   <= `BUS_WRITE;

                                mporto[`BUS_MO_REQ]  <= 1;
                            end
                            else begin
                                if (mporti[`BUS_MI_ACK]) dump_state <= 1;

                                mporto[`BUS_MO_DATA] <= buffer[buffer_index];
                                mporto[`BUS_MO_ADDR] <= buffer_addr;

                                mporto[`BUS_MO_SIZE] <= `BUS_SIZE_BYTE;
                                mporto[`BUS_MO_RW]   <= `BUS_WRITE;

                                mporto[`BUS_MO_REQ]  <= 1;
                            end
                        end

                        1: begin
                            if (!mporti[`BUS_MI_ACK]) begin
                                dump_state <= 0;

                                mporto[`BUS_MO_REQ]  <= 0;

                                buffer_index <= buffer_index + 1;
                                buffer_addr  <= buffer_addr + 1;
                            end
                        end

                        2: begin
                            if (mporti[`BUS_MI_SEQSLV]) begin
                                if (buffer_size - buffer_index < 4) begin
                                    dump_state <= 4;

                                    mporto[`BUS_MO_REQ]  <= 0;
                                end
                                else begin
                                    dump_state <= 3;

                                    mporto[`BUS_MO_DATA] <= {buffer[buffer_index + 3], buffer[buffer_index + 2], buffer[buffer_index + 1], buffer[buffer_index + 0] };

                                    buffer_index <= buffer_index + 4;
                                    buffer_addr  <= buffer_addr + 4;
                                end
                            end
                        end

                        3: begin
                            if (!mporti[`BUS_MI_SEQSLV]) begin
                                dump_state <= 2;
                            end
                        end

                        4: begin
                            if (!mporti[`BUS_MI_ACK]) begin
                                dump_state <= 0;
                            end
                        end
                    endcase
                end
            endcase
        end
    end

endmodule
