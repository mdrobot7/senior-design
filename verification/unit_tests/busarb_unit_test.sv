`include "svunit_defines.svh"

`include "user_defines.v"

`include "spi_mem.v"

`include "test/clk_rst.v"
`include "test/spi_chip.v"
`include "test/bus_slave.v"
`include "test/bus_master.v"

`include "bus/busarb.v"

module busarb_m_unit_test;
  import svunit_pkg::svunit_testcase;

  string name = "busarb_m_ut";
  svunit_testcase svunit_ut;

  wire clk, nrst;
  clk_rst_m clk_rst(.clk_o(clk), .nrst_o(nrst));

  wire [`BUS_MIPORT] mportai;
  wire [`BUS_MOPORT] mportao;

  wire [`BUS_MIPORT] mportbi;
  wire [`BUS_MOPORT] mportbo;

  wire [`BUS_SIPORT] sportai;
  wire [`BUS_SOPORT] sportao;

  wire [`BUS_SIPORT] sportbi;
  wire [`BUS_SOPORT] sportbo;


  //===================================
  // This is the UUT that we're
  // running the Unit Tests on
  //===================================
  busarb_m #(2, 2, 2) dut(
    .clk_i(clk),
    .nrst_i(nrst),

    .mports_i({ mportbo, mportao }),
    .mports_o({ mportbi, mportai }),

    .sports_i({ sportbo, sportao }),
    .sports_o({ sportbi, sportai })
  );

  bus_master_m master_a(
    .clk_i(clk),
    .nrst_i(nrst),

    .mport_i(mportai),
    .mport_o(mportao)
  );

  bus_master_m master_b(
    .clk_i(clk),
    .nrst_i(nrst),

    .mport_i(mportbi),
    .mport_o(mportbo)
  );

  wire spi_clk1;
  wire spi_cs1;
  wire [3:0] spi_mosi1;
  wire [3:0] spi_miso1;
  wire spi_dqsmi1;
  wire spi_dqsmo1;

  spi_mem_m #(0, 1000) spi_mem1(
      .clk_i(clk),
      .nrst_i(nrst),

      .sport_i({ sportai }),
      .sport_o({ sportao }),

      .spi_clk_o(spi_clk1),
      .spi_cs_o(spi_cs1),
      .spi_mosi_o(spi_mosi1),
      .spi_miso_i(spi_miso1),
      .spi_dqsm_i(spi_dqsmi1),
      .spi_dqsm_o(spi_dqsmo1)
  );

  spi_chip_m #(7, 1, 1000) spi_chip1(
      .clk_i(spi_clk1),
      .cs_i(spi_cs1),
      .mosi_i(spi_mosi1),
      .miso_o(spi_miso1),
      .dqsm_o(spi_dqsmi1),
      .dqsm_i(spi_dqsmo1)
  );

  wire spi_clk2;
  wire spi_cs2;
  wire [3:0] spi_mosi2;
  wire [3:0] spi_miso2;
  wire spi_dqsmi2;
  wire spi_dqsmo2;

  spi_mem_m #(1000, 1000) spi_mem2(
      .clk_i(clk),
      .nrst_i(nrst),

      .sport_i({ sportbi }),
      .sport_o({ sportbo }),

      .spi_clk_o(spi_clk2),
      .spi_cs_o(spi_cs2),
      .spi_mosi_o(spi_mosi2),
      .spi_miso_i(spi_miso2),
      .spi_dqsm_i(spi_dqsmi2),
      .spi_dqsm_o(spi_dqsmo2)
  );

  spi_chip_m #(7, 1, 1000) spi_chip2(
      .clk_i(spi_clk2),
      .cs_i(spi_cs2),
      .mosi_i(spi_mosi2),
      .miso_o(spi_miso2),
      .dqsm_o(spi_dqsmi2),
      .dqsm_i(spi_dqsmo2)
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
    /* Place Teardown Code Here */

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
    `SVTEST(simple)
      fork
        fork
          begin : TEST_A
            master_a.WRITE_BYTE(10, 143);
          end

          begin : TEST_B
            reg [7:0] read_data;

            #1000;

            master_b.READ_BYTE(10, read_data);

            `FAIL_UNLESS_EQUAL(143, read_data);
          end
        join
        begin
          clk_rst.WAIT_CYCLES(10000000);

          $display("Timeout reached");
          `FAIL_IF(1);
        end
      join_any

      disable fork;
    `SVTEST_END

    `SVTEST(high_usage)
      fork
        fork
          begin : TEST_A
            integer i;

            for (i = 0; i < 2000; i = i + 1) begin
              master_a.WRITE_BYTE(10, 143);
            end

            for (i = 0; i < 20; i = i + 1) begin
              master_a.WRITE_STREAM(0, 20, 45289345);
            end
          end

          begin : TEST_B
            reg [7:0] read_data;

            integer i;

            while (1) begin
              for (i = 0; i < 2000; i = i + 1) begin
                master_b.READ_BYTE(1999 - i, read_data);
              end
            end
          end
        join_any
        begin
          clk_rst.WAIT_CYCLES(10000000);

          $display("Timeout reached");
          `FAIL_IF(1);
        end
      join_any

      disable fork;
    `SVTEST_END
  `SVUNIT_TESTS_END

endmodule
