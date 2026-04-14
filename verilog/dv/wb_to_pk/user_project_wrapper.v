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

localparam integer NUM_ADDRS = 1;

wire [31:0] wbs_datN_o [NUM_ADDRS-1:0];
wire wbs_ackN_o [NUM_ADDRS-1:0];
reg wbs_stbN_i [NUM_ADDRS-1:0];

`define address_map(n, address, mask)      \
  if ((wbs_adr_i & mask) == address) begin \
      wbs_dat_s = wbs_datN_o[n];          \
      wbs_ack_s = wbs_ackN_o[n];          \
      wbs_stbN_i[n] = wbs_stb_i;          \
  end

always @* begin
    wbs_dat_s = 0;
    wbs_ack_s = 0;
    wbs_stbN_i[0] = 0;                      

    // Add entries here to allocate more address ranges
    `address_map(0, 32'h30123000, 32'hFFFFF000);
end


  wire [`BUS_MIPORT] mportai;
  wire  [`BUS_MOPORT] mportao;

  wire [`BUS_SIPORT] sportai;
  wire [`BUS_SOPORT] sportao;


wb_to_pk_m my_wb_to_pk (
    .wb_clk_i(wb_clk_i),            // clock
    .wb_rst_i(wb_rst_i),            // Reset
    .wbs_stb_i(wbs_stbN_i[0]),           // Cycle strobe (asserts when ready to trasnsfer data)
    .wbs_cyc_i(wbs_cyc_i),           // cycle in progress (transfer)
    .wbs_sel_i(wbs_sel_i),           
    .wbs_ack_o(wbs_ackN_o[0]),           // acknowledge (asserted indicates termination of cycle)
    .wbs_dat_i(wbs_dat_i),    // data in 
    .wbs_adr_i(wbs_adr_i),    // address
    .wbs_dat_o(wbs_datN_o[0]),    // data out
    .wbs_we_i(wbs_we_i),           // write en 

    .mport_i(mportai),
    .mport_o(mportao)
);


 busarb_m #(1, 1, 1) arbiter (
      .clk_i(wb_clk_i),
      .nrst_i(!wb_rst_i),

      .mports_i({ mportao }),
      .mports_o({ mportai }),

      .sports_i({ sportao }),
      .sports_o({ sportai })
  );

  wire spi_clk1;
  wire spi_cs1;
  wire [3:0] spi_mosi1;
  wire [3:0] spi_miso1;
  wire spi_dqsmi1;
  wire spi_dqsmo1;

  spi_mem_m #(0, 4096) spi_mem1(
      .clk_i(wb_clk_i),
      .nrst_i(!wb_rst_i),

      .sport_i({ sportai }),
      .sport_o({ sportao }),

      .spi_clk_o(spi_clk1),
      .spi_cs_o(spi_cs1),
      .spi_mosi_o(spi_mosi1),
      .spi_miso_i(spi_miso1),
      .spi_dqsm_i(spi_dqsmi1),
      .spi_dqsm_o(spi_dqsmo1)
  );

    spi_chip_m #(4096) spi_chip1(
      .clk_i(spi_clk1),
      .cs_i(spi_cs1),
      .mosi_i(spi_mosi1),
      .miso_o(spi_miso1),
      .dqsm_o(spi_dqsmi1),
      .dqsm_i(spi_dqsmo1)
  );

// ---- Set pin directions ----

// Everything unused
assign io_oeb[`MPRJ_IO_PADS-1:0] = {`MPRJ_IO_PADS{1'b1}};

assign io_out[`MPRJ_IO_PADS-1:0] = 0;

assign la_data_out[127:0] = 0; // Internal logic analyzer data output

assign user_irq = 3'b000; // Interrupts, unused


endmodule	// user_project_wrapper

`default_nettype wire
