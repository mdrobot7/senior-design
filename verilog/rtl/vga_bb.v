module vga_wrapper_m (
    // Wishbone
    input wire wb_clk_i,
    input wire wb_rst_i,
    input wire wbs_stb_i,
    input wire wbs_cyc_i,
    input wire wbs_we_i,
    input wire [3:0] wbs_sel_i,
    input wire [31:0] wbs_dat_i,
    input wire [31:0] wbs_adr_i,
    output reg wbs_ack_o,
    output reg [31:0] wbs_dat_o,

    // IRQs
    output reg irq_hblank_o,
    output reg irq_vblank_o,

    // PKBus
    input  wire [33:0] mport_i, // For pixel data only
    output wire [68:0] mport_o,

    // GPIO
    output wire [7:0] pixel_o,
    output wire hsync_o,
    output wire vsync_o
);
endmodule

