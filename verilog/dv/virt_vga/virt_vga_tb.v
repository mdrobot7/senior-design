module virt_vga_tb();

    reg clk;
    reg nrst;

    initial forever begin
        clk <= 1;
        #10;
        clk <= 0;
        #10;
    end

    reg [7:0] buffer [(320 * 240) - 1:0];

    initial begin : MAIN_1
        integer i, j;

		$dumpfile("vga.vcd");
		$dumpvars(0, vga_tb);

        nrst = 0;
        #30;
        nrst = 1;
        #30;

        for (i = 0; i < 240; i = i + 1) begin
            for (j = 0; j < 320; j = j + 1) begin
                buffer[i * 320 + j] = i * j;
            end
        end

        `VGA_WRITE("test.bmp", buffer, 0, 320, 240, `COLOR_TYPE_RGB332);

        #1000000;
        $finish;
    end



endmodule
