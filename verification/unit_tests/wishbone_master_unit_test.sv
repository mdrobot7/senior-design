`include "svunit_defines.svh"

`include "user_defines.v"

`include "wishbone_register.v"

`include "test/clk_rst.v"
`include "test/wishbone_master.v"

`include "wishbone_helper.v"

module wishbone_master_m_unit_test;
    import svunit_pkg::svunit_testcase;

    string name = "wishbone_master_m_ut";
    svunit_testcase svunit_ut;

    wire clk, nrst;
    clk_rst_m clk_rst(.clk_o(clk), .nrst_o(nrst));

    wire wb_clk;
    wire wb_rst;
    wire wbs_stb;
    wire wbs_cyc;
    wire wbs_we;
    wire [3:0] wbs_sel;
    wire [`WORD_WIDTH-1:0] wbs_dato;
    wire [`WORD_WIDTH-1:0] wbs_adr;
    wire wbs_ack;
    wire [`WORD_WIDTH-1:0] wbs_dati;

    //===================================
    // This is the UUT that we're 
    // running the Unit Tests on
    //===================================
    wishbone_master_m wbmaster(
        .clk_i(clk),
        .nrst_i(nrst),

        .wb_clk_o(wb_clk),
        .wb_rst_o(wb_rst),
        .wbs_stb_o(wbs_stb),
        .wbs_cyc_o(wbs_cyc),
        .wbs_we_o(wbs_we),
        .wbs_sel_o(wbs_sel),
        .wbs_dat_o(wbs_dati),
        .wbs_adr_o(wbs_adr),
        .wbs_ack_i(wbs_ack),
        .wbs_dat_i(wbs_dato)
    );

    reg  [31:0] reg_vali;
    wire [31:0] reg_valo;
    wishbone_register_m #(32'h00000000, 1, `WBREG_TYPE_REG) wbreg(
        .wb_clk_i(wb_clk),
        .wb_rst_i(wb_rst),
        .wbs_stb_i(wbs_stb),
        .wbs_cyc_i(wbs_cyc),
        .wbs_we_i(wbs_we),
        .wbs_sel_i(wbs_sel),
        .wbs_dat_i(wbs_dati),
        .wbs_adr_i(wbs_adr),
        .wbs_ack_o(wbs_ack),
        .wbs_dat_o(wbs_dato),

        .access_read_mask_i(32'hFFFFFFFF),
        .access_write_mask_i(32'hFFFFFFFF),
        .periph_read_mask_i(32'hFFFFFFFF),

        .enable_prot_i(32'h00000000),
        .enable_i(1'b0),

        .reg_i(reg_vali),
        .reg_o(reg_valo)
    );

    //===================================
    // Build
    //===================================
    function void build();
        svunit_ut = new(name);
    endfunction


    //===================================
    // Setup for running the Unit Tests
    //===================================
    task setup();
        svunit_ut.setup();
        /* Place Setup Code Here */

        clk_rst.RESET();
    endtask


    //===================================
    // Here we deconstruct anything we 
    // need after running the Unit Tests
    //===================================
    task teardown();
        svunit_ut.teardown();
        /* Place Teardown Code Here */

    endtask


    //===================================
    // All tests are defined between the
    // SVUNIT_TESTS_BEGIN/END macros
    //
    // Each individual test must be
    // defined between `SVTEST(_NAME_)
    // `SVTEST_END
    //
    // i.e.
    //   `SVTEST(mytest)
    //     <test code>
    //   `SVTEST_END
    //===================================
    `SVUNIT_TESTS_BEGIN

        `SVTEST(write)
            integer i;
            reg [`WORD] data;

            for (i = 0; i < 100; i = i + 1) begin
                data = $random;

                wbmaster.WRITE(0, data);

                `FAIL_UNLESS(data == reg_valo);
            end
        `SVTEST_END

        `SVTEST(read)
            integer i;
            reg [`WORD] data;

            for (i = 0; i < 100; i = i + 1) begin
                reg_vali = $random;

                wbmaster.READ(0, data);

                `FAIL_UNLESS(data == reg_vali);
            end
        `SVTEST_END

        `SVTEST(read_write)
            integer i;
            reg [`WORD] data;

            for (i = 0; i < 100; i = i + 1) begin
                data = $random;

                wbmaster.WRITE(0, data);

                reg_vali = reg_valo;

                wbmaster.READ(0, data);

                `FAIL_UNLESS(data == reg_vali);
            end
        `SVTEST_END

    `SVUNIT_TESTS_END

endmodule
