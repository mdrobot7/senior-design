`include "svunit_defines.svh"
`include "user_defines.v"

`include "test/clk_rst.v"
`include "test/spi_chip.v"

module bus_unit_test;
  import svunit_pkg::svunit_testcase;

  string name = "metadata_cache_ut";
  svunit_testcase svunit_ut;

  wire clk, nrst;
  clk_rst_m clk_rst(.clk_o(clk), .nrst_o(nrst));

  reg core_req;
  reg data_from_core;
  reg core_addr;
  reg core_rw;
  wire data_to_core;
  wire core_ack;

  wire sram_addr;
  wire data_to_sram;
  wire sram_rw;
  wire sram_en;
  reg data_from_sram;

  wire mem_req;
  wire mem_rw;
  wire mem_size;
  wire mem_seqmst;
  wire mem_addr;
  wire data_to_mem;
  reg data_from_mem;
  reg mem_ack;
  reg mem_seqslv;



  //===================================
  // This is the UUT that we're
  // running the Unit Tests on
  //===================================
  metadata_cache DUT
  (
    .clk_i(clk),
    .nrst_i(nrst),

    .core_req_i(core_req),
    .data_i(data_from_core),
    .addr_i(core_addr),
    .rw_i(core_rw),
    .core_data_out(data_to_core),
    .core_ack_o(core_ack),

    .sram_addr(sram_addr),
    .sram_data_o(data_to_sram),
    .sram_rw(sram_rw),
    .sram_en(sram_en),
    .sram_data_i(data_from_sram),

    .mem_req_o(mem_req),
    .mem_rw(mem_rw),
    .mem_size_o(mem_size),
    .mem_seqmst_o(mem_seqmst),
    .mem_addr(mem_addr),
    .mem_data_o(data_to_mem),
    .mem_data_i(data_from_mem),
    .mem_ack_i(mem_ack),
    .mem_seqslv_i(mem_seqslv)
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

    mem_size = `BUS_SIZE_STREAM;
    


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
