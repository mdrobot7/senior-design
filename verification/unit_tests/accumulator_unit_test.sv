`include "svunit_defines.svh"
`include "user_defines.v"
`include "test/clk_rst.v"
`include "core/accumulator.v"


module accumulator_m_unit_test;
  import svunit_pkg::svunit_testcase;

  string name = "accumulator_m_ut";
  svunit_testcase svunit_ut;


  wire clk, nrst;
  clk_rst_m clk_rst(.clk_o(clk), .nrst_o(nrst));

  reg                      en;
  reg  signed[`WORD_WIDTH-1:0] a;
  wire signed[`WORD_WIDTH-1:0] acc;

  accumulator_m my_accumulator_m (
    .clk_i (clk),
    .nrst_i(nrst),
    .en_i  (en),
    .a_i   (a),
    .acc_o (acc)
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

    en   = 0;
    a  = '0;

    clk_rst.RESET();
    clk_rst.WAIT_CYCLES(1);
  endtask


  //===================================
  // Here we deconstruct anything we 
  // need after running the Unit Tests
  //===================================

  task teardown();
    svunit_ut.teardown();
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


  // Verify reset funtionality:
    `SVTEST(reset_clears_accumulator)

      `FAIL_UNLESS_EQUAL(acc, '0);

      en     = 1;
      a = 32'h00000005;
      clk_rst.WAIT_CYCLES(1);
      #1;
      `FAIL_UNLESS_EQUAL(acc, 32'h00000005);

      clk_rst.RESET();
      clk_rst.WAIT_CYCLES(1);
      #1;
      `FAIL_UNLESS_EQUAL(acc, '0);
      a = 32'h00000005;
      clk_rst.WAIT_CYCLES(1);
      `FAIL_UNLESS_EQUAL(acc, 32'h00000005);
          a = 32'h00000002;
      clk_rst.WAIT_CYCLES(1);
      `FAIL_UNLESS_EQUAL(acc, 32'h00000007);

    `SVTEST_END


  // Verify accumulation and enable functionality
    `SVTEST(accumulate_sequence_and_enable)
      integer i;
      integer expected;

      en       = 1;
      expected = 0;


      for (i = 1; i <= 10; i = i + 1) begin
        a      = 32'h00000000 + i;
        expected = expected + i;
        clk_rst.WAIT_CYCLES(1);
        #1;
      `FAIL_UNLESS_EQUAL(acc, expected);
      end


      en     = 0;
      a = 32'h00000064;
      clk_rst.WAIT_CYCLES(1);
      #1;
      `FAIL_UNLESS_EQUAL(acc, expected);
    `SVTEST_END

  `SVUNIT_TESTS_END

endmodule

