/*
 * Simulated PKBus master.
 */
module bus_master_m #(
    parameter SIZE_BYTES = 1024
)(
    input wire clk_i,
    input wire nrst_i,

    input  wire [`BUS_MIPORT] mport_i,
    output reg  [`BUS_MOPORT] mport_o
);

    reg [7:0] mem [SIZE_BYTES-1:0];
    wire [`WORD] data_in = mport_i[`BUS_MI_DATA];

    integer i;

    initial begin

        mport_o = 0;
        for (i = 0; i < SIZE_BYTES; i++)
            mem[i] <= 0;
    end

    task WRITE_BYTE;
        input [`BUS_ADDR_PORT] addr;
        input [7:0] data;
    begin
        wait(!clk_i);

        mport_o[`BUS_MO_ADDR] = addr;
        mport_o[`BUS_MO_DATA] = data;
        mport_o[`BUS_MO_SIZE] = `BUS_SIZE_BYTE;
        mport_o[`BUS_MO_RW]   = `BUS_WRITE;
        mport_o[`BUS_MO_REQ]  = 1;

        wait(mport_i[`BUS_MI_ACK]);
        wait(!mport_i[`BUS_MI_ACK]);

        mport_o[`BUS_MO_REQ]  = 0;

        wait(!clk_i);
        wait(clk_i);
    end
    endtask

    task WRITE_WORD;
        input [`BUS_ADDR_PORT] addr;
        input [31:0] data;
    begin
        wait(!clk_i);

        mport_o[`BUS_MO_ADDR] = addr;
        mport_o[`BUS_MO_DATA] = data;
        mport_o[`BUS_MO_SIZE] = `BUS_SIZE_WORD;
        mport_o[`BUS_MO_RW]   = `BUS_WRITE;
        mport_o[`BUS_MO_REQ]  = 1;

        wait(mport_i[`BUS_MI_ACK]);
        wait(!mport_i[`BUS_MI_ACK]);

        mport_o[`BUS_MO_REQ]  = 0;

        wait(!clk_i);
        wait(clk_i);
    end
    endtask

    task WRITE_STREAM;
        input [`BUS_ADDR_PORT] addr;
        input [`BUS_ADDR_PORT] size; // words
        input [31:0] data;

        integer i;
    begin
        wait(!clk_i);

        mport_o[`BUS_MO_ADDR] = addr;
        mport_o[`BUS_MO_DATA] = data;
        mport_o[`BUS_MO_SIZE] = `BUS_SIZE_STREAM;
        mport_o[`BUS_MO_RW]   = `BUS_WRITE;
        mport_o[`BUS_MO_REQ]  = 1;

        wait(mport_i[`BUS_MI_ACK]);

        for (i = 0; i < size; i = i + 1) begin
            wait(mport_i[`BUS_MI_SEQSLV]);
            wait(!mport_i[`BUS_MI_SEQSLV]);
        end

        mport_o[`BUS_MO_SEQMST]  = 1;

        wait(!mport_i[`BUS_MI_ACK]);

        mport_o[`BUS_MO_REQ]  = 0;
        mport_o[`BUS_MO_SEQMST]  = 0;

        wait(!clk_i);
        wait(clk_i);
    end
    endtask

    task READ_BYTE;
        input [`BUS_ADDR_PORT] addr;
        output [7:0] data;
    begin
        wait(!clk_i);

        mport_o[`BUS_MO_ADDR] = addr;
        mport_o[`BUS_MO_SIZE] = `BUS_SIZE_BYTE;
        mport_o[`BUS_MO_RW]   = `BUS_READ;
        mport_o[`BUS_MO_REQ]  = 1;

        wait(mport_i[`BUS_MI_ACK]);
        wait(!mport_i[`BUS_MI_ACK]);

        data = mport_i[`BUS_MI_DATA];

        mport_o[`BUS_MO_REQ]  = 0;

        wait(!clk_i);
        wait(clk_i);
    end
    endtask

    task READ_WORD;
        input [`BUS_ADDR_PORT] addr;
        output [31:0] data;
    begin
        wait(!clk_i);

        mport_o[`BUS_MO_ADDR] = addr;
        mport_o[`BUS_MO_SIZE] = `BUS_SIZE_WORD;
        mport_o[`BUS_MO_RW]   = `BUS_READ;
        mport_o[`BUS_MO_REQ]  = 1;

        wait(mport_i[`BUS_MI_ACK]);
        wait(!mport_i[`BUS_MI_ACK]);

        data = mport_i[`BUS_MI_DATA];

        mport_o[`BUS_MO_REQ]  = 0;

        wait(!clk_i);
        wait(clk_i);
    end
    endtask

    task READ_STREAM;
        input [`BUS_ADDR_PORT] addr;
        input [`BUS_ADDR_PORT] size; // words

        integer i;
    begin
        wait(!clk_i);

        mport_o[`BUS_MO_ADDR] = addr;
        mport_o[`BUS_MO_SIZE] = `BUS_SIZE_STREAM;
        mport_o[`BUS_MO_RW]   = `BUS_READ;
        mport_o[`BUS_MO_REQ]  = 1;

        wait(mport_i[`BUS_MI_ACK]);

        for (i = 0; i < size - 1; i = i + 1) begin
            wait(mport_i[`BUS_MI_SEQSLV]);
            wait(!mport_i[`BUS_MI_SEQSLV]);

            mem[i*4 + 0] = data_in[ 7: 0];
            mem[i*4 + 1] = data_in[15: 8];
            mem[i*4 + 2] = data_in[23:16];
            mem[i*4 + 3] = data_in[31:24];
            // $display("GOT DATA: 0x%h", mport_i[`BUS_MI_DATA]);
        end

        mport_o[`BUS_MO_SEQMST]  = 1;

        wait(!mport_i[`BUS_MI_ACK]);

        mem[(size-1)*4 + 0] = data_in[ 7: 0];
        mem[(size-1)*4 + 1] = data_in[15: 8];
        mem[(size-1)*4 + 2] = data_in[23:16];
        mem[(size-1)*4 + 3] = data_in[31:24];
        // $display("GOT DATA: 0x%h", mport_i[`BUS_MI_DATA]);

        mport_o[`BUS_MO_REQ]  = 0;
        mport_o[`BUS_MO_SEQMST]  = 0;

        wait(!clk_i);
        wait(clk_i);
    end
    endtask

endmodule
