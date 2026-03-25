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

    localparam WBS_ACK_STATUS = 0;
    localparam WBS_ACK_ADDR = 1;
    localparam WBS_ACK_WDATA = 2;
    localparam WBS_ACK_WCOUNT = 3;
    localparam WBS_ACK_RDATA = 4;

    reg [NUM_REGS-1:0] wbs_stbN;
    wire [NUM_REGS-1:0] wbs_ackN;
    wire [`WORD_WIDTH-1:0] wbs_datN [NUM_REGS-1:0];
    wire rdata_ready = (state == PK_STREAM_READ && mport_i[`BUS_MI_ACK]);

    //h30123000 -> 0000 : 0011 0000 0000 0000
    //h30123400 -> 0400 : 0011 0100 0000 0000
    //h30123800 -> 0800 : 0011 1000 0000 0000
    //h30123C00 -> 0C00 : 0011 1100 0000 0000
    //h30121000 -> 1000 : 0001 0000 0000 0000

    //wire mux/decoder logic
    // Mux between the registers (similar to user_project_wrapper's addressing)
    wire [$clog2(NUM_REGS)-1:0] word_offset = { ~wbs_adr_i[12], wbs_adr_i[11:10] }; // leaves bits of addr 4:2 as word offset 000 001 010 100 101
    always @ (*) begin
        wbs_stbN = 0;
 
        if (word_offset == WBS_ACK_RDATA)
            wbs_stbN[WBS_ACK_RDATA] = wbs_stb_i && rdata_ready;
        else
            wbs_stbN = wbs_stb_i << word_offset; // shifts by offset, thereore provides proper stb 00001, 00010, 00100, 01000, 10000 

        wbs_ack_o = wbs_ackN[word_offset];  //views ackN signals at the offset value, so if offset = 100 (00100), the 'middle' ack line and see what that value is
        wbs_dat_o = wbs_datN[word_offset]; // same as ack

    end


    reg [`WORD] status_reg;
    wire [`WORD] status_reg_unused;


    wishbone_register_m #(32'h00000000, 1, `WBREG_TYPE_REG) status (
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .wbs_stb_i(wbs_stbN[0]),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_we_i(wbs_we_i),
        .wbs_sel_i(wbs_sel_i),
        .wbs_dat_i(wbs_dat_i),
        .wbs_adr_i(wbs_adr_i),
        .wbs_ack_o(wbs_ackN[0]),
        .wbs_dat_o(wbs_datN[0]),

        .access_read_mask_i(32'hFFFFFFFF), // assuming masks dont change since this reg contains 1 numbers
        .access_write_mask_i(32'hFFFFFFFF),
        .periph_read_mask_i(0),

        .enable_prot_i(32'h00000000), 
        .enable_i(0), 

        .reg_i(status_reg), 
        .reg_o(status_reg_unused) 
    );

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
        .enable_i(0), 

        .reg_i(0), 
        .reg_o(wdata_reg) 
    );


    wire [`WORD] wcount_reg;
    reg [`WORD] wcount_inc_reg;

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

        .reg_i(wcount_inc_reg), // new count 
        .reg_o(wcount_reg) // updated count
    );

    reg [`WORD] rdata_reg;
    wire [`WORD] rdata_reg_unused;

    wishbone_register_m #(32'h00000000, 1, `WBREG_TYPE_REG) rdata (
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .wbs_stb_i(wbs_stbN[4]),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_we_i(wbs_we_i),
        .wbs_sel_i(wbs_sel_i),
        .wbs_dat_i(wbs_dat_i),
        .wbs_adr_i(wbs_adr_i),
        .wbs_ack_o(wbs_ackN[4]),
        .wbs_dat_o(wbs_datN[4]),

        .access_read_mask_i(32'hFFFFFFFF), // assuming masks dont change since this reg contains 1 numbers
        .access_write_mask_i(32'hFFFFFFFF),
        .periph_read_mask_i(32'hFFFFFFFF),

        .enable_prot_i(32'h00000000), //confused
        .enable_i(0), // what does this exactly mean

        .reg_i(rdata_reg),
        .reg_o(rdata_reg_unused)
    );


    localparam STANDBY = 0; 
    localparam WISHBONE_WRITE_PREP = 1;
    localparam PK_WRITE_PREP  = 2;
    localparam PK_STREAM_WRITE = 3;
    localparam PK_CLEANUP = 4;
    localparam TRANSACTION_COMPLETE = 5; 
    localparam WISHBONE_READ_PREP = 6;
    localparam PK_READ_PREP = 7;
    localparam PK_STREAM_READ = 8;
    localparam PK_READ_CLEANUP = 9;
    

    reg [16:0] state;
    reg [4:0] write_size;
    reg[2:0] bridge_write_status;

    always@ (posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            mport_o <= 0;
            // wbs_ack_o   <= 0; 
            status_reg <= 0;
            bridge_write_status <= 0; 
            wcount_inc_reg <= 1;
            state <= STANDBY;
        end
	else begin
        case (state) 
            STANDBY: begin  //wait until wishbone master wants to use bridge
                // wbs_ack_o   <=0; 
                mport_o[`BUS_MO_REQ]  <= 0;
                status_reg <= 0;
                if (wbs_stb_i && wbs_we_i)    
                    state  <= WISHBONE_WRITE_PREP;
                else if (wbs_stb_i && !wbs_we_i)
                    if (word_offset == WBS_ACK_RDATA)
                        state <= PK_READ_PREP;
                    else
                        state <= WISHBONE_READ_PREP;
            end
            WISHBONE_WRITE_PREP: begin //wait until a wb data reg slave is ready (ack_o is 1)
                status_reg <= 1;
                if (wbs_ackN[WBS_ACK_WDATA] == 1)
                    state <= PK_WRITE_PREP;  
                else if (wbs_ackN[WBS_ACK_ADDR] == 1)
                    state <= STANDBY;
                else if (wbs_ackN[WBS_ACK_WCOUNT] == 1)
                    state <= STANDBY;
       
            end  
            WISHBONE_READ_PREP: begin //wait until a wb data reg slave is ready (ack_o is 1)
                status_reg <= 6;
                if (wbs_ackN[WBS_ACK_WDATA] == 1)
                    state <= STANDBY;  
                else if (wbs_ackN[WBS_ACK_ADDR] == 1)
                    state <= STANDBY;
                else if (wbs_ackN[WBS_ACK_STATUS] == 1)
                    state <= STANDBY;                    
                   
            end 
            PK_WRITE_PREP: begin //data now on wishbone, pk stream write now occurs
                mport_o[`BUS_MO_REQ] <= 1;
                mport_o[`BUS_MO_RW] <= `BUS_WRITE;
                mport_o[`BUS_MO_SEQMST] <= 0;
                mport_o[`BUS_MO_SIZE]   <= `BUS_SIZE_STREAM;
                mport_o[`BUS_MO_ADDR]   <= addr_reg;
                mport_o[`BUS_MO_DATA]   <= wdata_reg;

                status_reg <= 2;

                if(mport_i[`BUS_MI_ACK] == 1)
                    state <= PK_STREAM_WRITE;
                else
                    state <= PK_WRITE_PREP;
            end
            PK_STREAM_WRITE: begin
                status_reg <= 3;
                if (mport_i[`BUS_MI_SEQSLV] == 0) begin
                    if(wcount_inc_reg + 1 == wcount_reg) 
                        mport_o[`BUS_MO_SEQMST] <= 1;
                    if (wcount_reg >= wcount_inc_reg) begin
                        mport_o[`BUS_MO_DATA]   <= wdata_reg;
                        wcount_inc_reg <= wcount_inc_reg + 1;
                    end
                    else begin
                        state <= PK_CLEANUP;
                    end
                end
            end
            PK_CLEANUP: begin
                status_reg <= 4;
                if(!mport_i[`BUS_MI_ACK]) begin
                    mport_o[`BUS_MO_REQ] <= 0;
                    mport_o[`BUS_MO_SEQMST] <= 0;
                    mport_o[`BUS_MO_DATA] <= 0;

                    state <= STANDBY;
                end
            end
            PK_READ_PREP: begin 
                    status_reg <= 7;

                    mport_o[`BUS_MO_REQ] <= 1;
                    mport_o[`BUS_MO_RW] <= `BUS_READ;
                    mport_o[`BUS_MO_SEQMST] <= 0;
                    mport_o[`BUS_MO_SIZE]   <= `BUS_SIZE_STREAM;
                    mport_o[`BUS_MO_ADDR]   <= addr_reg;

                    if(mport_i[`BUS_MI_ACK] == 1)
                        state <= PK_STREAM_READ;
                    else
                        state <= PK_READ_PREP;
            end
            PK_STREAM_READ: begin
                status_reg <= 8;

                mport_o[`BUS_MO_SEQMST] <= 1;

                if (mport_i[`BUS_MI_SEQSLV] == 1 && mport_i[`BUS_MI_ACK] == 1) begin
                    rdata_reg <= mport_i[`BUS_MI_DATA];
                    state <= PK_CLEANUP;
                end
            end


            
            PK_READ_CLEANUP: begin
                status_reg <= 9;
                    mport_o[`BUS_MO_REQ] <= 0;
                    mport_o[`BUS_MO_SEQMST] <= 0;
                    mport_o[`BUS_MO_DATA] <= 0;
                    mport_o[`BUS_MO_REQ] <= 0;
                    mport_o[`BUS_MO_SEQMST] <= 0;
                    mport_o[`BUS_MO_DATA] <= 0;
                    state <= PK_CLEANUP;                    

            end
        endcase
    end
end
endmodule

//PAST

//cases to watch for:
//What happens to wb side if managment core whats to update any wb regs during a pk stream write?
//soltion: this is why we have states, should not be a problem?

//TODO:
// how to make use of reset in wb registers
// how to compile before testing
// examples to plug in managment core and can i use vga as the slave.

//Include all wishbone signals (from top of user project wrapper)
//pk bus only include mport_i and mport_o, since it includes all the other wires, user_defs at 124

//issue, count seems not to decrement, we are stuck on streaming data, since seqmst is continously high.fixed.


//Questions:
// While a stream write on pk is occuring, do we halt wishbone? I believe so
//Hypothetical: If a long pkstream write occurs (pk is not ready or a large count), and wishbone sets up for a new write sequence, we can entirely miss it.
//However, this may not be possible since technically, wishone will continue to run strobe high until the bridge acknowledges, therefore we do not need to "halt" wb.

// Complete Bugs
// 1.
//Pk stream write looks like its working, however PK slave in ack hangs high for an additional cycle. Not as matching to the diagram.
//Cont: MO signals match diagram. Only discrepency is MI ack in hangs for 1 cycle until finishing. THIS IS OKAY




//Bugs:

// 1.
// If i am in state 2, pk write prep (wishbone regs all set) and I change the address register, it actually changes the ADDR reg in bridge while it is not 
// supposed to (ADDR is supposed to be locked). Is this because wishbone helper? Thought the states are the entire reason behind this.
//What is supposed to happen is wishbone needs to wait until it receives an ack from from slave. Can i add an AND to the ack signals from wb reg while 
// anything pk is occuring? Soltuion, status reg at the very least to make this a software issue, if need be more, we protection masking will help



//A wishbone read is a pk write

//possible issue, pk stream read will have 2 cycles until seqmst

//CURRENT

// need to fix the undefined signal with ack in some parts. 