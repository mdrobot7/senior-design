`include "svunit_defines.svh"
`include "user_defines.v"
`include "test/spi_chip.v"
`include "test/stream_slave.v"
`include "test/stream_master.v"

`include "bus/busarb.v"
`include "spi_mem.v"

`include "bus/address_coalescer.v"

module address_coalescer_m_unit_test;
  import svunit_pkg::svunit_testcase;

  string name = "address_coalescer_m_ut";
  svunit_testcase svunit_ut;


  //===================================
  // This is the UUT that we're 
  // running the Unit Tests on
  //===================================

  reg[`BUS_SIPORT_SIZE*`NUM_CORES-1:0]  core_port_i;
  wire[`BUS_SOPORT_SIZE*`NUM_CORES-1:0] core_port_o;
  reg[`BUS_MIPORT_SIZE*`NUM_CORES-1:0]  arb_port_i;
  wire[`BUS_MOPORT_SIZE*`NUM_CORES-1:0] arb_port_o;

  address_coalescer_m my_address_coalescer_m(
    .core_port_i(core_port_i),
    .core_port_o(core_port_o),
    .arb_port_i(arb_port_i),
    .arb_port_o(arb_port_o)
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
    core_port_i = 0;
    arb_port_i = 0;
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

  `SVTEST(test1)

  `SVTEST_END


  `SVUNIT_TESTS_END

endmodule
