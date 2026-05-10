`include "svunit_defines.svh"

`include "user_defines.v"

`include "math/add.v"
`include "math/sub.v"
`include "math/mul.v"
`include "math/div.v"

`include "rasterizer/bary_pipe.v"

`include "test/clk_rst.v"
`include "test/stream_master.v"
`include "test/stream_slave.v"
`include "test/fixed_point.v"

module bary_pipe_m_unit_test;
  import svunit_pkg::svunit_testcase;

  string name = "bary_pipe_m_ut";
  svunit_testcase svunit_ut;

  localparam WORD_WIDTH = 32;
  localparam WORD_SMAX = 64'd1 << (WORD_WIDTH - 2);

  localparam WIDTH = 320;
  localparam HEIGHT = 240;
  localparam SC_WIDTH = $clog2(WIDTH > HEIGHT ? WIDTH : HEIGHT);

  wire clk;
  wire nrst;

  clk_rst_m clk_rst( .clk_o(clk), .nrst_o(nrst) );

  reg  bary_run;
  wire bary_init;
  wire bary_discard;
  wire bary_busy;

  wire [`STREAM_MIPORT(SC_WIDTH * 2)] mstreami;
  wire [`STREAM_MOPORT(SC_WIDTH * 2)] mstreamo;

  wire [`STREAM_SIPORT(SC_WIDTH * 2 + WORD_WIDTH * 3)] sstreami;
  wire [`STREAM_SOPORT(SC_WIDTH * 2 + WORD_WIDTH * 3)] sstreamo;

  reg signed [WORD_WIDTH - 1:0] v0x, v0y, v0z;
  reg signed [WORD_WIDTH - 1:0] v1x, v1y, v1z;
  reg signed [WORD_WIDTH - 1:0] v2x, v2y, v2z;

  stream_master_m #(SC_WIDTH * 2) stream_master(
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
  bary_pipe_m dut(
    .clk_i(clk),
    .nrst_i(nrst),

    .run_i(bary_run),
    .init_o(bary_init),
    .discard_o(bary_discard),
    .busy_o(bary_busy),

    .sstream_i(mstreamo),
    .sstream_o(mstreami),

    .mstream_i(sstreamo),
    .mstream_o(sstreami),

    .v0x(v0x),
    .v0y(v0y),
    .v0z(v0z),

    .v1x(v1x),
    .v1y(v1y),
    .v1z(v1z),

    .v2x(v2x),
    .v2y(v2y),
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

    bary_run = 0;

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

    `SVTEST(bary_setup)
      integer i;

      reg [SC_WIDTH - 1:0] posx, posy;

      reg signed [WORD_WIDTH - 1:0] l0, l1, l2;

      v0x = 10 << `DECIMAL_POS;
      v0y = 50 << `DECIMAL_POS;
      v0z = 1 * 64'h80000000 / 3;

      v1x = 50 << `DECIMAL_POS;
      v1y = 10 << `DECIMAL_POS;
      v1z = 1 * 64'h80000000 / 3;

      v2x = 140 << `DECIMAL_POS;
      v2y = 140 << `DECIMAL_POS;
      v2z = 3 * 64'h80000000 / 3;

      SETUP_PIPELINE();

      `FAIL_UNLESS_EQUAL(dut.y1my2, v1y - v2y);
      `FAIL_UNLESS_EQUAL(dut.x2mx1, v2x - v1x);
      `FAIL_UNLESS_EQUAL(dut.x0mx2, v0x - v2x);
      `FAIL_UNLESS_EQUAL(dut.y0my2, v0y - v2y);
      `FAIL_UNLESS_EQUAL(dut.x2mx0, v2x - v0x);
      `FAIL_UNLESS_EQUAL(dut.y2my0, v2y - v0y);
      `FAIL_UNLESS_EQUAL(dut.x1mx0, v1x - v0x);

      `FAIL_UNLESS_EQUAL(dut.y1py0, v1y + v0y);
      `FAIL_UNLESS_EQUAL(dut.y2py1, v2y + v1y);
      `FAIL_UNLESS_EQUAL(dut.y0py2, v0y + v2y);

      $display("DET: %0d == %0d", dut.det_t, `FP_MUL(dut.y1my2, dut.x0mx2) + `FP_MUL(dut.x2mx1, dut.y0my2));
      `FAIL_UNLESS_EQUAL(dut.det_t, `FP_MUL(dut.y1my2, dut.x0mx2) + `FP_MUL(dut.x2mx1, dut.y0my2));
    `SVTEST_END

    `SVTEST(main)
      integer i;

      reg [SC_WIDTH - 1:0] posx, posy;

      reg [WORD_WIDTH - 1:0] bbx0, bbx1, bby0, bby1;

      reg signed [WORD_WIDTH - 1:0] l0, l1, l2;

      reg signed [WORD_WIDTH - 1:0] xmx2, ymy2;

      v0x = 10 << `DECIMAL_POS;
      v0y = 50 << `DECIMAL_POS;
      v0z = 1 * 64'h80000000 / 3;

      v1x = 50 << `DECIMAL_POS;
      v1y = 10 << `DECIMAL_POS;
      v1z = 1 * 64'h80000000 / 3;

      v2x = 140 << `DECIMAL_POS;
      v2y = 140 << `DECIMAL_POS;
      v2z = 3 * 64'h80000000 / 3;

      SET_BBOX(bbx0, bbx1, bby0, bby1);

      $display("BBOX (%0d, %0d) - (%0d, %0d)", bbx0, bby0, bbx1, bby1);

      SETUP_PIPELINE();

      for (i = 0; i < 1000; i = i + 1) begin
        posx = bbx0 + {$random} % (bbx1 - bbx0);
        posy = bby0 + {$random} % (bby1 - bby0);

        $display("Testing (%0d, %0d)", posx, posy);

        xmx2 = `FP(posx) - v2x;
        ymy2 = `FP(posy) - v2y;

        SEND_DATA(posx, posy);

        RECEIVE_DATA(l0, l1, l2);

        begin : L0_TEST
          reg signed [`WORD_WIDTH - 1:0] top;
          
          top = `FP_MUL(dut.y1my2, xmx2) + `FP_MUL(dut.x2mx1, ymy2);

          $display("%0d == %0d", l0, `FP_DIV(top, dut.det_t));
          `FAIL_UNLESS_EQUAL(l0, `FP_DIV(top, dut.det_t));
        end

        begin : L1_TEST
          reg signed [`WORD_WIDTH - 1:0] top;
          
          top = `FP_MUL(dut.y2my0, xmx2) + `FP_MUL(dut.x0mx2, ymy2);

          $display("%0d == %0d", l1, `FP_DIV(top, dut.det_t));
          `FAIL_UNLESS_EQUAL(l1, `FP_DIV(top, dut.det_t));
        end

        begin : L2_TEST
          `FAIL_UNLESS_EQUAL(l2, `FP(1) - l0 - l1);
        end
      end

    `SVTEST_END

  `SVUNIT_TESTS_END

  task SETUP_PIPELINE;
  begin
    bary_run = 1;
    clk_rst.WAIT_CYCLES(2);
    bary_run = 0;

    wait(bary_init);
  end
  endtask

  task SET_BBOX;
    output [WORD_WIDTH - 1:0] bbx0;
    output [WORD_WIDTH - 1:0] bbx1;
    output [WORD_WIDTH - 1:0] bby0;
    output [WORD_WIDTH - 1:0] bby1;
  begin
    bbx0 = WORD_SMAX;
    bby0 = WORD_SMAX;
    bbx1 = 0;
    bby1 = 0;

    if (v0x < bbx0) bbx0 = v0x;
    if (v1x < bbx0) bbx0 = v1x;
    if (v2x < bbx0) bbx0 = v2x;

    if (v0y < bby0) bby0 = v0y;
    if (v1y < bby0) bby0 = v1y;
    if (v2y < bby0) bby0 = v2y;

    if (v0x > bbx1) bbx1 = v0x;
    if (v1x > bbx1) bbx1 = v1x;
    if (v2x > bbx1) bbx1 = v2x;

    if (v0y > bby1) bby1 = v0y;
    if (v1y > bby1) bby1 = v1y;
    if (v2y > bby1) bby1 = v2y;

    bbx0 = bbx0 >>> `DECIMAL_POS;
    bby0 = bby0 >>> `DECIMAL_POS;
    bbx1 = bbx1 >>> `DECIMAL_POS;
    bby1 = bby1 >>> `DECIMAL_POS;

    if (bbx0 < 0) bbx0 = 0;
    if (bby0 < 0) bby0 = 0;
    if (bbx1 >= WIDTH) bbx1 = WIDTH - 1;
    if (bby1 >= HEIGHT) bby1 = HEIGHT - 1;
  end
  endtask

  task SEND_DATA;
    input [SC_WIDTH - 1:0] posx;
    input [SC_WIDTH - 1:0] posy;
  begin
    stream_master.WRITE({ posx, posy });
  end
  endtask

  task RECEIVE_DATA;
    output [WORD_WIDTH - 1:0] l0;
    output [WORD_WIDTH - 1:0] l1;
    output [WORD_WIDTH - 1:0] l2;

    reg [SC_WIDTH - 1:0] posx, posy;
  begin
    stream_slave.READ({ posx, posy, l0, l1, l2 });
  end
  endtask

endmodule
