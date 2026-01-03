`include "svunit_defines.svh"
`include "user_defines.v"

`include "test/clk_rst.v"
`include "core/regfile.v"
module regfile_m_unit_test;
  import svunit_pkg::svunit_testcase;

  string name = "regfile_m_ut";
  svunit_testcase svunit_ut;


  //===================================
  // This is the UUT that we're 
  // running the Unit Tests on
  //===================================

  localparam REG_WIDTH = `WORD_WIDTH;
  localparam CORE_HEIGHT = 16;
  localparam BASE_ADDR = 0;
  localparam NO_ZERO_REG = 0;

  wire clk, nrst;
  clk_rst_m clk_rst(.clk_o(clk), .nrst_o(nrst));
  reg wr_en;
  reg[REG_WIDTH-1:0] wr_data;
  reg[3:0] wr_addr, r1_addr, r2_addr;

  wire[`WORD_WIDTH-1:0] r1_data, r2_data;

  reg [REG_WIDTH-1:0] test_regfile [CORE_HEIGHT-1:0];

  regfile_m #(REG_WIDTH, CORE_HEIGHT, BASE_ADDR, NO_ZERO_REG) core_regfile_m 
  (
    .clk_i(clk),
    .nrst_i(nrst),
    .wr_en_i(wr_en),
    .wr_data_i(wr_data),
    .wr_addr_i(wr_addr),
    .r1_addr_i(r1_addr),
    .r2_addr_i(r2_addr),

    .r1_data_o(r1_data),
    .r2_data_o(r2_data)
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
    for (i = 0; i < CORE_HEIGHT; i = i + 1) begin
      test_regfile[i] = 0;
    end

    for(i = 0; i < 100; i = i + 1) begin
      @(negedge clk);
      wr_en <= {$random};
      wr_data <= {$random};
      wr_addr <= {$random};
      @(posedge clk);
      if(wr_en == 1) begin
        test_regfile[wr_addr] <= wr_data;
      end
      #1;
    end

    for(i = 0; i < CORE_HEIGHT; i = i + 1)begin
      @(posedge clk);
      r1_addr <= i;
      r2_addr <= i;
      
      @(posedge clk);
      `FAIL_UNLESS_EQUAL(r1_data, r2_data);
      `FAIL_UNLESS_EQUAL(test_regfile[i], r1_data);
    end
  `SVTEST_END



  `SVUNIT_TESTS_END

endmodule
