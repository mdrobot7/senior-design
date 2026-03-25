module wb_to_pk_m
(
    input wire wb_clk_i,            
    input wire wb_rst_i,            
    input wire wbs_stb_i,          
    input wire wbs_cyc_i,           
    input [3:0] wbs_sel_i,           
    output reg wbs_ack_o,         
    input wire [31:0] wbs_dat_i,   
    input wire [31:0] wbs_adr_i,   
    output reg [31:0] wbs_dat_o,    
    input wire wbs_we_i,             

  
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


    //wire mux/decoder logic
    wire [$clog2(NUM_REGS)-1:0] word_offset = { ~wbs_adr_i[12], wbs_adr_i[11:10] }; // leaves bits of addr 4:2 as word offset 000 001 010 100 101
    always @ (*) begin
        wbs_stbN = 0;
        
        if(word_offset < NUM_REGS) begin 
            if (word_offset == WBS_ACK_RDATA)
                wbs_stbN[WBS_ACK_RDATA] = wbs_stb_i && rdata_ready;
            else
                wbs_stbN = wbs_stb_i << word_offset; // shifts by offset, provides proper stb 00001, 00010, 00100, 01000, 10000 

            wbs_ack_o = wbs_ackN[word_offset];  
            wbs_dat_o = wbs_datN[word_offset]; 
        end 
        else
            wbs_ack_o = 0;
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

        .access_read_mask_i(32'hFFFFFFFF), 
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

        .access_read_mask_i(32'hFFFFFFFF), 
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

        .access_read_mask_i(32'hFFFFFFFF), 
        .access_write_mask_i(32'hFFFFFFFF),
        .periph_read_mask_i(0),

        .enable_prot_i(32'h00000000), 
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

        .access_read_mask_i(32'hFFFFFFFF), 
        .access_write_mask_i(32'hFFFFFFFF),
        .periph_read_mask_i(32'hFFFFFFFF),

        .enable_prot_i(32'h00000000), 
        .enable_i(0), 

        .reg_i(wcount_inc_reg), 
        .reg_o(wcount_reg) 
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

        .access_read_mask_i(32'hFFFFFFFF), 
        .access_write_mask_i(32'hFFFFFFFF),
        .periph_read_mask_i(32'hFFFFFFFF),

        .enable_prot_i(32'h00000000), 
        .enable_i(0), 

        .reg_i(rdata_reg),
        .reg_o(rdata_reg_unused)
    );


    localparam STANDBY = 0; 
    localparam WISHBONE_WRITE_PREP = 1;
    localparam PK_WRITE_PREP  = 2;
    localparam PK_STREAM_WRITE = 3;
    localparam WISHBONE_READ_PREP = 4;
    localparam PK_READ_PREP = 5;
    localparam PK_STREAM_READ = 6;
    localparam PK_CLEANUP = 7;
    
    reg [7:0] state;

    always@ (posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            mport_o <= 0;
            status_reg <= 0;
            wcount_inc_reg <= 1;
            state <= STANDBY;
        end
	else begin
        case (state) 
            STANDBY: begin  //wait until wishbone master wants to use bridge
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
                status_reg <= 4;
                if (wbs_ackN[WBS_ACK_WDATA] == 1)
                    state <= STANDBY;  
                else if (wbs_ackN[WBS_ACK_ADDR] == 1)
                    state <= STANDBY;
                else if (wbs_ackN[WBS_ACK_STATUS] == 1)
                    state <= STANDBY;                    
                   
            end 
            PK_WRITE_PREP: begin //data now on wishbone, pk stream write now occurs
                status_reg <= 2;
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
                status_reg <= 7;
                if(!mport_i[`BUS_MI_ACK]) begin
                    mport_o[`BUS_MO_REQ] <= 0;
                    mport_o[`BUS_MO_SEQMST] <= 0;
                    mport_o[`BUS_MO_DATA] <= 0;

                    state <= STANDBY;
                end
            end
            PK_READ_PREP: begin 
                    status_reg <= 5;

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
                status_reg <= 6;
                mport_o[`BUS_MO_SEQMST] <= 1;

                if (mport_i[`BUS_MI_SEQSLV] == 1 && mport_i[`BUS_MI_ACK] == 1) begin
                    rdata_reg <= mport_i[`BUS_MI_DATA];
                    state <= PK_CLEANUP;
                end
            end
        endcase
    end
end
endmodule

