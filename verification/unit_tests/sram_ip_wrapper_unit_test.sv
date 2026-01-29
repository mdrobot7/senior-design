`include "svunit_defines.svh"
`include "../../ip/CF_SRAM_1024x32/hdl/beh_models/CF_SRAM_1024x32.tt_180V_25C.v"

module sram_ip_wrapper_unit_test;
  import svunit_pkg::svunit_testcase;

  string name = "sram_ip_wrapper_ut";
  svunit_testcase svunit_ut;

  parameter NB = 32;    // Number of Data Bits
  parameter NA = 10;    // Number of Address Bits
  parameter NW = 1024;  // Number of WORDS
  parameter SEED = 0 ;  // User can define SEED at memory instantiation by .SEED(<Some_Seed_value>)

  wire [(NB - 1) : 0] DO;
  wire ScanOutCC;

  reg [(NB - 1) : 0] DI;
  reg [(NB - 1) : 0] BEN;
  reg [(NA - 1) : 0] AD;
  reg EN;
  reg R_WB;
  reg CLKin;
  reg WLBI;
  reg WLOFF;
  reg TM;
  reg SM;
  reg ScanInCC;
  reg ScanInDL;
  reg ScanInDR;
  reg vpwrac;
  reg vpwrpc;

  //===================================
  // This is the UUT that we're 
  // running the Unit Tests on
  //===================================
  CF_SRAM_1024x32_macro dut (
    .DO(DO),
    .ScanOutCC(ScanOutCC),
    .AD(AD),
    .BEN(BEN),
    .CLKin(CLKin),
    .DI(DI),
    .EN(EN),
    .R_WB(R_WB),
    .ScanInCC(ScanInCC),
    .ScanInDL(ScanInDL),
    .ScanInDR(ScanInDR),
    .SM(SM),
    .TM(TM),
    .WLBI(WLBI),
    .WLOFF(WLOFF),

    .vpwrac(vpwrac),

    .vpwrpc(vpwrpc));

  initial begin 
    CLKin = 0;
    #10
    forever #10 CLKin = ~CLKin;
  end


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
    AD = 10'h0;
    DI = 32'h0;
    BEN = 32'h0;
    EN = 1;
    R_WB = 1;
    WLBI = 0;
    WLOFF = 0;
    TM = 0;
    SM = 0;
    ScanInCC = 0;
    ScanInDL = 0;
    ScanInDR = 0;
    vpwrac = 1;
    vpwrpc = 1;
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

  `SVTEST(basic_write_read)
    AD = 10'h012;
    DI = 32'hA5A5_5A5A;
    BEN = 32'hFFFF_FFFF;
    R_WB = 0;
    #3;
    @(posedge CLKin);
    #3;
    R_WB = 1;
    //AD = 10'h0;
    #3;

    @(posedge CLKin);
    #3
    $display("0x%h == 0x%h", DO, 32'hA5A5_5A5A);
    `FAIL_IF(DO !== 32'hA5A5_5A5A);
  `SVTEST_END

  `SVTEST(random_full_mem_check)
    bit [31:0] exp_mem [1023:0];

    for(int addr = 0; addr < 1024; addr++) begin
      AD = addr[9:0];
      exp_mem[addr] = $urandom();
      BEN = 32'hFFFF_FFFF;
      R_WB = 0;

      DI = exp_mem[addr];
      #3;
      @(posedge CLKin);
      #3;
    end

    for(int addr = 0; addr < 1024; addr++) begin
      AD = addr[9:0];
      R_WB = 1;
      BEN = 32'hFFFF_FFFF;
      #3;
      @(posedge CLKin);
      #3;
      if(DO !== exp_mem[addr]) begin
        $display("ERROR: At ADDR 0x%h expected 0x%h got 0x%h", addr, exp_mem[addr], DO);
      end
      `FAIL_UNLESS_EQUAL(DO, exp_mem[addr]);
    end
  `SVTEST_END

  `SVUNIT_TESTS_END

endmodule
