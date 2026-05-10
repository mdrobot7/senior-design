module CurrentSteering_3bit_rev3 (
`ifdef USE_POWER_PINS
    inout VDD, // 3.3V
    inout VSS,
`endif

    input wire A, // LSB
    input wire B,
    input wire C, // MSB
    output wire VOUT
);

endmodule
