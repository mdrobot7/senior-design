`include "svunit_defines.svh"

`include "user_defines.v"
`include "bus/busarb.v"
`include "test/bus_slave.v"
`include "test/clk_rst.v"
`include "stream/stream_fifo.v"

`include "core_controller/index_fetch.v"

module index_fetch_m_unit_test;
  import svunit_pkg::svunit_testcase;

  string name = "index_fetch_m_ut";
  svunit_testcase svunit_ut;


  //===================================
  // This is the UUT that we're
  // running the Unit Tests on
  //===================================

  wire clk;
  wire nrst;
  clk_rst_m  #(10, 30) clk_rst (
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

  localparam INDEX_BUFFER_ADDR         = 32'h00001000;
  localparam INDEX_BUFFER_SIZE_BYTES   = 1024;
  bus_slave_m #(INDEX_BUFFER_ADDR, INDEX_BUFFER_SIZE_BYTES) ram (
    .clk_i(clk),
    .nrst_i(nrst),
    .sport_i(sportai),
    .sport_o(sportao),
    .bad_read_o()
  );

  reg                                enable;
  reg  [`WORD]                       index_buffer_addr;
  reg  [`WORD]                       num_dispatches;
  reg                                model_done_clr;
  wire                               model_done;
  reg  [`STREAM_MIPORT(`WORD_WIDTH)] mstreami;
  wire [`STREAM_MOPORT(`WORD_WIDTH)] mstreamo;
  index_fetch_m #(
    .CACHE_LEN_WORDS(64)
  ) dut (
    .clk_i(clk),
    .nrst_i(nrst),

    .mport_i(mportai),
    .mport_o(mportao),

    .enable_i(enable),
    .index_buffer_addr_i(index_buffer_addr),
    .num_dispatches_i(num_dispatches),
    .model_done_clr_i(model_done_clr),
    .model_done_o(model_done),

    .mstream_i(mstreami),
    .mstream_o(mstreamo)
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
    enable <= 0;
    index_buffer_addr <= 32'h00001000;
    num_dispatches <= 0;
    model_done_clr <= 0;
    mstreami <= 0;
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

  `SVTEST(test_basic)
    clk_rst.WAIT_CYCLES(1);
    // 64 triangles, 64 * 3  words
    for (int i = 0; i < 64 * 3 * 4; i++) begin
      ram.mem[i] = $urandom;
    end
    num_dispatches = 64 * 3;

    // Start fetching
    enable = 1;
    for (int i = 0; i < 10000000; i++) begin
      clk_rst.WAIT_CYCLES(1);
      if (dut.fifo_full)
        break;
    end
    `FAIL_UNLESS_EQUAL(dut.fifo_full, 1);
    enable = 0;
    clk_rst.WAIT_CYCLES(1);

    // Check
    for (int i = 0; i < 64; i++) begin
      int byte_offset = i * 4;
      reg [`WORD] mem_value = {ram.mem[byte_offset+3], ram.mem[byte_offset+2], ram.mem[byte_offset+1], ram.mem[byte_offset]};

      if (mstreamo[`STREAM_MO_DATA(`WORD_WIDTH)] != mem_value) begin
        $display("Fetch mismatch at idx %d, expected 0x%x, got 0x%x", i, mem_value, mstreamo[`STREAM_MO_DATA(`WORD_WIDTH)]);
        `FAIL_UNLESS_EQUAL(mstreamo[`STREAM_MO_DATA(`WORD_WIDTH)], mem_value);
      end

      mstreami[`STREAM_MI_READY(`WORD_WIDTH)] = 1;
      clk_rst.WAIT_CYCLES(1);
    end
    `FAIL_UNLESS_EQUAL(mstreamo[`STREAM_MO_VALID(`WORD_WIDTH)], 0); // FIFO empty
  `SVTEST_END

  `SVTEST(test_model_done)
    clk_rst.WAIT_CYCLES(1);
    // 64 triangles, 64 * 3  words
    for (int i = 0; i < 64 * 3 * 4; i++) begin
      ram.mem[i] = $urandom;
    end
    num_dispatches = 5 * 3;

    // Start fetching
    enable = 1;
    for (int i = 0; i < 10000000; i++) begin
      clk_rst.WAIT_CYCLES(1);
      if (dut.fifo_full || model_done)
        break;
    end
    `FAIL_UNLESS_EQUAL(dut.fifo_full, 0);
    `FAIL_UNLESS_EQUAL(model_done, 1);
    enable = 0;
    clk_rst.WAIT_CYCLES(1);

    // Check
    for (int i = 0; i < 15; i++) begin
      int byte_offset = i * 4;
      reg [`WORD] mem_value = {ram.mem[byte_offset+3], ram.mem[byte_offset+2], ram.mem[byte_offset+1], ram.mem[byte_offset]};

      if (mstreamo[`STREAM_MO_DATA(`WORD_WIDTH)] != mem_value) begin
        $display("Fetch mismatch at idx %d, expected 0x%x, got 0x%x", i, mem_value, mstreamo[`STREAM_MO_DATA(`WORD_WIDTH)]);
        `FAIL_UNLESS_EQUAL(mstreamo[`STREAM_MO_DATA(`WORD_WIDTH)], mem_value);
      end

      mstreami[`STREAM_MI_READY(`WORD_WIDTH)] = 1;
      clk_rst.WAIT_CYCLES(1);
    end
    `FAIL_UNLESS_EQUAL(mstreamo[`STREAM_MO_VALID(`WORD_WIDTH)], 0); // FIFO empty
  `SVTEST_END

  `SVTEST(test_multiple)
    clk_rst.WAIT_CYCLES(1);
    // 64 triangles, 64 * 3  words
    for (int i = 0; i < 64 * 3 * 4; i++) begin
      ram.mem[i] = $urandom;
    end
    num_dispatches = 64 * 3;

    for (int run = 0; run < 3; run++) begin
      // Start fetching
      enable = 1;
      for (int i = 0; i < 10000000; i++) begin
        clk_rst.WAIT_CYCLES(1);
        if (dut.fifo_full)
          break;
      end
      if (!dut.fifo_full) begin
        $display("FIFO not filled on run %d", run);
        `FAIL_UNLESS_EQUAL(dut.fifo_full, 1);
      end
      enable = 0;
      clk_rst.WAIT_CYCLES(1);

      // Check
      for (int i = 0; i < 64; i++) begin
        int byte_offset = run * 64 + i * 4;
        reg [`WORD] mem_value = {ram.mem[byte_offset+3], ram.mem[byte_offset+2], ram.mem[byte_offset+1], ram.mem[byte_offset]};

        if (mstreamo[`STREAM_MO_DATA(`WORD_WIDTH)] != mem_value) begin
          $display("Fetch mismatch at run %d idx %d, expected 0x%x, got 0x%x", run, i, mem_value, mstreamo[`STREAM_MO_DATA(`WORD_WIDTH)]);
          `FAIL_UNLESS_EQUAL(mstreamo[`STREAM_MO_DATA(`WORD_WIDTH)], mem_value);
        end

        mstreami[`STREAM_MI_READY(`WORD_WIDTH)] = 1;
        clk_rst.WAIT_CYCLES(1);
      end
      mstreami[`STREAM_MI_READY(`WORD_WIDTH)] = 0;
      `FAIL_UNLESS_EQUAL(mstreamo[`STREAM_MO_VALID(`WORD_WIDTH)], 0); // FIFO empty
    end
    `FAIL_UNLESS_EQUAL(model_done, 1);
  `SVTEST_END

  `SVUNIT_TESTS_END

endmodule
