/*
* Core register file.
*
* 16 word-width entries, indexed r0-r15. r15 is a
* special register with a different reset value,
* for use as a stack pointer. r15 can be reset
* both synchronously and asynchronously.
*/
module core_regfile_m #(
    parameter SP = 32'h00000000
) (
    input wire clk_i,
    input wire nrst_i,
    input wire nsync_rst_i,

    input wire wr_en_i,
    input wire [`REG_DEST_WIDTH-1:0] wr_addr_i,
    input wire [`WORD] wr_data_i,

    input wire [`REG_DEST_WIDTH-1:0] r1_addr_i,
    input wire [`REG_DEST_WIDTH-1:0] r2_addr_i,

    output reg [`WORD] r1_data_o,
    output reg [`WORD] r2_data_o,

    input  wire inbox_write_i,
    input  wire [`WORD_WIDTH * `CORE_MAILBOX_HEIGHT-1:0] inbox_i,
    output reg  [`WORD_WIDTH * `CORE_MAILBOX_HEIGHT-1:0] outbox_o
);
    reg [`WORD] mem [`NUM_LOCAL_REGS-1:0];

    always @(posedge clk_i, negedge nrst_i) begin
        if (!nrst_i) begin : RESET
            integer i;
            for (i = 0; i < `NUM_LOCAL_REGS; i = i + 1) begin
                mem[i] <= 0;
            end
        end
        else if (clk_i) begin : WRITE
            integer i;
            if(inbox_write_i) begin
                for(i = 0; i < `CORE_MAILBOX_HEIGHT; i = i + 1) begin
                    mem[i + 1] <= inbox_i[(i*`WORD_WIDTH) +: `WORD_WIDTH];
                end
            end
            else if(wr_en_i)
                mem[wr_addr_i] <= wr_data_i;

            if (!nsync_rst_i)
              mem[`NUM_LOCAL_REGS-1] <= SP;
        end
    end

    always @(*) begin : READ
        integer i;
        reg [`WORD] r1_data;
        reg [`WORD] r2_data;

        //Forwards data if current write = current read address
        r1_data = ((r1_addr_i == wr_addr_i) && wr_en_i) ? wr_data_i : mem[r1_addr_i];
        r2_data = ((r2_addr_i == wr_addr_i) && wr_en_i) ? wr_data_i : mem[r2_addr_i];

        r1_data_o = r1_data;
        r2_data_o = r2_data;

        for(i = 0; i < `CORE_MAILBOX_HEIGHT; i = i + 1) begin
            outbox_o[i*`WORD_WIDTH +: `WORD_WIDTH] = {mem[i + 1]};
        end
    end

    wire [31:0] r0, r1, r2, r9;
    assign r0 = mem[0];
    assign r1 = mem[1];
    assign r2 = mem[2];
    assign r9 = mem[9];

endmodule
