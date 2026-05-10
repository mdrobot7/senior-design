module sram_wrapper_m(
`ifdef USE_POWER_PINS
    inout wire vccd1,
    inout wire vssd1,
`endif

    input  wire clk_i,

    input  wire [`SRAM_1024x32_ADDR_WIDTH-1:0] addr_i,
    input  wire read_en_i,
    input  wire [`WORD] ben_i,
    input  wire en_i,
    input  wire [`WORD] data_i,
    output wire [`WORD] data_o
);

    CF_SRAM_1024x32 sram (
        .vpwrac(1'b1), // power (vpwra)
        .vpwrpc(1'b1), // power

    `ifdef USE_POWER_PINS
        .vgnd(vssd1),   // gnd
        .vpwrm(vccd1),  // power

        .vpwra(vccd1), // power

        .vpwrp(vccd1), // power

        .vnb(vssd1), // gnd
        .vpb(vccd1), // power
    `endif
    
        .DO(data_o), 
        .ScanOutCC(),

        .CLKin(clk_i), 
        .AD(addr_i), 
        .BEN(ben_i), 
        .DI(data_i), 
        .EN(en_i), 
        .R_WB(read_en_i),

        .ScanInCC(1'b0), 
        .ScanInDL(1'b0), 
        .ScanInDR(1'b0), 
        .SM(1'b0), 
        .TM(1'b0), 
        .WLBI(1'b0), 
        .WLOFF(1'b0)
    );

endmodule

