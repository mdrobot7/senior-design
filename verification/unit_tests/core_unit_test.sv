`include "svunit_defines.svh"
`include "user_defines.v"

`include "test/clk_rst.v"
`include "core/core.v"
`include "core/accumulator.v"
`include "core/alu.v"
`include "core/decoder.v"
`include "core/forward.v"
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
  reg stall, flush_dec_stage;
  reg[`WORD_WIDTH-1:0] inst, global_r1_data, global_r2_data, mem_data_in;
  reg[`WORD_WIDTH-1:0] i_mem [0:127];


  wire is_load, is_store, jump_request;
  wire[`WORD_WIDTH-1:0] mem_addr, mem_data_out;

  //===================================
  // This is the UUT that we're 
  // running the Unit Tests on
  //===================================
  core_m my_core_m(
    .clk_i(clk),
    .nrst_i(nrst),
    .inst_i(inst),
    .global_r1_data_i(global_r1_data),
    .global_r2_data_i(global_r2_data),

    .mem_addr_o(mem_addr),
    .mem_data_o(mem_data_out),
    .is_load_o(is_load),
    .is_store_o(is_store),
    .mem_data_i(mem_data_in),

    .jump_request_o(jump_request),
    .flush_dec_stage_i(flush_dec_stage),
    .stall_i(stall)
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
    stall = 0;
    flush_dec_stage = 0;
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
    @(negedge clk);
    for(i = 0; i < 17; i = i + 1) begin
      inst = i_mem[i];
      clk_rst.WAIT_CYCLES(1);
    end
    inst = i_mem[0]; //pseudo nop for now
    clk_rst.WAIT_CYCLES(5);

    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[0], 32'd0);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[1], -32'd1);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[2], 32'd2);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[3], -32'd3);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[4], 32'd4);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[5], -32'd5);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[6], 32'd6);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[7], -32'd7);
  `SVTEST_END

  `SVTEST(test_math)
    integer i;
    $readmemh("test_cores.mem", i_mem);
    clk_rst.RESET();
    clk_rst.WAIT_CYCLES(3);
    @(negedge clk);

    for(i = 0; i < 55; i = i + 1) begin
      inst = i_mem[i];
      clk_rst.WAIT_CYCLES(1);
    end
    clk_rst.WAIT_CYCLES(5);

    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[0], 32'd0);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[1], -32'd1);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[2], 32'd2);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[3], -32'd3);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[4], 32'd4);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[5], -32'd5);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[6], 32'd6);
    
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[8], 32'h5);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[9], 32'h1000);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[10], 32'hFFFFF371);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[11], 32'hFFFF8E04);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[12], 32'h1);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[13], 32'hFFFF8B51);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[14], 32'hFFFFFC18);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[15], 32'hFFFFFFFF);

    `FAIL_UNLESS_EQUAL(my_core_m.outbox[0], -32'd1);
    `FAIL_UNLESS_EQUAL(my_core_m.outbox[1], 32'd2);
    `FAIL_UNLESS_EQUAL(my_core_m.outbox[2], -32'h3);
    `FAIL_UNLESS_EQUAL(my_core_m.outbox[3], 32'h4);
    `FAIL_UNLESS_EQUAL(my_core_m.outbox[4], -32'h5);
    `FAIL_UNLESS_EQUAL(my_core_m.outbox[5], 32'h6);
    `FAIL_UNLESS_EQUAL(my_core_m.outbox[6], -32'h7);
    `FAIL_UNLESS_EQUAL(my_core_m.outbox[7], 32'h5);

  `SVTEST_END

  `SVTEST(test_lui_lli)
    integer i;
    $readmemh("test_cores.mem", i_mem);
    clk_rst.RESET();
    clk_rst.WAIT_CYCLES(3);

    for(i = 0; i < 59; i = i + 1) begin
      @(negedge clk);
      inst = i_mem[i];
    end
    clk_rst.WAIT_CYCLES(5);

    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[0], 32'd0);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[1], -32'd1);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[2], 32'd2);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[3], -32'd3);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[4], 32'd4);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[5], -32'd5);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[6], 32'd6);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[7], 32'hFFFFFFF9)
    
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[8], 32'h5);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[9], 32'h00001000);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[10], 32'hFFFFF371);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[11], 32'hFFFF8E04);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[12], 32'h00000001);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[13], 32'hFFFF8B51);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[14], 32'hFFFFFC18);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[15], 32'h55559090);

    `FAIL_UNLESS_EQUAL(my_core_m.outbox[0], -32'd1);
    `FAIL_UNLESS_EQUAL(my_core_m.outbox[1], 32'd2);
    `FAIL_UNLESS_EQUAL(my_core_m.outbox[2], -32'h3);
    `FAIL_UNLESS_EQUAL(my_core_m.outbox[3], 32'h4);
    `FAIL_UNLESS_EQUAL(my_core_m.outbox[4], -32'h5);
    `FAIL_UNLESS_EQUAL(my_core_m.outbox[5], 32'h6);
    `FAIL_UNLESS_EQUAL(my_core_m.outbox[6], -32'h7);
    `FAIL_UNLESS_EQUAL(my_core_m.outbox[7], 32'h5);
  `SVTEST_END

    `SVTEST(test_macops)
    integer i;
    $readmemh("test_cores.mem", i_mem);
    clk_rst.RESET();
    clk_rst.WAIT_CYCLES(3);

    for(i = 0; i < 78; i = i + 1) begin
      @(negedge clk);
      inst = i_mem[i];
    end
    clk_rst.WAIT_CYCLES(5);

    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[0], 32'd0);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[1], -32'd1);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[2], 32'd2);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[3], -32'd3);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[4], 32'd4);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[5], -32'd5);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[6], 32'd6);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[7], 32'hFFFFFFF9)
    
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[8], 32'h5);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[9], 32'h0000107D);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[10], 32'h00019000);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[11], 32'h000050C8);

    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[12], 32'h000670D4);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[13], 32'h002C5E5B);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[14], 32'h002C5E5A);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[15], 32'h00000000);

    `FAIL_UNLESS_EQUAL(my_core_m.outbox[0], -32'd1);
    `FAIL_UNLESS_EQUAL(my_core_m.outbox[1], 32'd2);
    `FAIL_UNLESS_EQUAL(my_core_m.outbox[2], -32'h3);
    `FAIL_UNLESS_EQUAL(my_core_m.outbox[3], 32'h4);
    `FAIL_UNLESS_EQUAL(my_core_m.outbox[4], -32'h5);
    `FAIL_UNLESS_EQUAL(my_core_m.outbox[5], 32'h6);
    `FAIL_UNLESS_EQUAL(my_core_m.outbox[6], -32'h7);
    `FAIL_UNLESS_EQUAL(my_core_m.outbox[7], 32'h5);
  `SVTEST_END

  `SVTEST(test_predication)
    integer i;
    $readmemh("test_cores.mem", i_mem);
    clk_rst.RESET();
    clk_rst.WAIT_CYCLES(3);

    for(i = 0; i < 103; i = i + 1) begin
      @(negedge clk);
      inst = i_mem[i];
    end
    clk_rst.WAIT_CYCLES(5);

    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[0], 32'd0);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[1], -32'd1);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[2], 32'd2);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[3], -32'd3);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[4], 32'd4);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[5], -32'd5);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[6], 32'd6);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[7], 32'h00000000)
    
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[8], 32'h1);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[9], 32'h0);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[10], 32'h1);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[11], 32'h0);

    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[12], 32'h4);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[13], 32'h0);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[14], 32'h1);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[15], 32'hFFFFFFFF);

    `FAIL_UNLESS_EQUAL(my_core_m.outbox[0], -32'd1);
    `FAIL_UNLESS_EQUAL(my_core_m.outbox[1], 32'd2);
    `FAIL_UNLESS_EQUAL(my_core_m.outbox[2], -32'h3);
    `FAIL_UNLESS_EQUAL(my_core_m.outbox[3], 32'h4);
    `FAIL_UNLESS_EQUAL(my_core_m.outbox[4], -32'h5);
    `FAIL_UNLESS_EQUAL(my_core_m.outbox[5], 32'h6);
    `FAIL_UNLESS_EQUAL(my_core_m.outbox[6], -32'h7);
    `FAIL_UNLESS_EQUAL(my_core_m.outbox[7], 32'h5);
  `SVTEST_END

  `SVTEST(jumping)
    integer i;
    $readmemh("test_jumping.mem", i_mem);
    clk_rst.RESET();
    clk_rst.WAIT_CYCLES(3);
    //clear all regs and seed some values
    for(i = 0; i < 25; i = i + 1) begin
      @(negedge clk);
      inst = i_mem[i];
    end

    //due to wonderful jumping stuff, we are gonna take this slow and explicitly run each instruction
    @(negedge clk);
    inst = i_mem[i]; //jump 0x8

    @(negedge clk);
    `FAIL_IF(jump_request);
    i = i + 1;
    inst = i_mem[i]; // speq $p0, $r1, $r1, should be flushed 

    //jump is now in ex, speq in decode, we should be jumping
    @(negedge clk);
    `FAIL_UNLESS(jump_request);
    flush_dec_stage = 1;
    i = i + 2;
    inst = i_mem[i]; // speq $p1, $r1, $r1

    @(negedge clk);
    flush_dec_stage = 0;
    i = i + 1;
    inst = i_mem[i]; // jump -8 (annulled)

    @(negedge clk);
    i = i + 1;
    inst = i_mem[i]; // jal -12 (annulled)

    @(negedge clk);
    `FAIL_IF(jump_request); // jump -8 should be annulled
    i = i + 1;
    inst = i_mem[i]; // jump 4 

    @(negedge clk);
    `FAIL_IF(jump_request); //jal -12 should be annulled
    i = i + 1;
    inst = i_mem[i]; // addi $r1, $r1, 16

    @(negedge clk);
    `FAIL_UNLESS(jump_request);
    i = i + 1;
    inst = i_mem[i]; // (010) addi $r9, $r9, 100

    @(negedge clk);
    i = i + 1;
    inst = i_mem[i]; // addi $r10, $r9, 101

    @(negedge clk);
    i = i + 1;
    inst = i_mem[i]; // halt
    clk_rst.WAIT_CYCLES(5);

    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[0], 32'd0);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[1], -32'd1);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[2], 32'd2);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[3], -32'd3);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[4], 32'd4);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[5], -32'd5);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[6], 32'd6);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[7], -32'h7)
    
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[8], 32'h0);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[9], 32'h64);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[10], 32'hC9);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[11], 32'h0);

    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[12], 32'h0);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[13], 32'h0);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[14], 32'h0);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[15], 32'h0);

  `SVTEST_END

  `SVUNIT_TESTS_END

endmodule
