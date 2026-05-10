module inverter (
`ifdef USE_POWER_PINS
    inout VDD, // 1.8V
    inout VSS,
`endif

    input wire Vin,  // connect to LA
    output wire Vout // connect to LA
);

endmodule
