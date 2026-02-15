run = 0;

tex_addr <= `ADDR_FB1;
tex_width <= 60;

v0x = 50 << `DECIMAL_POS;
v0y = 50 << `DECIMAL_POS;
v0z = (2 * 64'h80000000 / 3) / 1000;
t0x = 0;
t0y = `FP(60);

v1x = 200 << `DECIMAL_POS;
v1y = 50 << `DECIMAL_POS;
v1z = (1 * 64'h80000000 / 3) / 1000;
t1x = `FP(60);
t1y = `FP(60);

v2x = 50 << `DECIMAL_POS;
v2y = 200 << `DECIMAL_POS;
v2z = (1 * 64'h80000000 / 3) / 1000;
t2x = 0;
t2y = 0;

wait(!clk);
run = 1;

wait(busy);
run = 0;
wait(!busy);

clk_rst.WAIT_CYCLES(10);

tex_addr <= `ADDR_FB1;
tex_width <= 60;

v0x = 50 << `DECIMAL_POS;
v0y = 200 << `DECIMAL_POS;
v0z = (1 * 64'h80000000 / 3) / 1000;
t0x = 0;
t0y = 0;

v1x = 200 << `DECIMAL_POS;
v1y = 50 << `DECIMAL_POS;
v1z = (1 * 64'h80000000 / 3) / 1000;
t1x = `FP(60);
t1y = `FP(60);

v2x = 200 << `DECIMAL_POS;
v2y = 200 << `DECIMAL_POS;
v2z = (2 * 64'h80000000 / 3) / 1000;
t2x = `FP(60);
t2y = 0;

wait(!clk);
run = 1;

wait(busy);
run = 0;
wait(!busy);

for (i = 0; i < 10; i = i + 1) begin
    wait(clk);
    wait(!clk);
end
