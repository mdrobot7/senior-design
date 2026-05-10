module core_bench_tb();

    reg clk;
    reg nrst;

    initial forever begin
        clk <= 1;
        #10;
        clk <= 0;
        #10;
    end

    initial begin
		$dumpfile("core_bench.vcd");
		$dumpvars(0, core_bench_tb);

        nrst = 0;
        #30;
        nrst = 1;
        #30;

        #1000000;
        $finish;
    end

endmodule