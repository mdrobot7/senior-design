`timescale 1ns/1ps
module sram_ip_wrapper_tb();

    parameter NB = 32;
    parameter NA = 10;

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

    .vpwrpc(vpwrpc)
  );

  initial begin 
    CLKin = 0;
    #10
    forever #10 CLKin = ~CLKin;
  end

  initial begin : MAIN
    integer addr;

    $dumpfile("sram_ip_wrapper.vcd");
    $dumpvars(0, sram_ip_wrapper_tb);

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

    #40;

    AD = 10'h012;
    DI = 32'hA5A5_5A5A;
    BEN = 32'hFFFF_FFFF;
    R_WB = 0;
    #40
    R_WB = 1;
    //AD = 10'h0;
    #40
    $display("0x%h == 0x%h", DO, 32'hA5A5_5A5A);

    for(addr = 0; addr < 1024; addr++) begin
      R_WB = 0;
      AD = addr[9:0];
      BEN = 32'hFFFF_FFFF;

      DI = addr;
      #3;
      @(posedge CLKin);
      #3;
    end

    BEN = 32'hFFFF_FFFF;
    R_WB = 1;

    for(addr = 0; addr < 1024; addr++) begin
      AD = addr[9:0];

      #3;
      

      @(posedge CLKin);
      #3;
      if(addr[9:0] !== DO) begin
        $display("Values not equal 0x%h !== 0x%h", DO, addr);
      end
    end

    #100;
    $finish;
  end


endmodule
