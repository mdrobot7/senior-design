`include "svunit_defines.svh"
`include "user_defines.v"
`include "core/decoder.v"

module decoder_m_unit_test;
  import svunit_pkg::svunit_testcase;

  string name = "decoder_m_ut";
  svunit_testcase svunit_ut;


  //===================================
  // This is the UUT that we're 
  // running the Unit Tests on
  //===================================
  reg[`WORD_WIDTH-1:0] instruction;
  wire[`CTL_SIGS_WIDTH-1:0] control_sigs;
  decoder_m my_decoder_m(
    .instruction_i(instruction),
    .control_sigs_o(control_sigs)
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
    instruction = 0;
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
  `SVTEST(add)
    instruction[`OPCODE_IDX] <= `ADD_OPCODE;
    instruction[`R2_IDX] <= 6'h30;
    #1
    `FAIL_UNLESS_EQUAL(control_sigs[`R1_USE_GLOBAL_VAL_IDX], 0);
    `FAIL_UNLESS_EQUAL(control_sigs[`R2_USE_GLOBAL_VAL_IDX], 1);
    `FAIL_UNLESS_EQUAL(control_sigs[`OUT_IDX], 0);
    `FAIL_UNLESS_EQUAL(control_sigs[`USE_IMM_IDX], 1'b0);
    `FAIL_UNLESS_EQUAL(control_sigs[`USE_PC_IDX], 0);
		`FAIL_UNLESS_EQUAL(control_sigs[`USE_ALU_RESULT_IDX], 1);
		`FAIL_UNLESS_EQUAL(control_sigs[`ALU_CTL_IDX], `ALU_ADD_CTL);
		`FAIL_UNLESS_EQUAL(control_sigs[`IS_PREDICABLE_IDX], 1);
		`FAIL_UNLESS_EQUAL(control_sigs[`PREDICATE_WRITE_IDX], 0);
		`FAIL_UNLESS_EQUAL(control_sigs[`IS_LOAD_IDX], 0);
		`FAIL_UNLESS_EQUAL(control_sigs[`IS_STORE_IDX], 0);
		`FAIL_UNLESS_EQUAL(control_sigs[`WB_SIG_IDX], `WB_EX_RESULT);
  `SVTEST_END
  `SVUNIT_TESTS_END

endmodule
