module rasterizer_wrapper_m(
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif

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

    output wire rast_busy_o,

    input  wire [1153:0] sstream_i,
    output reg  [0:0] sstream_o,

    input  wire [0:0] mstream_i,
    output wire [257:0] mstream_o,

    input  wire [33:0] depth_mport_i,
    output wire [68:0] depth_mport_o,

    input  wire [33:0] tex_mport_i,
    output wire [68:0] tex_mport_o
);
endmodule

