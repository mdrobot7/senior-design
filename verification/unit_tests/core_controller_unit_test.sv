`include "svunit_defines.svh"

`include "user_defines.v"

`include "bus/busarb.v"
`include "stream/stream_fifo.v"
`include "vertex_order_buffer.v"
`include "shaded_vertex_cache.v"
`include "test/bus_slave.v"
`include "test/clk_rst.v"
`include "test/stream_master.v"

`include "math/full_adder.v"
`include "math/mul.v"
`include "math/add.v"

`include "core/core.v"
`include "core/accumulator.v"
`include "core/alu.v"
`include "core/decoder.v"
`include "core/forward.v"
`include "core/inbox.v"
`include "core/mem_bus.v"
`include "core/outbox.v"
`include "core/predicate.v"
`include "core/regfile.v"
`include "core/signext.v"

`default_nettype wire
`define functional
  `include "../../ip/CF_SRAM_1024x32/hdl/beh_models/CF_SRAM_1024x32.tt_180V_25C.v"
`default_nettype none
`include "sram_1024x32.v"

`include "core_controller/index_fetch.v"
`include "core_controller/dispatch.v"
`include "core_controller/inst_fetch.v"
`include "core_controller/core_controller.v"

module core_controller_m_unit_test;
  import svunit_pkg::svunit_testcase;

  string name = "core_controller_m_ut";
  svunit_testcase svunit_ut;


  //===================================
  // This is the UUT that we're
  // running the Unit Tests on
  //===================================

  localparam STATE_STOPPED          = 0; // Waiting for program to start from beginning
  localparam STATE_DISPATCHING      = 1; // Dispatching jobs
  localparam STATE_DISPATCH_DELAY   = 2;
  localparam STATE_VERTEX_SHADING   = 3;
  localparam STATE_FRAGMENT_SHADING = 4;
  localparam STATE_GPGPU_COMPUTE    = 5;
  localparam STATE_PAUSED           = 6; // Manual pause by management core or step-through
  localparam STATE_DONE             = 7;
  localparam STATE_STOPPING         = 8;

  wire clk;
  wire nrst;
  clk_rst_m  #(10, 30) clk_rst (
    .clk_o(clk),
    .nrst_o(nrst)
  );

  wire [`BUS_MIPORT] mportai;
  reg  [`BUS_MOPORT] mportao;
  wire [`BUS_MIPORT] mportcorei [`NUM_CORES-1:0];
  reg  [`BUS_MOPORT] mportcoreo [`NUM_CORES-1:0];
  wire [`BUS_SIPORT] sportai;
  wire [`BUS_SOPORT] sportao;
  busarb_m #(`NUM_CORES+1, 1, `NUM_CORES+1) arbiter (
    .clk_i(clk),
    .nrst_i(nrst),

    .mports_i({ mportao, mportcoreo }),
    .mports_o({ mportai, mportcorei }),

    .sports_i({ sportao }),
    .sports_o({ sportai })
  );

  localparam INDEX_BUFFER_ADDR         = 0;
  localparam INDEX_BUFFER_SIZE_BYTES   = 1024;
  bus_slave_m #(INDEX_BUFFER_ADDR, INDEX_BUFFER_SIZE_BYTES) ram (
    .clk_i(clk),
    .nrst_i(nrst),
    .sport_i(sportai),
    .sport_o(sportao),
    .bad_read_o()
  );

  wire [`STREAM_SIPORT(`VERTEX_ORDER_WIDTH)] vertorder_sstreami;
  wire [`STREAM_SOPORT(`VERTEX_ORDER_WIDTH)] vertorder_sstreamo;
  wire                                       vertorder_clear;
  wire                                       vertorder_full;
  wire                                       vertorder_empty;
  vertex_order_buffer_m #(
    .ENTRIES(16),
    .INDEX_WIDTH(`VERTEX_ORDER_WIDTH)
  ) vertorder (
    .clk_i(clk),
    .nrst_i(nrst),

    .sstream_i(vertorder_sstreami),
    .sstream_o(vertorder_sstreamo),
    .mstream_i(1'b0),
    .mstream_o(),

    .clear_i(vertorder_clear),
    .full_o(vertorder_full),
    .empty_o(vertorder_empty)
  );

  wire                  vertcache_clear;
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

    .clear_i(vertcache_clear),

    .test_index_i(vertcache_test_index),
    .test_valid_i(vertcache_test_valid),
    .test_found_o(vertcache_test_found),

    .store_vertex_i(vertcache_store_vertex),
    .store_index_i(vertcache_store_index),
    .store_valid_i(vertcache_store_valid),

    .mstream_i(1'b0),
    .mstream_o()
  );

  reg                                 imem_rw;
  wire [`WORD]                        imem_do;
  reg  [`WORD]                        imem_di;
  reg  [`SRAM_1024x32_ADDR_WIDTH-1:0] imem_addr;
  reg  [`REG_SOURCE_WIDTH-1:0]        global_regfile_addr;
  reg                                 global_regfile_write_en;
  reg  [`WORD]                        global_regfile_write_data;
  wire [`WORD]                        global_regfile_read_data;
  reg  [`SRAM_1024x32_ADDR_WIDTH-1:0] pc_vertex_shading;
  reg  [`SRAM_1024x32_ADDR_WIDTH-1:0] pc_fragment_shading;
  reg  [`SRAM_1024x32_ADDR_WIDTH-1:0] pc_gpgpu_compute;
  reg                                 fragfifo_full;
  reg                                 fragfifo_empty;
  reg                                 fragfifo_done_mailing;
  wire                                fragfifo_clear;
  reg                                 rast_busy;
  reg  [`NUM_CORES-1:0]               core_enable;
  reg  [1:0]                          cmd;
  reg                                 cmd_written;
  reg                                 pause_at_halt;
  reg  [`WORD]                        index_buffer_addr;
  reg  [1:0]                          dispatch_ctrl;
  reg  [`WORD]                        num_dispatches;
  reg                                 job_done_clr;
  wire                                job_done;
  reg                                 batch_done_clr;
  wire                                batch_done;
  wire [3:0]                          state;
  wire [`WORD]                        inst;
  wire [`NUM_CORES-1:0]               core_reset;
  reg  [`NUM_CORES-1:0]               core_stalli;
  wire [`NUM_CORES-1:0]               core_stallo;
  reg  [`NUM_CORES-1:0]               core_jumpi;
  wire                                core_jumpo;
  wire [`WORD]                        global_regfile_rs1_data;
  wire [`WORD]                        global_regfile_rs2_data;
  core_controller_m #(
    .INDEX_FETCH_CACHE_LEN_WORDS(64),
    .CALL_STACK_LEN(8)
  ) dut (
    .clk_i(clk),
    .nrst_i(nrst),

    .imem_rw_i(imem_rw),
    .imem_do_o(imem_do),
    .imem_di_i(imem_di),
    .imem_addr_i(imem_addr),

    .global_regfile_addr_i(global_regfile_addr),
    .global_regfile_write_en_i(global_regfile_write_en),
    .global_regfile_write_data_i(global_regfile_write_data),
    .global_regfile_read_data_o(global_regfile_read_data),

    .pc_vertex_shading_i(pc_vertex_shading),
    .pc_fragment_shading_i(pc_fragment_shading),
    .pc_gpgpu_compute_i(pc_gpgpu_compute),

    .mport_i(mportai),
    .mport_o(mportao),

    .vertcache_test_index_o(vertcache_test_index),
    .vertcache_test_valid_o(vertcache_test_valid),
    .vertcache_test_found_i(vertcache_test_found),
    .vertcache_clear_o(vertcache_clear),

    .vertorder_sstreamo_i(vertorder_sstreamo),
    .vertorder_sstreami_o(vertorder_sstreami),
    .vertorder_full_i(vertorder_full),
    .vertorder_empty_i(vertorder_empty),
    .vertorder_clear_o(vertorder_clear),

    .fragfifo_full_i(fragfifo_full),
    .fragfifo_empty_i(fragfifo_empty),
    .fragfifo_done_mailing_i(fragfifo_done_mailing),
    .fragfifo_clear_o(fragfifo_clear),

    .rast_busy_i(rast_busy),

    .core_enable_i(core_enable),
    .cmd_i(cmd),
    .cmd_written_i(cmd_written),
    .pause_at_halt_i(pause_at_halt),
    .index_buffer_addr_i(index_buffer_addr),
    .dispatch_ctrl_i(dispatch_ctrl),
    .num_dispatches_i(num_dispatches),
    .job_done_clr_i(job_done_clr),
    .job_done_o(job_done),
    .batch_done_clr_i(batch_done_clr),
    .batch_done_o(batch_done),
    .state_o(state),

    .inst_o(inst),
    .core_reset_o(core_reset),
    .core_stall_i(core_stalli),
    .core_stall_o(core_stallo),
    .core_jump_i(core_jumpi),
    .core_jump_o(core_jumpo),
    .global_regfile_rs1_data_o(global_regfile_rs1_data),
    .global_regfile_rs2_data_o(global_regfile_rs2_data)
  );

  reg  [`STREAM_SIPORT(`WORD_WIDTH)] core_inbox_sstreami;
  wire [`STREAM_SOPORT(`WORD_WIDTH)] core_inbox_sstreamo;
  core_m core[`NUM_CORES-1:0] (
    .clk_i(clk),
    .nrst_i(nrst),
    .inst_i(inst),
    .global_r1_data_i(global_regfile_rs1_data),
    .global_r2_data_i(global_regfile_rs2_data),
    .jump_request_o(core_jumpi),
    .flush_dec_stage_i(core_jumpo),
    .stall_i(core_stallo),
    .stall_o(core_stalli),
    .nsync_rst_i(core_reset),
    .inbox_sstream_i(core_inbox_sstreami),
    .inbox_sstream_o(core_inbox_sstreamo),
    .outbox_mstream_i(1'b0),
    .outbox_mstream_o(),
    .mport_i(mportcorei),
    .mport_o(mportcoreo)
  );


  stream_master_m #(
      .SIZE(`WORD_WIDTH)
  ) stream_master (
      .clk_i(clk),

      .mstream_i(core_inbox_sstreamo),
      .mstream_o(core_inbox_sstreami)
  );

  // Can't for loop this (compiler issues) so we're doing this instead
  // (expand to NUM_CORES once multicore tests are added)
  `define FAIL_UNLESS_EQUAL_PRINT(exp, found) \
    if (exp != found) begin \
      $display("Fail: expected 0x%x, found 0x%x", exp, found); \
      `FAIL_UNLESS_EQUAL(exp, found); \
    end
  `define CHECK_REG(local_reg, val, core_en_mask) \
    $display("Checking reg  %d...", local_reg); \
    if (core_en_mask & (1 << 0)) begin `FAIL_UNLESS_EQUAL_PRINT(val, core[0].regfile.mem[local_reg]); end \
    else                         begin `FAIL_UNLESS_EQUAL_PRINT(0,   core[0].regfile.mem[local_reg]); end \
    if (core_en_mask & (1 << 1)) begin `FAIL_UNLESS_EQUAL_PRINT(val, core[1].regfile.mem[local_reg]); end \
    else                         begin `FAIL_UNLESS_EQUAL_PRINT(0,   core[1].regfile.mem[local_reg]); end \
    if (core_en_mask & (1 << 2)) begin `FAIL_UNLESS_EQUAL_PRINT(val, core[2].regfile.mem[local_reg]); end \
    else                         begin `FAIL_UNLESS_EQUAL_PRINT(0,   core[2].regfile.mem[local_reg]); end \
    if (core_en_mask & (1 << 3)) begin `FAIL_UNLESS_EQUAL_PRINT(val, core[3].regfile.mem[local_reg]); end \
    else                         begin `FAIL_UNLESS_EQUAL_PRINT(0,   core[3].regfile.mem[local_reg]); end \
    if (core_en_mask & (1 << 4)) begin `FAIL_UNLESS_EQUAL_PRINT(val, core[4].regfile.mem[local_reg]); end \
    else                         begin `FAIL_UNLESS_EQUAL_PRINT(0,   core[4].regfile.mem[local_reg]); end \
    if (core_en_mask & (1 << 5)) begin `FAIL_UNLESS_EQUAL_PRINT(val, core[5].regfile.mem[local_reg]); end \
    else                         begin `FAIL_UNLESS_EQUAL_PRINT(0,   core[5].regfile.mem[local_reg]); end

  reg[`WORD_WIDTH-1:0] imem_reg [0:1023];

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

    imem_rw = 1;
    imem_di = 0;
    imem_addr = 0;
    global_regfile_addr = 0;
    global_regfile_write_en = 0;
    global_regfile_write_data = 0;
    pc_vertex_shading = 0;
    pc_fragment_shading = 0;
    pc_gpgpu_compute = 0;
    fragfifo_full = 0;
    fragfifo_empty = 1;
    fragfifo_done_mailing = 0;
    rast_busy = 0;
    core_enable = 0;
    cmd = 0;
    pause_at_halt = 0;
    index_buffer_addr = 0;
    dispatch_ctrl = 0;
    num_dispatches = 0;
    job_done_clr = 0;
    batch_done_clr = 0;
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

  `SVTEST(global_regfile)
    clk_rst.WAIT_CYCLES(1);

    // Write test
    global_regfile_write_en = 1;
    for (int i = `NUM_LOCAL_REGS; i < `NUM_LOCAL_REGS + `NUM_GLOBAL_REGS; i++) begin
      global_regfile_write_data = $urandom;
      global_regfile_addr = i;
      clk_rst.WAIT_CYCLES(1);
      if (i != `NUM_LOCAL_REGS + `NUM_GLOBAL_REGS - 1) begin
        if (global_regfile_write_data != dut.inst_fetch.global_regfile.mem[i]) begin
          $display("Global regfile r%d data mismatch, expected 0x%x, got 0x%x", i, global_regfile_write_data, dut.inst_fetch.global_regfile.mem[i]);
          `FAIL_UNLESS_EQUAL(global_regfile_write_data, dut.inst_fetch.global_regfile.mem[i]);
        end
      end
    end
    clk_rst.WAIT_CYCLES(1);

    // Read test: data should appear on the same cycle
    global_regfile_write_en = 0;
    clk_rst.WAIT_CYCLES(1);
    for (int i = `NUM_LOCAL_REGS; i < `NUM_LOCAL_REGS + `NUM_GLOBAL_REGS; i++) begin
      global_regfile_addr = i;
      #1;
      if (i == `NUM_LOCAL_REGS + `NUM_GLOBAL_REGS - 1) begin
        if (global_regfile_read_data != 0) begin
          $display("Global regfile r%d data mismatch, expected 0x%x, got 0x%x", i, 0, global_regfile_read_data);
          `FAIL_UNLESS_EQUAL(global_regfile_read_data, 0); // zero reg
        end
      end
      else begin
        if (global_regfile_read_data != dut.inst_fetch.global_regfile.mem[i]) begin
          $display("Global regfile r%d data mismatch, expected 0x%x, got 0x%x", i, dut.inst_fetch.global_regfile.mem[i], global_regfile_read_data);
          `FAIL_UNLESS_EQUAL(global_regfile_read_data, dut.inst_fetch.global_regfile.mem[i]);
        end
      end
    end
  `SVTEST_END

  `SVTEST(imem_test)
    // Manual clock control here, timing matters
    wait(clk);

    // Write
    imem_rw = 0;
    for (int i = 0; i < 1024; i++) begin
      imem_addr = i;
      imem_di = 1024 + i;
      wait(!clk);
      wait(clk);
    end
    wait(!clk);
    wait(clk);

    // Read: data should appear on the next cycle
    imem_rw = 1;
    wait(!clk);
    wait(clk);
    fork
    begin
      for (int i = 0; i < 1024; i++) begin
        imem_addr = i;
        wait(!clk);
        wait(clk);
      end
    end
    begin
      for (int i = 0; i < 1024; i++) begin
        wait(!clk);
        wait(clk);
        #1;
        if (imem_do != 1024 + i) begin
          $display("IMEM data mismatch at word 0x%x, expected 0x%x, got 0x%x", i, 1024 + i, imem_do);
          `FAIL_UNLESS_EQUAL(imem_do, 1024 + i);
        end
      end
    end
    join
  `SVTEST_END

  `SVTEST(exec_gpgpu)
    clk_rst.WAIT_CYCLES(1);
    fill_imem("../../verilog/dv/top_level/src/asm/test_core.hex", 0);
    fill_inbox();

    pc_gpgpu_compute = 0;
    core_enable = {`NUM_CORES{1'b1}};
    cmd = `CORE_CTRL_CMD_RUN;
    pause_at_halt = 1;
    dispatch_ctrl = `CORE_CTRL_DISPATCH_DISABLE;
    num_dispatches = 100;

    for (int i = 0; i < 10000000; i++) begin
      clk_rst.WAIT_CYCLES(1);
      if (job_done)
        break;
    end
    `FAIL_UNLESS_EQUAL(state, STATE_STOPPING);
    `FAIL_UNLESS_EQUAL(job_done, 1);

    `CHECK_REG( 0, 32'h00000000, {`NUM_CORES{1'b1}});
    `CHECK_REG( 1, 32'hFFFFFFFF, {`NUM_CORES{1'b1}});
    `CHECK_REG( 2, 32'h00000002, {`NUM_CORES{1'b1}});
    `CHECK_REG( 3, 32'hFFFFFFFD, {`NUM_CORES{1'b1}});
    `CHECK_REG( 4, 32'h00000004, {`NUM_CORES{1'b1}});
    `CHECK_REG( 5, 32'hFFFFFFFB, {`NUM_CORES{1'b1}});
    `CHECK_REG( 6, 32'h00000006, {`NUM_CORES{1'b1}});
    `CHECK_REG( 7, 32'h000193E8, {`NUM_CORES{1'b1}});
    `CHECK_REG( 8, 32'h00000A00, {`NUM_CORES{1'b1}});
    `CHECK_REG( 9, 32'h00000007, {`NUM_CORES{1'b1}});
    // r10: Undefined value in test_core.s
    `CHECK_REG(11, 32'h000050C8, {`NUM_CORES{1'b1}});
    `CHECK_REG(12, 32'h00000000, {`NUM_CORES{1'b1}});
    // r13: Undefined value in test_core.s
    `CHECK_REG(14, 32'h0000000A, {`NUM_CORES{1'b1}});
    `CHECK_REG(15, 32'h0000000A, {`NUM_CORES{1'b1}});
  `SVTEST_END

  `SVTEST(exec_gpgpu_dispatch)
    clk_rst.WAIT_CYCLES(1);
    for (int i = 0; i < 1024; i++)
      imem_reg[i] = 32'h04000000;

    imem_rw = 0;
    for (int i = 0; i < 1024; i++) begin // Word-addressed
      // dut.imem.memory_mode_inst.memory[i] = imem_reg[i];
      imem_addr = i;
      imem_di = imem_reg[i];
      clk_rst.WAIT_CYCLES(1);
    end
    clk_rst.WAIT_CYCLES(1);
    fill_inbox();

    pc_gpgpu_compute = 0;
    core_enable = {`NUM_CORES{1'b1}};
    pause_at_halt = 1;
    dispatch_ctrl = `CORE_CTRL_DISPATCH_INT;
    num_dispatches = 100;
    clk_rst.WAIT_CYCLES(1);

    cmd = `CORE_CTRL_CMD_RUN;
    clk_rst.WAIT_CYCLES(1);

    for (int i = 0; i < 10000000; i++) begin
      clk_rst.WAIT_CYCLES(1);
      if (dut.dispatch_done)
        break;
    end
    `FAIL_UNLESS_EQUAL(dut.dispatch_done, 1);

    clk_rst.WAIT_CYCLES(10);

    `FAIL_UNLESS_EQUAL_PRINT(0, core[0].regfile.mem[0]);
    `FAIL_UNLESS_EQUAL_PRINT(1, core[1].regfile.mem[0]);
    `FAIL_UNLESS_EQUAL_PRINT(2, core[2].regfile.mem[0]);
    `FAIL_UNLESS_EQUAL_PRINT(3, core[3].regfile.mem[0]);
    `FAIL_UNLESS_EQUAL_PRINT(4, core[4].regfile.mem[0]);
    `FAIL_UNLESS_EQUAL_PRINT(5, core[5].regfile.mem[0]);
  `SVTEST_END

  `SVTEST(exec_gpgpu_cores_disabled)
    clk_rst.WAIT_CYCLES(1);
    fill_imem("../../verilog/dv/top_level/src/asm/test_core.hex", 0);
    fill_inbox();

    pc_gpgpu_compute = 0;
    core_enable = 6'b101010;
    cmd = `CORE_CTRL_CMD_RUN;
    pause_at_halt = 1;
    dispatch_ctrl = `CORE_CTRL_DISPATCH_INT;
    num_dispatches = 100;

    for (int i = 0; i < 10000000; i++) begin
      clk_rst.WAIT_CYCLES(1);
      if (job_done)
        break;
    end
    `FAIL_UNLESS_EQUAL(state, STATE_STOPPING);
    `FAIL_UNLESS_EQUAL(job_done, 1);

    `CHECK_REG( 0, 32'h00000000, 6'b101010);
    `CHECK_REG( 1, 32'hFFFFFFFF, 6'b101010);
    `CHECK_REG( 2, 32'h00000002, 6'b101010);
    `CHECK_REG( 3, 32'hFFFFFFFD, 6'b101010);
    `CHECK_REG( 4, 32'h00000004, 6'b101010);
    `CHECK_REG( 5, 32'hFFFFFFFB, 6'b101010);
    `CHECK_REG( 6, 32'h00000006, 6'b101010);
    `CHECK_REG( 7, 32'h000193E8, 6'b101010);
    `CHECK_REG( 8, 32'h00000A00, 6'b101010);
    `CHECK_REG( 9, 32'h00000007, 6'b101010);
    // r10: Undefined value in test_core.s
    `CHECK_REG(11, 32'h000050C8, 6'b101010);
    `CHECK_REG(12, 32'h00000000, 6'b101010);
    // r13: Undefined value in test_core.s
    `CHECK_REG(14, 32'h0000000A, 6'b101010);
    `CHECK_REG(15, 32'h0000000A, 6'b101010);
  `SVTEST_END

  `SVTEST(exec_gpgpu_completion)
    clk_rst.WAIT_CYCLES(1);
    fill_imem("../../verilog/dv/top_level/src/asm/test_core.hex", 0);
    fill_inbox();

    pc_gpgpu_compute = 0;
    core_enable = 6'b101010;
    cmd = `CORE_CTRL_CMD_RUN;
    pause_at_halt = 0;
    dispatch_ctrl = `CORE_CTRL_DISPATCH_INT;
    num_dispatches = 11;

    for (int run = 0; run < 3; run++) begin
      for (int i = 0; i < 10000000; i++) begin
        clk_rst.WAIT_CYCLES(1);
        if (job_done)
          break;
      end
      `FAIL_UNLESS_EQUAL(state, STATE_DISPATCHING);
      `FAIL_UNLESS_EQUAL(job_done, 1);
      job_done_clr <= 1;
      clk_rst.WAIT_CYCLES(1);
      job_done_clr <= 0;
      `FAIL_UNLESS_EQUAL(job_done, 0);

      $display("Checking run %d...", run);
      `CHECK_REG( 0, 32'h00000000, 6'b101010);
      `CHECK_REG( 1, 32'hFFFFFFFF, 6'b101010);
      `CHECK_REG( 2, 32'h00000002, 6'b101010);
      `CHECK_REG( 3, 32'hFFFFFFFD, 6'b101010);
      `CHECK_REG( 4, 32'h00000004, 6'b101010);
      `CHECK_REG( 5, 32'hFFFFFFFB, 6'b101010);
      `CHECK_REG( 6, 32'h00000006, 6'b101010);
      `CHECK_REG( 7, 32'h000193E8, 6'b101010);
      `CHECK_REG( 8, 32'h00000A00, 6'b101010);
      `CHECK_REG( 9, 32'h00000007, 6'b101010);
      // r10: Undefined value in test_core.s
      `CHECK_REG(11, 32'h000050C8, 6'b101010);
      `CHECK_REG(12, 32'h00000000, 6'b101010);
      // r13: Undefined value in test_core.s
      `CHECK_REG(14, 32'h0000000A, 6'b101010);
      `CHECK_REG(15, 32'h0000000A, 6'b101010);
    end

    for (int i = 0; i < 10000000; i++) begin
      clk_rst.WAIT_CYCLES(1);
      if (job_done)
        break;
    end
    cmd = `CORE_CTRL_CMD_STOP;
    `FAIL_UNLESS_EQUAL(state, STATE_STOPPING);
    `FAIL_UNLESS_EQUAL(job_done, 1);
    job_done_clr <= 1;
    clk_rst.WAIT_CYCLES(1);
    job_done_clr <= 0;
    `FAIL_UNLESS_EQUAL(job_done, 0);
    `FAIL_UNLESS_EQUAL(batch_done, 1);
    batch_done_clr <= 1;
    clk_rst.WAIT_CYCLES(1);
    batch_done_clr <= 0;
    `FAIL_UNLESS_EQUAL(batch_done, 0);

    $display("Checking final run, expecting core to be stopped...");
    // Core 5 won't execute code, but the regfile will stay the same
    // because soft reset doesn't clear the regfile. Check it I guess
    `CHECK_REG( 0, 32'h00000000, 6'b101010);
    `CHECK_REG( 1, 32'hFFFFFFFF, 6'b101010);
    `CHECK_REG( 2, 32'h00000002, 6'b101010);
    `CHECK_REG( 3, 32'hFFFFFFFD, 6'b101010);
    `CHECK_REG( 4, 32'h00000004, 6'b101010);
    `CHECK_REG( 5, 32'hFFFFFFFB, 6'b101010);
    `CHECK_REG( 6, 32'h00000006, 6'b101010);
    `CHECK_REG( 7, 32'h000193E8, 6'b101010);
    `CHECK_REG( 8, 32'h00000A00, 6'b101010);
    `CHECK_REG( 9, 32'h00000007, 6'b101010);
    // r10: Undefined value in test_core.s
    `CHECK_REG(11, 32'h000050C8, 6'b101010);
    `CHECK_REG(12, 32'h00000000, 6'b101010);
    // r13: Undefined value in test_core.s
    `CHECK_REG(14, 32'h0000000A, 6'b101010);
    `CHECK_REG(15, 32'h0000000A, 6'b101010);
  `SVTEST_END

  `SVTEST(exec_raster)
    // This isn't an actual rasterization test, use the integration tb for
    // that. This is using test_core. It checks index dispatch and the
    // rasterization stop conditions.
    clk_rst.WAIT_CYCLES(1);
    fill_imem("../../verilog/dv/top_level/src/asm/test_core.hex", 0);
    fill_inbox();

    pc_gpgpu_compute = 0;
    pc_vertex_shading = 0;
    pc_fragment_shading = 0;
    core_enable = 6'b101010;
    cmd = `CORE_CTRL_CMD_RUN;
    pause_at_halt = 0;
    dispatch_ctrl = `CORE_CTRL_DISPATCH_INDEX;
    num_dispatches = 11;

    rast_busy = 1;
    fragfifo_done_mailing = 1;
    fragfifo_empty = 0;

    for (int run = 0; run < 7; run++) begin
      for (int i = 0; i < 10000000; i++) begin
        clk_rst.WAIT_CYCLES(1);
        if (job_done)
          break;
      end
      `FAIL_UNLESS_EQUAL(job_done, 1);

      $display("Checking run %d...", run);
      `CHECK_REG( 0, 32'h00000000, 6'b101010);
      `CHECK_REG( 1, 32'hFFFFFFFF, 6'b101010);
      `CHECK_REG( 2, 32'h00000002, 6'b101010);
      `CHECK_REG( 3, 32'hFFFFFFFD, 6'b101010);
      `CHECK_REG( 4, 32'h00000004, 6'b101010);
      `CHECK_REG( 5, 32'hFFFFFFFB, 6'b101010);
      `CHECK_REG( 6, 32'h00000006, 6'b101010);
      `CHECK_REG( 7, 32'h000193E8, 6'b101010);
      `CHECK_REG( 8, 32'h00000A00, 6'b101010);
      `CHECK_REG( 9, 32'h00000007, 6'b101010);
      // r10: Undefined value in test_core.s
      `CHECK_REG(11, 32'h000050C8, 6'b101010);
      `CHECK_REG(12, 32'h00000000, 6'b101010);
      // r13: Undefined value in test_core.s
      `CHECK_REG(14, 32'h0000000A, 6'b101010);
      `CHECK_REG(15, 32'h0000000A, 6'b101010);

      job_done_clr <= 1;
      clk_rst.WAIT_CYCLES(1);
      job_done_clr <= 0;
      `FAIL_UNLESS_EQUAL(job_done, 0);

      // Program switchover happened when job_done was set high
      if (fragfifo_done_mailing) begin
        `FAIL_UNLESS_EQUAL(dut.cur_prog, STATE_FRAGMENT_SHADING);
      end
      else begin
        `FAIL_UNLESS_EQUAL(dut.cur_prog, STATE_VERTEX_SHADING);
      end
      fragfifo_done_mailing = !fragfifo_done_mailing; // flip between vertex and frag shading
    end

    for (int i = 0; i < 10000000; i++) begin
      clk_rst.WAIT_CYCLES(1);
      if (job_done)
        break;
    end
    cmd = `CORE_CTRL_CMD_STOP;
    `FAIL_UNLESS_EQUAL(state, STATE_STOPPING);
    `FAIL_UNLESS_EQUAL(job_done, 1);
    job_done_clr <= 1;
    clk_rst.WAIT_CYCLES(1);
    job_done_clr <= 0;
    `FAIL_UNLESS_EQUAL(job_done, 0);
    `FAIL_UNLESS_EQUAL(batch_done, 1);
    batch_done_clr <= 1;
    clk_rst.WAIT_CYCLES(1);
    batch_done_clr <= 0;
    `FAIL_UNLESS_EQUAL(batch_done, 0);

    `FAIL_UNLESS_EQUAL(dut.dispatch_index_fetch_clear, 1);
    `FAIL_UNLESS_EQUAL(vertorder_clear, 1);
    `FAIL_UNLESS_EQUAL(fragfifo_clear, 1);
    clk_rst.WAIT_CYCLES(1);
    rast_busy = 0;
    clk_rst.WAIT_CYCLES(1);
    `FAIL_UNLESS_EQUAL(state, STATE_STOPPING);
    fragfifo_empty = 1;
    clk_rst.WAIT_CYCLES(2);
    `FAIL_UNLESS_EQUAL(state, STATE_STOPPED);

    $display("Checking final run, expecting core to be stopped...");
    // Core 5 won't execute code, but the regfile will stay the same
    // because soft reset doesn't clear the regfile. Check it I guess
    `CHECK_REG( 0, 32'h00000000, 6'b101010);
    `CHECK_REG( 1, 32'hFFFFFFFF, 6'b101010);
    `CHECK_REG( 2, 32'h00000002, 6'b101010);
    `CHECK_REG( 3, 32'hFFFFFFFD, 6'b101010);
    `CHECK_REG( 4, 32'h00000004, 6'b101010);
    `CHECK_REG( 5, 32'hFFFFFFFB, 6'b101010);
    `CHECK_REG( 6, 32'h00000006, 6'b101010);
    `CHECK_REG( 7, 32'h000193E8, 6'b101010);
    `CHECK_REG( 8, 32'h00000A00, 6'b101010);
    `CHECK_REG( 9, 32'h00000007, 6'b101010);
    // r10: Undefined value in test_core.s
    `CHECK_REG(11, 32'h000050C8, 6'b101010);
    `CHECK_REG(12, 32'h00000000, 6'b101010);
    // r13: Undefined value in test_core.s
    `CHECK_REG(14, 32'h0000000A, 6'b101010);
    `CHECK_REG(15, 32'h0000000A, 6'b101010);
  `SVTEST_END

  `SVUNIT_TESTS_END

  int fd;
  task fill_imem;
    input string path;
    input integer offset;
  begin
    // For the sake of this test set unused IMEM to 0. Shouldn't cause any
    // issues
    for (int i = 0; i < 1024; i++)
      imem_reg[i] = 0;

    $readmemh(path, imem_reg);
    imem_rw = 0;
    for (int i = 0; i < 1024; i++) begin // Word-addressed
      // dut.imem.memory_mode_inst.memory[i] = imem_reg[i];
      imem_addr = i + offset;
      imem_di = imem_reg[i];
      clk_rst.WAIT_CYCLES(1);
    end
    clk_rst.WAIT_CYCLES(1);
  end
  endtask

  task fill_inbox;
  begin
    for (int i = 0; i < `CORE_MAILBOX_HEIGHT - 1; i++)
      stream_master.WRITE($urandom);
    stream_master.WRITE_LAST($urandom);
  end
  endtask

endmodule
