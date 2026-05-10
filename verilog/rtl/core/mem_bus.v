/*
*   Memory pkbus connection for the uGPU core
*   clk_i   : clock
*   nrst_i  : async reset
*   nsync_rst_i : synchrounous reset
*   stall_i : external stall from other modules
*   stall_o : stall required by this module
*   data_o  : latched read data
*   mport_i : PKBus master input
*   mo_req_o    : PKBus master output request
*   prep_state_condition : condition to enter prep state
*   repeated_access_condition : condition for repeated access 
*/

module mem_bus_m (
    input  wire         clk_i,
    input  wire         nrst_i,
    input  wire         nsync_rst_i,
    input  wire         stall_i,
    output reg          stall_o,
    output reg[`WORD]   data_o,

    input  wire[`BUS_MIPORT] mport_i,
    output reg mo_req_o,

    input  wire prep_state_condition,
    input  wire repeated_acccess_condition
);
    localparam BUS_DEFAULT_STATE = 0;
    localparam BUS_PREP_STATE = 1;
    localparam BUS_TRANSACTION_STATE = 2;
    localparam BUS_WAIT_STATE = 3;
    localparam BUS_BACK2BACK_STATE = 4;
    reg[2:0] bus_state;
    reg[2:0] next_bus_state;

    always @(*) begin
        next_bus_state <= bus_state;

        stall_o <= 0;

        case(bus_state)
            BUS_DEFAULT_STATE: begin
                if(prep_state_condition)
                    next_bus_state <= BUS_PREP_STATE;
            end
            BUS_PREP_STATE: begin
                stall_o <= 1;
                if(mport_i[`BUS_MI_ACK])
                    next_bus_state <= BUS_TRANSACTION_STATE;
            end
            BUS_TRANSACTION_STATE: begin
                stall_o <= 1;
                if(!mport_i[`BUS_MI_ACK]) begin
                    next_bus_state <= BUS_WAIT_STATE;
                end
            end
            BUS_WAIT_STATE: begin
                if(!stall_i) begin
                    if(repeated_acccess_condition)
                        next_bus_state <= BUS_BACK2BACK_STATE;
                    else
                        next_bus_state <= BUS_DEFAULT_STATE;
                end 
            end
            BUS_BACK2BACK_STATE: begin
                stall_o <= 1;
                next_bus_state <= BUS_PREP_STATE;
            end
            default:
                next_bus_state <= BUS_DEFAULT_STATE;
        endcase

        case(bus_state)
            BUS_PREP_STATE, BUS_TRANSACTION_STATE: mo_req_o <= 1;
            default: mo_req_o <= 0;
        endcase
    end

always @(posedge clk_i, negedge nrst_i) begin
    if(!nrst_i) begin
        bus_state <= BUS_DEFAULT_STATE;
        data_o <= 0;
    end
    else if (clk_i) begin
        if(!nsync_rst_i) begin
            bus_state <= BUS_DEFAULT_STATE;
            data_o <= 0;
        end
        else begin
            bus_state <= next_bus_state;
            if(bus_state == BUS_TRANSACTION_STATE)
                data_o <= mport_i[`BUS_MI_DATA];
        end
    end
end

endmodule