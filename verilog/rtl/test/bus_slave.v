/*
    Simulated memory block acting as a PKBus slave.
*/
module bus_slave_m #(
    parameter ADDRESS = 0,
    parameter SIZE = 1024
) (
    input wire clk_i,
    input wire nrst_i,

    input wire [`BUS_SIPORT] sport_i,
    output reg  [`BUS_SOPORT] sport_o,

    output reg bad_read_o
);

    localparam STATE_READY      = 0;
    localparam STATE_ARB        = 1; // Need 1 cycle of waiting between ACK and data for arbiter
    localparam STATE_READ       = 2;
    localparam STATE_READ_WAIT  = 3;
    localparam STATE_WRITE      = 4;
    localparam STATE_WRITE_WAIT = 5;
    localparam STATE_DONE       = 6;
    reg [3:0] state;

    wire [`BUS_ADDR_PORT] rel_addr;
    assign rel_addr = sport_i[`BUS_SI_ADDR] - ADDRESS;

    reg [`WORD] stream_counter;

    // 32-bit wire lets us slice up the incoming data neatly
    wire [`BUS_DATA_SIZE-1:0] in_data;
    assign in_data = sport_i[`BUS_SI_DATA];

    reg [7:0] mem[SIZE-1:0];

    integer i;

    always @ (posedge clk_i or negedge nrst_i) begin
        if (!nrst_i) begin
            for(i = 0; i < SIZE; i++)
                mem[i] <= 0;
            sport_o <= 0;
            state <= STATE_READY;
            stream_counter <= 0;
            bad_read_o <= 0;
        end
        else if (clk_i) begin
            case (state)
                STATE_READY: begin
                    if (sport_i[`BUS_SI_REQ]) begin
                        sport_o[`BUS_SO_ACK] <= 1; // "I got a request"
                        stream_counter <= 0;
                        state <= STATE_ARB;
                    end
                end
                STATE_ARB: begin
                    if (sport_i[`BUS_SI_RW] == `BUS_READ)
                        state <= STATE_READ;
                    else
                        state <= STATE_WRITE;
                end
                STATE_READ: begin
                    // Return 0 and assert bad_read_o if out of address range
                    if (rel_addr + stream_counter >= SIZE) begin
                        sport_o[`BUS_SO_DATA] <= 0;
                        bad_read_o <= 1;
                        $display("ERROR: Read out of address range");
                        case (sport_i[`BUS_SI_SIZE])
                          `BUS_SIZE_BYTE, `BUS_SIZE_WORD: begin
                            sport_o[`BUS_SO_ACK] <= 0;
                            state <= STATE_DONE;
                          end
                          `BUS_SIZE_STREAM: begin
                              sport_o[`BUS_SO_SEQSLV] <= 1;
                              state <= STATE_READ_WAIT;
                          end
                        endcase
                    end
                    else begin
                        case (sport_i[`BUS_SI_SIZE])
                        `BUS_SIZE_BYTE: begin
                            sport_o[`BUS_SO_DATA] <= {24'd0, mem[rel_addr]};
                            sport_o[`BUS_SO_ACK] <= 0;
                            state <= STATE_DONE;
                        end
                        `BUS_SIZE_WORD: begin
                            sport_o[`BUS_SO_DATA] <= {
                                mem[rel_addr + 3],
                                mem[rel_addr + 2],
                                mem[rel_addr + 1],
                                mem[rel_addr + 0]
                            };
                            sport_o[`BUS_SO_ACK] <= 0;
                            state <= STATE_DONE;
                        end
                        `BUS_SIZE_STREAM: begin
                            sport_o[`BUS_SO_DATA] <= {
                                mem[rel_addr + stream_counter + 3],
                                mem[rel_addr + stream_counter + 2],
                                mem[rel_addr + stream_counter + 1],
                                mem[rel_addr + stream_counter + 0]
                            };
                            stream_counter <= stream_counter + 4;
                            sport_o[`BUS_SO_SEQSLV] <= 1; // Data is valid
                            state <= STATE_READ_WAIT;
                        end
                        endcase
                    end
                end
                STATE_READ_WAIT: begin
                    sport_o[`BUS_SO_SEQSLV] <= 0;
                    case (sport_i[`BUS_SI_SIZE])
                    `BUS_SIZE_STREAM: begin
                        if (sport_i[`BUS_SI_SEQMST]) begin
                            sport_o[`BUS_SO_SEQSLV] <= 0;
                            sport_o[`BUS_SO_ACK] <= 0; // Operation done
                            state <= STATE_DONE;
                        end
                        else begin
                            state <= STATE_READ; // Simulate 1 cycle of latency between repeat reads
                        end
                    end
                    endcase
                end
                STATE_WRITE: begin
                    case (sport_i[`BUS_SI_SIZE])
                    `BUS_SIZE_BYTE: begin
                        mem[rel_addr] <= in_data[7:0];
                        sport_o[`BUS_SO_ACK] <= 0;
                        state <= STATE_DONE;
                    end
                    `BUS_SIZE_WORD: begin
                        mem[rel_addr + 3] <= in_data[31:24];
                        mem[rel_addr + 2] <= in_data[23:16];
                        mem[rel_addr + 1] <= in_data[15:8];
                        mem[rel_addr + 0] <= in_data[7:0];
                        sport_o[`BUS_SO_ACK] <= 0;
                        state <= STATE_DONE;
                    end
                    `BUS_SIZE_STREAM: begin
                        mem[rel_addr + stream_counter + 3] <= in_data[31:24];
                        mem[rel_addr + stream_counter + 2] <= in_data[23:16];
                        mem[rel_addr + stream_counter + 1] <= in_data[15:8];
                        mem[rel_addr + stream_counter + 0] <= in_data[7:0];
                        stream_counter <= stream_counter + 4;
                        sport_o[`BUS_SO_SEQSLV] <= 0; // Data stored
                        state <= STATE_WRITE_WAIT;
                    end
                    endcase
                end
                STATE_WRITE_WAIT: begin
                    case (sport_i[`BUS_SI_SIZE])
                    `BUS_SIZE_STREAM: begin
                        if (sport_i[`BUS_SI_SEQMST]) begin
                            sport_o[`BUS_SO_SEQSLV] <= 0;
                            sport_o[`BUS_SO_ACK] <= 0;
                            state <= STATE_DONE;
                        end
                        else begin
                            sport_o[`BUS_SO_SEQSLV] <= 1; // Next bus write will be stored
                            state <= STATE_WRITE; // Simulate 1 cycle of latency between repeat reads
                        end
                    end
                    endcase
                end
                STATE_DONE: begin
                    if (!sport_i[`BUS_SI_REQ])
                        state <= STATE_READY;
                    stream_counter <= 0;
                end
            endcase
        end
    end

endmodule
