/*
 * Generic 4kb (1024 x 32b) SRAM module. Wraps around the commercial SRAM
 * (for hardening) and a Vivado-inferred BRAM (for FPGA test).
 *
 * Follows the commercial SRAM timing -- reads and writes both take 1 full cycle.
 * https://platform.chipfoundry.io/marketplace/item/cf-sram-1024x32-v123
 */
module sram_1024x32_m (
`ifdef USE_POWER_PINS
    input wire vccd1,
    input wire vssd1,
    input wire vpwrac,
    input wire vpwrpc,
`endif

    input  wire clk_i,

    input  wire [`SRAM_1024x32_ADDR_WIDTH-1:0] addr_i,
    input  wire read_en_i,
    input  wire en_i,
    input  wire [`WORD] data_i,
    output wire [`WORD] data_o
);

// Do not use this file for synthesis, we do not want to wrap the bb.

`ifdef FPGA
  rams_sp_wf sram (
    .clk(clk_i),
    .we(!read_en_i),
    .en(en_i),
    .addr(addr_i),
    .di(data_i),
    .dout(data_o)
  );
`else
  `define functional // Use this for RTL tests, disables the $setuphold tests that can't be checked with RTL
  CF_SRAM_1024x32_macro sram (
  `ifdef USE_POWER_PINS
    .vpwrac(vpwrac),
    .vpwrpc(vpwrpc),
  `endif

    .CLKin(clk_i),
    .DO(data_o),
    .DI(data_i),
    .BEN(32'hFFFFFFFF), // Write mask
    .AD(addr_i),
    .EN(en_i),
    .R_WB(read_en_i),

    // Test signals
    .WLBI(1'b0),
    .WLOFF(1'b0),
    .TM(1'b0),
    .SM(1'b0),
    .ScanInCC(1'b0),
    .ScanInDL(1'b0),
    .ScanInDR(1'b0),
    .ScanOutCC()
  );
`endif
endmodule

// https://docs.amd.com/r/en-US/ug901-vivado-synthesis/Single-Port-Block-RAM-Write-First-Mode-Verilog
// https://docs.amd.com/v/u/en-US/pg058-blk-mem-gen
// Vivado Single-Port Block RAM Write-First Mode (recommended template)
// File: rams_sp_wf.v
`ifdef FPGA
`default_nettype wire // bad vivado
module rams_sp_wf (clk, we, en, addr, di, dout);
  input clk;
  input we;
  input en;
  input [9:0] addr;
  input [31:0] di;
  output [31:0] dout;
  reg [31:0] RAM [1023:0];
  reg [31:0] dout;

  always @(posedge clk) begin
    if (en) begin
      if (we) begin
        RAM[addr] <= di;
        dout <= di;
      end
    else
      dout <= RAM[addr];
    end
  end
endmodule
`default_nettype none
`endif
