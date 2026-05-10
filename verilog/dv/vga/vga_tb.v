module vga_tb();

    reg clk;
    reg nrst;

    initial forever begin
        clk <= 1;
        #10;
        clk <= 0;
        #10;
    end

    initial begin
		$dumpfile("vga.vcd");
		$dumpvars(0, vga_tb);

        nrst = 0;
        #30;
        nrst = 1;
        #30;

        #1000;
        $finish;
    end

endmodule
