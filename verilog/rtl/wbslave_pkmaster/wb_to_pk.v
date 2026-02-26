module wb_to_pk_m
(
    // Wb slave
    input wire wb_clk_i,            // clock
    input wire wb_rst_i,            // Reset
    input wire wbs_stb_i,           // Cycle strobe (asserts when ready to trasnsfer data)
    input wire wbs_cyc_i,           // cycle in progress (transfer)
    input [3:0] wbs_sel_i,           
    output reg wbs_ack_o,           // acknowledge (asserted indicates termination of cycle)
    input wire [31:0] wbs_dat_i,    // data in 
    input wire [31:0] wbs_adr_i,    // address
    output reg [31:0] wbs_dat_o,    // data out
    input wire wbs_we_i,             // write en 

    // PKbus master
    input wire [`BUS_MIPORT] mport_i, 
    output reg [`BUS_MOPORT] mport_o
);

    //wires for wishbone reg communication
    localparam NUM_REGS = 5;

    localparam WBS_ACK_ADDR = 1;
    localparam WBS_ACK_WDATA = 2;
    localparam WBS_ACK_WCOUNT = 3;

    reg [NUM_REGS-1:0] wbs_stbN;
    wire [NUM_REGS-1:0] wbs_ackN;
    wire [`WORD_WIDTH-1:0] wbs_datN [NUM_REGS-1:0];


    wire [`WORD] addr_reg;

    wishbone_register_m #(32'h00000000, 1, `WBREG_TYPE_REG) addr (
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .wbs_stb_i(wbs_stbN[1]),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_we_i(wbs_we_i),
        .wbs_sel_i(wbs_sel_i),
        .wbs_dat_i(wbs_dat_i),
        .wbs_adr_i(wbs_adr_i),
        .wbs_ack_o(wbs_ackN[1]),
        .wbs_dat_o(wbs_datN[1]),

        .access_read_mask_i(32'hFFFFFFFF), // assuming masks dont change since this reg contains 1 numbers
        .access_write_mask_i(32'hFFFFFFFF),
        .periph_read_mask_i(0),

        .enable_prot_i(32'h00000000), 
        .enable_i(0), 

        .reg_i(0), 
        .reg_o(addr_reg) 
    );


    wire [`WORD] wdata_reg;

    wishbone_register_m #(32'h00000000, 1, `WBREG_TYPE_REG) wdata (
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .wbs_stb_i(wbs_stbN[2]),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_we_i(wbs_we_i),
        .wbs_sel_i(wbs_sel_i),
        .wbs_dat_i(wbs_dat_i),
        .wbs_adr_i(wbs_adr_i),
        .wbs_ack_o(wbs_ackN[2]),
        .wbs_dat_o(wbs_datN[2]),

        .access_read_mask_i(32'hFFFFFFFF), // assuming masks dont change since this reg contains 1 numbers
        .access_write_mask_i(32'hFFFFFFFF),
        .periph_read_mask_i(0),

        .enable_prot_i(32'h00000000), //confused
        .enable_i(0), // 

        .reg_i(0), //will need for pk read later
        .reg_o(wdata_reg) 
    );


    wire [`WORD] wcount_reg;
    reg [`WORD] wcount_dec_reg;

    wishbone_register_m #(32'h00000000, 1, `WBREG_TYPE_REG) wcount (
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .wbs_stb_i(wbs_stbN[3]),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_we_i(wbs_we_i),
        .wbs_sel_i(wbs_sel_i),
        .wbs_dat_i(wbs_dat_i),
        .wbs_adr_i(wbs_adr_i),
        .wbs_ack_o(wbs_ackN[3]),
        .wbs_dat_o(wbs_datN[3]),

        .access_read_mask_i(32'hFFFFFFFF), // assuming masks dont change since this reg contains 1 numbers
        .access_write_mask_i(32'hFFFFFFFF),
        .periph_read_mask_i(32'hFFFFFFFF),

        .enable_prot_i(32'h00000000), //confused
        .enable_i(0), // what does this exactly mean

        .reg_i(wcount_dec_reg), // new count 
        .reg_o(wcount_reg) // updated count
    );



    //wire mux/decoder logic
    // Mux between the registers (similar to user_project_wrapper's addressing)
    wire [$clog2(NUM_REGS)-1:0] word_offset = {2'b00, wbs_adr_i[31:2]}; // leaves bits of addr 4:2 as word offset 000 001 010 100 101
    always @ (*) begin
        wbs_stbN = wbs_stb_i << word_offset; // shifts by offset, thereore provides proper stb 00001, 00010, 00100, 01000, 10000 
        wbs_ack_o = wbs_ackN[word_offset];  //views ackN signals at the offset value, so if offset = 100 (00100), the 'middle' ack line and see what that value is
        wbs_dat_o = wbs_datN[word_offset]; // same as ack
    end


    localparam STANDBY = 0; 
    localparam WISHBONE_WRITE_PREP = 1;
    localparam PK_WRITE_PREP  = 2;
    localparam PK_STREAM_WRITE = 3;
    localparam PK_WRITE_CLEANUP = 4;
    localparam TRANSACTION_COMPLETE = 5; 

    reg [16:0] state;
    reg [4:0] write_size;
    reg[2:0] bridge_write_status;

    always@ (posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            mport_o <= 0;
            wbs_ack_o   <= 0; 

            bridge_write_status <= 0; 
            wcount_dec_reg <= 0;

            state <= STANDBY;
        end
	else begin
        case (state) 
            STANDBY: begin  //wait until wishbone master wants to use bridge
                wbs_ack_o   <= 1'b0; 
                mport_o[`BUS_MO_REQ]  <= 0;
                
                if (wbs_stb_i)    
                    state  <= WISHBONE_WRITE_PREP;
            end
            WISHBONE_WRITE_PREP: begin //wait until a wb data reg slave is ready (ack_o is 1)
                if (wbs_ack[WBS_ACK_WDATA] == 1) 
                    state <= PK_WRITE_PREP;  
            end  
            PK_WRITE_PREP: begin //data now on wishbone, pk stream write now occurs
                mport_o[`BUS_MO_REQ] <= 1;
                mport_o[`BUS_MO_RW] <= `BUS_WRITE;
                mport_o[`BUS_MO_SEQMST] <= 0;

                mport_o[`BUS_MO_SIZE]   <= `BUS_SIZE_STREAM;
                mport_o[`BUS_MO_ADDR]   <= addr_reg;
                mport_o[`BUS_MO_DATA]   <= wdata_reg;

                if(mport_i[`BUS_MI_ACK] == 1)
                    state <= PK_STREAM_WRITE;
                else
                    state <= PK_WRITE_PREP;
            end
            PK_STREAM_WRITE: begin
                if (mport_i[`BUS_MI_SEQSLV] == 0) begin
                    if (wcount_reg > 0)
                        mport_o[`BUS_MO_DATA]   <= wdata_reg;
                    else begin
                        mport_o[`BUS_MO_SEQMST] <= 1;
                        state <= PK_WRITE_CLEANUP;
                    end
                    wcount_dec_reg <= wcount_reg - 1;
                end
            end
            PK_WRITE_CLEANUP: begin
                if(!mport_i[`BUS_MI_ACK]) begin
                    mport_o[`BUS_MO_REQ] <= 0;
                    mport_o[`BUS_MO_SEQMST] <= 0;
                    state <= STANDBY;
                end
            end
        endcase
    end
end
endmodule

//cases to watch for:
//What happens to wb side if managment core whats to update any wb regs during a pk stream write?
//soltion: this is why we have states, should not be a problem?

//TODO:
// how to make use of reset in wb registers
// how to compile before testing
// examples to plug in managment core and can i use vga as the slave.

//Include all wishbone signals (from top of user project wrapper)
//pk bus only include mport_i and mport_o, since it includes all the other wires, user_defs at 124