module reram_transgate (
`ifdef USE_POWER_PINS
    inout vdda1, // 1.8V
    inout vssa1,
`endif

    input wire SIG_IN,
    output wire SIG_OUT,
    input wire INV_SELECT, // connect to LA
    input wire SELECT      // connect to LA
);

endmodule
