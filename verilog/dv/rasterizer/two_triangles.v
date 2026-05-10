run = 0;

tex_addr <= `ADDR_FB1;
tex_width <= 10;

v0x = 0 - 1 << `DECIMAL_POS;
v0y = 20 << `DECIMAL_POS;
v0z = 2 * 64'h80000000 / 3;
t0x = 0;
t0y = 0;

v1x = 80 << `DECIMAL_POS;
v1y = 50 << `DECIMAL_POS;
v1z = 1 * 64'h80000000 / 3;
t1x = 10;
t1y = 0;

v2x = 50 << `DECIMAL_POS;
v2y = 80 << `DECIMAL_POS;
v2z = 1 * 64'h80000000 / 3;
t2x = 0;
t2y = 10;

wait(!clk);
run = 1;

wait(busy);
run = 0;
wait(!busy);

clk_rst.WAIT_CYCLES(10);

tex_addr <= `ADDR_FB1 + 100;
tex_width <= 10;

v0x = 10 << `DECIMAL_POS;
v0y = 50 << `DECIMAL_POS;
v0z = 1 * 64'h80000000 / 3;
t0x = 0;
t0y = 0;

v1x = 50 << `DECIMAL_POS;
v1y = 10 << `DECIMAL_POS;
v1z = 1 * 64'h80000000 / 3;
t1x = 10;
t1y = 0;

v2x = 140 << `DECIMAL_POS;
v2y = 140 << `DECIMAL_POS;
v2z = 2 * 64'h80000000 / 3;
t2x = 0;
t2y = 10;

wait(!clk);
run = 1;

wait(busy);
run = 0;
wait(!busy);

for (i = 0; i < 10; i = i + 1) begin
    wait(clk);
    wait(!clk);
end
