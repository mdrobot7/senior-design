`timescale 1ns/1ps

module spi_chip_m #(
    parameter SIZE = 1024,

    parameter LC = 5,
    parameter PRE_CYCLES = 0,

    parameter tDQSCK_MIN = 2,
    parameter tDQSCK_MAX = 7
) (
    input  wire       clk_i,

    input  wire       cs_i,
    input  wire [3:0] mosi_i,
    output reg  [3:0] miso_o,
    output reg        dqsm_o,
    input  wire       dqsm_i
);

`define tDQSCK (({$random} % (tDQSCK_MAX - tDQSCK_MIN)) + tDQSCK_MIN)

    `DL_DEFINE(logger, "spi_chip_m", `DL_BLUE, 1);
    `DL_DEFINE(error, "spi_chip_m ERROR", `DL_RED, 1);

    localparam CMD_READ  = 8'h0A;
    localparam CMD_WRITE = 8'h02;

    reg [7:0] mem [SIZE - 1:0];

    initial begin : MEM_INIT
        integer i;

        for (i = 0; i < SIZE; i = i + 1) begin
            mem[i] = i;
        end
    end

    reg [7:0] command;

    reg [31:0] full_address;
    wire [24:0] address;
    assign address = {
        full_address[28:16],
        full_address[13:5]
    };

    initial forever begin : MAIN
        integer i;

        integer is_2lc;

        miso_o = 0;
        dqsm_o = 0;

        wait(!cs_i);

        `DL(logger, ("QSPI REQUEST RECEIVED"));

        is_2lc = {$random} % 2 == 1;

        dqsm_o = is_2lc;

        wait(clk_i);
        command[3:0] = mosi_i;
        wait(!clk_i);

        wait(clk_i);
        command[7:4] = mosi_i;
        wait(!clk_i);

        `DL(logger, ("  Command: 0x%h (%s)", command, command == CMD_READ ? "READ" : (command == CMD_WRITE ? "WRITE" : "?????")));

        for (i = 0; i < 4; i = i + 1) begin
            wait(clk_i);
            full_address[28 - (i * 8) +: 4] = mosi_i;
            wait(!clk_i);
            full_address[24 - (i * 8) +: 4] = mosi_i;
        end
        #1;

        `DL(logger, ("  Address: 0x%h", address));

        `DL(logger, ("  2LC access: %s", is_2lc == 1 ? "true" : "false"));

        case (command)
            CMD_WRITE: begin : WRITE
                integer lc_cycles;
                integer offset;

                `DL(logger, ("  Write:"));

                lc_cycles = is_2lc ? (2 * LC - 2) : (LC - 2);
                offset = 0;

                dqsm_o = 1;

                for (i = 0; i < lc_cycles; i = i + 1) begin
                    wait(!clk_i);
                    wait(clk_i);
                end

                wait(!clk_i);

                while (!cs_i) begin
                    wait(clk_i || cs_i);

                    if (!cs_i) begin
                        mem[address + offset][7:4] = mosi_i;

                        wait(!clk_i);

                        mem[address + offset][3:0] = mosi_i;

                        `DL(logger, ("    mem[0x%h] <= 0x%h", address + offset, mem[address + offset]));

                        offset = offset + 1;
                    end
                end
            end

            CMD_READ: begin : READ
                integer lc_cycles;
                integer offset;
                reg [7:0] data;

                `DL(logger, ("  Read:"));

                lc_cycles = is_2lc ? (2 * LC - 2) : (LC - 2);
                offset = 0;

                dqsm_o = 0;

                for (i = 0; i < lc_cycles; i = i + 1) begin
                    wait(!clk_i);
                    wait(clk_i);
                end

                for (i = 0; i < PRE_CYCLES; i = i + 1) begin
                    wait(!clk_i);
                    #`tDQSCK;
                    dqsm_o = 0;

                    wait(clk_i);
                    #`tDQSCK;
                    dqsm_o = 1;
                end

                wait(!clk_i);
                #`tDQSCK;
                dqsm_o = 0;

                while (!cs_i) begin
                    wait(clk_i || cs_i);
                    if (!cs_i) begin
                        data = mem[address + offset];

                        `DL(logger, ("    mem[0x%h] => 0x%h", address + offset, data));

                        #`tDQSCK;
                        dqsm_o = 1;
                        miso_o = data[7:4];

                        wait(!clk_i || cs_i);
                        if (!cs_i) begin
                            #`tDQSCK;
                            dqsm_o = 0;
                            miso_o = data[3:0];
                        end
                    end

                    offset = offset + 1;
                end
            end

            default: begin
                `DL(error, ("INVALID COMMAND RECEIVED! (0x%h)", command));

                $stop;
            end
        endcase
    end

endmodule
