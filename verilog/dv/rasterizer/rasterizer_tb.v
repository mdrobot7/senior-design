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

    assign mportbo = mportao;
    assign mportai = mportbi;

    // word_stripe_cache_m #(20, 20) word_cache(
    //     .clk_i(clk),
    //     .nrst_i(nrst),

    //     .cached_mport_i(mportao),
    //     .cached_mport_o(mportai),

    //     .mport_i(mportbi),
    //     .mport_o(mportbo)
    // );

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

        run = 0;

        // color <= 8'b00000111;

        // v0x = 20 << `DECIMAL_POS;
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

        // `VGA_WRITE("depth1.bmp", spi_chip.mem, `ADDR_DEPTH_BUFFER, 320, 240, `COLOR_TYPE_GSW);

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

        // color <= 8'b00111111;

        // v0x = 0 << `DECIMAL_POS;
        // v0y = 0 << `DECIMAL_POS;
        // v0z = 32'h40000000;
        // t0x = 0;
        // t0y = 0;

        // v1x = 320 << `DECIMAL_POS;
        // v1y = 0 << `DECIMAL_POS;
        // v1z = 32'h40000000;
        // t1x = 10;
        // t1y = 0;

        // v2x = 0 << `DECIMAL_POS;
        // v2y = 240 << `DECIMAL_POS;
        // v2z = 32'h40000000;
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

        // color <= 8'b11111000;

        // v0x = 320 << `DECIMAL_POS;
        // v0y = 240 << `DECIMAL_POS;
        // v0z = 2 * 64'h80000000 / 3 + 10000;
        // t0x = 0;
        // t0y = 0;

        // v1x = 0 << `DECIMAL_POS;
        // v1y = 240 << `DECIMAL_POS;
        // v1z = 2 * 64'h80000000 / 3 + 10000;
        // t1x = 10;
        // t1y = 0;

        // v2x = 320 << `DECIMAL_POS;
        // v2y = 0 << `DECIMAL_POS;
        // v2z = 2 * 64'h80000000 / 3 + 10000;
        // t2x = 0;
        // t2y = 10;

        // wait(!clk);
        // run = 1;

        // wait(busy);
        // wait(!busy);
        // run = 0;
















color = 8'd54;
v0x = 145366;
v0y = 115838;
v0z = 43155;
t0x = 0;
t0y = 0;
v1x = 146545;
v1y = 118328;
v1z = 43083;
t1x = 0;
t1y = 0;
v2x = 150033;
v2y = 115746;
v2z = 42647;
t2x = 0;
t2y = 0;
wait(!clk);
run = 1;
wait(busy);
wait(!busy);
run = 0;
clk_rst.WAIT_CYCLES(10);
$display("Triangle %d", 0);

color = 8'd238;
v0x = 150033;
v0y = 115746;
v0z = 42647;
t0x = 0;
t0y = 0;
v1x = 146545;
v1y = 118328;
v1z = 43083;
t1x = 0;
t1y = 0;
v2x = 150110;
v2y = 119447;
v2z = 42866;
t2x = 0;
t2y = 0;
wait(!clk);
run = 1;
wait(busy);
wait(!busy);
run = 0;
clk_rst.WAIT_CYCLES(10);
$display("Triangle %d", 1);

color = 8'd124;
v0x = 150110;
v0y = 119447;
v0z = 42866;
t0x = 0;
t0y = 0;
v1x = 153427;
v1y = 118286;
v1z = 42720;
t1x = 0;
t1y = 0;
v2x = 150033;
v2y = 115746;
v2z = 42647;
t2x = 0;
t2y = 0;
wait(!clk);
run = 1;
wait(busy);
wait(!busy);
run = 0;
clk_rst.WAIT_CYCLES(10);
$display("Triangle %d", 2);

color = 8'd184;
v0x = 153427;
v0y = 118286;
v0z = 42720;
t0x = 0;
t0y = 0;
v1x = 154958;
v1y = 115759;
v1z = 42720;
t1x = 0;
t1y = 0;
v2x = 150033;
v2y = 115746;
v2z = 42647;
t2x = 0;
t2y = 0;
wait(!clk);
run = 1;
wait(busy);
wait(!busy);
run = 0;
clk_rst.WAIT_CYCLES(10);
$display("Triangle %d", 3);

color = 8'd5;
v0x = 154958;
v0y = 115759;
v0z = 42720;
t0x = 0;
t0y = 0;
v1x = 153427;
v1y = 113003;
v1z = 42720;
t1x = 0;
t1y = 0;
v2x = 150033;
v2y = 115746;
v2z = 42647;
t2x = 0;
t2y = 0;
wait(!clk);
run = 1;
wait(busy);
wait(!busy);
run = 0;
clk_rst.WAIT_CYCLES(10);
$display("Triangle %d", 4);

color = 8'd104;
v0x = 153427;
v0y = 113003;
v0z = 42720;
t0x = 0;
t0y = 0;
v1x = 150110;
v1y = 111896;
v1z = 42866;
t1x = 0;
t1y = 0;
v2x = 150033;
v2y = 115746;
v2z = 42647;
t2x = 0;
t2y = 0;
wait(!clk);
run = 1;
wait(busy);
wait(!busy);
run = 0;
clk_rst.WAIT_CYCLES(10);
$display("Triangle %d", 5);

color = 8'd194;
v0x = 150110;
v0y = 111896;
v0z = 42866;
t0x = 0;
t0y = 0;
v1x = 146545;
v1y = 113095;
v1z = 43083;
t1x = 0;
t1y = 0;
v2x = 150033;
v2y = 115746;
v2z = 42647;
t2x = 0;
t2y = 0;
wait(!clk);
run = 1;
wait(busy);
wait(!busy);
run = 0;
clk_rst.WAIT_CYCLES(10);
$display("Triangle %d", 6);

color = 8'd159;
v0x = 146545;
v0y = 113095;
v0z = 43083;
t0x = 0;
t0y = 0;
v1x = 145366;
v1y = 115838;
v1z = 43155;
t1x = 0;
t1y = 0;
v2x = 150033;
v2y = 115746;
v2z = 42647;
t2x = 0;
t2y = 0;
wait(!clk);
run = 1;
wait(busy);
wait(!busy);
run = 0;
clk_rst.WAIT_CYCLES(10);
$display("Triangle %d", 7);

color = 8'd7;
v0x = 160316;
v0y = 145782;
v0z = 44336;
t0x = 0;
t0y = 0;
v1x = 162081;
v1y = 146840;
v1z = 44403;
t1x = 0;
t1y = 0;
v2x = 160297;
v2y = 144134;
v2z = 44133;
t2x = 0;
t2y = 0;
wait(!clk);
run = 1;
wait(busy);
wait(!busy);
run = 0;
clk_rst.WAIT_CYCLES(10);
$display("Triangle %d", 8);

color = 8'd191;
v0x = 163840;
v0y = 107059;
v0z = 44933;
t0x = 0;
t0y = 0;
v1x = 159758;
v1y = 109979;
v1z = 44604;
t1x = 0;
t1y = 0;
v2x = 163840;
v2y = 111530;
v2z = 44670;
t2x = 0;
t2y = 0;
wait(!clk);
run = 1;
wait(busy);
wait(!busy);
run = 0;
clk_rst.WAIT_CYCLES(10);
$display("Triangle %d", 9);

color = 8'd212;
v0x = 150120;
v0y = 127233;
v0z = 48149;
t0x = 0;
t0y = 0;
v1x = 156693;
v1y = 132805;
v1z = 48040;
t1x = 0;
t1y = 0;
v2x = 155998;
v2y = 130441;
v2z = 46071;
t2x = 0;
t2y = 0;
wait(!clk);
run = 1;
wait(busy);
wait(!busy);
run = 0;
clk_rst.WAIT_CYCLES(10);
$display("Triangle %d", 10);

color = 8'd98;
v0x = 156212;
v0y = 129023;
v0z = 45762;
t0x = 0;
t0y = 0;
v1x = 156444;
v1y = 127573;
v1z = 45511;
t1x = 0;
t1y = 0;
v2x = 148020;
v2y = 125422;
v2z = 45762;
t2x = 0;
t2y = 0;
wait(!clk);
run = 1;
wait(busy);
wait(!busy);
run = 0;
clk_rst.WAIT_CYCLES(10);
$display("Triangle %d", 11);

color = 8'd99;
v0x = 153672;
v0y = 126172;
v0z = 52340;
t0x = 0;
t0y = 0;
v1x = 149532;
v1y = 122360;
v1z = 52382;
t1x = 0;
t1y = 0;
v2x = 154122;
v2y = 121693;
v2z = 52993;
t2x = 0;
t2y = 0;
wait(!clk);
run = 1;
wait(busy);
wait(!busy);
run = 0;
clk_rst.WAIT_CYCLES(10);
$display("Triangle %d", 12);

color = 8'd167;
v0x = 141139;
v0y = 121954;
v0z = 50336;
t0x = 0;
t0y = 0;
v1x = 141070;
v1y = 123436;
v1z = 50240;
t1x = 0;
t1y = 0;
v2x = 140362;
v2y = 122880;
v2z = 49606;
t2x = 0;
t2y = 0;
wait(!clk);
run = 1;
wait(busy);
wait(!busy);
run = 0;
clk_rst.WAIT_CYCLES(10);
$display("Triangle %d", 13);

color = 8'd65;
v0x = 128364;
v0y = 115178;
v0z = 52046;
t0x = 0;
t0y = 0;
v1x = 130834;
v1y = 116646;
v1z = 51526;
t1x = 0;
t1y = 0;
v2x = 132395;
v2y = 115432;
v2z = 51658;
t2x = 0;
t2y = 0;
wait(!clk);
run = 1;
wait(busy);
wait(!busy);
run = 0;
clk_rst.WAIT_CYCLES(10);
$display("Triangle %d", 14);

color = 8'd63;
v0x = 124962;
v0y = 121665;
v0z = 52299;
t0x = 0;
t0y = 0;
v1x = 123112;
v1y = 116247;
v1z = 52130;
t1x = 0;
t1y = 0;
v2x = 126918;
v2y = 112495;
v2z = 52382;
t2x = 0;
t2y = 0;
wait(!clk);
run = 1;
wait(busy);
wait(!busy);
run = 0;
clk_rst.WAIT_CYCLES(10);
$display("Triangle %d", 15);

color = 8'd84;
v0x = 200761;
v0y = 112495;
v0z = 52382;
t0x = 0;
t0y = 0;
v1x = 204567;
v1y = 116247;
v1z = 52130;
t1x = 0;
t1y = 0;
v2x = 202717;
v2y = 121665;
v2z = 52299;
t2x = 0;
t2y = 0;
wait(!clk);
run = 1;
wait(busy);
wait(!busy);
run = 0;
clk_rst.WAIT_CYCLES(10);
$display("Triangle %d", 16);

color = 8'd157;
v0x = 195284;
v0y = 115432;
v0z = 51658;
t0x = 0;
t0y = 0;
v1x = 196845;
v1y = 116646;
v1z = 51526;
t1x = 0;
t1y = 0;
v2x = 199315;
v2y = 115178;
v2z = 52046;
t2x = 0;
t2y = 0;
wait(!clk);
run = 1;
wait(busy);
wait(!busy);
run = 0;
clk_rst.WAIT_CYCLES(10);
$display("Triangle %d", 17);

color = 8'd136;
v0x = 187317;
v0y = 122880;
v0z = 49606;
t0x = 0;
t0y = 0;
v1x = 186609;
v1y = 123436;
v1z = 50240;
t1x = 0;
t1y = 0;
v2x = 186540;
v2y = 121954;
v2z = 50336;
t2x = 0;
t2y = 0;
wait(!clk);
run = 1;
wait(busy);
wait(!busy);
run = 0;
clk_rst.WAIT_CYCLES(10);
$display("Triangle %d", 18);

color = 8'd226;
v0x = 173557;
v0y = 121693;
v0z = 52993;
t0x = 0;
t0y = 0;
v1x = 178147;
v1y = 122360;
v1z = 52382;
t1x = 0;
t1y = 0;
v2x = 174007;
v2y = 126172;
v2z = 52340;
t2x = 0;
t2y = 0;
wait(!clk);
run = 1;
wait(busy);
wait(!busy);
run = 0;
clk_rst.WAIT_CYCLES(10);
$display("Triangle %d", 19);

color = 8'd229;
v0x = 179659;
v0y = 125422;
v0z = 45762;
t0x = 0;
t0y = 0;
v1x = 171235;
v1y = 127573;
v1z = 45511;
t1x = 0;
t1y = 0;
v2x = 171467;
v2y = 129023;
v2z = 45762;
t2x = 0;
t2y = 0;
wait(!clk);
run = 1;
wait(busy);
wait(!busy);
run = 0;
clk_rst.WAIT_CYCLES(10);
$display("Triangle %d", 20);

color = 8'd104;
v0x = 171681;
v0y = 130441;
v0z = 46071;
t0x = 0;
t0y = 0;
v1x = 170986;
v1y = 132805;
v1z = 48040;
t1x = 0;
t1y = 0;
v2x = 177559;
v2y = 127233;
v2z = 48149;
t2x = 0;
t2y = 0;
wait(!clk);
run = 1;
wait(busy);
wait(!busy);
run = 0;
clk_rst.WAIT_CYCLES(10);
$display("Triangle %d", 21);

color = 8'd245;
v0x = 163840;
v0y = 111530;
v0z = 44670;
t0x = 0;
t0y = 0;
v1x = 167921;
v1y = 109979;
v1z = 44604;
t1x = 0;
t1y = 0;
v2x = 163840;
v2y = 107059;
v2z = 44933;
t2x = 0;
t2y = 0;
wait(!clk);
run = 1;
wait(busy);
wait(!busy);
run = 0;
clk_rst.WAIT_CYCLES(10);
$display("Triangle %d", 22);

color = 8'd104;
v0x = 167382;
v0y = 144134;
v0z = 44133;
t0x = 0;
t0y = 0;
v1x = 165598;
v1y = 146840;
v1z = 44403;
t1x = 0;
t1y = 0;
v2x = 167363;
v2y = 145782;
v2z = 44336;
t2x = 0;
t2y = 0;
wait(!clk);
run = 1;
wait(busy);
wait(!busy);
run = 0;
clk_rst.WAIT_CYCLES(10);
$display("Triangle %d", 23);

color = 8'd222;
v0x = 177646;
v0y = 115746;
v0z = 42647;
t0x = 0;
t0y = 0;
v1x = 182313;
v1y = 115838;
v1z = 43155;
t1x = 0;
t1y = 0;
v2x = 181134;
v2y = 113095;
v2z = 43083;
t2x = 0;
t2y = 0;
wait(!clk);
run = 1;
wait(busy);
wait(!busy);
run = 0;
clk_rst.WAIT_CYCLES(10);
$display("Triangle %d", 24);

color = 8'd183;
v0x = 177646;
v0y = 115746;
v0z = 42647;
t0x = 0;
t0y = 0;
v1x = 181134;
v1y = 113095;
v1z = 43083;
t1x = 0;
t1y = 0;
v2x = 177569;
v2y = 111896;
v2z = 42866;
t2x = 0;
t2y = 0;
wait(!clk);
run = 1;
wait(busy);
wait(!busy);
run = 0;
clk_rst.WAIT_CYCLES(10);
$display("Triangle %d", 25);

color = 8'd234;
v0x = 177646;
v0y = 115746;
v0z = 42647;
t0x = 0;
t0y = 0;
v1x = 177569;
v1y = 111896;
v1z = 42866;
t1x = 0;
t1y = 0;
v2x = 174252;
v2y = 113003;
v2z = 42720;
t2x = 0;
t2y = 0;
wait(!clk);
run = 1;
wait(busy);
wait(!busy);
run = 0;
clk_rst.WAIT_CYCLES(10);
$display("Triangle %d", 26);

color = 8'd54;
v0x = 177646;
v0y = 115746;
v0z = 42647;
t0x = 0;
t0y = 0;
v1x = 174252;
v1y = 113003;
v1z = 42720;
t1x = 0;
t1y = 0;
v2x = 172721;
v2y = 115759;
v2z = 42720;
t2x = 0;
t2y = 0;
wait(!clk);
run = 1;
wait(busy);
wait(!busy);
run = 0;
clk_rst.WAIT_CYCLES(10);
$display("Triangle %d", 27);

color = 8'd186;
v0x = 177646;
v0y = 115746;
v0z = 42647;
t0x = 0;
t0y = 0;
v1x = 172721;
v1y = 115759;
v1z = 42720;
t1x = 0;
t1y = 0;
v2x = 174252;
v2y = 118286;
v2z = 42720;
t2x = 0;
t2y = 0;
wait(!clk);
run = 1;
wait(busy);
wait(!busy);
run = 0;
clk_rst.WAIT_CYCLES(10);
$display("Triangle %d", 28);

color = 8'd140;
v0x = 177646;
v0y = 115746;
v0z = 42647;
t0x = 0;
t0y = 0;
v1x = 174252;
v1y = 118286;
v1z = 42720;
t1x = 0;
t1y = 0;
v2x = 177569;
v2y = 119447;
v2z = 42866;
t2x = 0;
t2y = 0;
wait(!clk);
run = 1;
wait(busy);
wait(!busy);
run = 0;
clk_rst.WAIT_CYCLES(10);
$display("Triangle %d", 29);

color = 8'd28;
v0x = 177569;
v0y = 119447;
v0z = 42866;
t0x = 0;
t0y = 0;
v1x = 181134;
v1y = 118328;
v1z = 43083;
t1x = 0;
t1y = 0;
v2x = 177646;
v2y = 115746;
v2z = 42647;
t2x = 0;
t2y = 0;
wait(!clk);
run = 1;
wait(busy);
wait(!busy);
run = 0;
clk_rst.WAIT_CYCLES(10);
$display("Triangle %d", 30);

color = 8'd138;
v0x = 177646;
v0y = 115746;
v0z = 42647;
t0x = 0;
t0y = 0;
v1x = 181134;
v1y = 118328;
v1z = 43083;
t1x = 0;
t1y = 0;
v2x = 182313;
v2y = 115838;
v2z = 43155;
t2x = 0;
t2y = 0;
wait(!clk);
run = 1;
wait(busy);
wait(!busy);
run = 0;
clk_rst.WAIT_CYCLES(10);
$display("Triangle %d", 31);
























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
