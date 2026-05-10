`default_nettype none

`timescale 1 ns / 1 ps

module bus_tb();

    reg clk;
    reg nrst;

    initial forever begin
        clk <= 1;
        #10;
        clk <= 0;
        #10;
    end

    wire [`BUS_MIPORT] mportai;
    reg  [`BUS_MOPORT] mportao;
    wire [`BUS_MIPORT] mportbi;
    reg  [`BUS_MOPORT] mportbo;
    wire [`BUS_SIPORT] sportai;
    wire [`BUS_SOPORT] sportao;
    wire [`BUS_SIPORT] sportbi;
    wire [`BUS_SOPORT] sportbo;

    busarb_m #(2, 2, 2) arbiter(
        .clk_i(clk),
        .nrst_i(nrst),

        .mports_i({ mportao, mportbo }),
        .mports_o({ mportai, mportbi }),

        .sports_i({ sportao, sportbo }),
        .sports_o({ sportai, sportbi })
    );

    ram_m #(0, 32) ram1(
        .clk_i(clk),
        .nrst_i(nrst),

        .sport_i(sportai),
        .sport_o(sportao)
    );

    ram_m #(32, 32) ram2(
        .clk_i(clk),
        .nrst_i(nrst),

        .sport_i(sportbi),
        .sport_o(sportbo)
    );

    initial begin
		$dumpfile("bus.vcd");
		$dumpvars(0, bus_tb);

        mportao = 0;
        mportbo = 0;

        nrst = 0;
        #30;
        nrst = 1;
        #30;

        #1000;
        $finish;
    end

    initial begin : MAIN_1
        reg [31:0] read_data;

        #100;

        PORTA_READ(32 + 4, read_data);
        PORTA_READ(4, read_data);
        PORTA_READ(32 + 5, read_data);
        PORTA_READ(5, read_data);
    end

    initial begin : MAIN_2
        reg [31:0] read_data;

        #200;

        PORTB_READ(7, read_data);
        PORTB_READ(32 + 7, read_data);
        PORTB_READ(8, read_data);
        PORTB_READ(32 + 8, read_data);
    end

    task PORTA_READ;
        input  [31:0] addr;
        output [31:0] data;
    begin
        mportao[`BUS_MO_ADDR] = addr;
        mportao[`BUS_MO_RW]   = 0;
        mportao[`BUS_MO_SIZE] = 0;
        mportao[`BUS_MO_REQ]  = 1;

        wait(mportai[`BUS_MI_ACK]);
        wait(!mportai[`BUS_MI_ACK]);
        $display("A READ %0d: %0d", addr, mportai[`BUS_MI_DATA]);

        wait(!clk);
        wait(clk);

        mportao[`BUS_MO_REQ] = 0;

        wait(!clk);
        wait(clk);
    end
    endtask

    task PORTA_WRITE;
        input  [31:0] addr;
        input  [31:0] data;
    begin
        mportao[`BUS_MO_ADDR] = addr;
        mportao[`BUS_MO_DATA] = data;
        mportao[`BUS_MO_RW]   = 1;
        mportao[`BUS_MO_SIZE] = `BUS_SIZE_WORD;
        mportao[`BUS_MO_REQ]  = 1;

        wait(mportai[`BUS_MI_ACK]);
        wait(!mportai[`BUS_MI_ACK]);

        wait(!clk);
        wait(clk);

        mportao[`BUS_MO_REQ] = 0;

        wait(!clk);
        wait(clk);
    end
    endtask

    task PORTB_READ;
        input  [31:0] addr;
        output [31:0] data;
    begin
        mportbo[`BUS_MO_ADDR] = addr;
        mportbo[`BUS_MO_RW]   = 0;
        mportbo[`BUS_MO_SIZE] = 0;
        mportbo[`BUS_MO_REQ]  = 1;

        wait(mportbi[`BUS_MI_ACK]);
        wait(!mportbi[`BUS_MI_ACK]);
        $display("B READ %0d: %0d", addr, mportbi[`BUS_MI_DATA]);

        wait(!clk);
        wait(clk);

        mportbo[`BUS_MO_REQ] = 0;

        wait(!clk);
        wait(clk);
    end
    endtask

endmodule
