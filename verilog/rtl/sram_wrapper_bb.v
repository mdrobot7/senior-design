module sram_wrapper_m(
`ifdef USE_POWER_PINS
    input wire vccd1,
    input wire vssd1,
`endif

    input  wire clk_i,

    input  wire [9:0] addr_i,
    input  wire read_en_i,
    input  wire [31:0] ben_i,
    input  wire en_i,
    input  wire [31:0] data_i,
    output wire [31:0] data_o
);
endmodule

