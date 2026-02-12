run = 0;

tex_addr <= `ADDR_FB1;
tex_width <= 60;

// front top
color = 8'd176;
v0x = 187179;
v0y = 147704;
v0z = 75300;
t0x = `FP(0);
t0y = `FP(0);
v1x = 187179;
v1y = 98055;
v1z = 75300;
t1x = `FP(0);
t1y = `FP(60);
v2x = 262055;
v2y = 157627;
v2z = 72654;
t2x = `FP(60);
t2y = `FP(0);
wait(!clk);
run = 1;
wait(busy);
run = 0;
wait(!busy);
clk_rst.WAIT_CYCLES(10);
$display("Triangle %d", 0);

tex_addr <= `ADDR_FB1;
tex_width <= 60;

// front bottom?
color = 8'd15;
v1x = 187179;
v1y = 98055;
v1z = 75300;
t0x = `FP(0);
t0y = `FP(60);
v0x = 262055;
v0y = 88132;
v0z = 72654;
t1x = `FP(60);
t1y = `FP(0);
v2x = 262055;
v2y = 157627;
v2z = 72654;
t2x = `FP(60);
t2y = `FP(60);
wait(!clk);
run = 1;
wait(busy);
run = 0;
wait(!busy);
clk_rst.WAIT_CYCLES(10);
$display("Triangle %d", 1);

tex_addr <= `ADDR_FB1;
tex_width <= 60;

color = 8'd190;
v0x = 218380;
v0y = 142186;
v0z = 76771;
t0x = `FP(0);
t0y = `FP(0);
v1x = 218380;
v1y = 103573;
v1z = 76771;
t1x = `FP(60);
t1y = `FP(0);
v2x = 187179;
v2y = 147704;
v2z = 75300;
t2x = `FP(0);
t2y = `FP(60);
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
v0x = 218380;
v0y = 103573;
v0z = 76771;
t0x = `FP(0);
t0y = `FP(0);
v1x = 187179;
v1y = 147704;
v1z = 75300;
t1x = `FP(60);
t1y = `FP(0);
v2x = 187179;
v2y = 98055;
v2z = 75300;
t2x = `FP(0);
t2y = `FP(60);
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
v0x = 280770;
v0y = 147698;
v0z = 75301;
t0x = `FP(0);
t0y = `FP(0);
v2x = 280770;
v2y = 98061;
v2z = 75301;
t2x = `FP(0);
t2y = `FP(60);
v1x = 218380;
v1y = 142186;
v1z = 76771;
t1x = `FP(60);
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
v0x = 280770;
v0y = 98061;
v0z = 75301;
t0x = `FP(0);
t0y = `FP(0);
v1x = 218380;
v1y = 142186;
v1z = 76771;
t1x = `FP(60);
t1y = `FP(0);
v2x = 218380;
v2y = 103573;
v2z = 76771;
t2x = `FP(0);
t2y = `FP(60);
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
v0x = 262055;
v0y = 157627;
v0z = 72654;
t0x = `FP(0);
t0y = `FP(0);
v2x = 280770;
v2y = 147698;
v2z = 75301;
t2x = `FP(60);
t2y = `FP(0);
v1x = 262055;
v1y = 88132;
v1z = 72654;
t1x = `FP(0);
t1y = `FP(60);
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
v0x = 262055;
v0y = 88132;
v0z = 72654;
t0x = `FP(0);
t0y = `FP(0);
v1x = 280770;
v1y = 147698;
v1z = 75301;
t1x = `FP(60);
t1y = `FP(0);
v2x = 280770;
v2y = 98061;
v2z = 75301;
t2x = `FP(0);
t2y = `FP(60);
wait(!clk);
run = 1;
clk_rst.WAIT_CYCLES(10);
wait(busy);
run = 0;
wait(!busy);
clk_rst.WAIT_CYCLES(1000);
$display("Triangle %d", 7);

#100000;

$finish;

tex_addr <= `ADDR_FB1;
tex_width <= 60;

// no

color = 8'd56;
v0x = 262055;
v0y = 88132;
v0z = 72654;
t0x = `FP(0);
t0y = `FP(0);
v2x = 280770;
v2y = 98061;
v2z = 75301;
t2x = `FP(60);
t2y = `FP(0);
v1x = 187179;
v1y = 98055;
v1z = 75300;
t1x = `FP(0);
t1y = `FP(60);
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
v0x = 187179;
v0y = 98055;
v0z = 75300;
t0x = `FP(0);
t0y = `FP(0);
v2x = 280770;
v2y = 98061;
v2z = 75301;
t2x = `FP(60);
t2y = `FP(0);
v1x = 218380;
v1y = 103573;
v1z = 76771;
t1x = `FP(0);
t1y = `FP(60);
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
v0x = 280770;
v0y = 147698;
v0z = 75301;
t0x = `FP(0);
t0y = `FP(0);
v2x = 262055;
v2y = 157627;
v2z = 72654;
t2x = `FP(0);
t2y = `FP(0);
v1x = 218380;
v1y = 142186;
v1z = 76771;
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
v0x = 218380;
v0y = 142186;
v0z = 76771;
t0x = `FP(0);
t0y = `FP(0);
v1x = 262055;
v1y = 157627;
v1z = 72654;
t1x = `FP(0);
t1y = `FP(0);
v2x = 187179;
v2y = 147704;
v2z = 75300;
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

