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