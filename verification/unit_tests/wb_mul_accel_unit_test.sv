`include "svunit_defines.svh"

`include "user_defines.v"

`include "test/clk_rst.v"
`include "test/wishbone_master.v"

`include "math/mul.v"

`include "wb_mul_accel.v"
`include "wishbone_register.v"
`include "wishbone_helper.v"

module wb_mul_accel_m_unit_test;
    import svunit_pkg::svunit_testcase;

    string name = "wb_mul_accel_m_ut";
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

    wb_mul_accel_m dut(
        .wb_clk_i(wb_clk),
        .wb_rst_i(wb_rst),
        .wbs_stb_i(wbs_stb),
        .wbs_cyc_i(wbs_cyc),
        .wbs_we_i(wbs_we),
        .wbs_sel_i(wbs_sel),
        .wbs_dat_i(wbs_dati),
        .wbs_adr_i(wbs_adr),
        .wbs_ack_o(wbs_ack),
        .wbs_dat_o(wbs_dato)
    );

    reg [`WORD] ma, mb;
    wire [`WORD] my;
    mul_m #(`WORD_WIDTH) mul(.a_i(ma), .b_i(mb), .y_o(my));

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

        `SVTEST(main)
            integer i;

            reg [`WORD] a, b, y;

            for (i = 0; i < 100000; i = i + 1) begin
                a = {$random} % 65536;
                b = {$random} % 65536;

                ma = a;
                mb = b;

                wbmaster.WRITE(0, a);
                wbmaster.WRITE(4, b);
                wbmaster.READ(8, y);

                `FAIL_UNLESS(my == y);
            end
        `SVTEST_END

    `SVUNIT_TESTS_END

endmodule
