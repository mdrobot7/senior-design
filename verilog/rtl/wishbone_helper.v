/**
 * See wishbone_adder.v for example usage
 *
 *      **** ALL ADDRESSES MUST SATISFY ADDR % 4 == 0. *****
 *
 * This module simplifies checking if a write is happening on the wishbone bus.
 *
 * Note: This will only raise we if it is a 32-bit write (sel_i = 0xF), so 
 * 8 and 16-byte transactions are ignored.
 *
 * If you try to write to an address that ends in hex 1, 2, or 3, it will be ignored.
 *
 * Also, there is a bug in the management core where if wbs_ack_o is 1 in the same
 * cycle a read transaction begins, the management core reads incorrect data from the
 * last accessed address. This also delays the ack signal by 1 for read and write 
 * transactions.
 *
 * Also note that wbs_adr_i will always be a multiple of 4. Single-byte or half-word 
 * reads are done by reading the word, then masking and shifting.
 */

`default_nettype wire
module wishbone_helper_m(
  input wire wb_clk_i,
  input wire wbs_we_i,
  input wire wbs_stb_i,
  input wire wbs_cyc_i,
  /* verilator lint_off UNUSEDSIGNAL */
  input wire [3:0] wbs_sel_i,
  /* verilator lint_on UNUSEDSIGNAL */
  output wire wbs_effective_we_o,
  output reg wbs_ack_o
);

  always @(posedge wb_clk_i)
    wbs_ack_o <= wbs_stb_i && wbs_cyc_i && ~wbs_ack_o;

  assign wbs_effective_we_o = wbs_we_i && wbs_stb_i && wbs_cyc_i && wbs_ack_o; //  && wbs_sel_i == 4'b1111 <-- TODO: This does not work. WHY?

endmodule
`default_nettype none
