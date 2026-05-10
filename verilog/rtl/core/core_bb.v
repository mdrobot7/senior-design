module core_m(
    input  wire clk_i,
    input  wire nrst_i,
    input  wire[31:0] inst_i,
    input  wire[31:0] global_r1_data_i,
    input  wire[31:0] global_r2_data_i,

    output wire jump_request_o,
    input  wire flush_dec_stage_i,
    input  wire stall_i,
    output reg stall_o,
    input  wire nsync_rst_i,
    input  wire nsync_rst_mailbox_i,

    input  wire [33:0] inbox_sstream_i,
    output wire [0:0] inbox_sstream_o,

    input  wire [0:0] outbox_mstream_i,
    output wire [33:0] outbox_mstream_o,

    input  wire [33:0] mport_i,
    output reg  [68:0] mport_o,

    input wire [31:0] SP_i
);
endmodule

