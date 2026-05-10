module opamp_5t (
`ifdef USE_POWER_PINS
    inout VDD, // 3.3V
    inout VSS,
`endif

    input wire Vinp,
    input wire Vinm,
    input wire VBIAS,
    output wire Vout
);

endmodule
