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
    localparam STATUS_INDEX = 0;
    localparam ADDR_INDEX = 1;
    localparam WDATA_INDEX = 2;
    localparam WCOUNT_INDEX = 3;
    localparam RDATA_INDEX = 4;

    localparam STANDBY = 0;
    localparam PK_WRITE_PREP  = 1;
    localparam PK_STREAM_WRITE = 2;
    localparam PK_READ_PREP = 3;
    localparam PK_WORD_READ = 4;
    localparam PK_CLEANUP = 5;

    reg [2:0] state;

    reg [NUM_REGS-1:0] wbs_stbN;
    wire [NUM_REGS-1:0] wbs_ackN;
    wire [`WORD_WIDTH-1:0] wbs_datN [NUM_REGS-1:0];
    wire rdata_ready = (state == PK_CLEANUP);


    // reg seqmst_hold_reg;
    // wire combinational_seqmst;
    // wire base_seqmst;

    // assign base_seqmst =
    //     (state == PK_STREAM_WRITE && (wcount_inc_reg + 2 > wcount_reg) && mport_i[`BUS_MI_SEQSLV]) ? 1'b1 :
    //     1'b0;
    // assign combinational_seqmst = base_seqmst | seqmst_hold_reg;
    // assign mport_o = {
    //     mport_o[`BUS_MOPORT_SIZE-1:`BUS_MO_SEQMST+1],
    //     combinational_seqmst,
    //     mport_o[`BUS_MO_SEQMST-1:0]
    // };

    //wire mux/decoder logic
    wire [$clog2(NUM_REGS)-1:0] word_offset = {2'b00, wbs_adr_i[31:2]};

    always @ (*) begin
        wbs_stbN = 0;
        wbs_dat_o = wbs_datN[word_offset];

        if(word_offset < NUM_REGS) begin
            if (word_offset == RDATA_INDEX) begin
                wbs_stbN[RDATA_INDEX] = wbs_stb_i && rdata_ready;
            end
            else
                wbs_stbN = {{(NUM_REGS-1){1'b0}}, wbs_stb_i} << word_offset; // shifts by offset, provides proper stb 00001, 00010, 00100, 01000, 10000
            wbs_ack_o = wbs_ackN[word_offset];
        end
        else
            wbs_ack_o = 0;
    end


    wishbone_register_m #(.RESET_VALUE(32'h00000000), .SIZE_WORDS(1), .TYPE(`WBREG_TYPE_REG)) status (
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .wbs_stb_i(wbs_stbN[STATUS_INDEX]),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_we_i(wbs_we_i),
        .wbs_sel_i(wbs_sel_i),
        .wbs_dat_i(wbs_dat_i),
        .wbs_adr_i(wbs_adr_i),
        .wbs_ack_o(wbs_ackN[STATUS_INDEX]),
        .wbs_dat_o(wbs_datN[STATUS_INDEX]),

        .access_read_mask_i(32'h0000000F),
        .access_write_mask_i(32'h0000000F),
        .periph_read_mask_i(32'h0000000F),

        .enable_prot_i(32'h00000000),
        .enable_i(0),

        .reg_i({29'b0 , state}),
        .reg_o()
    );


    wire [`WORD] addr_reg;

    wishbone_register_m #(.RESET_VALUE(32'h00000000), .SIZE_WORDS(1), .TYPE(`WBREG_TYPE_REG)) addr (
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .wbs_stb_i(wbs_stbN[ADDR_INDEX]),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_we_i(wbs_we_i),
        .wbs_sel_i(wbs_sel_i),
        .wbs_dat_i(wbs_dat_i),
        .wbs_adr_i(wbs_adr_i),
        .wbs_ack_o(wbs_ackN[ADDR_INDEX]),
        .wbs_dat_o(wbs_datN[ADDR_INDEX]),

        .access_read_mask_i(32'hFFFFFFFF),
        .access_write_mask_i(32'hFFFFFFFF),
        .periph_read_mask_i(0),

        .enable_prot_i(32'h00000000),
        .enable_i(0),

        .reg_i(0),
        .reg_o(addr_reg)
    );


    wire [`WORD] wdata_reg;

    wishbone_register_m #(.RESET_VALUE(32'h00000000), .SIZE_WORDS(1), .TYPE(`WBREG_TYPE_REG)) wdata (
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .wbs_stb_i(wbs_stbN[WDATA_INDEX]),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_we_i(wbs_we_i),
        .wbs_sel_i(wbs_sel_i),
        .wbs_dat_i(wbs_dat_i),
        .wbs_adr_i(wbs_adr_i),
        .wbs_ack_o(wbs_ackN[WDATA_INDEX]),
        .wbs_dat_o(wbs_datN[WDATA_INDEX]),

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

    wishbone_register_m #(.RESET_VALUE(32'h00000000), .SIZE_WORDS(1), .TYPE(`WBREG_TYPE_REG)) wcount (
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .wbs_stb_i(wbs_stbN[WCOUNT_INDEX]),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_we_i(wbs_we_i),
        .wbs_sel_i(wbs_sel_i),
        .wbs_dat_i(wbs_dat_i),
        .wbs_adr_i(wbs_adr_i),
        .wbs_ack_o(wbs_ackN[WCOUNT_INDEX]),
        .wbs_dat_o(wbs_datN[WCOUNT_INDEX]),

        .access_read_mask_i(32'hFFFFFFFF),
        .access_write_mask_i(32'hFFFFFFFF),
        .periph_read_mask_i(32'h00000000),

        .enable_prot_i(32'h00000000),
        .enable_i(0),

        .reg_i(wcount_inc_reg),
        .reg_o(wcount_reg)
    );


    reg [`WORD] rdata_reg;

    wishbone_register_m #(.RESET_VALUE(32'h00000000), .SIZE_WORDS(1), .TYPE(`WBREG_TYPE_REG)) rdata (
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .wbs_stb_i(wbs_stbN[RDATA_INDEX]),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_we_i(wbs_we_i),
        .wbs_sel_i(wbs_sel_i),
        .wbs_dat_i(wbs_dat_i),
        .wbs_adr_i(wbs_adr_i),
        .wbs_ack_o(wbs_ackN[RDATA_INDEX]),
        .wbs_dat_o(wbs_datN[RDATA_INDEX]),

        .access_read_mask_i(32'hFFFFFFFF),
        .access_write_mask_i(32'hFFFFFFFF),
        .periph_read_mask_i(32'hFFFFFFFF),

        .enable_prot_i(32'h00000000),
        .enable_i(0),

        .reg_i(rdata_reg),
        .reg_o()
    );

    always @ (*) begin
        mport_o[`BUS_MO_DATA] = wdata_reg;
        mport_o[`BUS_MO_ADDR] = addr_reg;
    end


    always@ (posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            wcount_inc_reg <= 0;
            state <= STANDBY;
            mport_o[`BUS_MO_REQ] <= 0;
            mport_o[`BUS_MO_RW] <= 0;
            mport_o[`BUS_MO_SIZE]   <= 0;
            mport_o[`BUS_MO_SEQMST]   <= 0;
        end
	else begin
        case (state)
            STANDBY: begin  //wait until wishbone master wants to use bridge
                mport_o[`BUS_MO_REQ]  <= 0;

                if ((wbs_ackN[WDATA_INDEX]) && wbs_we_i)
                    state  <= PK_WRITE_PREP;
                else if (wbs_stb_i && !wbs_we_i && !wbs_ack_o && word_offset == RDATA_INDEX)
                    state <= PK_READ_PREP;
            end
            PK_WRITE_PREP: begin //data now on wishbone, pk stream write now occurs
                mport_o[`BUS_MO_REQ] <= 1;
                mport_o[`BUS_MO_RW] <= `BUS_WRITE;
                mport_o[`BUS_MO_SIZE]   <= `BUS_SIZE_STREAM;

                if(mport_i[`BUS_MI_ACK]) 
                    state <= PK_STREAM_WRITE;     
                else
                    state <= PK_WRITE_PREP;
            end
            PK_STREAM_WRITE: begin
                if (mport_i[`BUS_MI_SEQSLV]) begin
                    if(wcount_inc_reg < wcount_reg)
                        wcount_inc_reg <= wcount_inc_reg + 1;
                end
                if(wcount_inc_reg == wcount_reg - 1) begin
                    mport_o[`BUS_MO_SEQMST] <= 1;
                    state <= PK_CLEANUP;
                end
            end
            PK_CLEANUP: begin
                mport_o[`BUS_MO_REQ] <= 0;

                if(!mport_i[`BUS_MI_ACK]) begin
                    mport_o[`BUS_MO_SEQMST] <= 0;
                    wcount_inc_reg <= 0;
                    state <= STANDBY;
                end
            end
            PK_READ_PREP: begin
                    mport_o[`BUS_MO_REQ] <= 1;
                    mport_o[`BUS_MO_RW] <= `BUS_READ;
                    mport_o[`BUS_MO_SIZE]   <= `BUS_SIZE_WORD;

                    if(mport_i[`BUS_MI_ACK])
                        state <= PK_WORD_READ;
                    else
                        state <= PK_READ_PREP;
            end
            PK_WORD_READ: begin
                rdata_reg <= mport_i[`BUS_MI_DATA];

                if(!mport_i[`BUS_MI_ACK])
                    state <= PK_CLEANUP;
            end
        endcase
    end
end
endmodule
