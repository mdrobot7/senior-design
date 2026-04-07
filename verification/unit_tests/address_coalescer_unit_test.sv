`include "svunit_defines.svh"
`include "user_defines.v"
`include "test/clk_rst.v" 
`include "test/spi_chip.v"
`include "test/bus_master.v"

`include "bus/busarb.v"
`include "spi_mem.v"

`include "bus/address_coalescer.v"

module address_coalescer_m_unit_test;
  import svunit_pkg::svunit_testcase;

  string name = "address_coalescer_m_ut";
  svunit_testcase svunit_ut;


  //===================================
  // This is the UUT that we're 
  // running the Unit Tests on
  //===================================

  reg[`BUS_SIPORT_SIZE*`NUM_CORES-1:0]  core_port_i;
  wire[`BUS_SOPORT_SIZE*`NUM_CORES-1:0] core_port_o;
  reg[`BUS_MIPORT_SIZE*`NUM_CORES-1:0]  arb_port_i;
  wire[`BUS_MOPORT_SIZE*`NUM_CORES-1:0] arb_port_o;
  reg[5:0] captured_val;

  wire clk, nrst;
  clk_rst_m clk_rst(.clk_o(clk), .nrst_o(nrst));

  wire [`BUS_SIPORT] sportai;
  wire [`BUS_SOPORT] sportao;

  localparam MEM_BASE_ADDR = 0;
  localparam MEM_SIZE = 32'h8000;

  wire spi_clk1;
  wire spi_cs1;
  wire [3:0] spi_mosi1, spi_sio_en;
  wire [3:0] spi_miso1;
  wire spi_dqsmi1;
  wire spi_dqsmo1;
  wire spi_dqsm_en;

  reg [31:0] addr;

  busarb_m #(6, 1, 1) arbiter(
      .clk_i(clk),
      .nrst_i(nrst),

      .mports_i({ arb_port_o }),
      .mports_o({ arb_port_i }),

      .sports_i({ sportao }),
      .sports_o({ sportai })
  );

    spi_mem_m #(MEM_BASE_ADDR, MEM_SIZE) spi_mem1(
    .clk_i(clk),
    .nrst_i(nrst),

    .sport_i({ sportai }),
    .sport_o({ sportao }),

    .spi_clk_o(spi_clk1),
    .spi_cs_o(spi_cs1),
    .spi_mosi_o(spi_mosi1),
    .spi_miso_i(spi_miso1),
    .spi_dqsm_i(spi_dqsmi1),
    .spi_dqsm_o(spi_dqsmo1),
    .spi_dqsm_en_o(spi_dqsm_en),
    .spi_sio_en_o(spi_sio_en)
  );

  spi_chip_m #(5, 1, MEM_SIZE) spi_chip1(
    .clk_i(spi_clk1),
    .cs_i(spi_cs1),
    .mosi_i(spi_mosi1),
    .miso_o(spi_miso1),
    .dqsm_o(spi_dqsmi1),
    .dqsm_i(spi_dqsmo1)
  );

  address_coalescer_m my_address_coalescer_m(
    .core_port_i(core_port_i),
    .core_port_o(core_port_o),
    .arb_port_i(arb_port_i),
    .arb_port_o(arb_port_o)
  );

    reg[`NUM_CORES-1:0] data_o [7:0];
  bus_master_m c0 (
    .clk_i(clk),
    .nrst_i(nrst),
    .mport_i(core_port_o[`BUS_MIPORT_SIZE*0 +: `BUS_MIPORT_SIZE]),
    .mport_o(core_port_i[`BUS_SIPORT_SIZE*0 +: `BUS_SIPORT_SIZE])
  );

  bus_master_m c1 (
    .clk_i(clk),
    .nrst_i(nrst),
    .mport_i(core_port_o[`BUS_SOPORT_SIZE*1 +: `BUS_SOPORT_SIZE]),
    .mport_o(core_port_i[`BUS_SIPORT_SIZE*1 +: `BUS_SIPORT_SIZE])
  );

  bus_master_m c2 (
    .clk_i(clk),
    .nrst_i(nrst),
    .mport_i(core_port_o[`BUS_SOPORT_SIZE*2 +: `BUS_SOPORT_SIZE]),
    .mport_o(core_port_i[`BUS_SIPORT_SIZE*2 +: `BUS_SIPORT_SIZE])
  );

  bus_master_m c3(
    .clk_i(clk),
    .nrst_i(nrst),
    .mport_i(core_port_o[`BUS_SOPORT_SIZE*3 +: `BUS_SOPORT_SIZE]),
    .mport_o(core_port_i[`BUS_SIPORT_SIZE*3 +: `BUS_SIPORT_SIZE])
  );

  bus_master_m c4 (
    .clk_i(clk),
    .nrst_i(nrst),
    .mport_i(core_port_o[`BUS_SOPORT_SIZE*4 +: `BUS_SOPORT_SIZE]),
    .mport_o(core_port_i[`BUS_SIPORT_SIZE*4 +: `BUS_SIPORT_SIZE])
  );

  bus_master_m c5 (
    .clk_i(clk),
    .nrst_i(nrst),
    .mport_i(core_port_o[`BUS_SOPORT_SIZE*5 +: `BUS_SOPORT_SIZE]),
    .mport_o(core_port_i[`BUS_SIPORT_SIZE*5 +: `BUS_SIPORT_SIZE])
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
    clk_rst.WAIT_CYCLES(3);
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

  `SVTEST(full_read)
    addr = {$random % MEM_SIZE};
    clk_rst.RESET();
    clk_rst.WAIT_CYCLES(3);
    //fork to run all at the same time
    fork
      c0.READ_BYTE(addr, data_o[0]);
      begin
        c1.READ_BYTE(addr, data_o[1]);
      end begin
        c2.READ_BYTE(addr, data_o[2]);
      end begin
        c3.READ_BYTE(addr, data_o[3]);
      end begin
        c4.READ_BYTE(addr, data_o[4]);
      end begin
        c5.READ_BYTE(addr, data_o[5]);
      end begin
        `FAIL_UNLESS_EQUAL(my_address_coalescer_m.coalesce, 'b111111);
      end
    join
    clk_rst.WAIT_CYCLES(1);
    `FAIL_UNLESS_EQUAL(c0.mport_i, c1.mport_i);
    `FAIL_UNLESS_EQUAL(c1.mport_i, c2.mport_i);
    `FAIL_UNLESS_EQUAL(c2.mport_i, c3.mport_i);
    `FAIL_UNLESS_EQUAL(c3.mport_i, c4.mport_i);
    `FAIL_UNLESS_EQUAL(c4.mport_i, c5.mport_i);

    `FAIL_UNLESS_EQUAL(data_o[0], data_o[1]);
    `FAIL_UNLESS_EQUAL(data_o[1], data_o[2]);
    `FAIL_UNLESS_EQUAL(data_o[2], data_o[3]);
    `FAIL_UNLESS_EQUAL(data_o[3], data_o[4]);
    `FAIL_UNLESS_EQUAL(data_o[4], data_o[5]);

    `FAIL_UNLESS_EQUAL(my_address_coalescer_m.coalesce, 'b111111);

  `SVTEST_END

  `SVTEST(single_read)
    addr = {$random % (MEM_SIZE-100)};
    clk_rst.RESET();
    clk_rst.WAIT_CYCLES(3);
    fork
      c0.READ_BYTE(addr, data_o[0]);
      begin
        `FAIL_UNLESS_EQUAL(my_address_coalescer_m.coalesce, 'b111111);
      end
    join
    clk_rst.WAIT_CYCLES(1);

    `FAIL_UNLESS_EQUAL(my_address_coalescer_m.coalesce, 'b111111);
  `SVTEST_END


  `SVTEST(partial_read)
    addr = {$random % (MEM_SIZE-100)};
    clk_rst.RESET();
    clk_rst.WAIT_CYCLES(3);
    fork
      c0.READ_BYTE(addr, data_o[0]);
      begin
        c3.READ_BYTE(addr, data_o[3]);
      end begin
        c5.READ_BYTE(addr, data_o[5]);
      end begin
        clk_rst.WAIT_CYCLES(1);
        captured_val = my_address_coalescer_m.coalesce;
      end
    join
    clk_rst.WAIT_CYCLES(1);

    `FAIL_UNLESS_EQUAL(captured_val, 'b111111);
    `FAIL_UNLESS_EQUAL(my_address_coalescer_m.coalesce, 'b111111);
  `SVTEST_END

  `SVTEST(partial_read_2)
    addr = {$random % (MEM_SIZE-100)};
    clk_rst.RESET();
    clk_rst.WAIT_CYCLES(3);
    fork
      begin
        c2.READ_BYTE(addr+2, data_o[2]);
      end begin
        c3.READ_BYTE(addr, data_o[3]);
      end begin
        c5.READ_BYTE(addr, data_o[5]);
      end begin
        clk_rst.WAIT_CYCLES(1);
        captured_val = my_address_coalescer_m.coalesce;
      end begin
        clk_rst.WAIT_CYCLES(1);
        captured_val = my_address_coalescer_m.coalesce;
      end
    join
    clk_rst.WAIT_CYCLES(1);

    `FAIL_IF_EQUAL(captured_val, 'b111111);
  `SVTEST_END

  `SVTEST(different_read)
    addr = {$random % (MEM_SIZE-100)};
    clk_rst.RESET();
    clk_rst.WAIT_CYCLES(3);
    fork
      c0.READ_BYTE(addr, data_o[0]);
      begin
        c1.READ_BYTE(addr+1, data_o[1]);
      end begin
        c2.READ_BYTE(addr+2, data_o[2]);
      end begin
        c3.READ_BYTE(addr, data_o[3]);
      end begin
        c4.READ_BYTE(addr+4, data_o[4]);
      end begin
        c5.READ_BYTE(addr, data_o[5]);
      end
    join
    clk_rst.WAIT_CYCLES(1);

    `FAIL_IF_EQUAL(captured_val, 'b111111);
  `SVTEST_END

  `SVTEST(full_write)
    clk_rst.RESET();
    clk_rst.WAIT_CYCLES(3);
    addr = {$random % MEM_SIZE};
    fork
      c0.WRITE_BYTE(addr, 8'h01);
      begin
        c1.WRITE_BYTE(addr, 8'h02);
      end begin
        c2.WRITE_BYTE(addr, 8'h03);
      end begin
        c3.WRITE_BYTE(addr, 8'h04);
      end begin
        c4.WRITE_BYTE(addr, 8'h05);
      end begin
        c5.WRITE_BYTE(addr, 8'h06);
      end
    join
    clk_rst.WAIT_CYCLES(1);
    //only first core should write
    `FAIL_UNLESS_EQUAL(spi_chip1.mem[addr], 8'h01);

    `FAIL_UNLESS_EQUAL(my_address_coalescer_m.coalesce, 'b111111);
  `SVTEST_END

   `SVTEST(one_write)
    clk_rst.RESET();
    clk_rst.WAIT_CYCLES(3);
    addr = {$random % MEM_SIZE};
    fork
      c5.WRITE_BYTE(addr, 8'h06);
    join
    clk_rst.WAIT_CYCLES(1);

    `FAIL_UNLESS_EQUAL(spi_chip1.mem[addr], 8'h06);
  `SVTEST_END

    `SVTEST(partial_write)
    addr = {$random % (MEM_SIZE-100)};
    clk_rst.RESET();
    clk_rst.WAIT_CYCLES(3);
    fork
      c0.WRITE_BYTE(addr, 3);
      begin
        c3.WRITE_BYTE(addr, 1);
      end begin
        c5.WRITE_BYTE(addr, 2);
      end begin
        clk_rst.WAIT_CYCLES(1);
        captured_val = my_address_coalescer_m.coalesce;
      end
    join
    clk_rst.WAIT_CYCLES(1);

    `FAIL_UNLESS_EQUAL(captured_val, 'b111111);
    `FAIL_UNLESS_EQUAL(spi_chip1.mem[addr], 8'h03);
  `SVTEST_END

  `SVTEST(partial_write_2)
    addr = {$random % (MEM_SIZE-100)};
    clk_rst.RESET();
    clk_rst.WAIT_CYCLES(3);
    fork
      begin
        c2.WRITE_BYTE(addr+2, 1);
      end begin
        c3.WRITE_BYTE(addr, 0);
      end begin
        c5.WRITE_BYTE(addr, 2);
      end begin
        clk_rst.WAIT_CYCLES(1);
        captured_val = my_address_coalescer_m.coalesce;
      end begin
        clk_rst.WAIT_CYCLES(1);
        captured_val = my_address_coalescer_m.coalesce;
      end
    join
    clk_rst.WAIT_CYCLES(1);

    `FAIL_IF_EQUAL(captured_val, 'b111111);
    `FAIL_UNLESS_EQUAL(spi_chip1.mem[addr+2], 1);
    //c5 should write to addr
    `FAIL_UNLESS_EQUAL(spi_chip1.mem[addr], 2);
  `SVTEST_END

  `SVUNIT_TESTS_END

endmodule
