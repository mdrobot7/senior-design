`define CORE_SPY(core_num, corespy_wbs_stb_i, corespy_wbs_ack_o, corespy_wbs_dat_o) \
    reg  [`NUM_LOCAL_REGS-1:0] _wbs_stbN; \
    wire [`NUM_LOCAL_REGS-1:0] _wbs_ackN; \
    wire [`WORD] _wbs_datN [`NUM_LOCAL_REGS-1:0]; \
    reg  _wbs_ack; \
    reg  [`WORD] _wbs_dat; \
    assign corespy_wbs_ack_o = _wbs_ack; \
    assign corespy_wbs_dat_o = _wbs_dat; \
 \
    generate begin : CORESPY \
    genvar i; \
        for (i = 0; i < `NUM_LOCAL_REGS; i = i + 1) begin : CORESPY_GENLOOP \
            wishbone_register_m #(32'h00000000, 1, `WBREG_TYPE_REG) r ( \
                .wb_clk_i(wb_clk_i), \
                .wb_rst_i(wb_rst_i), \
                .wbs_stb_i(_wbs_stbN[i]), \
                .wbs_cyc_i(wbs_cyc_i), \
                .wbs_we_i(wbs_we_i), \
                .wbs_sel_i(wbs_sel_i), \
                .wbs_dat_i(wbs_dat_i), \
                .wbs_adr_i(wbs_adr_i), \
                .wbs_ack_o(_wbs_ackN[i]), \
                .wbs_dat_o(_wbs_datN[i]), \
                .access_read_mask_i(32'hFFFFFFFF), \
                .access_write_mask_i(32'h00000000), \
                .periph_read_mask_i(32'hFFFFFFFF), \
                .enable_prot_i(32'h00000000), \
                .enable_i(1'b0), \
                .reg_i(CORES.CORES_GENLOOP[core_num].core.regfile.mem[i]), \
                .reg_o() \
            ); \
        end \
    end endgenerate \
 \
    wire [$clog2(`NUM_LOCAL_REGS)-1:0] _word_offset = {2'b00, wbs_adr_i[31:2]}; \
    always @ (*) begin \
        _wbs_stbN = corespy_wbs_stb_i << _word_offset; \
        _wbs_ack = _wbs_ackN[_word_offset]; \
        _wbs_dat = _wbs_datN[_word_offset]; \
    end
