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

  wire clk, nrst;
  clk_rst_m clk_rst(.clk_o(clk), .nrst_o(nrst));

  reg nsync_rst;
  reg wr_en, inbox_write;
  reg[REG_WIDTH-1:0] wr_data;
  reg[3:0] wr_addr, r1_addr, r2_addr;
  reg[`WORD_WIDTH * `CORE_MAILBOX_HEIGHT-1:0] inbox;

  wire[`WORD_WIDTH-1:0] r1_data, r2_data;
  wire[`WORD_WIDTH * `CORE_MAILBOX_HEIGHT-1:0] outbox;

  reg [REG_WIDTH-1:0] test_regfile [CORE_HEIGHT-1:0];

  core_regfile_m #(.SP(32'hADEAFBEE)) core_regfile
  (
    .clk_i(clk),
    .nrst_i(nrst),
    .nsync_rst_i(nsync_rst),

    .wr_en_i(wr_en),
    .wr_data_i(wr_data),
    .wr_addr_i(wr_addr),

    .r1_addr_i(r1_addr),
    .r2_addr_i(r2_addr),

    .r1_data_o(r1_data),
    .r2_data_o(r2_data),

    .inbox_write_i(inbox_write),
    .inbox_i(inbox),
    .outbox_o(outbox)
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
    inbox_write <= 0;
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

    nsync_rst = 1;
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

`SVTEST(mailbox_test)
    integer i, j;
    nsync_rst = 1;
    for(i = 0; i < 100; i=i+1) begin
        inbox_write <= 1;
        wr_en <= 0;
        for (j = 0; j < `CORE_MAILBOX_HEIGHT; j=j+1) begin
            inbox[j*REG_WIDTH +: REG_WIDTH] = $urandom;
        end
        @(posedge clk);
        @(posedge clk);
        `FAIL_UNLESS_EQUAL(inbox, outbox);
    end
  `SVTEST_END

  `SVTEST(sync_rst)
    integer i;

    nsync_rst = 1;
    for (i = 0; i < `NUM_LOCAL_REGS; i++) begin
      test_regfile[i] = $urandom;
      core_regfile.mem[i] = test_regfile[i];
    end

    @(negedge clk);
    nsync_rst = 0;
    @(negedge clk);
    nsync_rst = 1;

    for (i = 0; i < `NUM_LOCAL_REGS - 1; i++) begin
      `FAIL_UNLESS_EQUAL(core_regfile.mem[i], test_regfile[i]);
    end
    `FAIL_UNLESS_EQUAL(core_regfile.mem[`NUM_LOCAL_REGS-1], 32'hADEAFBEE);
  `SVTEST_END

  `SVUNIT_TESTS_END

endmodule
