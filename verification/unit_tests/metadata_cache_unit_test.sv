`include "svunit_defines.svh"
`include "user_defines.v"

`include "test/clk_rst.v"

module bus_unit_test;
  import svunit_pkg::svunit_testcase;

  string name = "metadata_cache_ut";
  svunit_testcase svunit_ut;

  wire clk, nrst;
  clk_rst_m clk_rst(.clk_o(clk), .nrst_o(nrst));


  //===================================
  // This is the UUT that we're
  // running the Unit Tests on
  //===================================
  metadata_cache DUT
  (
    .clk_i(clk),
    .nrst_i(nrst),

    .core_req_i(),
    .data_i(),
    .addr_i(),
    .rw_i(),
    .core_data_out(),
    .core_ack_o(),

    .sram_addr(),
    .sram_data_o(),
    .sram_rw(),
    .sram_en(),
    .sram_data_i(),

    .mem_req_o(),
    .mem_rw(),
    .mem_size_o(),
    .mem_seqmst_o(),
    .mem_addr(),
    .mem_data_o(),
    .mem_data_i(),
    .mem_ack_i(),
    .mem_seqslv_i()
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



endmodule
