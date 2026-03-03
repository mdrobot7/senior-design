`include "svunit_defines.svh"
`include "fragment_fifo.v"

module fragment_fifo_m_unit_test;
  import svunit_pkg::svunit_testcase;

  string name = "fragment_fifo_m_ut";
  svunit_testcase svunit_ut;

  wire clk, nrst;
  clk_rst_m clk_rst(.clk_o(clk), .nrst_o(nrst));

  reg [`STREAM_SIPORT(SIZE)] sstream_i;
  reg [`STREAM_SOPORT(SIZE)] sstream_o;

  reg [`STREAM_MIPORT(SIZE) * `NUM_CORES] mstream_i;
  reg [`STREAM_MOPORT(SIZE) * `NUM_CORES] mstream_o;

  wire empty;
  wire full;
  wire done_mailing;

  parameter SIZE = 1;
  parameter DEPTH = 10;
  


  //===================================
  // This is the UUT that we're 
  // running the Unit Tests on
  //===================================
  fragment_fifo_m #(.SIZE(SIZE) .DEPTH(DEPTH)) my_fragment_fifo_m(
    .clk_i(clk),
    .nrst_i(nrst),
    .sstream_i(sstream_i),
    .sstream_o(sstream_o),
    .mstream_i(mstream_i),
    .mstream_o(mstream_o),
    .empty(empty),
    .full(full),
    .done_mailing(done_mailing)
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
    clk_rst.WAIT_CYCLES(1);
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
  integer i; 
  `SVUNIT_TESTS_BEGIN
    i = 0;
    sstream_i[`STREAM_SI_DATA(SIZE)] = 2'b1
    

    mstream_i[`STREAM_MIPORT_SIZE(SIZE)* i + STREAM_MI_READY(SIZE)] = 1;


  `SVUNIT_TESTS_END

endmodule
