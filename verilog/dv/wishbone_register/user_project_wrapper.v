`default_nettype none

module user_project_wrapper #(
    /* verilator lint_off UNUSEDPARAM */
    parameter BITS = 32
    /* verilator lint_on UNUSEDPARAM */
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

    /* verilator lint_off UNUSEDSIGNAL */
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
    /* verilator lint_on UNUSEDSIGNAL */
);

/*--------------------------------------*/
/* User project is instantiated  here   */
/*--------------------------------------*/

reg [31:0] wbs_dat_s; // Override prior definitions and make these regs.
reg wbs_ack_s;

assign wbs_dat_o = wbs_dat_s;
assign wbs_ack_o = wbs_ack_s;

wire oe_enable_s;

localparam integer NUM_ADDRS = 9;

wire [31:0] wbs_datN_o [NUM_ADDRS:0];
wire wbs_ackN_o [NUM_ADDRS-1:0];
reg wbs_stbN_i [NUM_ADDRS-1:0];

`define address_map(n, address, mask)      \
  wbs_stbN_i[n] = 0;                      \
  if ((wbs_adr_i & mask) == address) begin \
      wbs_dat_s = wbs_datN_o[n];          \
      wbs_ack_s = wbs_ackN_o[n];          \
      wbs_stbN_i[n] = wbs_stb_i;          \
  end

always @* begin
    wbs_dat_s = 0;
    wbs_ack_s = 0;

    // Add entries here to allocate more address ranges
    `address_map(0, 32'h30123400, 32'hFFFFFFF0);
    `address_map(1, 32'h30123500, 32'hFFFFFFF0);
    `address_map(2, 32'h30123600, 32'hFFFFFFF0);
    `address_map(3, 32'h30123700, 32'hFFFFFFF0);
    `address_map(4, 32'h30123800, 32'hFFFFFFF0);
    `address_map(5, 32'h30123900, 32'hFFFFFFF0);
    `address_map(6, 32'h30123A00, 32'hFFFFFFF0);
    `address_map(7, 32'h30123B00, 32'hFFFFFFF0);
    `address_map(8, 32'h30123C00, 32'hFFFFFFF0);
end

// Baseline
wire [31:0] reg0_data;
wishbone_register_m #(32'h01010101, 1, `WBREG_TYPE_REG) reg0 (
    .wb_clk_i(wb_clk_i),
    .wb_rst_i(wb_rst_i),
    .wbs_stb_i(wbs_stbN_i[0]),
    .wbs_cyc_i(wbs_cyc_i),
    .wbs_we_i(wbs_we_i),
    .wbs_sel_i(wbs_sel_i),
    .wbs_dat_i(wbs_dat_i),
    .wbs_adr_i(wbs_adr_i),
    .wbs_ack_o(wbs_ackN_o[0]),
    .wbs_dat_o(wbs_datN_o[0]),

    .access_read_mask_i(32'hFFFFFFFF),
    .access_write_mask_i(32'hFFFFFFFF),
    .periph_read_mask_i(32'h00000000),

    .enable_prot_i(0),
    .enable_i(0),

    .reg_i(0),
    .reg_o(reg0_data)
);

// Write mask
wire [31:0] reg1_data;
wishbone_register_m #(32'h01010101, 1, `WBREG_TYPE_REG) reg1 (
    .wb_clk_i(wb_clk_i),
    .wb_rst_i(wb_rst_i),
    .wbs_stb_i(wbs_stbN_i[1]),
    .wbs_cyc_i(wbs_cyc_i),
    .wbs_we_i(wbs_we_i),
    .wbs_sel_i(wbs_sel_i),
    .wbs_dat_i(wbs_dat_i),
    .wbs_adr_i(wbs_adr_i),
    .wbs_ack_o(wbs_ackN_o[1]),
    .wbs_dat_o(wbs_datN_o[1]),

    .enable_prot_i(0),
    .enable_i(0),

    .access_read_mask_i(32'hFFFFFFFF),
    .access_write_mask_i(32'hFFFF0000),
    .periph_read_mask_i(32'h00000000),
    .reg_i(0),
    .reg_o(reg1_data)
);

// Read mask
wire [31:0] reg2_data;
wishbone_register_m #(32'h01010101, 1, `WBREG_TYPE_REG) reg2 (
    .wb_clk_i(wb_clk_i),
    .wb_rst_i(wb_rst_i),
    .wbs_stb_i(wbs_stbN_i[2]),
    .wbs_cyc_i(wbs_cyc_i),
    .wbs_we_i(wbs_we_i),
    .wbs_sel_i(wbs_sel_i),
    .wbs_dat_i(wbs_dat_i),
    .wbs_adr_i(wbs_adr_i),
    .wbs_ack_o(wbs_ackN_o[2]),
    .wbs_dat_o(wbs_datN_o[2]),

    .enable_prot_i(0),
    .enable_i(0),

    .access_read_mask_i(32'h0000FFFF),
    .access_write_mask_i(32'hFFFFFFFF),
    .periph_read_mask_i(32'h00000000),
    .reg_i(0),
    .reg_o(reg2_data)
);

// Write 1 to clear
wire [31:0] reg3_data;
wishbone_register_m #(32'h01010101, 1, `WBREG_TYPE_W1C) reg3 (
    .wb_clk_i(wb_clk_i),
    .wb_rst_i(wb_rst_i),
    .wbs_stb_i(wbs_stbN_i[3]),
    .wbs_cyc_i(wbs_cyc_i),
    .wbs_we_i(wbs_we_i),
    .wbs_sel_i(wbs_sel_i),
    .wbs_dat_i(wbs_dat_i),
    .wbs_adr_i(wbs_adr_i),
    .wbs_ack_o(wbs_ackN_o[3]),
    .wbs_dat_o(wbs_datN_o[3]),

    .enable_prot_i(0),
    .enable_i(0),

    .access_read_mask_i(32'hFFFFFFFF),
    .access_write_mask_i(32'hFFFFFFFF),
    .periph_read_mask_i(32'h00000000),
    .reg_i(0),
    .reg_o(reg3_data)
);

// Write 1 to set
wire [31:0] reg4_data;
wishbone_register_m #(32'h01010101, 1, `WBREG_TYPE_W1S) reg4 (
    .wb_clk_i(wb_clk_i),
    .wb_rst_i(wb_rst_i),
    .wbs_stb_i(wbs_stbN_i[4]),
    .wbs_cyc_i(wbs_cyc_i),
    .wbs_we_i(wbs_we_i),
    .wbs_sel_i(wbs_sel_i),
    .wbs_dat_i(wbs_dat_i),
    .wbs_adr_i(wbs_adr_i),
    .wbs_ack_o(wbs_ackN_o[4]),
    .wbs_dat_o(wbs_datN_o[4]),

    .enable_prot_i(0),
    .enable_i(0),

    .access_read_mask_i(32'hFFFFFFFF),
    .access_write_mask_i(32'hFFFFFFFF),
    .periph_read_mask_i(32'h00000000),
    .reg_i(0),
    .reg_o(reg4_data)
);

// Write 1 to toggle
wire [31:0] reg5_data;
wishbone_register_m #(32'h01010101, 1, `WBREG_TYPE_W1T) reg5 (
    .wb_clk_i(wb_clk_i),
    .wb_rst_i(wb_rst_i),
    .wbs_stb_i(wbs_stbN_i[5]),
    .wbs_cyc_i(wbs_cyc_i),
    .wbs_we_i(wbs_we_i),
    .wbs_sel_i(wbs_sel_i),
    .wbs_dat_i(wbs_dat_i),
    .wbs_adr_i(wbs_adr_i),
    .wbs_ack_o(wbs_ackN_o[5]),
    .wbs_dat_o(wbs_datN_o[5]),

    .enable_prot_i(0),
    .enable_i(0),

    .access_read_mask_i(32'hFFFFFFFF),
    .access_write_mask_i(32'hFFFFFFFF),
    .periph_read_mask_i(32'h00000000),
    .reg_i(0),
    .reg_o(reg5_data)
);

// Multi-word reg: address masking handled by address map above.
wire [`WORD_WIDTH*4-1:0] reg6_data;
wishbone_register_m #({32'h03030303, 32'h02020202, 32'h10101010, 32'h01010101}, 4, `WBREG_TYPE_REG, 32'h30123A00) reg6 (
    .wb_clk_i(wb_clk_i),
    .wb_rst_i(wb_rst_i),
    .wbs_stb_i(wbs_stbN_i[6]),
    .wbs_cyc_i(wbs_cyc_i),
    .wbs_we_i(wbs_we_i),
    .wbs_sel_i(wbs_sel_i),
    .wbs_dat_i(wbs_dat_i),
    .wbs_adr_i(wbs_adr_i),
    .wbs_ack_o(wbs_ackN_o[6]),
    .wbs_dat_o(wbs_datN_o[6]),

    .enable_prot_i(0),
    .enable_i(0),

    .access_read_mask_i({128{1'b1}}),
    .access_write_mask_i({128{1'b1}}),
    .periph_read_mask_i({128{1'b0}}),
    .reg_i(128'h0),
    .reg_o(reg6_data)
);

// Read from peripheral's reg
reg [31:0] reg7_data;
always @(posedge wb_rst_i)
  reg7_data <= 32'h01010101;
wishbone_register_m #(0, 1, `WBREG_TYPE_REG) reg7 (
    .wb_clk_i(wb_clk_i),
    .wb_rst_i(wb_rst_i),
    .wbs_stb_i(wbs_stbN_i[7]),
    .wbs_cyc_i(wbs_cyc_i),
    .wbs_we_i(wbs_we_i),
    .wbs_sel_i(wbs_sel_i),
    .wbs_dat_i(wbs_dat_i),
    .wbs_adr_i(wbs_adr_i),
    .wbs_ack_o(wbs_ackN_o[7]),
    .wbs_dat_o(wbs_datN_o[7]),

    .enable_prot_i(0),
    .enable_i(0),

    .access_read_mask_i(32'hFFFFFFFF),
    .access_write_mask_i(0),
    .periph_read_mask_i(32'hFFFFFFFF),
    .reg_i(reg7_data),
    .reg_o()
);

// Enable-protection
wire [31:0] reg8_data;
wishbone_register_m #(32'h01010101, 1, `WBREG_TYPE_REG) reg8 (
    .wb_clk_i(wb_clk_i),
    .wb_rst_i(wb_rst_i),
    .wbs_stb_i(wbs_stbN_i[8]),
    .wbs_cyc_i(wbs_cyc_i),
    .wbs_we_i(wbs_we_i),
    .wbs_sel_i(wbs_sel_i),
    .wbs_dat_i(wbs_dat_i),
    .wbs_adr_i(wbs_adr_i),
    .wbs_ack_o(wbs_ackN_o[8]),
    .wbs_dat_o(wbs_datN_o[8]),

    .enable_prot_i(32'hFFFFFFFE),
    .enable_i(reg8_data[0]),

    .access_read_mask_i(32'hFFFFFFFF),
    .access_write_mask_i(32'hFFFFFFFF),
    .periph_read_mask_i(0),
    .reg_i(0),
    .reg_o(reg8_data)
);

// ---- Set pin directions ----

// Everything unused
assign io_oeb[`MPRJ_IO_PADS-1:0] = {`MPRJ_IO_PADS{1'b1}};

assign io_out[`MPRJ_IO_PADS-1:0] = 0;

assign la_data_out[127:0] = 0; // Internal logic analyzer data output

assign user_irq = 3'b000; // Interrupts, unused


endmodule	// user_project_wrapper

`default_nettype wire
