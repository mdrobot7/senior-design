`include "svunit_defines.svh"
`include "user_defines.v"
`include "test/bus_master.v"
`include "test/bus_slave.v"
`include "test/clk_rst.v"
`include "bus/busarb.v"


module bus_unit_test;
  import svunit_pkg::svunit_testcase;

  string name = "bus_ut";
  svunit_testcase svunit_ut;


  //===================================
  // This is the UUT that we're
  // running the Unit Tests on
  //===================================
  reg clk;
  reg nrst;

  clk_rst_m #(10, 30) clk_rst (
    .clk_o(clk),
    .nrst_o(nrst)
  );

  wire [`BUS_MIPORT] mportai;
  reg  [`BUS_MOPORT] mportao;

  wire [`BUS_SIPORT] sportai;
  wire [`BUS_SOPORT] sportao;

  busarb_m #(1, 1, 1) arbiter (
      .clk_i(clk),
      .nrst_i(nrst),

      .mports_i({ mportao }),
      .mports_o({ mportai }),

      .sports_i({ sportao }),
      .sports_o({ sportai })
  );

  localparam SLAVE_ADDR = 20'd0;
  localparam MEM_SIZE = 1024;

  wire bad_read;

  bus_slave_m #(SLAVE_ADDR, MEM_SIZE) slave (
    .clk_i(clk),
    .nrst_i(nrst),

    .sport_i(sportai),
    .sport_o(sportao),

    .bad_read_o(bad_read)
  );

  bus_master_m #(MEM_SIZE) master (
    .clk_i(clk),
    .nrst_i(nrst),

    .mport_i(mportai),
    .mport_o(mportao)
  );

  reg [7:0] mem[MEM_SIZE-1:0];

  reg [`WORD] read_word;

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

  `SVTEST(test_rbyte)
    load_slave();
    for (int i = 0; i < MEM_SIZE; i++) begin
      master.READ_BYTE(SLAVE_ADDR + i, mem[i]);
    end
    check_mem();
  `SVTEST_END

  `SVTEST(test_rword)
    load_slave();
    for (int i = 0; i < MEM_SIZE; i = i + 4) begin
      master.READ_WORD(SLAVE_ADDR + i, read_word);
      mem[i + 0] = read_word[ 7: 0];
      mem[i + 1] = read_word[15: 8];
      mem[i + 2] = read_word[23:16];
      mem[i + 3] = read_word[31:24];
    end
    check_mem();
  `SVTEST_END

  `SVTEST(test_rstream)
    load_slave();
    master.READ_STREAM(SLAVE_ADDR, MEM_SIZE / 4);
    for (int i = 0; i < MEM_SIZE; i++) begin
      if (master.mem[i] != slave.mem[i]) begin
        $display("Memory not equal at offset %d", i);
        $display("Master: 0x%X, Slave 0x%X", master.mem[i], slave.mem[i]);
        `FAIL_UNLESS_EQUAL(master.mem[i], slave.mem[i]);
      end
    end
  `SVTEST_END

  `SVTEST(test_wbyte)
    load_master();
    for (int i = 0; i < MEM_SIZE; i++) begin
      master.WRITE_BYTE(SLAVE_ADDR + i, mem[i]);
    end
    check_mem();
  `SVTEST_END

  `SVTEST(test_wword)
    load_master();
    for (int i = 0; i < MEM_SIZE; i = i + 4) begin
      master.WRITE_WORD(SLAVE_ADDR + i, {mem[i + 3], mem[i + 2], mem[i + 1], mem[i + 0]});
    end
    check_mem();
  `SVTEST_END

  `SVTEST(test_wstream)
    mem[0] = $urandom % 256;
    mem[1] = $urandom % 256;
    mem[2] = $urandom % 256;
    mem[3] = $urandom % 256;
    for (int i = 4; i < MEM_SIZE; i += 4) begin
      mem[i + 0] = mem[0];
      mem[i + 1] = mem[1];
      mem[i + 2] = mem[2];
      mem[i + 3] = mem[3];
    end

    master.WRITE_STREAM(SLAVE_ADDR, MEM_SIZE / 4, {mem[3], mem[2], mem[1], mem[0]});
    check_mem();
  `SVTEST_END

  `SVUNIT_TESTS_END

  task load_slave; begin
    for(int i = 0; i < MEM_SIZE; i++) begin
      slave.mem[i] = $urandom % 256;
    end
  end
  endtask

  task load_master; begin
    for(int i = 0; i < MEM_SIZE; i++) begin
      mem[i] = $urandom % 256;
    end
  end
  endtask

  task check_mem;
  begin
    for(int i = 0; i < MEM_SIZE; i++) begin
      if (mem[i] != slave.mem[i]) begin
        $display("Memory not equal at offset %d", i);
        $display("Master: 0x%X, Slave 0x%X", mem[i], slave.mem[i]);
        `FAIL_UNLESS_EQUAL(mem[i], slave.mem[i]);
      end
    end
  end
  endtask

  task timeout;
    input integer cycles;
  begin
    clk_rst.WAIT_CYCLES(cycles);
  end
  endtask

endmodule
