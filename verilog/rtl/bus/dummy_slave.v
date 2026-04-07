module dummy_slave_m #(
    parameter ADDRESS = 0,
    parameter SIZE = 1
) (
    input wire clk_i,
    input wire nrst_i,

    input  wire [`BUS_SIPORT] sport_i,
    output reg  [`BUS_SOPORT] sport_o
);

    localparam STATE_READY = 2'd0;
    localparam STATE_WRITE = 2'd1;
    localparam STATE_READ  = 2'd2;
    localparam STATE_DONE  = 2'd3;

    reg [1:0] state;

    always @(posedge clk_i, negedge nrst_i) begin
        if (!nrst_i) begin
            state <= STATE_READY;

            sport_o <= 0;
        end
        else if (clk_i) begin
            case (state)
                STATE_READY: begin
                    if (sport_i[`BUS_SI_REQ]) begin
                        if (sport_i[`BUS_SI_RW] == `BUS_READ) state <= STATE_READ;
                        else state <= STATE_WRITE;

                        sport_o[`BUS_SO_ACK] <= 1;
                        sport_o[`BUS_SO_SEQSLV] <= 0;
                    end
                end

                STATE_WRITE: begin
                    if (sport_i[`BUS_SI_SIZE] == `BUS_SIZE_STREAM) begin
                        if (sport_i[`BUS_SI_SEQMST]) begin
                            state <= STATE_DONE;
                            
                            sport_o[`BUS_SO_SEQSLV] <= 0;
                        end
                        else begin
                            sport_o[`BUS_SO_SEQSLV] <= !sport_o[`BUS_SO_SEQSLV];
                        end
                    end
                    else begin
                        state <= STATE_DONE;
                    end
                end

                STATE_READ: begin
                    if (sport_i[`BUS_SI_SIZE] == `BUS_SIZE_STREAM) begin
                        if (sport_i[`BUS_SI_SEQMST]) begin
                            state <= STATE_DONE;
                            
                            sport_o[`BUS_SO_SEQSLV] <= 0;
                        end
                        else begin
                            sport_o[`BUS_SO_SEQSLV] <= !sport_o[`BUS_SO_SEQSLV];
                        end
                    end
                    else begin
                        state <= STATE_DONE;
                    end
                end

                STATE_DONE: begin
                    if (!sport_i[`BUS_SI_REQ]) state <= STATE_READY;

                    sport_o[`BUS_SO_ACK] <= 0;
                end
            endcase
        end
    end

endmodule
