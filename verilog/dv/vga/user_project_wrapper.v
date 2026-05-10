`default_nettype none

/*
    Sample user project wrapper implementation for
    the vga module. DOES NOT RUN during rtl testing
    or fpga testing.
*/
module user_project_wrapper #(
    parameter BITS = 32
) (
`ifdef USE_POWER_PINS
    inout vdda1,	// User area 1 3.3V supply
    inout vdda2,	// User area 2 3.3V supply
    inout vssa1,	// User area 1 analog ground
    inout vssa2,	// User area 2 analog ground
    inout vccd1,	// User area 1 1.8V supply
    inout vccd2,	// User area 2 1.8v supply
    inout vssd1,	// User area 1 digital ground
    inout vssd2,	// User area 2 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // Analog (direct connection to GPIO pad---use with caution)
    // Note that analog I/O is not available on the 7 lowest-numbered
    // GPIO pads, and so the analog_io indexing is offset from the
    // GPIO indexing by 7 (also upper 2 GPIOs do not have analog_io).
    inout [`MPRJ_IO_PADS-10:0] analog_io,

    // Independent clock (on independent integer divider)
    input   user_clock2,

    // User maskable interrupt signals
    output [2:0] user_irq
);

assign wbs_ack_o = 0;
assign wbs_dat_o = 0;

reg [`BUS_MIPORT] mportai;
wire  [`BUS_MOPORT] mportao;

always @ (*) begin
  mportai[`BUS_MI_SEQSLV] = 1;
  mportai[`BUS_MI_DATA] = 32'hE0E0E0E0; // Green on every pixel, 0bRRRGGGBB
end

// ---- Instantiate DUT ----

reg [7:0] enable_delay;
wire enable;

always @(posedge wb_clk_i or posedge wb_rst_i)
    if (wb_rst_i)
        enable_delay <= 0;
    else if (wb_clk_i && enable_delay != 200)
        enable_delay <= enable_delay + 1;
assign enable = enable_delay > 150;

vga_m #(0, 0) my_vga (
  .clk_i(wb_clk_i),
  .nrst_i(!wb_rst_i),
  .enable_i(enable),
  .prescaler_i(4),
  .resolution_i(`VGA_RES_320x240),
  .base_h_active_i(`VGA_BASE_H_ACTIVE),
  .base_h_fporch_i(`VGA_BASE_H_FPORCH),
  .base_h_sync_i(`VGA_BASE_H_SYNC),
  .base_h_bporch_i(`VGA_BASE_H_BPORCH),
  .base_v_active_i(`VGA_BASE_V_ACTIVE),
  .base_v_fporch_i(`VGA_BASE_V_FPORCH),
  .base_v_sync_i(`VGA_BASE_V_SYNC),
  .base_v_bporch_i(`VGA_BASE_V_BPORCH),
  .mport_i(mportai),
  .mport_o(mportao),
  .fb_i(0),
  .pixel_o({io_out[26], io_out[25], io_out[24],
            io_out[30], io_out[29], io_out[28],
            io_out[31], io_out[27]}), // Remap standard 8 bit color to the correct IO
  .hsync_o(io_out[23]),
  .vsync_o(io_out[22])
);

// debug
assign io_oeb[21] = 0;
assign io_out[21] = my_vga.base_h_counter == 0 || my_vga.base_h_counter == (`VGA_BASE_H_ACTIVE + `VGA_BASE_H_FPORCH);
assign io_oeb[20] = 0;
assign io_out[20] = my_vga.base_v_counter == 0 || my_vga.base_v_counter == (`VGA_BASE_V_ACTIVE + `VGA_BASE_V_FPORCH);

// ---- Set pin directions ----

// IO output enable, output = low
assign io_oeb[`MPRJ_IO_PADS-1:32] = {`MPRJ_IO_PADS-32{1'b1}};
assign io_oeb[31:22] = 0;
assign io_oeb[19:0] = {20{1'b1}};

// IO output (pins 31-23 passed to VGA above)
assign io_out[`MPRJ_IO_PADS-1:32] = 0;
assign io_out[19:0] = 0;

assign la_data_out[127:0] = 0; // Internal logic analyzer data output

assign user_irq = 3'b000; // Interrupts, unused


endmodule	// user_project_wrapper

`default_nettype wire
