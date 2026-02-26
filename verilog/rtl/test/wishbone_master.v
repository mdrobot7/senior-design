module wishbone_master_m(
    input wire clk_i,
    input wire nrst_i,

    output wire wb_clk_o,
    output wire wb_rst_o,
    output reg  wbs_stb_o,
    output reg  wbs_cyc_o,
    output reg  wbs_we_o,
    output reg  [3:0] wbs_sel_o,
    output reg  [`WORD_WIDTH-1:0] wbs_dat_o,
    output reg  [`WORD_WIDTH-1:0] wbs_adr_o,
    input  wire wbs_ack_i,
    input  wire [`WORD_WIDTH-1:0] wbs_dat_i
);

    assign wb_clk_o = clk_i;
    assign wb_rst_o = !nrst_i;

    initial forever begin
        wait(wb_rst_o);

        wbs_stb_o = 0;
        wbs_cyc_o = 0;
        wbs_we_o = 0;
        wbs_sel_o = 0;
        wbs_dat_o = 0;
        wbs_adr_o = 0;

        wait(!wb_rst_o);
    end

    task WRITE;
        input [`WORD] addr;
        input [`WORD] data;
    begin
        wait(wb_clk_o);

        wbs_adr_o = addr;
        wbs_dat_o = data;

        wbs_we_o  = 1;

        wbs_sel_o = 0;
        wbs_stb_o = 1;
        wbs_cyc_o = 1;

        wait(!wb_clk_o);
        wait(wb_clk_o);

        while(!wbs_ack_i) begin
            wait(!wb_clk_o);
            wait(wb_clk_o);
        end

        wait(!wb_clk_o);

        wbs_adr_o = 0;
        wbs_dat_o = 0;

        wbs_we_o  = 0;

        wbs_sel_o = 0;
        wbs_stb_o = 0;
        wbs_cyc_o = 0;
    end
    endtask

    task READ;
        input  [`WORD] addr;
        output [`WORD] data;
    begin
        wait(wb_clk_o);

        wbs_adr_o = addr;

        wbs_we_o  = 0;

        wbs_sel_o = 0;
        wbs_stb_o = 1;
        wbs_cyc_o = 1;

        wait(!wb_clk_o);
        wait(wb_clk_o);

        while(!wbs_ack_i) begin
            wait(!wb_clk_o);
            wait(wb_clk_o);
        end

        data = wbs_dat_i;

        wait(!wb_clk_o);

        wbs_adr_o = 0;
        wbs_dat_o = 0;

        wbs_we_o  = 0;

        wbs_sel_o = 0;
        wbs_stb_o = 0;
        wbs_cyc_o = 0;
    end
    endtask

endmodule
