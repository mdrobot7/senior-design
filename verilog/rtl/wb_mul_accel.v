module wb_mul_accel_m(
    input wire wb_clk_i,
    input wire wb_rst_i,
    input wire wbs_stb_i,
    input wire wbs_cyc_i,
    input wire wbs_we_i,
    input wire [3:0] wbs_sel_i,
    input wire [`WORD_WIDTH-1:0] wbs_dat_i,
    input wire [`WORD_WIDTH-1:0] wbs_adr_i,
    output reg wbs_ack_o,
    output reg [`WORD_WIDTH-1:0] wbs_dat_o
);

    localparam NUM_REGS = 3;

    reg [NUM_REGS-1:0] wbs_stbN;
    wire [NUM_REGS-1:0] wbs_ackN;
    wire [`WORD_WIDTH-1:0] wbs_datN [NUM_REGS-1:0];

    wire [`WORD] a, b;
    wire [`WORD] y;
    mul_m #(`WORD_WIDTH) mul(.a_i(a), .b_i(b), .y_o(y));

    wishbone_register_m #(32'h00000000, 1, `WBREG_TYPE_REG) val_a_reg (
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
        .periph_read_mask_i(32'h00000000),

        .enable_prot_i(32'h00000000),
        .enable_i(1'b0),

        .reg_i(32'd0),
        .reg_o(a)
    );

    wishbone_register_m #(32'h00000000, 1, `WBREG_TYPE_REG) val_b_reg (
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
        .periph_read_mask_i(32'h00000000),

        .enable_prot_i(32'h00000000),
        .enable_i(1'b0),

        .reg_i(32'd0),
        .reg_o(b)
    );

    wishbone_register_m #(32'h00000000, 1, `WBREG_TYPE_REG) val_y_reg (
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
        .access_write_mask_i(32'h00000000),
        .periph_read_mask_i(32'hFFFFFFFF),

        .enable_prot_i(32'h00000000),
        .enable_i(1'b0),

        .reg_i(y),
        .reg_o()
    );

    wire [$clog2(NUM_REGS)-1:0] word_offset = {2'b00, wbs_adr_i[31:2]};
    always @ (*) begin
        wbs_stbN = wbs_stb_i << word_offset; // Only one at a time
        if (word_offset < NUM_REGS) begin
            wbs_ack_o = wbs_ackN[word_offset];
            wbs_dat_o = wbs_datN[word_offset];
        end
    end

endmodule

