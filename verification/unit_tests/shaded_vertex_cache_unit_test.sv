`include "svunit_defines.svh"
`include "user_defines.v"

`include "test/clk_rst.v"
`include "test/stream_slave.v"

`include "shaded_vertex_cache.v"

module shaded_vertex_cache_m_unit_test;
    import svunit_pkg::svunit_testcase;

    string name = "shaded_vertex_cache_m_ut";
    svunit_testcase svunit_ut;

    wire clk, nrst;
    clk_rst_m clk_rst(.clk_o(clk), .nrst_o(nrst));

    reg  [`WORD] test_index;
    reg  test_valid;
    wire test_found;

    reg [`SHADED_VERTEX] store_vertex;
    reg [`WORD] store_index;
    reg store_valid;

    wire [`STREAM_MIPORT(`SHADED_VERTEX_WIDTH)] mstreami;
    wire [`STREAM_MOPORT(`SHADED_VERTEX_WIDTH)] mstreamo;

    //===================================
    // This is the UUT that we're 
    // running the Unit Tests on
    //===================================
    shaded_vertex_cache_m dut(
        .nrst_i(nrst),
        .clk_i(clk),

        .test_index_i(test_index),
        .test_valid_i(test_valid),
        .test_found_o(test_found),

        .store_vertex_i(store_vertex),
        .store_index_i(store_index),
        .store_valid_i(store_valid),

        .mstream_i(mstreami),
        .mstream_o(mstreamo)
    );

    stream_slave_m #(`SHADED_VERTEX_WIDTH, 10) stream_slave(
        .clk_i(clk),

        .sstream_i(mstreamo),
        .sstream_o(mstreami)
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

        test_index = 0;
        test_valid = 0;

        store_vertex = 0;
        store_index = 0;
        store_valid = 0;

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
        `SVTEST(not_found)
            integer i;

            for (i = 0; i < 100; i++) begin
                reg found;
                reg [`SHADED_VERTEX] vertex;

                REQUEST_VERTEX(0, found, vertex);

                `FAIL_IF(found == 1);
            end
        `SVTEST_END

        `SVTEST(simple_found)
            integer i;

            for (i = 0; i < 100; i++) begin
                reg found;
                reg [`WORD] index;
                reg [`SHADED_VERTEX] vertex;
                reg [`SHADED_VERTEX] original_vertex;

                index = {$random};
                original_vertex = {$random};

                STORE_VERTEX(index, original_vertex);
                
                REQUEST_VERTEX(index, found, vertex);

                `FAIL_IF(found == 0);

                `FAIL_UNLESS_EQUAL(original_vertex, vertex);
            end
        `SVTEST_END
    `SVUNIT_TESTS_END

    task REQUEST_VERTEX;
        input [`WORD] index;

        output found;
        output [`SHADED_VERTEX] vertex;
    begin
        @(posedge clk);

        test_index = index;
        test_valid = 1;
        #1;

        if (test_found) begin
            found = 1;

            @(posedge clk);

            test_valid = 0;

            stream_slave.READ(vertex);
        end
        else begin
            found  = 0;
            vertex = 0;

            test_valid = 0;
        end
    end
    endtask

    task STORE_VERTEX;
        input [`WORD] index;
        input [`SHADED_VERTEX] vertex;
    begin
        @(posedge clk);

        store_index = index;
        store_vertex = vertex;
        store_valid = 1;

        @(posedge clk);

        store_valid = 0;
    end
    endtask

endmodule
