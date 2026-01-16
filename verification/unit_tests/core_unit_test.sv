`include "svunit_defines.svh"
`include "user_defines.v"

`include "test/clk_rst.v"
`include "core/core.v"
`include "core/accumulator.v"
`include "core/alu.v"
`include "core/decoder.v"
`include "core/predicate.v"
`include "core/regfile.v"
`include "core/signext.v"

`include "math/full_adder.v"
`include "math/mul.v"

`define DEBUG_PRINTS 1

module core_m_unit_test;
  import svunit_pkg::svunit_testcase;

  string name = "core_m_ut";
  svunit_testcase svunit_ut;

  wire clk, nrst;
  clk_rst_m clk_rst(.clk_o(clk), .nrst_o(nrst));
  reg[`WORD_WIDTH-1:0] inst, pc, global_r1_data, global_r2_data, mem_data_in;
  reg[`WORD_WIDTH-1:0] i_mem [0:63];


  wire is_load, is_store;
  wire[`WORD_WIDTH-1:0] mem_addr, mem_data_out;

  //===================================
  // This is the UUT that we're 
  // running the Unit Tests on
  //===================================
  core_m my_core_m(
    .clk_i(clk),
    .nrst_i(nrst),
    .inst_i(inst),
    .pc_i(pc),
    .global_r1_data_i(global_r1_data),
    .global_r2_data_i(global_r2_data),

    .mem_addr_o(mem_addr),
    .mem_data_o(mem_data_out),
    .is_load_o(is_load),
    .is_store_o(is_store),
    .mem_data_i(mem_data_in)
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
    global_r1_data = 0;
    global_r2_data = 0;
    mem_data_in = 0;
    pc = 0;
    clk_rst.RESET();
    clk_rst.WAIT_CYCLES(3);
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
 
  `SVTEST(set_regfile)
    integer i;
    //values from test_core.s
    $readmemh("test_cores.mem", i_mem);
    for(i = 0; i < 17; i = i + 1) begin
      @(negedge clk);
      pc = pc + 1;
      inst = i_mem[i];
      $display("inst:0x%h", inst);
      clk_rst.WAIT_CYCLES(1);
    end
    assign inst = i_mem[0]; //pseudo nop for now
    clk_rst.WAIT_CYCLES(5);

    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[0], 32'd0);
    $display("res:0x%h exp:0x%h", my_core_m.regfile.mem[1], -32'd1);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[1], -32'd1);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[2], 32'd2);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[3], -32'd3);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[4], 32'd4);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[5], -32'd5);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[6], 32'd6);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[7], -32'd7);
  `SVTEST_END


  `SVUNIT_TESTS_END

endmodule
