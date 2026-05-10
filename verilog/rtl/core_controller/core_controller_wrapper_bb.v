module core_controller_wrapper_m(
`ifdef USE_POWER_PINS
    inout wire vccd1,
    inout wire vssd1,
`endif

    // Wishbone (common)
    input wire wb_clk_i,
    input wire wb_rst_i,
    input wire wbs_cyc_i,
    input wire wbs_we_i,
    input wire [3:0] wbs_sel_i,
    input wire [31:0] wbs_dat_i,
    input wire [31:0] wbs_adr_i,

    // Wishbone (control registers)
    input wire wbs_stb_control_i,
    output reg wbs_ack_control_o,
    output reg [31:0] wbs_dat_control_o,

    // Wishbone (IMEM)
    input  wire wbs_stb_imem_i,
    output wire wbs_ack_imem_o,
    output wire [31:0] wbs_dat_imem_o,

    // IRQs
    output wire irq_jobdone_o,
    output wire irq_batchdone_o,

    // PKBus
    input  wire [33:0] mport_i,
    output wire [68:0] mport_o,

    // Shaded vertex cache
    output wire [31:0] vertcache_test_index_o,
    output wire         vertcache_test_valid_o,
    input  wire         vertcache_test_found_i,
    output wire         vertcache_clear_o,

    // Vertex order buffer
    input  wire [0:0] vertorder_mstream_i,
    output wire [3:0] vertorder_mstream_o,
    input  wire                                       vertorder_full_i,
    input  wire                                       vertorder_empty_i,
    output wire                                       vertorder_clear_o,

    // Vertex reorder controller
    input wire vertcont_busy_i,

    // index buffer
    input  wire [0:0] index_mstream_i,
    output wire [33:0] index_mstream_o,

    // Rasterizer fragment output FIFO
    input  wire fragfifo_full_i,
    input  wire fragfifo_empty_i,
    output wire fragfifo_clear_o,

    // Rasterizer
    input wire rast_busy_i,

    // Shader core interface
    output wire [31:0]           inst_o,
    output wire [2:0]  core_reset_o,         // Core soft reset
    output wire [2:0]  core_reset_mailbox_o, // Core mailbox soft reset
    input  wire [2:0]  core_stall_i,
    output wire [2:0]  core_stall_o,         // Per-core stall control
    input  wire [2:0]  core_jump_i,
    output wire                   core_jump_o,          // Flushes decode on all cores
    output wire [31:0]           global_regfile_rs1_data_o,
    output wire [31:0]           global_regfile_rs2_data_o,

    input  wire [2:0] core_inbox_mstream_i,
    input  wire [2:0] core_outbox_mstream_valid_i
);
endmodule

