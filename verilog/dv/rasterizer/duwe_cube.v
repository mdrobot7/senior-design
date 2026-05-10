run = 0;

`define FIX(x) ((x) << (`DECIMAL_POS - 10))
`define EX (10000)

tex_addr <= `ADDR_FB1;
tex_width <= 60;

// front top
color = 8'd176;
v0x = `FIX(187179);
v0y = `FIX(147704);
v0z = `FIX(75300) * `EX;
t0x = `FP(0);
t0y = `FP(0);
v1x = `FIX(187179);
v1y = `FIX(98055);
v1z = `FIX(75300) * `EX;
t1x = `FP(0);
t1y = `FP(59);
v2x = `FIX(262055);
v2y = `FIX(157627);
v2z = `FIX(72654) * `EX;
t2x = `FP(59);
t2y = `FP(0);
wait(!clk);
run = 1;
wait(busy);
run = 0;
wait(!busy);
clk_rst.WAIT_CYCLES(1000);
$display("Triangle %d", 0);

tex_addr <= `ADDR_FB1;
tex_width <= 60;

// front bottom
color = 8'd15;
v0x = `FIX(187179);
v0y = `FIX(98055);
v0z = `FIX(75300) * `EX;
t0x = `FP(0);
t0y = `FP(59);
v1x = `FIX(262055);
v1y = `FIX(88132);
v1z = `FIX(72654) * `EX;
t1x = `FP(59);
t1y = `FP(59);
v2x = `FIX(262055);
v2y = `FIX(157627);
v2z = `FIX(72654) * `EX;
t2x = `FP(59);
t2y = `FP(00);
wait(!clk);
run = 1;
wait(busy);
run = 0;
wait(!busy);
clk_rst.WAIT_CYCLES(1000);
$display("Triangle %d", 1);

tex_addr <= `ADDR_FB1;
tex_width <= 60;

color = 8'd190;
v0x = `FIX(218380);
v0y = `FIX(142186);
v0z = `FIX(76771) * `EX;
t0x = `FP(0);
t0y = `FP(0);
v1x = `FIX(218380);
v1y = `FIX(103573);
v1z = `FIX(76771) * `EX;
t1x = `FP(59);
t1y = `FP(0);
v2x = `FIX(187179);
v2y = `FIX(147704);
v2z = `FIX(75300) * `EX;
t2x = `FP(0);
t2y = `FP(59);
wait(!clk);
run = 1;
wait(busy);
run = 0;
wait(!busy);
clk_rst.WAIT_CYCLES(10);
$display("Triangle %d", 2);

tex_addr <= `ADDR_FB1;
tex_width <= 60;

color = 8'd90;
v0x = `FIX(218380);
v0y = `FIX(103573);
v0z = `FIX(76771) * `EX;
t0x = `FP(0);
t0y = `FP(0);
v1x = `FIX(187179);
v1y = `FIX(147704);
v1z = `FIX(75300) * `EX;
t1x = `FP(59);
t1y = `FP(0);
v2x = `FIX(187179);
v2y = `FIX(98055);
v2z = `FIX(75300) * `EX;
t2x = `FP(0);
t2y = `FP(59);
wait(!clk);
run = 1;
wait(busy);
run = 0;
wait(!busy);
clk_rst.WAIT_CYCLES(10);
$display("Triangle %d", 3);

tex_addr <= `ADDR_FB1;
tex_width <= 60;

// back
color = 8'd206;
v0x = `FIX(280770);
v0y = `FIX(147698);
v0z = `FIX(75301) * `EX;
t0x = `FP(0);
t0y = `FP(0);
v2x = `FIX(280770);
v2y = `FIX(98061);
v2z = `FIX(75301) * `EX;
t2x = `FP(0);
t2y = `FP(59);
v1x = `FIX(218380);
v1y = `FIX(142186);
v1z = `FIX(76771) * `EX;
t1x = `FP(59);
t1y = `FP(0);
wait(!clk);
run = 1;
wait(busy);
run = 0;
wait(!busy);
clk_rst.WAIT_CYCLES(10);
$display("Triangle %d", 4);

tex_addr <= `ADDR_FB1;
tex_width <= 60;


// back
color = 8'd217;
v0x = `FIX(280770);
v0y = `FIX(98061);
v0z = `FIX(75301) * `EX;
t0x = `FP(0);
t0y = `FP(0);
v1x = `FIX(218380);
v1y = `FIX(142186);
v1z = `FIX(76771) * `EX;
t1x = `FP(59);
t1y = `FP(0);
v2x = `FIX(218380);
v2y = `FIX(103573);
v2z = `FIX(76771) * `EX;
t2x = `FP(0);
t2y = `FP(59);
wait(!clk);
run = 1;
wait(busy);
run = 0;
wait(!busy);
clk_rst.WAIT_CYCLES(10);
$display("Triangle %d", 5);

tex_addr <= `ADDR_FB1;
tex_width <= 60;

// right top
color = 8'd144;
v0x = `FIX(262055);
v0y = `FIX(157627);
v0z = `FIX(72654) * `EX;
t0x = `FP(0);
t0y = `FP(0);
v2x = `FIX(280770);
v2y = `FIX(147698);
v2z = `FIX(75301) * `EX;
t2x = `FP(59);
t2y = `FP(0);
v1x = `FIX(262055);
v1y = `FIX(88132);
v1z = `FIX(72654) * `EX;
t1x = `FP(0);
t1y = `FP(59);
wait(!clk);
run = 1;
wait(busy);
run = 0;
wait(!busy);
clk_rst.WAIT_CYCLES(1000);
$display("Triangle %d", 6);

tex_addr <= `ADDR_FB1;
tex_width <= 60;

// right bottom
color = 8'd230;
v0x = `FIX(262055);
v0y = `FIX(88132);
v0z = `FIX(72654) * `EX;
t0x = `FP(0);
t0y = `FP(59);
v2x = `FIX(280770);
v2y = `FIX(147698);
v2z = `FIX(75301) * `EX;
t2x = `FP(59);
t2y = `FP(0);
v1x = `FIX(280770);
v1y = `FIX(98061);
v1z = `FIX(75301) * `EX;
t1x = `FP(59);
t1y = `FP(59);
wait(!clk);
run = 1;
clk_rst.WAIT_CYCLES(10);
wait(busy);
run = 0;
wait(!busy);
clk_rst.WAIT_CYCLES(1000);
$display("Triangle %d", 7);

tex_addr <= `ADDR_FB1;
tex_width <= 60;

// no

color = 8'd56;
v0x = `FIX(262055);
v0y = `FIX(88132);
v0z = `FIX(72654) * `EX;
t0x = `FP(0);
t0y = `FP(0);
v2x = `FIX(280770);
v2y = `FIX(98061);
v2z = `FIX(75301) * `EX;
t2x = `FP(59);
t2y = `FP(0);
v1x = `FIX(187179);
v1y = `FIX(98055);
v1z = `FIX(75300) * `EX;
t1x = `FP(0);
t1y = `FP(59);
wait(!clk);
run = 1;
wait(busy);
run = 0;
wait(!busy);
clk_rst.WAIT_CYCLES(10);
$display("Triangle %d", 8);

tex_addr <= `ADDR_FB1;
tex_width <= 60;

// bottom
color = 8'd109;
v0x = `FIX(187179);
v0y = `FIX(98055);
v0z = `FIX(75300) * `EX;
t0x = `FP(0);
t0y = `FP(0);
v2x = `FIX(280770);
v2y = `FIX(98061);
v2z = `FIX(75301) * `EX;
t2x = `FP(59);
t2y = `FP(0);
v1x = `FIX(218380);
v1y = `FIX(103573);
v1z = `FIX(76771) * `EX;
t1x = `FP(0);
t1y = `FP(59);
wait(!clk);
run = 1;
wait(busy);
run = 0;
wait(!busy);
clk_rst.WAIT_CYCLES(10);
$display("Triangle %d", 9);

tex_addr <= `ADDR_FB1;
tex_width <= 60;

// top
color = 8'd148;
v0x = `FIX(280770);
v0y = `FIX(147698);
v0z = `FIX(75301) * `EX;
t0x = `FP(0);
t0y = `FP(0);
v2x = `FIX(262055);
v2y = `FIX(157627);
v2z = `FIX(72654) * `EX;
t2x = `FP(0);
t2y = `FP(0);
v1x = `FIX(218380);
v1y = `FIX(142186);
v1z = `FIX(76771) * `EX;
t1x = `FP(0);
t1y = `FP(0);
wait(!clk);
run = 1;
wait(busy);
run = 0;
wait(!busy);
clk_rst.WAIT_CYCLES(10);
$display("Triangle %d", 10);

tex_addr <= `ADDR_FB1;
tex_width <= 60;

//top
color = 8'd94;
v0x = `FIX(218380);
v0y = `FIX(142186);
v0z = `FIX(76771) * `EX;
t0x = `FP(0);
t0y = `FP(0);
v1x = `FIX(262055);
v1y = `FIX(157627);
v1z = `FIX(72654) * `EX;
t1x = `FP(0);
t1y = `FP(0);
v2x = `FIX(187179);
v2y = `FIX(147704);
v2z = `FIX(75300) * `EX;
t2x = `FP(0);
t2y = `FP(0);
wait(!clk);
run = 1;
wait(busy);
run = 0;
wait(!busy);
clk_rst.WAIT_CYCLES(10);
$display("Triangle %d", 11);

tex_addr <= `ADDR_FB1;
tex_width <= 60;

