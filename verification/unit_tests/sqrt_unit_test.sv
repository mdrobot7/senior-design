`include "svunit_defines.svh"

`include "user_defines.v"

`include "math/sqrt.v"

`include "test/clk_rst.v"
`include "test/stream_master.v"
`include "test/stream_slave.v"

module sqrt_m_unit_test;
    import svunit_pkg::svunit_testcase;

    string name = "sqrt_m_ut";
    svunit_testcase svunit_ut;

    wire clk, nrst;
    clk_rst_m clk_rst(
        .clk_o(clk),
        .nrst_o(nrst)
    );

    wire [`STREAM_SIPORT(32)] sstreami;
    wire [`STREAM_SOPORT(32)] sstreamo;

    wire [`STREAM_MIPORT(16)] mstreami;
    wire [`STREAM_MOPORT(16)] mstreamo;

    stream_master_m #(32) master(
        .clk_i(clk),

        .mstream_i(sstreamo),
        .mstream_o(sstreami)
    );

    stream_slave_m #(16, 1) slave(
        .clk_i(clk),

        .sstream_i(mstreamo),
        .sstream_o(mstreami)
    );

    //===================================
    // This is the UUT that we're 
    // running the Unit Tests on
    //===================================
    sqrt_m my_sqrt_m(
        .clk_i(clk),
        .nrst_i(nrst),

        .sstream_i(sstreami),
        .sstream_o(sstreamo),

        .mstream_i(mstreami),
        .mstream_o(mstreamo)
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

        `SVTEST(backwards)
            reg [15:0] root;
            reg [31:0] square;
            reg [15:0] out;
            integer diff;

            for (int i = 0; i < 1000; i++) begin
                root = {$random} % 65537;
                square = root * root;

                master.WRITE(square);

                out = 0;
                slave.READ(out);

                diff = out - root;
                if (diff < 0) diff = -diff;

                $display("%d == %d   -   diff: %d", out, root, diff);
                `FAIL_UNLESS(diff <= 1);
            end
        `SVTEST_END

    `SVUNIT_TESTS_END

endmodule
