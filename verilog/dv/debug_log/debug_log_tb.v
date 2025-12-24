module debug_log_tb();

    `DL_DEFINE(yep, "a very long name", `DL_BLUE, 1);

    initial begin : MAIN
		$dumpfile("debug_log.vcd");
		$dumpvars(0, debug_log_tb);

        `DL(yep, ("yep %s, %b", "aaa", 10));
    end

    initial begin
        #1000000000;
        $finish;
    end

endmodule
