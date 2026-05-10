`include "svunit_defines.svh"

`include "user_defines.v"

`include "test/clk_rst.v"
`include "test/stream_master.v"
`include "test/stream_slave.v"

`include "stream/stream_fifo.v"

`include "vertex_reorder_controller.v"

module buffered_master_m #(
    parameter WIDTH = 1,
    parameter DEPTH = 10
)(
    input wire clk_i,
    input wire nrst_i,

    input  wire [`STREAM_MIPORT(WIDTH)] mstream_i,
    output wire [`STREAM_MOPORT(WIDTH)] mstream_o
);

    wire [`STREAM_MIPORT(WIDTH)] sia, sib;
    wire [`STREAM_MOPORT(WIDTH)] soa, sob;

    stream_master_m #(WIDTH) master(
        .clk_i(clk_i),

        .mstream_i(sia),
        .mstream_o(soa)
    );

    stream_fifo_m #(WIDTH, DEPTH) fifo(
        .clk_i(clk_i),
        .nrst_i(nrst_i),

        .sstream_i(soa),
        .sstream_o(sia),
        
        .mstream_i(sib),
        .mstream_o(sob)
    );

    assign mstream_o = sob;
    assign sib = mstream_i;

endmodule

module vertex_reorder_controller_m_unit_test;
    import svunit_pkg::svunit_testcase;

    string name = "vertex_reorder_controller_m_ut";
    svunit_testcase svunit_ut;

    wire clk, nrst;

    clk_rst_m clk_rst(
        .clk_o(clk),
        .nrst_o(nrst)
    );

    //===================================
    // This is the UUT that we're 
    // running the Unit Tests on
    //===================================
    
    wire [`STREAM_MIPORT(2)] ord_msi;
    wire [`STREAM_MOPORT(2)] ord_mso;

    wire [`STREAM_MIPORT(`SHADED_VERTEX_WIDTH)] c0_msi;
    wire [`STREAM_MOPORT(`SHADED_VERTEX_WIDTH)] c0_mso;
    wire [`STREAM_MIPORT(`SHADED_VERTEX_WIDTH)] c1_msi;
    wire [`STREAM_MOPORT(`SHADED_VERTEX_WIDTH)] c1_mso;
    wire [`STREAM_MIPORT(`SHADED_VERTEX_WIDTH)] c2_msi;
    wire [`STREAM_MOPORT(`SHADED_VERTEX_WIDTH)] c2_mso;

    wire [`STREAM_MIPORT(`SHADED_VERTEX_WIDTH)] cch_msi;
    wire [`STREAM_MOPORT(`SHADED_VERTEX_WIDTH)] cch_mso;

    wire [`STREAM_MIPORT(3 * `SHADED_VERTEX_WIDTH)] out_msi;
    wire [`STREAM_MOPORT(3 * `SHADED_VERTEX_WIDTH)] out_mso;
    wire [`STREAM_MIPORT(3 * `SHADED_VERTEX_WIDTH)] fifo_msi;
    wire [`STREAM_MOPORT(3 * `SHADED_VERTEX_WIDTH)] fifo_mso;

    buffered_master_m #($clog2(4)) order(
        .clk_i(clk),
        .nrst_i(nrst),

        .mstream_i(ord_msi),
        .mstream_o(ord_mso)
    );

    buffered_master_m #(`SHADED_VERTEX_WIDTH) c0(
        .clk_i(clk),
        .nrst_i(nrst),

        .mstream_i(c0_msi),
        .mstream_o(c0_mso)
    );

    buffered_master_m #(`SHADED_VERTEX_WIDTH) c1(
        .clk_i(clk),
        .nrst_i(nrst),

        .mstream_i(c1_msi),
        .mstream_o(c1_mso)
    );

    buffered_master_m #(`SHADED_VERTEX_WIDTH) c2(
        .clk_i(clk),
        .nrst_i(nrst),

        .mstream_i(c2_msi),
        .mstream_o(c2_mso)
    );

    buffered_master_m #(`SHADED_VERTEX_WIDTH) cache(
        .clk_i(clk),
        .nrst_i(nrst),

        .mstream_i(cch_msi),
        .mstream_o(cch_mso)
    );

    vertex_reorder_controller_m #(4) dut(
        .clk_i(clk),
        .nrst_i(nrst),

        .order_sstream_i(ord_mso),
        .order_sstream_o(ord_msi),

        .sstreams_i({ cch_mso, c2_mso, c1_mso, c0_mso }),
        .sstreams_o({ cch_msi, c2_msi, c1_msi, c0_msi }),

        .mstream_i(out_msi),
        .mstream_o(out_mso)
    );

    stream_fifo_m #(3 * `SHADED_VERTEX_WIDTH, 200) out_fifo(
        .clk_i(clk),
        .nrst_i(nrst),

        .sstream_i(out_mso),
        .sstream_o(out_msi),

        .mstream_i(fifo_msi),
        .mstream_o(fifo_mso)
    );

    stream_slave_m #(3 * `SHADED_VERTEX_WIDTH, 200) slave(
        .clk_i(clk),

        .sstream_i(fifo_mso),
        .sstream_o(fifo_msi)
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

            reg [1:0] sources [98:0];
            reg [`SHADED_VERTEX] temp0;
            reg [`SHADED_VERTEX] temp1;
            reg [`SHADED_VERTEX] temp2;

            for (i = 0; i < 99; i = i + 1) begin
                $display("Sending %d", i);

                PUSH_DATA(i, {$random});
            end

            for (i = 0; i < 99; i = i + 3) begin
                slave.READ({ temp0, temp1, temp2 });

                $display("Recieved %d, %d, %d", temp0, temp1, temp2);

                `FAIL_UNLESS_EQUAL(temp0, i + 0);
                `FAIL_UNLESS_EQUAL(temp1, i + 1);
                `FAIL_UNLESS_EQUAL(temp2, i + 2);
            end

        `SVTEST_END
    `SVUNIT_TESTS_END

    task PUSH_DATA;
        input [`SHADED_VERTEX] vertex;
        input [1:0] source;
    begin
        case (source)
            0: c0.master.WRITE(vertex);
            1: c1.master.WRITE(vertex);
            2: c2.master.WRITE(vertex);
            3: cache.master.WRITE(vertex);
        endcase

        order.master.WRITE(source);
    end
    endtask

endmodule
