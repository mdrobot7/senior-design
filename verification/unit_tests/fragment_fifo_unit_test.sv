`include "svunit_defines.svh"
`include "user_defines.v"
`include "test/clk_rst.v"
`include "stream/stream_fifo.v"
`include "fragment_fifo.v"

// `define NUM_CORES (1) // Does not work :(

module fragment_fifo_m_unit_test;
  import svunit_pkg::svunit_testcase;

  string name = "fragment_fifo_m_ut";
  svunit_testcase svunit_ut;

  // Test configuration
  localparam int SIZE  = `MAILBOX_STREAM_SIZE;
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
    sstream_i = '0;
    mstream_i = '0;

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

  `SVTEST(mc_flags)
    integer n;
    `FAIL_UNLESS(empty == 1'b1)
    `FAIL_UNLESS(full == 1'b0)

      // Load FIFO with data
      for (n = 0; n < DEPTH; n = n + 1) begin
        sstream_i[`STREAM_SI_DATA(SIZE)]  = 32'hBEEFDEED;    
        sstream_i[`STREAM_SI_VALID(SIZE)] = 1'b1;
        sstream_i[`STREAM_SI_LAST(SIZE)]  = 1'b1;
        clk_rst.WAIT_CYCLES(1);
        `FAIL_UNLESS(empty == 1'b0)
        if(n!=DEPTH-1) begin
        `FAIL_UNLESS(full == 1'b0)
        end
      end
      `FAIL_UNLESS(full == 1'b1)
    `SVTEST_END

  `SVTEST(round_robin_all_cores)
      integer n, i, j;
      reg [`NUM_CORES-1:0] seen_valid;

      // Load FIFO with data
      for (n = 0; n < DEPTH; n = n + 1) begin
        if(n%2 == 0)
          sstream_i[`STREAM_SI_DATA(SIZE)]  = 32'hDEADBEEF;    
        else
        sstream_i[`STREAM_SI_DATA(SIZE)]  = 32'hFEEDFEED;    
        sstream_i[`STREAM_SI_VALID(SIZE)] = 1'b1;
        sstream_i[`STREAM_SI_LAST(SIZE)]  = 1'b1;
        clk_rst.WAIT_CYCLES(1);
      end

      sstream_i[`STREAM_SI_VALID(SIZE)] = 1'b0;
      sstream_i[`STREAM_SI_LAST(SIZE)]  = 1'b0;
      clk_rst.WAIT_CYCLES(1);

      for (i = 0; i < `NUM_CORES; i = i + 1) begin 
        mstream_i[MI_Size*i + `STREAM_MI_READY(SIZE)] = 1'b1;

        while(1) begin
        if (mstream_o[MO_Size*i + `STREAM_MO_VALID(SIZE)]) begin
            seen_valid[i] = 1'b1;
            break;
        end
        else begin
          clk_rst.WAIT_CYCLES(1);
        end
        end
        clk_rst.WAIT_CYCLES(1);
        mstream_i[MI_Size*i + `STREAM_MI_READY(SIZE)] = 1'b0; 
      end
      clk_rst.WAIT_CYCLES(1);
      for (i = 0; i < `NUM_CORES; i = i + 1) begin 
        `FAIL_UNLESS(seen_valid[i] == 1'b1);
      end

    `SVTEST_END



  `SVUNIT_TESTS_END

endmodule
