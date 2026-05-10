module normal_pipe_tb();

    wire clk, nrst;

    clk_rst_m clk_rst(
        .clk_o(clk),
        .nrst_o(nrst)
    );

    reg run;
    wire busy;

    wire [`STREAM_SIPORT(2 * `DIVIDER_WIDTH)] div_si;
    wire [`STREAM_SOPORT(2 * `DIVIDER_WIDTH)] div_so;
    wire [`STREAM_MIPORT(`DIVIDER_WIDTH)] div_mi;
    wire [`STREAM_MOPORT(`DIVIDER_WIDTH)] div_mo;

    reg signed [`WORD] v0x, v0y, v0z;
    reg signed [`WORD] v1x, v1y, v1z;
    reg signed [`WORD] v2x, v2y, v2z;

    wire valid;
    wire signed [`WORD] nx, ny, nz;
    
    normal_pipe_m normal_pipe(
        .clk_i(clk),
        .nrst_i(nrst),

        .run_i(run),
        .busy_o(busy),

        .v0x_i(v0x),
        .v0y_i(v0y),
        .v0z_i(v0z),
        .v1x_i(v1x),
        .v1y_i(v1y),
        .v1z_i(v1z),
        .v2x_i(v2x),
        .v2y_i(v2y),
        .v2z_i(v2z),

        .div_mstream_i(div_so),
        .div_mstream_o(div_si),

        .div_sstream_i(div_mo),
        .div_sstream_o(div_mi),

        .valid_o(valid),
        .nx_o(nx),
        .ny_o(ny),
        .nz_o(nz)
    );

    div_pipe_m #(`DIVIDER_WIDTH) div_pipe(
        .clk_i(clk),
        .nrst_i(nrst),

        .sstream_i(div_si),
        .sstream_o(div_so),

        .mstream_i(div_mi),
        .mstream_o(div_mo)
    );

    initial begin
		$dumpfile("normal_pipe.vcd");
		$dumpvars(0, normal_pipe_tb);

        run = 0;

        v0x = 0;
        v0y = 0;
        v0z = 0;

        v1x = (1 << `DECIMAL_POS) / 4;
        v1y = 0;
        v1z = 0;

        v2x = 0;
        v2y = 0;
        v2z = (1 << `DECIMAL_POS) / 4;

        #100;

        run = 1;
        #100;
        run = 0;

        wait(valid);

        $display("(%0d, %0d, %0d)", nx >>> `DECIMAL_POS, ny >>> `DECIMAL_POS, nz >>> `DECIMAL_POS);

        $finish;
    end

    initial begin
        #1000000;

        $finish;
    end

endmodule
