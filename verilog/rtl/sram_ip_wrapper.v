module sram_ip_wrapper #(parameter NB = 32, parameter NA = 10) (
    output [(NB - 1) : 0] DO,
    output ScanOutCC,

    input [(NB - 1) : 0] DI,
    input [(NB - 1) : 0] BEN,
    input [(NA - 1) : 0] AD,
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

    CF_SRAM_1024x32 i_CF_SRAM_1024x32
    (
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
endmodule