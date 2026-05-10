`include "svunit_defines.svh"

`include "user_defines.v"

`include "math/add.v"
`include "math/mul.v"

`include "rasterizer/wavg_pipe.v"

`include "test/stream_master.v"
`include "test/stream_slave.v"
`include "test/clk_rst.v"
`include "test/fixed_point.v"

module wavg_pipe_m_unit_test;
  import svunit_pkg::svunit_testcase;

  string name = "wavg_pipe_m_ut";
  svunit_testcase svunit_ut;

  localparam WORD_WIDTH = 32;
  localparam WIDTH = 320;
  localparam HEIGHT = 240;
  localparam SC_WIDTH = $clog2(WIDTH > HEIGHT ? WIDTH : HEIGHT);

  wire clk;
  wire nrst;

  clk_rst_m clk_rst( .clk_o(clk), .nrst_o(nrst) );

  wire [`STREAM_MIPORT(SC_WIDTH * 2 + WORD_WIDTH * 3)] mstreami;
  wire [`STREAM_MOPORT(SC_WIDTH * 2 + WORD_WIDTH * 3)] mstreamo;

  wire [`STREAM_SIPORT(SC_WIDTH * 2 + WORD_WIDTH * 3)] sstreami;
  wire [`STREAM_SOPORT(SC_WIDTH * 2 + WORD_WIDTH * 3)] sstreamo;

  reg signed [WORD_WIDTH - 1:0] t0x, t1x, t2x;
  reg signed [WORD_WIDTH - 1:0] t0y, t1y, t2y;

  reg signed [WORD_WIDTH - 1:0] v0z, v1z, v2z;

  stream_master_m #(SC_WIDTH * 2 + WORD_WIDTH * 3) stream_master(
    .clk_i(clk),

    .mstream_i(mstreami),
    .mstream_o(mstreamo)
  );

  stream_slave_m #(SC_WIDTH * 2 + WORD_WIDTH * 3) stream_slave(
    .clk_i(clk),

    .sstream_i(sstreami),
    .sstream_o(sstreamo)
  );

  //===================================
  // This is the UUT that we're 
  // running the Unit Tests on
  //===================================
  wavg_pipe_m #(WORD_WIDTH, SC_WIDTH) my_wavg_pipe_m(
    .clk_i(clk),
    .nrst_i(nrst),

    .sstream_i(mstreamo),
    .sstream_o(mstreami),

    .mstream_i(sstreamo),
    .mstream_o(sstreami),

    .t0x(t0x),
    .t1x(t1x),
    .t2x(t2x),

    .t0y(t0y),
    .t1y(t1y),
    .t2y(t2y),

    .v0z(v0z),
    .v1z(v1z),
    .v2z(v2z)
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

    wait(nrst);
    #100;

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

      reg signed [SC_WIDTH - 1:0] posx, posy;
      reg signed [WORD_WIDTH - 1:0] l0, l1, l2;
      reg signed [WORD_WIDTH - 1:0] correct_depth, depth;
      reg signed [WORD_WIDTH - 1:0] correct_tx, tx;
      reg signed [WORD_WIDTH - 1:0] correct_ty, ty;

      for (i = 0; i < 10000; i = i + 1) begin

        posx = {$random} % WIDTH;
        posy = {$random} % HEIGHT;

        l0 = $random % (1 << (`DECIMAL_POS));
        l1 = $random % (1 << (`DECIMAL_POS));
        l2 = `FP(1) - l0 - l1;

        t0x = $random;
        t1x = $random;
        t2x = $random;

        t0y = $random;
        t1y = $random;
        t2y = $random;

        v0z = $random;
        v1z = $random;
        v2z = $random;

        SEND_DATA(posx, posy, l0, l1, l2);

        RECEIVE_DATA(depth, tx, ty);

        $display("%d * %d", v0z >>> `DECIMAL_POS, l0 >>> `DECIMAL_POS);
        $display("%d * %d", v1z >>> `DECIMAL_POS, l1 >>> `DECIMAL_POS);
        $display("%d * %d", v2z >>> `DECIMAL_POS, l2 >>> `DECIMAL_POS);

        $display("%d", $signed(`FP_MUL(v0z, l0) / (1 << `DECIMAL_POS)));
        $display("%d", $signed(`FP_MUL(v1z, l1) / (1 << `DECIMAL_POS)));
        $display("%d", $signed(`FP_MUL(v2z, l2) / (1 << `DECIMAL_POS)));

        correct_depth =
          $signed(`FP_MUL(v0z, l0)) +
          $signed(`FP_MUL(v1z, l1)) +
          $signed(`FP_MUL(v2z, l2));

        $display("%d == %d", depth >>> `DECIMAL_POS, correct_depth >>> `DECIMAL_POS);
        `FAIL_UNLESS_EQUAL(depth, correct_depth);

      end
      
    `SVTEST_END

  `SVUNIT_TESTS_END

  task SEND_DATA;
    input [SC_WIDTH - 1:0] posx;
    input [SC_WIDTH - 1:0] posy;

    input [WORD_WIDTH - 1:0] l0;
    input [WORD_WIDTH - 1:0] l1;
    input [WORD_WIDTH - 1:0] l2;
  begin
    stream_master.WRITE({ posx, posy, l0, l1, l2 });
  end
  endtask

  task RECEIVE_DATA;
    output [WORD_WIDTH - 1:0] depth;
    output [WORD_WIDTH - 1:0] tx;
    output [WORD_WIDTH - 1:0] ty;

    reg [SC_WIDTH - 1:0] posx, posy;
  begin
    stream_slave.READ({ posx, posy, tx, ty, depth });
  end
  endtask

endmodule
