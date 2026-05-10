`include "user_defines.v"

`include "svunit_defines.svh"

`include "spi_mem.v"
`include "wishbone_register.v"
`include "wishbone_helper.v"

`include "wbslave_pkmaster/wb_to_pk.v"

`include "test/debug_log_config.v"
`include "test/debug_log.v"

`include "test/clk_rst.v"
`include "test/spi_chip.v"
`include "test/wishbone_master.v"

`include "bus/busarb.v"
`include "test/bus_master.v"

module wb_to_pk_m_unit_test;
  import svunit_pkg::svunit_testcase;

  string name = "wb_to_pk_m_ut";
  svunit_testcase svunit_ut;


  //===================================
  // This is the UUT that we're 
  // running the Unit Tests on
  //===================================
    wire clk, nrst;
    clk_rst_m clk_rst(.clk_o(clk), .nrst_o(nrst));

    wire wb_clk;
    wire wb_rst;
    wire wbs_stb;
    wire wbs_cyc;
    wire wbs_we;
    wire [3:0] wbs_sel;
    wire [`WORD_WIDTH-1:0] wbs_dato;
    wire [`WORD_WIDTH-1:0] wbs_adr;
    wire wbs_ack;
    wire [`WORD_WIDTH-1:0] wbs_dati;

    wire [`BUS_MIPORT] mporti;
    wire [`BUS_MOPORT] mporto;

    wire [`BUS_SIPORT] sporti;
    wire [`BUS_SOPORT] sporto;

    wishbone_master_m wbmaster(
        .clk_i(clk),
        .nrst_i(nrst),

        .wb_clk_o(wb_clk),
        .wb_rst_o(wb_rst),
        .wbs_stb_o(wbs_stb),
        .wbs_cyc_o(wbs_cyc),
        .wbs_we_o(wbs_we),
.wbs_sel_o(wbs_sel),
        .wbs_dat_o(wbs_dati),
        .wbs_adr_o(wbs_adr),
        .wbs_ack_i(wbs_ack),
        .wbs_dat_i(wbs_dato)
    );

    wb_to_pk_m dut(
        .wb_clk_i(wb_clk),
        .wb_rst_i(wb_rst),
        .wbs_stb_i(wbs_stb),
        .wbs_cyc_i(wbs_cyc),
        .wbs_we_i(wbs_we),
        .wbs_sel_i(wbs_sel),
        .wbs_dat_i(wbs_dati),
        .wbs_adr_i(wbs_adr),
        .wbs_ack_o(wbs_ack),
        .wbs_dat_o(wbs_dato),

        .mport_i(mporti),
        .mport_o(mporto)
    );

    busarb_m #(1, 1, 1) arbiter(
        .clk_i(clk),
        .nrst_i(nrst),

        .mports_i({ mporto }),
        .mports_o({ mporti }),

        .sports_i({ sporto }),
        .sports_o({ sporti })
    );

    wire spi_clk;
    wire spi_cs;
    wire [3:0] spi_mosi;
    wire [3:0] spi_miso;
    wire spi_dqsmi;
    wire spi_dqsmo;

    spi_mem_m #(0, 1024) my_spi_mem_m(
        .clk_i(clk),
        .nrst_i(nrst),

        .sport_i(sporti),
        .sport_o(sporto),

        .spi_clk_o(spi_clk),
        .spi_cs_o(spi_cs),
        .spi_mosi_o(spi_mosi),
        .spi_miso_i(spi_miso),
        .spi_dqsm_i(spi_dqsmi),
        .spi_dqsm_o(spi_dqsmo)
    );

    spi_chip_m #(1024) spi_chip(
        .clk_i(spi_clk),
        .cs_i(spi_cs),
        .mosi_i(spi_mosi),
        .miso_o(spi_miso),
        .dqsm_o(spi_dqsmi),
        .dqsm_i(spi_dqsmo)
    );

    //===================================
    // Build
    //===================================
    function void build();
        svunit_ut = new(name);
    endfunction


    //===================================
    // Setup for running the Unit Tests
    //===================================
    task setup();
        svunit_ut.setup();
        /* Place Setup Code Here */

        clk_rst.RESET();
    endtask


    //===================================
    // Here we deconstruct anything we 
    // need after running the Unit Tests
    //===================================
    task teardown();
        svunit_ut.teardown();
    endtask


    //===================================
    // All tests are defined between the
    // SVUNIT_TESTS_BEGIN/END macros
    //
    // Each individual test must be
    // defined between `SVTEST(_NAME_)
    // `SVTEST_END
    //
    // i.e.
    //   `SVTEST(mytest)
    //     <test code>
    //   `SVTEST_END
    //===================================
    `SVUNIT_TESTS_BEGIN

        `SVTEST(word_write)
            integer i, j, k;

            integer addr;
            reg [31:0] temp;
            reg [31:0] status;

            reg [7:0] data [1023:0];

            for (j = 0; j < 1024; j = j + 1) begin
                data[j] = {$random};
                spi_chip.mem[j] = data[j];
            end

            for (i = 0; i < 1000; i = i + 1) begin
                addr = {$random} % (1021);
                temp = {$random};

                $display(addr);

                wbmaster.WRITE(3 * 4, 1);
                wbmaster.WRITE(1 * 4, addr);
                wbmaster.WRITE(2 * 4, temp);

                data[addr + 0] = temp[8 * 0+:8];
                data[addr + 1] = temp[8 * 1+:8];
                data[addr + 2] = temp[8 * 2+:8];
                data[addr + 3] = temp[8 * 3+:8];

                wbmaster.READ(0 * 4, status);
                while (status != 0) begin
                    wbmaster.READ(0 * 4, status);
                end

                for (j = 0; j < 1024; j = j + 1) begin
                    if (data[j] != spi_chip.mem[j]) begin
                        $display(j);
                    end

                    `FAIL_UNLESS_EQUAL(data[j], spi_chip.mem[j]);
                end
            end
        `SVTEST_END

        `SVTEST(stream_write)
            integer i, j, k;

            integer addr, word_len;
            reg [31:0] word;
            reg [31:0] status;

            reg [7:0] data [1023:0];

            for (j = 0; j < 1024; j = j + 1) begin
                data[j] = {$random};
                spi_chip.mem[j] = data[j];
            end

            for (i = 0; i < 10; i = i + 1) begin
                word_len = {$random} % 100;
                addr = 4 * ({$random} % (256 - word_len));
                word = {$random};

                for (j = 0; j < word_len; j = j + 1) begin
                    data[addr + j * 4 + 0] = word[8 * 0+:8];
                    data[addr + j * 4 + 1] = word[8 * 1+:8];
                    data[addr + j * 4 + 2] = word[8 * 2+:8];
                    data[addr + j * 4 + 3] = word[8 * 3+:8];
                end

                wbmaster.WRITE(1 * 4, addr);
                wbmaster.WRITE(3 * 4, word_len);
                wbmaster.WRITE(2 * 4, word);

                wbmaster.READ(0 * 4, status);
                while (status != 0) begin
                    wbmaster.READ(0 * 4, status);
                end

                for (j = 0; j < 1024; j = j + 1) begin
                    if (data[j] != spi_chip.mem[j]) begin
                        $display(j);
                    end

                    `FAIL_UNLESS_EQUAL(data[j], spi_chip.mem[j]);
                end
            end
        `SVTEST_END
    
    `SVUNIT_TESTS_END

endmodule
