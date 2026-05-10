`include "svunit_defines.svh"

`include "user_defines.v"
`include "test/debug_log.v"

`include "test/clk_rst.v"

`include "bus/dummy_slave.v"
`include "bus/busarb.v"

`include "test/bus_master.v"

module dummy_slave_m_unit_test;
  import svunit_pkg::svunit_testcase;

  string name = "dummy_slave_m_ut";
  svunit_testcase svunit_ut;

  wire clk, nrst;
  clk_rst_m clk_rst(.clk_o(clk), .nrst_o(nrst));

  wire [`BUS_MIPORT] mporti;
  wire [`BUS_MOPORT] mporto;

  wire [`BUS_SIPORT] sporti;
  wire [`BUS_SOPORT] sporto;

  busarb_m #(1, 1, 1) busarb(
    .clk_i(clk),
    .nrst_i(nrst),

    .mports_i(mporto),
    .mports_o(mporti),

    .sports_i(sporto),
    .sports_o(sporti)
  );

  bus_master_m master(
    .clk_i(clk),
    .nrst_i(nrst),

    .mport_i(mporti),
    .mport_o(mporto)
  );

  dummy_slave_m #(0, 32'hFFFFFFFF) my_dummy_slave_m(
    .clk_i(clk),
    .nrst_i(nrst),

    .sport_i(sporti),
    .sport_o(sporto)
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

    `SVTEST(byte_write)
      for (int i = 0; i < 1000; i++) begin
        master.WRITE_BYTE($random, $random);
      end
    `SVTEST_END

    `SVTEST(word_write)
      for (int i = 0; i < 1000; i++) begin
        master.WRITE_WORD($random, $random);
      end
    `SVTEST_END

    `SVTEST(stream_write)
      for (int i = 0; i < 1000; i++) begin
        master.WRITE_STREAM($random, 1000, $random);
      end
    `SVTEST_END

    `SVTEST(byte_read)
      for (int i = 0; i < 1000; i++) begin
        reg [7:0] data;
        master.READ_BYTE($random, data);
      end
    `SVTEST_END

    `SVTEST(word_read)
      for (int i = 0; i < 1000; i++) begin
        reg [31:0] data;
        master.READ_WORD($random, data);
      end
    `SVTEST_END

    `SVTEST(stream_read)
      for (int i = 0; i < 1000; i++) begin
        master.READ_STREAM($random, 1000);
      end
    `SVTEST_END

  `SVUNIT_TESTS_END

endmodule
