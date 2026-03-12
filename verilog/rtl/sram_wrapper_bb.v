module CF_SRAM_1024x32_wrapper (
    output [31 : 0] DO,
    output ScanOutCC,
    input [31 : 0] DI,
    input [31 : 0] BEN,
    input [9 : 0] AD,
    input EN,
    input R_WB,
    input CLKin,
    input WLBI,
    input WLOFF,
    input TM,
    input SM,
    input ScanInCC,
    input ScanInDL,
    input ScanInDR,
    input vpwrac,
    input vpwrpc
);
endmodule