/**
*   Generic Register File 
*
*   Can have variable widths/heights. Standard widths is 32 bits, and standard heights are 16 and 48
*   Has a variable base address for regfile concatenation.
*/
module regfile_m #(
    parameter REGFILE_WIDTH         = `WORD_WIDTH,
    parameter REGFILE_HEIGHT        = 16,
    parameter REGFILE_ADDR_SIZE     = $clog2(REGFILE_HEIGHT)
) (
    input wire clk_i,
    input wire nrst_i,

    input wire wr_en_i,
    input wire [REGFILE_ADDR_SIZE - 1:0] wr_addr_i,
    input wire [REGFILE_WIDTH-1:0] wr_data_i,

    input wire [REGFILE_ADDR_SIZE-1:0] r1_addr_i,
    input wire [REGFILE_ADDR_SIZE-1:0] r2_addr_i,
    
    output reg [REGFILE_WIDTH-1:0] r1_data_o,
    output reg [REGFILE_WIDTH-1:0] r2_data_o
);

    reg [REGFILE_WIDTH - 1:0] mem [REGFILE_HEIGHT - 1:0];

    always @(posedge clk_i, negedge nrst_i) begin
        if (!nrst_i) begin : RESET
            integer i;
            for (i = 0; i < REGFILE_HEIGHT; i = i + 1) begin
                mem[i] <= 0;
            end
        end
        else if (wr_en_i) begin : WRITE
            mem[wr_addr_i] <= wr_data_i;
        end
    end

    always @(*) begin : READ
        r1_data_o = mem[r1_addr_i];
        r2_data_o = mem[r2_addr_i];
    end

endmodule
