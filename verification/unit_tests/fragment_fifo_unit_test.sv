`include "svunit_defines.svh"
`include "user_defines.v"
`include "test/clk_rst.v"
`include "stream/stream_fifo.v"
`include "fragment_fifo.v"


module fragment_fifo_m_unit_test;
  import svunit_pkg::svunit_testcase;

  string name = "fragment_fifo_m_ut";
  svunit_testcase svunit_ut;

  // Test configuration
  localparam int SIZE  = 1;
  localparam int DEPTH = 10;
  localparam int MI_Size = `STREAM_MIPORT_SIZE(SIZE);
  localparam int MO_Size = `STREAM_MOPORT_SIZE(SIZE);

  wire clk, nrst;
  clk_rst_m clk_rst(.clk_o(clk), .nrst_o(nrst));

  reg  [`STREAM_SIPORT(SIZE)] sstream_i;
  wire [`STREAM_SOPORT(SIZE)] sstream_o;

  // Packed master streams for NUM_CORES cores
  reg  [MI_Size*`NUM_CORES-1:0] mstream_i;
  wire [MO_Size*`NUM_CORES-1:0] mstream_o;

  wire empty;
  wire full;
  wire done_mailing;

  //===================================
  // This is the UUT that we're 
  // running the Unit Tests on
  //===================================
  fragment_fifo_m #(.SIZE(SIZE), .DEPTH(DEPTH)) my_fragment_fifo_m(
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
  `SVUNIT_TESTS_BEGIN

    `SVTEST(single_fragment_core0)
      sstream_i = '0;
      mstream_i = '0;


      //  data from rasterizer
      sstream_i[`STREAM_SI_DATA(SIZE)]  = 'h1;
      sstream_i[`STREAM_SI_VALID(SIZE)] = 1'b1;
      sstream_i[`STREAM_SI_LAST(SIZE)]  = 1'b0;

      mstream_i = '0;
      mstream_i[`STREAM_MI_READY(SIZE)] = 1'b1;

      clk_rst.WAIT_CYCLES(1);

      // core 0 should have VALID and data
      `FAIL_UNLESS(mstream_o[0*MO_Size + `STREAM_MO_VALID(SIZE)] == 1'b1);
      `FAIL_UNLESS_EQUAL(1, mstream_o[0*MO_Size + `STREAM_MO_DATA(SIZE)]);
    `SVTEST_END

  `SVUNIT_TESTS_END

endmodule
