/**
*   Global register file.
*
* 48 word-width registers, indexed r16-r63. r63 is a 0 register,
* always returning 0 when read.
*/
module global_regfile_m (
    input wire clk_i,
    input wire nrst_i,

    input wire wr_en_i,
    input wire [`REG_SOURCE_WIDTH-1:0] wr_addr_i,
    input wire [`WORD] wr_data_i,

    input wire [`REG_SOURCE_WIDTH-1:0] r1_addr_i,
    input wire [`REG_SOURCE_WIDTH-1:0] r2_addr_i,

    output reg [`WORD] r1_data_o,
    output reg [`WORD] r2_data_o
);
    localparam HIGHEST_ADDR = `NUM_LOCAL_REGS + `NUM_GLOBAL_REGS;
    reg [`WORD] mem [HIGHEST_ADDR-1:`NUM_LOCAL_REGS];

    always @(posedge clk_i, negedge nrst_i) begin
        if (!nrst_i) begin : RESET
            integer i;
            for (i = `NUM_LOCAL_REGS; i < HIGHEST_ADDR; i = i + 1) begin
                mem[i] <= 0;
            end
        end
        else if (clk_i) begin : WRITE
            if(wr_en_i) begin
                mem[wr_addr_i] <= (wr_addr_i == HIGHEST_ADDR-1 ? 0 : wr_data_i);
            end
        end
    end

    always @(*) begin : READ
        if (r1_addr_i >= `NUM_LOCAL_REGS)
          r1_data_o = mem[r1_addr_i];
        else
          r1_data_o = 0;
        if (r2_addr_i >= `NUM_LOCAL_REGS)
          r2_data_o = mem[r2_addr_i];
        else
          r2_data_o = 0;
    end

endmodule
