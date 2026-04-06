`include "svunit_defines.svh"

`include "user_defines.v"
`include "bus/busarb.v"
`include "test/bus_slave.v"
`include "test/clk_rst.v"
`include "stream/stream_fifo.v"
`include "core_controller/index_fetch.v"
`include "vertex_order_buffer.v"
`include "shaded_vertex_cache.v"

`include "core_controller/dispatch.v"

module dispatch_m_unit_test;
  import svunit_pkg::svunit_testcase;

  string name = "dispatch_m_ut";
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

  wire [`STREAM_MOPORT(`NUM_CORES_WIDTH)] vertorder_mstreamo;
  wire [`STREAM_MIPORT(`NUM_CORES_WIDTH)] vertorder_mstreami;
  wire                                    vertorder_empty;
  reg                                     vertorder_full; // Driven by TB
  vertex_order_buffer_m #(
    .ENTRIES(16),
    .INDEX_WIDTH(`NUM_CORES_WIDTH)
  ) vertorder (
    .clk_i(clk),
    .nrst_i(nrst),

    .sstream_i(vertorder_mstreamo),
    .sstream_o(vertorder_mstreami),
    .mstream_i(32'b0),
    .mstream_o(),

    .clear_i(1'b0),
    .full_o(),
    .empty_o(vertorder_empty)
  );

  wire [`WORD]          vertcache_test_index;
  wire                  vertcache_test_valid;
  wire                  vertcache_test_found;
  reg  [`SHADED_VERTEX] vertcache_store_vertex;
  reg  [`WORD]          vertcache_store_index;
  reg                   vertcache_store_valid;
  shaded_vertex_cache_m #(
    .ENTRIES(16)
  ) vertcache (
    .clk_i(clk),
    .nrst_i(nrst),

    .clear_i(1'b0),

    .test_index_i(vertcache_test_index),
    .test_valid_i(vertcache_test_valid),
    .test_found_o(vertcache_test_found),

    .store_vertex_i(vertcache_store_vertex),
    .store_index_i(vertcache_store_index),
    .store_valid_i(vertcache_store_valid),

    .mstream_i(0),
    .mstream_o()
  );


  reg [`WORD]           index_buffer_addr;
  reg                   index_fetch_enable;
  reg                   reset_dispatch;
  reg                   enable;
  reg                   dispatch_indices;
  reg  [`WORD]          num_dispatches;
  reg  [`NUM_CORES-1:0] core_enable;
  wire [`WORD]          thread_id;
  wire [`WORD]          inst;
  wire [`NUM_CORES-1:0] core_stall;
  wire                  dispatch_done;
  wire                  model_done;
  dispatch_m #(
    .INDEX_FETCH_CACHE_LEN_WORDS(64)
  ) dut (
    .clk_i(clk),
    .nrst_i(nrst),

    .mport_i(mportai),
    .mport_o(mportao),

    .vertcache_test_index_o(vertcache_test_index),
    .vertcache_test_valid_o(vertcache_test_valid),
    .vertcache_test_found_i(vertcache_test_found),

    .vertorder_mstream_i(vertorder_mstreami),
    .vertorder_mstream_o(vertorder_mstreamo),
    .vertorder_full_i(vertorder_full),

    .index_buffer_addr_i(index_buffer_addr),
    .index_fetch_enable_i(index_fetch_enable),
    .index_fetch_clear_i(1'b0),
    .index_fetch_clear_done_o(),

    .reset_dispatch_i(reset_dispatch),
    .enable_i(enable),
    .dispatch_indices_i(dispatch_indices),
    .num_dispatches_i(num_dispatches),
    .core_enable_i(core_enable),

    .thread_id_o(thread_id),
    .inst_o(inst),
    .core_stall_o(core_stall),

    .dispatch_done_o(dispatch_done),
    .model_done_o(model_done)
  );

  int core_idx;

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

    index_buffer_addr = 32'h00001000;
    index_fetch_enable = 0;
    reset_dispatch = 0;
    enable = 0;
    dispatch_indices = 0;
    num_dispatches = 0;
    core_enable = 0;
    vertorder_full = 0;
    clk_rst.RESET();

    clk_rst.WAIT_CYCLES(1);

    // 64 triangles, 64 * 3  indices
    for (int i = 0; i < 64 * 3 * 4; i++) begin
      ram.mem[i] = $urandom;
    end

    // Prefill the cache
    for (int i = 0; i < 64 * 3; i++) begin
      if ($urandom < 32'h3FFFFFFF) begin
        int cur;
        int base_addr;
        cur = vertcache.current_entry;
        base_addr = i * 4;
        vertcache.valid[cur] = 1;
        vertcache.vertex[cur] = 1024 + i; // Nonsense
        vertcache.index[cur] = {ram.mem[base_addr+3], ram.mem[base_addr+2], ram.mem[base_addr+1], ram.mem[base_addr+0]};
        vertcache.current_entry = vertcache.current_entry + 1;
      end
    end
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

  `SVTEST(test_ints)
    dispatch_indices = `CORE_CTRL_DISPATCH_INT;
    num_dispatches = 100;
    dispatch_indices = 0;
    core_enable = {`NUM_CORES{1'b1}};

    enable = 1;
    for (int run = 0; run < 3; run++) begin
      reg [`WORD] tids [`NUM_CORES-1:0];
      while (1) begin
        clk_rst.WAIT_CYCLES(1);
        if (dispatch_done) begin
          break;
        end

        core_idx = $clog2(~core_stall);
        tids[core_idx] = thread_id;
      end

      for (int i = 0; i < `NUM_CORES; i++) begin
        if (tids[i] != run * `NUM_CORES + i) begin
          $display("TID mismatch at run %d core %d, expected 0x%x, got 0x%x", run, i, run * `NUM_CORES + i, tids[i]);
          `FAIL_UNLESS_EQUAL(tids[i], run * `NUM_CORES + i);
        end
      end
      clk_rst.WAIT_CYCLES(1);
      enable = 0;
      clk_rst.WAIT_CYCLES(1);
      enable = 1;
    end
  `SVTEST_END

  `SVTEST(test_indices)
    dispatch_indices = `CORE_CTRL_DISPATCH_INDEX;
    num_dispatches = 100;
    dispatch_indices = 1;
    index_fetch_enable = 1;
    core_enable = {`NUM_CORES{1'b1}};

    enable = 1;
    for (int run = 0; run < 3; run++) begin
      reg [`WORD] tids [`NUM_CORES-1:0];
      while (1) begin
        clk_rst.WAIT_CYCLES(1);
        if (dispatch_done)
          break;

        if (core_stall != {`NUM_CORES{1'b1}}) begin
          core_idx = $clog2(~core_stall);
          tids[core_idx] = thread_id;
        end
      end

      for (int i = 0; i < `NUM_CORES; i++) begin
        int expected_tid;
        int base_addr;
        base_addr = (run * `NUM_CORES + i) * 4;
        expected_tid = {ram.mem[base_addr+3], ram.mem[base_addr+2], ram.mem[base_addr+1], ram.mem[base_addr+0]};
        if (tids[i] != expected_tid) begin
          $display("TID mismatch at run %d core %d, expected 0x%x, got 0x%x", run, i, expected_tid, tids[i]);
          `FAIL_UNLESS_EQUAL(tids[i], expected_tid);
        end
      end
      clk_rst.WAIT_CYCLES(1);
      enable = 0;
      clk_rst.WAIT_CYCLES(250);
      enable = 1;
    end
  `SVTEST_END

  `SVTEST(test_reset)
    dispatch_indices = `CORE_CTRL_DISPATCH_INT;
    num_dispatches = 100;
    dispatch_indices = 0;
    core_enable = {`NUM_CORES{1'b1}};

    enable = 1;
    for (int run = 0; run < 3; run++) begin
      reg [`WORD] tids [`NUM_CORES-1:0];
      while (1) begin
        clk_rst.WAIT_CYCLES(1);
        if (dispatch_done)
          break;

        core_idx = $clog2(~core_stall);
        tids[core_idx] = thread_id;
      end

      for (int i = 0; i < `NUM_CORES; i++) begin
        if (tids[i] != i) begin
          $display("TID mismatch at run %d core %d, expected 0x%x, got 0x%x", run, i, i, tids[i]);
          `FAIL_UNLESS_EQUAL(tids[i], i);
        end
      end
      clk_rst.WAIT_CYCLES(1);
      enable = 0;
      clk_rst.WAIT_CYCLES(1);
      reset_dispatch = 1;
      clk_rst.WAIT_CYCLES(1);
      reset_dispatch = 0;
      enable = 1;
    end
  `SVTEST_END

  `SVTEST(test_core_enable)
    int expected_tid;
    dispatch_indices = `CORE_CTRL_DISPATCH_INT;
    num_dispatches = 100;
    dispatch_indices = 0;
    core_enable = $urandom & {`NUM_CORES{1'b1}};

    enable = 1;
    expected_tid = 0;
    for (int run = 0; run < 3; run++) begin
      reg [`WORD] tids [`NUM_CORES-1:0];
      while (1) begin
        clk_rst.WAIT_CYCLES(1);
        if (dispatch_done) begin
          break;
        end

        if (core_stall != {`NUM_CORES{1'b1}}) begin
          core_idx = $clog2(~core_stall);
          tids[core_idx] = thread_id;
        end
      end

      for (int i = 0; i < `NUM_CORES; i++) begin
        if (core_enable[i]) begin
          if (tids[i] != expected_tid) begin
            $display("TID mismatch at run %d core %d, expected 0x%x, got 0x%x", run, i, expected_tid, tids[i]);
            `FAIL_UNLESS_EQUAL(tids[i], expected_tid);
          end
          expected_tid = expected_tid + 1;
        end
      end
      clk_rst.WAIT_CYCLES(1);
      enable = 0;
      clk_rst.WAIT_CYCLES(1);
      enable = 1;
    end
  `SVTEST_END

  `SVUNIT_TESTS_END

endmodule
