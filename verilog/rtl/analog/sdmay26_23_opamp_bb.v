module sdmay26_23_opamp (
`ifdef USE_POWER_PINS
    inout VDD, // 1.8V
    inout VSS,
`endif

    input wire VINP,
    input wire VINN,
    output wire VOUT
);

endmodule
