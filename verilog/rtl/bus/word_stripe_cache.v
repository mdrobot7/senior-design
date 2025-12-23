module word_stripe_cache_m #(
    parameter WRITE_STRIPE_SIZE = 8,
    parameter READ_STRIPE_SIZE  = 8
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

    assign mporti = cached_mport_i[`BUS_MO_SIZE] == `BUS_SIZE_WORD ? mport_i : 0;
    assign cached_mporti = cached_mport_i[`BUS_MO_SIZE] == `BUS_SIZE_WORD ? cached_mport_i : 0;

    assign mport_o = cached_mport_i[`BUS_MO_SIZE] == `BUS_SIZE_WORD ? mporto : cached_mport_i;
    assign cached_mport_o = cached_mport_i[`BUS_MO_SIZE] == `BUS_SIZE_WORD ? cached_mporto : mport_i;

    // assign mporti = mport_i;
    // assign cached_mporti = cached_mport_i;

    // assign mport_o = mporto;
    // assign cached_mport_o = cached_mporto;

    localparam STATE_READY       = 3'b000;
    localparam STATE_WRITE       = 3'b001;
    localparam STATE_WRITE_FLUSH = 3'b010;
    localparam STATE_READ        = 3'b011;
    localparam STATE_READ_PREP   = 3'b100;
    localparam STATE_DONE        = 3'b101;

    reg [2:0] state;

    reg [`BUS_ADDR_PORT] write_stripe_addr;
    reg [$clog2(WRITE_STRIPE_SIZE + 1) - 1:0] write_stripe_size;
    reg [31:0] write_stripe [WRITE_STRIPE_SIZE - 1:0];

    reg [$clog2(WRITE_STRIPE_SIZE + 1) - 1:0] write_stripe_index;
    reg [1:0] write_stripe_state;

    reg [`BUS_ADDR_PORT] read_stripe_addr;
    reg [31:0] read_stripe [READ_STRIPE_SIZE - 1:0];

    reg [$clog2(READ_STRIPE_SIZE + 1) - 1:0] read_stripe_index;
    reg [1:0] read_stripe_state;

    always @(posedge clk_i, negedge nrst_i) begin
        if (!nrst_i) begin
            state <= STATE_READY;

            cached_mporto <= 0;
            mporto <= 0;

            write_stripe_addr  <= 0;
            write_stripe_size  <= 0;

            write_stripe_index <= 0;
            write_stripe_state <= 0;

            read_stripe_addr <= 32'hFFFFFFFF - READ_STRIPE_SIZE - 10;
            read_stripe_index <= 0;
            read_stripe_state <= 0;
        end
        else if (clk_i) begin
            case (state)
                STATE_READY: begin
                    if (write_stripe_size == WRITE_STRIPE_SIZE) begin
                        state <= STATE_WRITE_FLUSH;
                                    
                        write_stripe_index <= 0;
                    end
                    else begin
                        if (cached_mporti[`BUS_MO_REQ]) begin
                            if (cached_mporti[`BUS_MO_RW] == `BUS_READ) begin
                                if (
                                    cached_mporti[`BUS_MO_ADDR] - read_stripe_addr >= READ_STRIPE_SIZE * 4
                                ) begin
                                    state <= STATE_READ_PREP;
                                    
                                    read_stripe_addr <= cached_mporti[`BUS_MO_ADDR];
                                    read_stripe_index <= 0;
                                end
                                else begin
                                    state <= STATE_READ;

                                    cached_mporto[`BUS_MI_ACK] <= 1;
                                end
                            end
                            else begin
                                if (
                                    cached_mporti[`BUS_MO_ADDR] != write_stripe_addr + (write_stripe_size * 4) &&
                                    write_stripe_size != 0
                                ) begin
                                    state <= STATE_WRITE_FLUSH;
                                    
                                    write_stripe_index <= 0;
                                end
                                else begin
                                    state <= STATE_WRITE;

                                    if (write_stripe_size == 0) write_stripe_addr <= cached_mporti[`BUS_MO_ADDR];

                                    cached_mporto[`BUS_MI_ACK] <= 1;
                                end
                            end
                        end
                    end
                end

                STATE_WRITE: begin
                    state <= STATE_DONE;

                    write_stripe[write_stripe_size] <= cached_mporti[`BUS_MO_DATA];

                    write_stripe_size <= write_stripe_size + 1;
                end

                STATE_WRITE_FLUSH: begin
                    case (write_stripe_state)
                        0: begin
                            if (mporti[`BUS_MI_ACK]) begin
                                write_stripe_state <= 1;

                                write_stripe_index <= write_stripe_index + 1;

                                if (write_stripe_size == 1) mporto[`BUS_MO_SEQMST] <= 1;
                            end

                            mporto[`BUS_MO_ADDR] <= write_stripe_addr;
                            mporto[`BUS_MO_DATA] <= write_stripe[write_stripe_index];
                            mporto[`BUS_MO_RW]   <= `BUS_WRITE;
                            mporto[`BUS_MO_SIZE] <= `BUS_SIZE_STREAM;
                            mporto[`BUS_MO_REQ] <= 1;
                        end

                        1: begin
                            if (mporti[`BUS_MI_SEQSLV]) begin
                                if (write_stripe_index == write_stripe_size) begin
                                    write_stripe_state <= 3;

                                    mporto[`BUS_MO_SEQMST] <= 1;
                                end
                                else begin
                                    write_stripe_state <= 2;

                                    $display("Attempt write 0x%h", write_stripe[write_stripe_index]);
                                    mporto[`BUS_MO_DATA] <= write_stripe[write_stripe_index];
                                end
                            end
                        end

                        2: begin
                            write_stripe_state <= 1;

                            write_stripe_index <= write_stripe_index + 1;
                        end

                        3: begin
                            if (!mporti[`BUS_MI_ACK]) begin
                                state <= STATE_READY;
                                write_stripe_state <= 0;
                            end

                            mporto[`BUS_MO_SEQMST] <= 0;
                            mporto[`BUS_MO_REQ] <= 0;

                            write_stripe_size <= 0;
                        end
                    endcase
                end

                STATE_READ: begin
                    state <= STATE_DONE;

                    cached_mporto[`BUS_MO_DATA] <= read_stripe[(cached_mporti[`BUS_MO_ADDR] - read_stripe_addr) / 4];
                end

                STATE_READ_PREP: begin
                    case (read_stripe_state)
                        0: begin
                            if (mporti[`BUS_MI_ACK]) begin
                                read_stripe_state <= 1;
                            end

                            mporto[`BUS_MO_ADDR] <= read_stripe_addr;
                            mporto[`BUS_MO_RW]   <= `BUS_READ;
                            mporto[`BUS_MO_SIZE] <= `BUS_SIZE_STREAM;

                            mporto[`BUS_MO_REQ] <= 1;
                        end

                        1: begin
                            if (mporti[`BUS_MI_SEQSLV]) begin
                                if (read_stripe_index == READ_STRIPE_SIZE - 1) begin
                                    read_stripe_state <= 3;

                                    mporto[`BUS_MO_SEQMST] <= 1;
                                end
                                else begin
                                    read_stripe_state <= 2;

                                    read_stripe_index <= read_stripe_index + 1;
                                end

                                read_stripe[read_stripe_index] <= mporti[`BUS_MI_DATA];
                            end
                        end

                        2: begin
                            if (!mporti[`BUS_MI_SEQSLV]) begin
                                read_stripe_state <= 1;
                            end
                        end

                        3: begin
                            mporto[`BUS_MO_REQ] <= 0;

                            if (!mporti[`BUS_MI_ACK]) begin
                                state <= STATE_READY;

                                mporto[`BUS_MO_SEQMST] <= 0;

                                read_stripe_state <= 0;
                            end
                        end
                    endcase
                end

                STATE_DONE: begin
                    if (!cached_mporti[`BUS_MO_REQ]) state <= STATE_READY;

                    cached_mporto[`BUS_MI_ACK] <= 0;
                end
            endcase
        end
    end

endmodule