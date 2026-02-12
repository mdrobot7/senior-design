module wb_to_pk #(
    parameter ADDRESS = 0,
    parameter SIZE = 1  
) (
    // Wb slave
    input wire wb_clk_i,            // clock
    input wire wb_rst_i,            // Reset
    input wire wbs_stb_i,           // Cycle strobe (asserts when ready to trasnsfer data)
    input wire wbs_cyc_i,           // cycle in progress (transfer)
    output reg wbs_ack_o,           // acknowledge (asserted indicates termination of cycle)

    input wire [31:0] wbs_dat_i,    // data in 
    input wire [31:0] wbs_adr_i,    // address
    output reg [31:0] wbs_dat_o,    // data out

    input wire wbs_we_i,             // write en 


    // PKbus master
    input wire [`BUS_MIPORT] mport_i, 
    output wire [`BUS_MOPORT] mport_o, 

    output reg pk_req_o, 
    input wire pk_ack_i, 
    output reg pk_rw_o, // WE

    output reg [1:0] pk_size_o,

    output reg [`BUS_ADDR_PORT] pk_addr_o,

    input wire [`BUS_DATA_PORT] pk_data_i,
    output reg [`BUS_DATA_PORT] pk_data_o
);

    localparam STATE_WAIT  = 2'b00; 
    localparam STATE_TRANSFER = 2'b01;
    localparam STATE_ACK  = 2'b10;

    reg [1:0] cur_state, next_state;

    always@ (posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
        //what does reset do
            cur_state <= STATE_WAIT;

        end
	else begin

        next_state = STATE_WAIT; // default
        pk_size_o = 2'b10; // default size, word

        case (cur_state) 

            STATE_WAIT: begin
                wbs_ack_o   = 1'b0; 
                pk_req_o    = 1'b0;

                if (wbs_stb_i && wbs_cyc_i) begin
                    pk_addr_o   = wbs_adr_i;
                    pk_data_o   = wbs_dat_i;
                    pk_rw_o     = wbs_we_i;
                    pk_req_o    = 1'b1;
                    next_state  = STATE_TRANSFER;
                end
            end

            STATE_TRANSFER: begin
                wbs_ack_o   = 1'b1;
                wbs_dat_o   = wbs_we_i ? 0 : pk_data_i;
                next_state = STATE_ACK;
            end  

            STATE_ACK: begin
                if (!pk_ack_i) begin
                    pk_req_o = 1'b0;
                    wbs_ack_o   = 1'b0;
                    next_state  = STATE_WAIT;
                end
            end

        endcase
    end
end
endmodule