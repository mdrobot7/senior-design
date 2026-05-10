`include "svunit_defines.svh"

`include "user_defines.v"

`include "test/clk_rst.v"
`include "test/stream_master.v"
`include "test/stream_slave.v"

`include "stream/stream_fifo.v"

`include "math/div_pipe.v"
`include "math/shared_div.v"

module div_pipe_m_unit_test;
    import svunit_pkg::svunit_testcase;

    string name = "div_pipe_m_ut";
    svunit_testcase svunit_ut;

    wire clk, nrst;
    clk_rst_m clk_rst(.clk_o(clk), .nrst_o(nrst));

    reg  [`STREAM_SIPORT(32 * 2)] sstreamai;
    wire [`STREAM_SOPORT(32 * 2)] sstreamao;

    reg  [`STREAM_SIPORT(32 * 2)] sstreambi;
    wire [`STREAM_SOPORT(32 * 2)] sstreambo;

    reg  [`STREAM_MIPORT(32)] mstreamai;
    wire [`STREAM_MOPORT(32)] mstreamao;

    reg  [`STREAM_MIPORT(32)] mstreambi;
    wire [`STREAM_MOPORT(32)] mstreambo;

    //===================================
    // This is the UUT that we're 
    // running the Unit Tests on
    //===================================
    shared_div_m #(
        32,
        32'hFFFFFFFF,
        2
    ) dut(
        .clk_i(clk),
        .nrst_i(nrst),

        .sstreams_i({ sstreambi, sstreamai }),
        .sstreams_o({ sstreambo, sstreamao }),

        .mstreams_i({ mstreambi, mstreamai }),
        .mstreams_o({ mstreambo, mstreamao })
    );

    stream_master_m #(32 * 2) pipe0_master(
        .clk_i(clk),

        .mstream_i(sstreamao),
        .mstream_o(sstreamai)
    );

    stream_slave_m #(32, 1) pipe0_slave(
        .clk_i(clk),

        .sstream_i(mstreamao),
        .sstream_o(mstreamai)
    );

    stream_master_m #(32 * 2) pipe1_master(
        .clk_i(clk),

        .mstream_i(sstreambo),
        .mstream_o(sstreambi)
    );

    stream_slave_m #(32, 1) pipe1_slave(
        .clk_i(clk),

        .sstream_i(mstreambo),
        .sstream_o(mstreambi)
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
        `SVTEST(main)
        integer i;

        reg signed [31:0] a, b;
        reg signed [31:0] div;

        for (i = 0; i < 10000; i = i + 1) begin
            a = $random;
            b = $random;

            if ({$random} % 2 == 0) begin
                TEST_DIV0(a, b, div);
                $display("%d / %d == %d == %d", a, b, div, a / b);
                `FAIL_UNLESS_EQUAL(div, (a / b));
            end
            else begin
                TEST_DIV1(a, b, div);
                $display("%d / %d == %d == %d", a, b, div, a / b);
                `FAIL_UNLESS_EQUAL(div, (a / b));
            end
        end
        `SVTEST_END
    `SVUNIT_TESTS_END

    task TEST_DIV0;
        input [31:0] a, b;
        output [31:0] y;
    begin
        pipe0_master.WRITE({ a, b });
        pipe0_slave.READ(y);
    end
    endtask

    task TEST_DIV1;
        input [31:0] a, b;
        output [31:0] y;
    begin
        pipe1_master.WRITE({ a, b });
        pipe1_slave.READ(y);
    end
    endtask

endmodule
