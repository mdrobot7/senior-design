`include "svunit_defines.svh"

`include "user_defines.v"

`include "test/clk_rst.v"
`include "test/stream_master.v"
`include "test/stream_slave.v"

`include "math/div_pipe.v"

module div_pipe_m_unit_test;
  import svunit_pkg::svunit_testcase;

  string name = "div_pipe_m_ut";
  svunit_testcase svunit_ut;

  wire clk, nrst;
  clk_rst_m clk_rst(.clk_o(clk), .nrst_o(nrst));

  reg  [`STREAM_SIPORT(32 * 2)] sstreamai;
  wire [`STREAM_SOPORT(32 * 2)] sstreamao;

  reg  [`STREAM_MIPORT(32)] mstreamai;
  wire [`STREAM_MOPORT(32)] mstreamao;

  //===================================
  // This is the UUT that we're 
  // running the Unit Tests on
  //===================================
  div_pipe_m #(
    32,
    32'b0000_0000_0000_0100_0000_0000_1000_0001
  ) dut(
    .clk_i(clk),
    .nrst_i(nrst),

    .sstream_i(sstreamai),
    .sstream_o(sstreamao),

    .mstream_i(mstreamai),
    .mstream_o(mstreamao)
  );

  stream_master_m #(32 * 2) pipe0_master(
    .clk_i(clk),

    .mstream_i(sstreamao),
    .mstream_o(sstreamai)
  );

  stream_slave_m #(32, 1000) pipe0_slave(
    .clk_i(clk),

    .sstream_i(mstreamao),
    .sstream_o(mstreamai)
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

      for (i = 0; i < 1000; i = i + 1) begin
        a = $random;
        b = $random;

        TEST_DIV(a, b, div);

        // $display("%d / %d == %d == %d", a, b, div, a / b);
        `FAIL_UNLESS_EQUAL(div, (a / b));
      end
    `SVTEST_END

    `SVTEST(backpressure)
      localparam BACKPRESSURE_AMOUNT = 3;

      integer i, j;

      reg signed [31:0] a [BACKPRESSURE_AMOUNT - 1:0];
      reg signed [31:0] b [BACKPRESSURE_AMOUNT - 1:0];
      reg signed [31:0] div [BACKPRESSURE_AMOUNT - 1:0];

      for (i = 0; i < 1000; i = i + 1) begin
        for (j = 0; j < BACKPRESSURE_AMOUNT; j = j + 1) begin
          a[j] = $random;
          b[j] = $random;

          pipe0_master.WRITE({ a[j], b[j] });
        end

        for (j = 0; j < BACKPRESSURE_AMOUNT; j = j + 1) begin
          pipe0_slave.READ(div[j]);
        end

        for (j = 0; j < BACKPRESSURE_AMOUNT; j = j + 1) begin
          // $display("%d / %d == %d == %d", a[j], b[j], div[j], a[j] / b[j]);
          `FAIL_UNLESS_EQUAL(div[j], (a[j] / b[j]));
        end
      end
    `SVTEST_END
  `SVUNIT_TESTS_END

  task TEST_DIV;
    input [31:0] a, b;
    output [31:0] y;
  begin
      pipe0_master.WRITE({ a, b });
      pipe0_slave.READ(y);
  end
  endtask

endmodule
