module sram_ip_wrapper_tb();

    parameter NB = 32;    // Number of Data Bits
    parameter NA = 10;    // Number of Address Bits

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
  sram_ip_wrapper #(NB, NA) dut (
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

  initial begin
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
  end

endmodule
