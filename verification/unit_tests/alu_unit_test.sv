`include "svunit_defines.svh"
`include "user_defines.v"
`include "core/alu.v"
`include "test/clk_rst.v"
`include "test/fixed_point.v"
`include "math/mul.v"
`include "math/full_adder.v"

module alu_unit_test;
  import svunit_pkg::svunit_testcase;

  string name = "alu_m_ut";
  svunit_testcase svunit_ut;

  int temp;

  reg signed [`WORD_WIDTH-1:0] a;
  reg signed [`WORD_WIDTH-1:0] b;
  reg [`ALU_CTL_SIZE-1:0] alu_ctl;

  wire [`WORD_WIDTH-1:0] result;
  alu_m my_alu_m(
    .a_i(a),
    .b_i(b),
    .alu_ctl_i(alu_ctl),

    .result_o(result)
  );


  function void build();
    svunit_ut = new(name);
  endfunction


  task setup();
    svunit_ut.setup();
  endtask


  task teardown();
    svunit_ut.teardown();
  endtask


  `SVUNIT_TESTS_BEGIN

   /*
   * Test boundary conditions and one random value
   */
    integer i;
    `SVTEST(add)
      alu_ctl = `ALU_ADD_CTL;
      a = 0;
      b = 0;
      #1
      `FAIL_UNLESS_EQUAL(result, 0);

      a = 0;
      b = 1;
      #1;
      `FAIL_UNLESS_EQUAL(result, 1);

      a = 0;
      b = -1;
      #1;
      `FAIL_UNLESS_EQUAL(result, -1);

      a = -1;
      b = -1;
      #1;
      `FAIL_UNLESS_EQUAL(result, -2);

      a = 32'h7FFFFFFF;
      b = 1;
      #1;
      `FAIL_UNLESS_EQUAL(result, 32'h80000000);

      a = -1;
      b = 1;
      #1;
      `FAIL_UNLESS_EQUAL(result, 0);


      for(i = 0; i < 100; i = i + 1) begin
        a = $random;
        b = $random;
        #1
        `FAIL_UNLESS_EQUAL(result, a + b);
      end
    `SVTEST_END

    `SVTEST(sub)
      alu_ctl  = `ALU_SUB_CTL;
      a = 0;
      b = 0;
      #1;
      `FAIL_UNLESS_EQUAL(result, 0);

      a = 0;
      b = 1;
      #1;
      `FAIL_UNLESS_EQUAL(result, -1);

      a = 0;
      b = -1;
      #1;
      `FAIL_UNLESS_EQUAL(result, 1);

      a = -1;
      b = -1;
      #1;
      `FAIL_UNLESS_EQUAL(result, 0);

      a = 32'h80000000;
      b = 1;
      #1;
      `FAIL_UNLESS_EQUAL(result, 32'h7FFFFFFF);

      a = -1;
      b = 1;
      #1;
      `FAIL_UNLESS_EQUAL(result, -2);

      for(i = 0; i < 100; i = i + 1) begin
        a = $random;
        b = $random;
        #1
        `FAIL_UNLESS_EQUAL(result, a - b);
      end
    `SVTEST_END

    `SVTEST(mult)
      alu_ctl = `ALU_MULT_CTL;
      a = `FP(0);
      b = `FP(0);
      #1
      `FAIL_UNLESS_EQUAL(result, `FP(0));

      a = `FP(0);
      b = `FP(1);
      #1;
      `FAIL_UNLESS_EQUAL(result, `FP(0));

      a = `FP(0);
      b = `FP(-1);
      #1;
      `FAIL_UNLESS_EQUAL(result, `FP(0));

      a = `FP(1);
      b = `FP(10);
      #1;
      `FAIL_UNLESS_EQUAL(result, `FP(10));

      a = `FP(1);
      b = `FP(-10);
      #1;
      `FAIL_UNLESS_EQUAL(result, `FP(-10));

      a = `FP(-1);
      b = `FP(-1);
      #1;
      `FAIL_UNLESS_EQUAL(result, `FP(1));

      a = `FP(32'h7FFFFFFF);
      b = `FP(32'h13401987);
      #1;
      `FAIL_UNLESS_EQUAL(result, `FP(32'h6CBFE679));

      for(i = 0; i < 100; i = i + 1) begin
        temp = $random;
      a = `FP(temp);
      b = `FP(1234);
      #1;
      `FAIL_UNLESS_EQUAL(result, `FP(temp * 1234));
      end
    `SVTEST_END

    `SVTEST(and_op)
      alu_ctl = `ALU_AND_CTL;
      a = 32'h00000000;
      b = 32'h00000000;
      #1;
      `FAIL_UNLESS_EQUAL(result, 32'h00000000);

      a = 32'h00000000;
      b = 32'hFFFFFFFF;
      #1;
      `FAIL_UNLESS_EQUAL(result, 32'h00000000);

      a = 32'h55555555;
      b = 32'hAAAAAAAA;
      #1;
      `FAIL_UNLESS_EQUAL(result, 32'h00000000);

      a = 32'h55555555;
      b = 32'hFFFFFFFF;
      #1;
      `FAIL_UNLESS_EQUAL(result, 32'h55555555);

      a = 32'hFFFFFFFF;
      b = 32'hAAAAAAAA;
      #1;
      `FAIL_UNLESS_EQUAL(result, 32'hAAAAAAAA);

      for(i = 0; i < 100; i = i + 1) begin
        a = $random;
        b = $random;
        #1
        `FAIL_UNLESS_EQUAL(result, a & b);
      end
    `SVTEST_END

    `SVTEST(or_op)
      alu_ctl = `ALU_OR_CTL;
      a = 32'h00000000;
      b = 32'h00000000;
      #1;
      `FAIL_UNLESS_EQUAL(result, 32'h00000000);

      a = 32'h00000000;
      b = 32'hFFFFFFFF;
      #1;
      `FAIL_UNLESS_EQUAL(result, 32'hFFFFFFFF);

      a = 32'h55555555;
      b = 32'hAAAAAAAA;
      #1;
      `FAIL_UNLESS_EQUAL(result, 32'hFFFFFFFF);

      a = 32'h55555555;
      b = 32'h00000000;
      #1;
      `FAIL_UNLESS_EQUAL(result, 32'h55555555);

      a = 32'h00000000;
      b = 32'hAAAAAAAA;
      #1;
      `FAIL_UNLESS_EQUAL(result, 32'hAAAAAAAA);

      for(i = 0; i < 100; i = i + 1) begin
        a = $random;
        b = $random;
        #1
        `FAIL_UNLESS_EQUAL(result, a | b);
      end
    `SVTEST_END

    `SVTEST(xor_op)
      alu_ctl = `ALU_XOR_CTL;
      a = 32'h00000000;
      b = 32'h00000000;
      #1;
      `FAIL_UNLESS_EQUAL(result, 32'h00000000);

      a = 32'h00000000;
      b = 32'hFFFFFFFF;
      #1;
      `FAIL_UNLESS_EQUAL(result, 32'hFFFFFFFF);

      a = 32'h55555555;
      b = 32'hAAAAAAAA;
      #1;
      `FAIL_UNLESS_EQUAL(result, 32'hFFFFFFFF);

      a = 32'h55555555;
      b = 32'h55555555;
      #1;
      `FAIL_UNLESS_EQUAL(result, 32'h00000000);

      a = 32'h00000000;
      b = 32'hAAAAAAAA;
      #1;
      `FAIL_UNLESS_EQUAL(result, 32'hAAAAAAAA);

      for(i = 0; i < 100; i = i + 1) begin
        a = $random;
        b = $random;
        #1
        `FAIL_UNLESS_EQUAL(result, a ^ b);
      end
    `SVTEST_END

    `SVTEST(seq)
      alu_ctl = `ALU_SEQ_CTL;
      a = 10;
      b = 10;
      #1;
      `FAIL_UNLESS_EQUAL(result, 1);

      a = 0;
      b = 1;
      #1;
      `FAIL_UNLESS_EQUAL(result, 0);
    `SVTEST_END

    `SVTEST(slt)
      alu_ctl = `ALU_SLT_CTL;
      a = 10;
      b = 10;
      #1;
      `FAIL_UNLESS_EQUAL(result, 0);

      a = -10;
      b = 10;
      #1;
      `FAIL_UNLESS_EQUAL(result, 1);

      a = 10;
      b = 123;
      #1;
      `FAIL_UNLESS_EQUAL(result, 1);

      a = 123;
      b = 10;
      #1;
      `FAIL_UNLESS_EQUAL(result, 0);

      a = -10;
      b = 123;
      #1;
      `FAIL_UNLESS_EQUAL(result, 1);
    `SVTEST_END

    `SVTEST(sltu)
      alu_ctl = `ALU_SLTU_CTL;
      a = 0;
      b = 0;
      #1;
      `FAIL_UNLESS_EQUAL(result, 0);

      a = 32'hFFFFFFFF;
      b = 1;
      #1;
      `FAIL_UNLESS_EQUAL(result, 0);

      a = 1;
      b = 32'hFFFFFFFF;
      #1;
      `FAIL_UNLESS_EQUAL(result, 1);

      for(i = 0; i < 100; i = i + 1) begin
        a = {$random};
        b = {$random};
        #1;
        `FAIL_UNLESS_EQUAL(result[0], $unsigned(a) < $unsigned(b));
      end
    `SVTEST_END

    `SVTEST(sll)
      alu_ctl = `ALU_SLL_CTL;
      a = 32'h00000101;
      b = 0;
      #1;
      `FAIL_UNLESS_EQUAL(result, a);

      a = 32'hFFFF0000;
      b = 16;
      #1;
      `FAIL_UNLESS_EQUAL(result, 32'h00000000);

      a = 32'h0000FFFF;
      b = 16;
      #1;
      `FAIL_UNLESS_EQUAL(result, 32'hFFFF0000);

      a = 32'h55555555;
      b = 1;
      #1;
      `FAIL_UNLESS_EQUAL(result, 32'hAAAAAAAA);

      a = 32'h00000001;
      b = 31;
      #1;
      `FAIL_UNLESS_EQUAL(result, 32'h80000000);


      for(i = 0; i < 100; i = i + 1) begin
        a = $random;
        b = $random % 32;
        #1
        `FAIL_UNLESS_EQUAL(result, a << b);
      end
    `SVTEST_END

    `SVTEST(srl)
      alu_ctl = `ALU_SRL_CTL;
      a = 32'h00000101;
      b = 0;
      #1;
      `FAIL_UNLESS_EQUAL(result, a);

      a = 32'hFFFF0000;
      b = 16;
      #1;
      `FAIL_UNLESS_EQUAL(result, 32'h0000FFFF);

      a = 32'h0000FFFF;
      b = 16;
      #1;
      `FAIL_UNLESS_EQUAL(result, 32'h00000000);

      a = 32'h55555555;
      b = 1;
      #1;
      `FAIL_UNLESS_EQUAL(result, 32'h2AAAAAAA);

      a = 32'h80000000;
      b = 31;
      #1;
      `FAIL_UNLESS_EQUAL(result, 32'h00000001);

      for(i = 0; i < 100; i = i + 1) begin
        a = $random;
        b = $random % 32;
        #1
        `FAIL_UNLESS_EQUAL(result, a >> b);
      end
    `SVTEST_END

    `SVTEST(sra)
      alu_ctl = `ALU_SRA_CTL;
      a = 32'h00000101;
      b = 0;
      #1;
      `FAIL_UNLESS_EQUAL(result, a);

      a = 32'hFFFF0000;
      b = 16;
      #1;
      `FAIL_UNLESS_EQUAL(result, 32'hFFFFFFFF);

      a = 32'h0000FFFF;
      b = 16;
      #1;
      `FAIL_UNLESS_EQUAL(result, 32'h00000000);

      a = 32'h55555555;
      b = 1;
      #1;
      `FAIL_UNLESS_EQUAL(result, 32'h2AAAAAAA);

      a = 32'h80000000;
      b = 31;
      #1;
      `FAIL_UNLESS_EQUAL(result, 32'hFFFFFFFF);

      for(i = 0; i < 100; i = i + 1) begin
        a = $random;
        b = $random % 32;
        #1
        temp = {a>>>b};
        `FAIL_UNLESS_EQUAL(result, temp);
      end
    `SVTEST_END

  `SVUNIT_TESTS_END

endmodule
