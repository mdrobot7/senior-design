`include "svunit_defines.svh"
`include "user_defines.v"

`include "test/clk_rst.v"
`include "core/predicate.v"

module predicate_m_unit_test;
  import svunit_pkg::svunit_testcase;

  string name = "predicate_m_ut";
  svunit_testcase svunit_ut;


  //===================================
  // This is the UUT that we're 
  // running the Unit Tests on
  //===================================
  wire clk, nrst;
  clk_rst_m clk_rst(.clk_o(clk), .nrst_o(nrst));
  reg wr_en, is_predicable;
  reg[`PREDICATE_BITS_WIDTH-1:0] wr_mask, wr_data, instruction_predicate;
  wire[`PREDICATE_BITS_WIDTH-1:0] status;
  wire equal;
  predicate_m my_predicate_m(
    .clk_i(clk),
    .nrst_i(nrst),
    .wr_en_i(wr_en),
    .wr_mask_i(wr_mask),
    .wr_data_i(wr_data),
    .instruction_predicate_i(instruction_predicate),
    .is_predicable_i(is_predicable),
    .status_o(status),
    .equal_o(equal)
  );
	reg[`PREDICATE_BITS_WIDTH-1:0] test_predicate_bits;


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
		test_predicate_bits = 0;
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
  `SVTEST(write_test)
		integer i = 0;
		integer j = 0;
		for(i = 0; i < 100; i = i + 1) begin
			@(negedge clk);
			wr_en = {$random};
			wr_mask = {$random};
			wr_data = {$random};
			clk_rst.WAIT_CYCLES(1);
			if(wr_en == 1) begin
				for(j = 0; j < `PREDICATE_BITS_WIDTH; j = j + 1) begin
					if(wr_mask[j]) begin
						test_predicate_bits[j] <= wr_data[j];
					end
				end
			end
			clk_rst.WAIT_CYCLES(1);
			`FAIL_UNLESS_EQUAL(test_predicate_bits, status);
		end
  `SVTEST_END

	`SVTEST(equal_test)
		integer i = 0;
		wr_en = 1;
		wr_mask = 3'b111;
		for(i = 0; i < 100; i = i + 1) begin
			@(negedge clk);
			is_predicable = {$random};
			wr_data = {$random};
			instruction_predicate = {$random};
			clk_rst.WAIT_CYCLES(1);
			if(~is_predicable) begin
				//always equal if not predicable
				`FAIL_UNLESS_EQUAL(equal, 1);
			end
			else begin
				`FAIL_UNLESS_EQUAL(wr_data == instruction_predicate, equal);
			end
		end
	`SVTEST_END
  `SVUNIT_TESTS_END

endmodule
