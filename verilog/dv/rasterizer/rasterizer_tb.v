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
    wire [`BUS_MIPORT] mportdi;
    wire [`BUS_MOPORT] mportdo;
    wire [`BUS_MIPORT] mportei;
    wire [`BUS_MOPORT] mporteo;

    wire [`BUS_SIPORT] sportai;
    wire [`BUS_SOPORT] sportao;
    wire [`BUS_SIPORT] sportbi;
    wire [`BUS_SOPORT] sportbo;

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

    busarb_m #(3, 1, 1) arbiter(
        .clk_i(clk),
        .nrst_i(nrst),

        .mports_i({ mportco, mportdo, mporteo }),
        .mports_o({ mportci, mportdi, mportei }),

        .sports_i({ sportao }),
        .sports_o({ sportai })
    );

    wire spi_clk1;
    wire spi_cs1;
    wire [3:0] spi_mosi1;
    wire [3:0] spi_miso1;
    wire spi_dqsmi1;
    wire spi_dqsmo1;

    wire spi_clk2;
    wire spi_cs2;
    wire [3:0] spi_mosi2;
    wire [3:0] spi_miso2;
    wire spi_dqsmi2;
    wire spi_dqsmo2;

    spi_mem_m #(0, 4000000) spi_mem1(
        .clk_i(clk),
        .nrst_i(nrst),

        .sport_i({ sportai }),
        .sport_o({ sportao }),

        .spi_clk_o(spi_clk1),
        .spi_cs_o(spi_cs1),
        .spi_mosi_o(spi_mosi1),
        .spi_miso_i(spi_miso1),
        .spi_dqsm_i(spi_dqsmi1),
        .spi_dqsm_o(spi_dqsmo1)
    );

    spi_chip_m #(5, 1, 500000) spi_chip1(
        .clk_i(spi_clk1),
        .cs_i(spi_cs1),
        .mosi_i(spi_mosi1),
        .miso_o(spi_miso1),
        .dqsm_o(spi_dqsmi1),
        .dqsm_i(spi_dqsmo1)
    );

    // spi_mem_m #(4000000, 4000000) spi_mem2(
    //     .clk_i(clk),
    //     .nrst_i(nrst),

    //     .sport_i({ sportbi }),
    //     .sport_o({ sportbo }),

    //     .spi_clk_o(spi_clk2),
    //     .spi_cs_o(spi_cs2),
    //     .spi_mosi_o(spi_mosi2),
    //     .spi_miso_i(spi_miso2),
    //     .spi_dqsm_i(spi_dqsmi2),
    //     .spi_dqsm_o(spi_dqsmo2)
    // );

    // spi_chip_m #(5, 1, 500000) spi_chip2(
    //     .clk_i(spi_clk2),
    //     .cs_i(spi_cs2),
    //     .mosi_i(spi_mosi2),
    //     .miso_o(spi_miso2),
    //     .dqsm_o(spi_dqsmi2),
    //     .dqsm_i(spi_dqsmo2)
    // );

    reg  run;
    wire busy;
    wire output_ready;
    reg [7:0] color;
    reg [`BUS_ADDR_PORT] tex_addr;
    reg [`TEX_DIM] tex_width;

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

    image_m image();

    rasterizer_m rasterizer(
        .clk_i(clk),
        .nrst_i(nrst),

        .depth_mport_i({ mportai }),
        .depth_mport_o({ mportao }),

        .pix_mport_i({ mportdi }),
        .pix_mport_o({ mportdo }),

        .tex_mport_i({ mportei }),
        .tex_mport_o({ mporteo }),

        .run_i(run),
        .busy_o(busy),

        .tex_addr_i(tex_addr),
        .tex_width_i(tex_width),
        .fb_i(1'b0),

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

    stream_stat_m #(`RAST_WAVG_OUT_WIDTH) wavg_stat(
        .clk_i(clk),

        .mstreami_i(rasterizer.wavg_streami),
        .mstreamo_i(rasterizer.wavg_streamo)
    );

    stream_stat_m #(`RAST_WAVG_OUT_WIDTH) wavg_fifo_stat(
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

        tex_addr = `ADDR_FB1;
        tex_width = 10;

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

                WRITE_MEM(`ADDR_DEPTH_BUFFER + (y * 320 + x) * 4 + 0, value[7:0]);
                WRITE_MEM(`ADDR_DEPTH_BUFFER + (y * 320 + x) * 4 + 1, value[15:8]);
                WRITE_MEM(`ADDR_DEPTH_BUFFER + (y * 320 + x) * 4 + 2, value[23:16]);
                WRITE_MEM(`ADDR_DEPTH_BUFFER + (y * 320 + x) * 4 + 3, value[31:24]);
            end
        end

        for (x = 0; x < 60; x = x + 1) begin
            for (y = 0; y < 60; y = y + 1) begin
                WRITE_MEM(`ADDR_FB1 + (y * 60 + x), image.tex_data[y * 60 + x]);
                // WRITE_MEM(`ADDR_FB1 + (y * 60 + x), 8'b11000000);
            end
        end

        for (x = 0; x < 10; x = x + 1) begin
            for (y = 0; y < 10; y = y + 1) begin
                if ((x % 2 == 0) ^ (y % 2 == 0)) begin
                    spi_chip.mem[`ADDR_FB1 + (y * 10 + x) + 0] = 8'b00111000;
                end
                else begin
                    spi_chip.mem[`ADDR_FB1 + (y * 10 + x) + 0] = 8'b00000111;
                end
            end
        end

        for (x = 0; x < 10; x = x + 1) begin
            for (y = 0; y < 10; y = y + 1) begin
                if ((x % 2 == 0) ^ (y % 2 == 0)) begin
                    spi_chip.mem[`ADDR_FB1 + 100 + (y * 10 + x) + 0] = 8'b11000000;
                end
                else begin
                    spi_chip.mem[`ADDR_FB1 + 100 + (y * 10 + x) + 0] = 8'b00111111;
                end
            end
        end

        for (x = 0; x < 320; x = x + 1) begin
            for (y = 0; y < 240; y = y + 1) begin
                WRITE_MEM(`ADDR_FB0 + (y * 320 + x), 0);
            end
        end

`include "duwe_cube.v"

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

        `VGA_WRITE("output.bmp", spi_chip1.mem, `ADDR_FB0, 320, 240, `COLOR_TYPE_RGB332);

        // `VGA_WRITE("depth.bmp", spi_chip1.mem, `ADDR_DEPTH_BUFFER, 320, 240, `COLOR_TYPE_GSW);

        $finish;
    end

    initial begin
        #100000000000;
        $finish;
    end

    task WRITE_MEM;
        input [31:0] addr;
        input [7:0] data;
    begin
        // if (addr < 4000000) begin
            spi_chip1.mem[addr] = data;
        // end
        // else begin
        //     spi_chip2.mem[addr - 4000000] = data;
        // end
    end
    endtask

endmodule
