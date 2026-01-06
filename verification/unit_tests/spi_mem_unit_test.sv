`include "svunit_defines.svh"

`include "user_defines.v"

`include "spi_mem.v"

`include "test/clk_rst.v"
`include "test/spi_chip.v"

`include "bus/busarb.v"
`include "bus/virtual_master.v"

module spi_mem_m_unit_test;
  import svunit_pkg::svunit_testcase;

  string name = "spi_mem_m_ut";
  svunit_testcase svunit_ut;

  localparam MEMORY_SIZE = 10000;

  wire clk, nrst;
  clk_rst_m clk_rst(.clk_o(clk), .nrst_o(nrst));

  wire [`BUS_MIPORT] mportai;
  wire [`BUS_MOPORT] mportao;

  wire [`BUS_SIPORT] sportai;
  wire [`BUS_SOPORT] sportao;

  busarb_m #(1, 1, 1) arbiter(
    .clk_i(clk),
    .nrst_i(nrst),

    .mports_i({ mportao }),
    .mports_o({ mportai }),

    .sports_i({ sportao }),
    .sports_o({ sportai })
  );

  virtual_master_m master(
    .clk_i(clk),
    .nrst_i(nrst),

    .mport_i(mportai),
    .mport_o(mportao)
  );

  wire spi_clk;
  wire spi_cs;
  wire [3:0] spi_mosi;
  wire [3:0] spi_miso;
  wire spi_dqsmi;
  wire spi_dqsmo;

  //===================================
  // This is the UUT that we're 
  // running the Unit Tests on
  //===================================
  spi_mem_m #(0, MEMORY_SIZE) my_spi_mem_m(
    .clk_i(clk),
    .nrst_i(nrst),

    .sport_i(sportai),
    .sport_o(sportao),

    .spi_clk_o(spi_clk),
    .spi_cs_o(spi_cs),
    .spi_mosi_o(spi_mosi),
    .spi_miso_i(spi_miso),
    .spi_dqsm_i(spi_dqsmi),
    .spi_dqsm_o(spi_dqsmo)
  );

  spi_chip_m #(5, 1, MEMORY_SIZE) spi_chip(
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
    `SVTEST(bytes)
      integer count;
      reg [7:0] test_mem[MEMORY_SIZE - 1:0];

      reg [`BUS_ADDR_PORT] addr;
      reg [7:0] data;
      reg [7:0] read_data;

      integer i, j;

      count = 100;

      for (i = 0; i < MEMORY_SIZE; i = i + 1) begin
        test_mem[i] = spi_chip.mem[i];
      end

      for (i = 0; i < count; i = i + 1) begin
        addr = {$random} % MEMORY_SIZE;
        data = {$random};

        master.WRITE_BYTE(addr, data);
        test_mem[addr] = data;

        for (j = 0; j < MEMORY_SIZE; j = j + 1) begin
          // $display("0x%h == 0x%h", test_mem[j], spi_chip.mem[j]);
          `FAIL_UNLESS_EQUAL(test_mem[j], spi_chip.mem[j]);
        end

        master.READ_BYTE(addr, read_data);

        // $display("0x%h == 0x%h", data, read_data);
        `FAIL_UNLESS_EQUAL(data, read_data);
      end
    `SVTEST_END

    `SVTEST(words)
      integer count;
      reg [7:0] test_mem[MEMORY_SIZE - 1:0];

      reg [`BUS_ADDR_PORT] addr;
      reg [31:0] data;
      reg [31:0] read_data;

      integer i, j;

      count = 100;

      for (i = 0; i < MEMORY_SIZE; i = i + 1) begin
        test_mem[i] = spi_chip.mem[i];
      end

      for (i = 0; i < count; i = i + 1) begin
        addr = {$random} % (MEMORY_SIZE - 3);
        data = {$random};

        master.WRITE_WORD(addr, data);
        test_mem[addr + 0] = data[7:0];
        test_mem[addr + 1] = data[15:8];
        test_mem[addr + 2] = data[23:16];
        test_mem[addr + 3] = data[31:24];

        for (j = 0; j < MEMORY_SIZE; j = j + 1) begin
          // $display("%d: 0x%h == 0x%h, %d", j, test_mem[j], spi_chip.mem[j], addr);
          `FAIL_UNLESS_EQUAL(test_mem[j], spi_chip.mem[j]);
        end

        master.READ_WORD(addr, read_data);

        // $display("0x%h == 0x%h", data, read_data);
        `FAIL_UNLESS_EQUAL(data, read_data);
      end
    `SVTEST_END

    `SVTEST(single_stream)
      integer count;

      reg [`BUS_ADDR_PORT] addr;
      reg [31:0] data;
      reg [31:0] read_data;

      integer i, j;

      count = 1;

      `FAIL_IF(1);

      for (i = 0; i < count; i = i + 1) begin
        addr = {$random} % (MEMORY_SIZE - 1000);
        data = {$random};

        master.WRITE_STREAM(addr, 1000, data);

        for (j = 0; j < 1000 - 4; j = j + 4) begin
          `FAIL_UNLESS_EQUAL(data[7:0], spi_chip.mem[addr + j + 0]);
          `FAIL_UNLESS_EQUAL(data[15:8], spi_chip.mem[addr + j + 1]);
          `FAIL_UNLESS_EQUAL(data[23:16], spi_chip.mem[addr + j + 2]);
          `FAIL_UNLESS_EQUAL(data[31:24], spi_chip.mem[addr + j + 3]);
        end
      end
    `SVTEST_END
  `SVUNIT_TESTS_END

endmodule
