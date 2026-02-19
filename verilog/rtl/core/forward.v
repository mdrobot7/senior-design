/*
    signals to forward data to the ex stage
    only works for forwarding ALU ops right now

    should modify signal before pc/imm muxes

*/

module forward_m(
    input wire[`REG_SOURCE_WIDTH-1:0] ex_r1_addr,
    input wire[`REG_SOURCE_WIDTH-1:0] ex_r2_addr,

    input wire[`REG_SOURCE_WIDTH-1:0] wb_dest_addr,
    input wire[`WORD_WIDTH-1:0] wb_data,
    input wire wb_reg_wr,

    input wire[`REG_SOURCE_WIDTH-1:0] mem_dest_addr,
    input wire[`WORD_WIDTH-1:0] mem_data,
    input wire mem_reg_wr,
    input wire[`WB_SIG_WIDTH-1:0] mem_wb_sig,

    output reg fwd_a_en_o,
    output reg [`WORD_WIDTH-1:0] fwd_a_data_o,
    output reg fwd_b_en_o,
    output reg [`WORD_WIDTH-1:0] fwd_b_data_o
);

always@(*) begin

    //mem gets priority over ex
    if((mem_wb_sig == `WB_EX_RESULT) && (mem_reg_wr == 1) && (ex_r1_addr == mem_dest_addr)) begin
        fwd_a_en_o = 1;
        fwd_a_data_o = mem_data;
    end else if((wb_reg_wr == 1) && (ex_r1_addr == wb_dest_addr)) begin
        fwd_a_en_o = 1;
        fwd_a_data_o = wb_data;
    end else begin
        fwd_a_en_o = 0;
        fwd_a_data_o = wb_data;
    end

    //mem gets priority over ex
    if((mem_wb_sig == `WB_EX_RESULT) && (mem_reg_wr == 1) && (ex_r2_addr == mem_dest_addr)) begin
        fwd_b_en_o = 1;
        fwd_b_data_o = mem_data;
    end else if((wb_reg_wr == 1) && (ex_r2_addr == wb_dest_addr)) begin
        fwd_b_en_o = 1;
        fwd_b_data_o = wb_data;
    end else begin
        fwd_b_en_o = 0;
        fwd_b_data_o = wb_data;
    end

end

endmodule