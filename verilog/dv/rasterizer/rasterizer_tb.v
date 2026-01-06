module rasterizer_tb();

    wire clk, nrst;

    clk_rst_m clk_rst(
        .clk_o(clk),
        .nrst_o(nrst)
    );

    localparam WORD_WIDTH = 32;
    localparam WIDTH = 320;
    localparam HEIGHT = 240;

    localparam SC_WIDTH = $clog2(WIDTH > HEIGHT ? WIDTH : HEIGHT);

    wire [`BUS_MIPORT] mportai;
    wire [`BUS_MOPORT] mportao;
    wire [`BUS_MIPORT] mportbi;
    wire [`BUS_MOPORT] mportbo;
    wire [`BUS_MIPORT] mportci;
    wire [`BUS_MOPORT] mportco;

    wire [`BUS_SIPORT] sportai;
    wire [`BUS_SOPORT] sportao;

    // assign mportbo = mportao;
    // assign mportai = mportbi;

    word_stripe_cache_m #(8, 2) word_cache(
        .clk_i(clk),
        .nrst_i(nrst),

        .cached_mport_i(mportao), 
        .cached_mport_o(mportai),

        .mport_i(mportbi),
        .mport_o(mportbo)
    );

    assign mportco = mportbo;
    assign mportbi = mportci;

    // byte_write_stripe_cache_m #(40) byte_cache(
    //     .clk_i(clk),
    //     .nrst_i(nrst),

    //     .cached_mport_i(mportbo),
    //     .cached_mport_o(mportbi),

    //     .mport_i(mportci),
    //     .mport_o(mportco)
    // );

    busarb_m #(1, 1, 1) arbiter(
        .clk_i(clk),
        .nrst_i(nrst),

        .mports_i({ mportco }),
        .mports_o({ mportci }),

        .sports_i({ sportao }),
        .sports_o({ sportai })
    );

    wire spi_clk;
    wire spi_cs;
    wire [3:0] spi_mosi;
    wire [3:0] spi_miso;
    wire spi_dqsmi;
    wire spi_dqsmo;

    spi_mem_m #(0, 500000) spi_mem(
        .clk_i(clk),
        .nrst_i(nrst),

        .sport_i({ sportai }),
        .sport_o({ sportao }),

        .spi_clk_o(spi_clk),
        .spi_cs_o(spi_cs),
        .spi_mosi_o(spi_mosi),
        .spi_miso_i(spi_miso),
        .spi_dqsm_i(spi_dqsmi),
        .spi_dqsm_o(spi_dqsmo)
    );

    spi_chip_m #(5, 1, 500000) spi_chip(
        .clk_i(spi_clk),
        .cs_i(spi_cs),
        .mosi_i(spi_mosi),
        .miso_o(spi_miso),
        .dqsm_o(spi_dqsmi),
        .dqsm_i(spi_dqsmo)
    );

    reg  run;
    wire busy;
    wire output_ready;
    reg [7:0] color;

    reg [31:0] t0x;
    reg [31:0] t0y;
    reg [31:0] t1x;
    reg [31:0] t1y;
    reg [31:0] t2x;
    reg [31:0] t2y;

    reg [31:0] v0x;
    reg [31:0] v0y;
    reg [31:0] v0z;
    reg [31:0] v1x;
    reg [31:0] v1y;
    reg [31:0] v1z;
    reg [31:0] v2x;
    reg [31:0] v2y;
    reg [31:0] v2z;

    rasterizer_m rasterizer(
        .clk_i(clk),
        .nrst_i(nrst),

        .mport_i({ mportai }),
        .mport_o({ mportao }),

        .run_i(run),
        .busy_o(busy),
        .output_ready_o(output_ready),

        .color_i(color),

        .t0x(t0x),
        .t0y(t0y),
        .t1x(t1x),
        .t1y(t1y),
        .t2x(t2x),
        .t2y(t2y),

        .v0x(v0x),
        .v0y(v0y),
        .v0z(v0z),
        .v1x(v1x),
        .v1y(v1y),
        .v1z(v1z),
        .v2x(v2x),
        .v2y(v2y),
        .v2z(v2z)
    );

    stream_stat_m #(SC_WIDTH * 2) pos_stat(
        .clk_i(clk),

        .mstreami_i(rasterizer.pos_streami),
        .mstreamo_i(rasterizer.pos_streamo)
    );

    stream_stat_m #(SC_WIDTH * 2 + WORD_WIDTH * 3) bary_stat(
        .clk_i(clk),

        .mstreami_i(rasterizer.bary_streami),
        .mstreamo_i(rasterizer.bary_streamo)
    );

    stream_stat_m #(SC_WIDTH * 2 + WORD_WIDTH * 3) filt_bary_stat(
        .clk_i(clk),

        .mstreami_i(rasterizer.filt_bary_streami),
        .mstreamo_i(rasterizer.filt_bary_streamo)
    );

    stream_stat_m #(SC_WIDTH * 2 + WORD_WIDTH * 3) wavg_stat(
        .clk_i(clk),

        .mstreami_i(rasterizer.wavg_streami),
        .mstreamo_i(rasterizer.wavg_streamo)
    );

    stream_stat_m #(SC_WIDTH * 2 + WORD_WIDTH * 3) wavg_fifo_stat(
        .clk_i(clk),

        .mstreami_i(rasterizer.wavg_fifo_streami),
        .mstreamo_i(rasterizer.wavg_fifo_streamo)
    );

    initial begin : MAIN
        integer i, j;
        integer x, y;

		$dumpfile("rasterizer.vcd");
		$dumpvars(0, rasterizer_tb);

        run = 0;

        clk_rst.RESET();

        pos_stat.RESET();
        bary_stat.RESET();
        filt_bary_stat.RESET();
        wavg_stat.RESET();
        wavg_fifo_stat.RESET();

        for (x = 0; x < 320; x = x + 1) begin
            for (y = 0; y < 240; y = y + 1) begin : DB_FILL
                reg [31:0] value;
                value = 32'hFFFFFFFF;

                // if (x % 5 == 4 || y % 5 == 4) begin
                //     value = 32'h80000000;
                // end

                spi_chip.mem[`ADDR_DEPTH_BUFFER + (y * 320 + x) * 4 + 0] = value[7:0];
                spi_chip.mem[`ADDR_DEPTH_BUFFER + (y * 320 + x) * 4 + 1] = value[15:8];
                spi_chip.mem[`ADDR_DEPTH_BUFFER + (y * 320 + x) * 4 + 2] = value[23:16];
                spi_chip.mem[`ADDR_DEPTH_BUFFER + (y * 320 + x) * 4 + 3] = value[31:24];
            end
        end

        for (x = 0; x < 320; x = x + 1) begin
            for (y = 0; y < 240; y = y + 1) begin
                // if (x % 5 == 4 && y % 5 == 4) begin
                //     spi_chip.mem[y * 320 + x] = 8'b00000010;
                // end
                // else if (y % 5 == 4 || x % 5 == 4) begin
                //     spi_chip.mem[y * 320 + x] = 8'b00000001;
                // end
                // else begin : EMPTY_FILL
                //     reg [2:0] r;
                //     reg [2:0] g;
                //     reg [1:0] b;

                //     r = x * 7 / 320;
                //     g = y * 7 / 320;
                //     b = 0;

                //     spi_chip.mem[y * 320 + x] = { b, g, r };
                // end

                spi_chip.mem[y * 320 + x] = 0;
            end
        end

        // run = 0;

        // color <= 8'b00000111;

        // v0x = 0 - 1 << `DECIMAL_POS;
        // v0y = 20 << `DECIMAL_POS;
        // v0z = 2 * 64'h80000000 / 3;
        // t0x = 0;
        // t0y = 0;

        // v1x = 60 << `DECIMAL_POS;
        // v1y = 30 << `DECIMAL_POS;
        // v1z = 1 * 64'h80000000 / 3;
        // t1x = 10;
        // t1y = 0;

        // v2x = 30 << `DECIMAL_POS;
        // v2y = 60 << `DECIMAL_POS;
        // v2z = 1 * 64'h80000000 / 3;
        // t2x = 0;
        // t2y = 10;

        // wait(!clk);
        // run = 1;

        // wait(busy);
        // wait(!busy);
        // run = 0;

        // clk_rst.WAIT_CYCLES(10);

        // color <= 8'b00111000;

        // v0x = 10 << `DECIMAL_POS;
        // v0y = 50 << `DECIMAL_POS;
        // v0z = 1 * 64'h80000000 / 3;
        // t0x = 0;
        // t0y = 0;

        // v1x = 50 << `DECIMAL_POS;
        // v1y = 10 << `DECIMAL_POS;
        // v1z = 1 * 64'h80000000 / 3;
        // t1x = 10;
        // t1y = 0;

        // v2x = 140 << `DECIMAL_POS;
        // v2y = 140 << `DECIMAL_POS;
        // v2z = 2 * 64'h80000000 / 3;
        // t2x = 0;
        // t2y = 10;

        // wait(!clk);
        // run = 1;

        // wait(busy);
        // wait(!busy);
        // run = 0;

        // for (i = 0; i < 10; i = i + 1) begin
        //     wait(clk);
        //     wait(!clk);
        // end

        // for (i = 0; i < 200; i = i + 1) begin
        //     color <= 8'b11000000;

        //     v0x = ((i % 20) * 15) << `DECIMAL_POS;
        //     v0y = (70 + (i / 20) * 15) << `DECIMAL_POS;
        //     v0z = 0;
        //     t0x = 0;
        //     t0y = 0;

        //     v1x = (10 + (i % 20) * 15) << `DECIMAL_POS;
        //     v1y = (70 + (i / 20) * 15) << `DECIMAL_POS;
        //     v1z = 0;
        //     t1x = 10;
        //     t1y = 0;

        //     v2x = ((i % 20) * 15) << `DECIMAL_POS;
        //     v2y = (80 + (i / 20) * 15) << `DECIMAL_POS;
        //     v2z = 0;
        //     t2x = 0;
        //     t2y = 10;

        //     wait(!clk);
        //     run = 1;

        //     wait(busy);
        //     wait(!busy);
        //     run = 0;

        //     for (j = 0; j < 10; j = j + 1) begin
        //         wait(clk);
        //         wait(!clk);
        //     end
        // end

        // for (i = 0; i < 200; i = i + 1) begin
        //     color <= 8'b00111000;

        //     v0x = (5 + (i % 20) * 15) << `DECIMAL_POS;
        //     v0y = (70 + (i / 20) * 15) << `DECIMAL_POS;
        //     v0z = 32'h40000000;
        //     t0x = 0;
        //     t0y = 0;

        //     v1x = (5 + 10 + (i % 20) * 15) << `DECIMAL_POS;
        //     v1y = (70 + (i / 20) * 15) << `DECIMAL_POS;
        //     v1z = 32'h40000000;
        //     t1x = 10;
        //     t1y = 0;

        //     v2x = (5 + (i % 20) * 15) << `DECIMAL_POS;
        //     v2y = (80 + (i / 20) * 15) << `DECIMAL_POS;
        //     v2z = 32'h40000000;
        //     t2x = 0;
        //     t2y = 10;

        //     wait(!clk);
        //     run = 1;

        //     wait(busy);
        //     wait(!busy);
        //     run = 0;

        //     for (j = 0; j < 10; j = j + 1) begin
        //         wait(clk);
        //         wait(!clk);
        //     end
        // end

        // for (i = 0; i < 200; i = i + 1) begin
        //     color <= 8'b00000111;

        //     v0x = (10 + (i % 20) * 15) << `DECIMAL_POS;
        //     v0y = (70 + (i / 20) * 15) << `DECIMAL_POS;
        //     v0z = 32'h40000000;
        //     t0x = 0;
        //     t0y = 0;

        //     v1x = (10 + 10 + (i % 20) * 15) << `DECIMAL_POS;
        //     v1y = (70 + (i / 20) * 15) << `DECIMAL_POS;
        //     v1z = 32'h40000000;
        //     t1x = 10;
        //     t1y = 0;

        //     v2x = (10 + (i % 20) * 15) << `DECIMAL_POS;
        //     v2y = (80 + (i / 20) * 15) << `DECIMAL_POS;
        //     v2z = 32'h40000000;
        //     t2x = 0;
        //     t2y = 10;

        //     wait(!clk);
        //     run = 1;

        //     wait(busy);
        //     wait(!busy);
        //     run = 0;

        //     for (j = 0; j < 10; j = j + 1) begin
        //         wait(clk);
        //         wait(!clk);
        //     end
        // end

        // for (i = 0; i < 10; i = i + 1) begin
        //     wait(clk);
        //     wait(!clk);
        // end












`include "cow_rotate.v"































        clk_rst.WAIT_CYCLES(10);
    
        $display("Elapsed %d clock cycles", clk_rst.current_cycle);
        $display("%d FPS at 10 MHz", 10000000.0 / clk_rst.current_cycle);
        $display("%d FPS at 20 MHz", 20000000.0 / clk_rst.current_cycle);
        $display("%d FPS at 30 MHz", 30000000.0 / clk_rst.current_cycle);
        $display("%d FPS at 40 MHz", 40000000.0 / clk_rst.current_cycle);
        $display("%d FPS at 50 MHz", 50000000.0 / clk_rst.current_cycle);
        $display("%d FPS at 100 MHz", 100000000.0 / clk_rst.current_cycle);

        $display("Pipeline info");

        $display("Pos Stats");
        pos_stat.PRINT_STATS();

        $display("Bary Stats");
        bary_stat.PRINT_STATS();

        $display("Filt Bary Stats");
        filt_bary_stat.PRINT_STATS();

        $display("WAvg Stats");
        wavg_stat.PRINT_STATS();

        $display("WAvg FIFO Stats");
        wavg_fifo_stat.PRINT_STATS();

        $display("Dumping image...");

        `VGA_WRITE("output.bmp", spi_chip.mem, 0, 320, 240, `COLOR_TYPE_RGB332);

        // `VGA_WRITE("depth.bmp", spi_chip.mem, `ADDR_DEPTH_BUFFER, 320, 240, `COLOR_TYPE_GSW);

        $finish;
    end

    initial begin
        #100000000000;
        $finish;
    end

endmodule
