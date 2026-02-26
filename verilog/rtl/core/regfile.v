/**
*   Generic Register File 
*
*   Can have variable widths/heights. Standard widths is 32 bits, and standard heights are 16 and 48
*   Has a variable base address for regfile concatenation.
*/
module regfile_m #(
    //How many bits are in each regfile entry
    parameter REGFILE_WIDTH         = `WORD_WIDTH,
    //How many entries there are
    parameter REGFILE_HEIGHT        = 16,
    //The first address of the register file
    parameter REGFILE_BASE_ADDR     = 0,
    //Truthy value for creation of a zero register at the maximum address
    parameter HAS_ZERO_REG          = 0,
    //Address space size
    parameter REGFILE_ADDR_SIZE     = $clog2(REGFILE_HEIGHT + REGFILE_BASE_ADDR)
) (
    input wire clk_i,
    input wire nrst_i,

    input wire wr_en_i,
    input wire [REGFILE_ADDR_SIZE - 1:0] wr_addr_i,
    input wire [REGFILE_WIDTH-1:0] wr_data_i,

    input wire [REGFILE_ADDR_SIZE-1:0] r1_addr_i,
    input wire [REGFILE_ADDR_SIZE-1:0] r2_addr_i,
    
    output reg [REGFILE_WIDTH-1:0] r1_data_o,
    output reg [REGFILE_WIDTH-1:0] r2_data_o,

    input wire inbox_write_i,
    input  wire[REGFILE_WIDTH * `CORE_MAILBOX_HEIGHT-1:0] inbox_i,
    output reg[REGFILE_WIDTH * `CORE_MAILBOX_HEIGHT-1:0] outbox_o
);
    localparam REGFILE_HIGHEST_ADDR = REGFILE_HEIGHT + REGFILE_BASE_ADDR - 1;
    reg [REGFILE_WIDTH - 1:0] mem [REGFILE_HIGHEST_ADDR:REGFILE_BASE_ADDR];

    always @(posedge clk_i, negedge nrst_i) begin
        if (!nrst_i) begin : RESET
            integer i;
            for (i = REGFILE_BASE_ADDR; i < REGFILE_HEIGHT + REGFILE_BASE_ADDR; i = i + 1) begin
                mem[i] <= 0;
            end
        end
        else if (clk_i) begin : WRITE
            integer i;
            if(inbox_write_i) begin
                for(i = 0; i < `CORE_MAILBOX_HEIGHT; i = i + 1) begin
                    $display("mem write ");
                    mem[i + 1] <= inbox_i[(i*REGFILE_WIDTH) +: REGFILE_WIDTH];
                end
            end
            else if(wr_en_i) begin
                if(!HAS_ZERO_REG) begin
                    mem[wr_addr_i] <= wr_data_i;
                end
                else if(HAS_ZERO_REG) begin
                    mem[wr_addr_i] <= (wr_addr_i == REGFILE_HIGHEST_ADDR ? 0 : wr_data_i);
                end
            end
        end
    end

    always @(*) begin : READ
        integer i;
        //Forwards data if current write = current read address
        if(!HAS_ZERO_REG) begin
            r1_data_o = ((r1_addr_i == wr_addr_i) && wr_en_i) ? wr_data_i : mem[r1_addr_i];
            r2_data_o = ((r2_addr_i == wr_addr_i) && wr_en_i) ? wr_data_i : mem[r2_addr_i];
        end else begin
            r1_data_o = ((r1_addr_i == wr_addr_i) && wr_en_i && (wr_addr_i != REGFILE_HIGHEST_ADDR)) ? wr_data_i : mem[r1_addr_i];
            r2_data_o = ((r2_addr_i == wr_addr_i) && wr_en_i && (wr_addr_i != REGFILE_HIGHEST_ADDR)) ? wr_data_i : mem[r2_addr_i];

        end

        for(i = 0; i < `CORE_MAILBOX_HEIGHT; i = i + 1) begin
            outbox_o[i*REGFILE_WIDTH +: REGFILE_WIDTH] = {mem[i + 1]};
        end
    end

endmodule
