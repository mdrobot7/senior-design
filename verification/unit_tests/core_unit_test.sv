`include "svunit_defines.svh"
`include "user_defines.v"

`include "test/debug_log.v"
`include "test/clk_rst.v"
`include "test/bus_slave.v"
`include "test/spi_chip.v"
`include "test/stream_slave.v"
`include "test/stream_master.v"

`include "core/core.v"
`include "core/accumulator.v"
`include "core/alu.v"
`include "core/decoder.v"
`include "core/forward.v"
`include "core/predicate.v"
`include "core/regfile.v"
`include "core/signext.v"
`include "core/mem_bus.v"
`include "core/inbox.v"
`include "core/outbox.v"

`include "math/full_adder.v"
`include "math/mul.v"
`include "math/add.v"

`include "bus/busarb.v"

`include "spi_mem.v"

module core_m_unit_test;
  import svunit_pkg::svunit_testcase;

  string name = "core_m_ut";
  svunit_testcase svunit_ut;

  wire clk, nrst;
  clk_rst_m clk_rst(.clk_o(clk), .nrst_o(nrst));
  reg stall, flush_dec_stage, nsync_rst;
  reg[`WORD_WIDTH-1:0] inst, global_r1_data, global_r2_data;
  reg[`STREAM_SIPORT(`MAILBOX_STREAM_SIZE)] inbox_sstreami;
  wire[`STREAM_SOPORT(`MAILBOX_STREAM_SIZE)] inbox_sstreamo;
  reg[`STREAM_MIPORT(`MAILBOX_STREAM_SIZE)] outbox_mstreami;
  wire[`STREAM_MOPORT(`MAILBOX_STREAM_SIZE)] outbox_mstreamo;
  reg[`WORD_WIDTH-1:0] i_mem [0:127];
  reg[`WORD_WIDTH-1:0] outbox;

  wire jump_request, stallo;

  wire [`BUS_MIPORT] mportai;
  reg  [`BUS_MOPORT] mportao;

  wire [`BUS_SIPORT] sportai;
  wire [`BUS_SOPORT] sportao;

  wire[`BUS_ADDR_PORT] maddr = mportao[`BUS_MO_ADDR];
  wire[`BUS_DATA_PORT] mdata = mportao[`BUS_MO_DATA];
  wire mrw = mportao[`BUS_MO_RW];
  wire mreq = mportao[`BUS_MO_REQ];


  //===================================
  // This is the UUT that we're
  // running the Unit Tests on
  //===================================
  core_m #(.SP(0)) my_core_m (
    .clk_i(clk),
    .nrst_i(nrst),
    .inst_i(inst),
    .global_r1_data_i(global_r1_data),
    .global_r2_data_i(global_r2_data),

    .jump_request_o(jump_request),
    .flush_dec_stage_i(flush_dec_stage),
    .stall_i(stall),
    .stall_o(stallo),
    .nsync_rst_i(nsync_rst),
    .nsync_rst_mailbox_i(1'b1),

    .inbox_sstream_i(inbox_sstreami),
    .inbox_sstream_o(inbox_sstreamo),
    .outbox_mstream_i(outbox_mstreami),
    .outbox_mstream_o(outbox_mstreamo),

    .mport_i(mportai),
    .mport_o(mportao)
  );

  busarb_m #(1, 1, 1) arbiter(
      .clk_i(clk),
      .nrst_i(nrst),

      .mports_i({ mportao }),
      .mports_o({ mportai }),

      .sports_i({ sportao }),
      .sports_o({ sportai })
  );

  localparam MEM_BASE_ADDR = 0;
  localparam MEM_SIZE = 32'h8000;

  wire spi_clk1;
  wire spi_cs1;
  wire [3:0] spi_mosi1, spi_sio_en;
  wire [3:0] spi_miso1;
  wire spi_dqsmi1;
  wire spi_dqsmo1;
  wire spi_dqsm_en;

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


  stream_slave_m #(.SIZE(`MAILBOX_STREAM_SIZE), .BUFFER_SIZE(2*`CORE_MAILBOX_HEIGHT)) outbox_slave (
    .clk_i(clk),
    .sstream_o(outbox_mstreami),
    .sstream_i(outbox_mstreamo)
  );

  stream_master_m #(`MAILBOX_STREAM_SIZE) inbox_master (
    .clk_i(clk),
    .mstream_i(inbox_sstreamo),
    .mstream_o(inbox_sstreami)
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
    global_r1_data = 0;
    global_r2_data = 0;
    stall = 0;
    flush_dec_stage = 0;
    nsync_rst = 1;
    outbox <= 0;
    inst = 32'h04000000; // nop
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

  `SVTEST(set_regfile)
    integer i;
    //values from test_core.s
    $readmemh("mem_files/test_cores.mem", i_mem);
    for(i = 0; i < 17; i = i + 1) begin
      @(negedge clk);
      inst = i_mem[i];
    end
    clk_rst.WAIT_CYCLES(5);


    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[0], 32'd0);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[1], -32'd1);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[2], 32'd2);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[3], -32'd3);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[4], 32'd4);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[5], -32'd5);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[6], 32'd6);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[7], -32'd7);
  `SVTEST_END

  `SVTEST(test_math)
    integer i;
    $readmemh("mem_files/test_cores.mem", i_mem);
    clk_rst.RESET();
    clk_rst.WAIT_CYCLES(3);
    @(negedge clk);

    for(i = 0; i < 54; i = i + 1) begin
      @(negedge clk);
      if(stallo) begin
        outbox_slave.READ(outbox);
        @(negedge stallo);
        @(negedge clk);
      end
      inst = i_mem[i];
    end
    clk_rst.WAIT_CYCLES(5);

    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[0], 32'd0);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[1], -32'd1);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[2], 32'd2);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[3], -32'd3);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[4], 32'd4);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[5], -32'd5);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[6], 32'd6);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[7], -32'h7);

    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[8], 32'h5);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[9], 32'h1000);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[10], 32'hFFFFF371);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[11], 32'hFFFFFFFF);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[12], 32'h1);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[13], 32'hFFFFFAAA);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[14], 32'hFFFFFC18);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[15], 32'hFFFFFFFF);

  `SVTEST_END

  `SVTEST(test_lui_lli)
    integer i;
    $readmemh("mem_files/test_cores.mem", i_mem);
    clk_rst.RESET();
    outbox_slave.buffer_head = 0;
    outbox_slave.buffer_size = 0;
    clk_rst.WAIT_CYCLES(3);

    for(i = 0; i < 59; i = i + 1) begin
      @(negedge clk);
      inst = i_mem[i];
    end
    clk_rst.WAIT_CYCLES(5);

    // Wait for outbox to be read
    for (i = 0; i < 100; i++) begin
      clk_rst.WAIT_CYCLES(1);
      if (outbox_slave.buffer_size == `CORE_MAILBOX_HEIGHT)
        break;
    end
    `FAIL_UNLESS_EQUAL(outbox_slave.buffer_size, `CORE_MAILBOX_HEIGHT);

    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[0], 32'd0);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[1], -32'd1);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[2], 32'd2);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[3], -32'd3);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[4], 32'd4);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[5], -32'd5);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[6], 32'd6);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[7], 32'hFFFFFFF9)

    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[8], 32'h5);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[9], 32'h00001000);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[10], 32'hFFFFF371);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[11], 32'hFFFFFFFF);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[12], 32'h00000001);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[13], 32'hFFFFFAAA);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[14], 32'hFFFFFC18);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[15], 32'h55559090);

    `FAIL_UNLESS_EQUAL(outbox_slave.buffer[0], -32'd1);
    `FAIL_UNLESS_EQUAL(outbox_slave.buffer[1], 32'd2);
    `FAIL_UNLESS_EQUAL(outbox_slave.buffer[2], -32'h3);
    `FAIL_UNLESS_EQUAL(outbox_slave.buffer[3], 32'h4);
    `FAIL_UNLESS_EQUAL(outbox_slave.buffer[4], -32'h5);
    `FAIL_UNLESS_EQUAL(outbox_slave.buffer[5], 32'h6);
    `FAIL_UNLESS_EQUAL(outbox_slave.buffer[6], -32'h7);
    `FAIL_UNLESS_EQUAL(outbox_slave.buffer[7], 32'h5);

  `SVTEST_END

    `SVTEST(test_macops)
    integer i;
    $readmemh("mem_files/test_cores.mem", i_mem);
    clk_rst.RESET();
    outbox_slave.buffer_head = 0;
    outbox_slave.buffer_size = 0;
    clk_rst.WAIT_CYCLES(3);

    for(i = 0; i < 78; i = i + 1) begin
      @(negedge clk);
      if (stallo) begin
        @(negedge stallo);
        @(negedge clk);
      end
      inst = i_mem[i];
    end
    clk_rst.WAIT_CYCLES(5);

    // Wait for outbox to be read
    for (i = 0; i < 100; i++) begin
      clk_rst.WAIT_CYCLES(1);
      if (outbox_slave.buffer_size == 2*`CORE_MAILBOX_HEIGHT)
        break;
    end
    `FAIL_UNLESS_EQUAL(outbox_slave.buffer_size, 2*`CORE_MAILBOX_HEIGHT);

    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[0], 32'd0);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[1], -32'd1);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[2], 32'd2);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[3], -32'd3);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[4], 32'd4);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[5], -32'd5);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[6], 32'd6);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[7], 32'hFFFFFFF9)

    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[8], 32'h5);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[9], 32'h0000107D);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[10], 32'h00019000);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[11], 32'h000050C8);

    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[12], 32'h000019C3);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[13], 32'h0000B178);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[14], 32'h0000B177);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[15], 32'h00000000);

    `FAIL_UNLESS_EQUAL(outbox_slave.buffer[0], -32'd1);
    `FAIL_UNLESS_EQUAL(outbox_slave.buffer[1], 32'd2);
    `FAIL_UNLESS_EQUAL(outbox_slave.buffer[2], -32'h3);
    `FAIL_UNLESS_EQUAL(outbox_slave.buffer[3], 32'h4);
    `FAIL_UNLESS_EQUAL(outbox_slave.buffer[4], -32'h5);
    `FAIL_UNLESS_EQUAL(outbox_slave.buffer[5], 32'h6);
    `FAIL_UNLESS_EQUAL(outbox_slave.buffer[6], -32'h7);
    `FAIL_UNLESS_EQUAL(outbox_slave.buffer[7], 32'h5);
  `SVTEST_END

  `SVTEST(test_predication)
    integer i;
    $readmemh("mem_files/test_cores.mem", i_mem);
    clk_rst.RESET();
    clk_rst.WAIT_CYCLES(3);

    for(i = 0; i < 103; i = i + 1) begin
      @(negedge clk);
      if(stallo) begin
        @(negedge stallo);
        @(negedge clk);
      end
      inst = i_mem[i];
    end
    clk_rst.WAIT_CYCLES(5);

    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[0], 32'd0);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[1], -32'd1);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[2], 32'd2);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[3], -32'd3);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[4], 32'd4);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[5], -32'd5);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[6], 32'd6);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[7], 32'h00000000)

    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[8], 32'h1);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[9], 32'h0);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[10], 32'h1);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[11], 32'h0);

    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[12], 32'h4);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[13], 32'h0);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[14], 32'h1);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[15], 32'hFFFFFFFF);

    `FAIL_UNLESS_EQUAL(outbox_slave.buffer[0], -32'd1);
    `FAIL_UNLESS_EQUAL(outbox_slave.buffer[1], 32'd2);
    `FAIL_UNLESS_EQUAL(outbox_slave.buffer[2], -32'h3);
    `FAIL_UNLESS_EQUAL(outbox_slave.buffer[3], 32'h4);
    `FAIL_UNLESS_EQUAL(outbox_slave.buffer[4], -32'h5);
    `FAIL_UNLESS_EQUAL(outbox_slave.buffer[5], 32'h6);
    `FAIL_UNLESS_EQUAL(outbox_slave.buffer[6], -32'h7);
    `FAIL_UNLESS_EQUAL(outbox_slave.buffer[7], 32'h5);
  `SVTEST_END

  `SVTEST(jumping)
    integer i;
    $readmemh("mem_files/test_jumping.mem", i_mem);
    clk_rst.RESET();
    clk_rst.WAIT_CYCLES(3);
    //clear all regs and seed some values
    for(i = 0; i < 25; i = i + 1) begin
      @(negedge clk);
      if(stallo) begin
        @(negedge stallo);
        @(negedge clk);
      end
      inst = i_mem[i];
    end

    //due to wonderful jumping stuff, we are gonna take this slow and explicitly run each instruction
    @(negedge clk);
    inst = i_mem[i]; //jump 0x8

    @(negedge clk);
    `FAIL_IF(jump_request);
    i = i + 1;
    inst = i_mem[i]; // speq $p0, $r1, $r1, should be flushed

    //jump is now in ex, speq in decode, we should be jumping
    @(negedge clk);
    `FAIL_UNLESS(jump_request);
    flush_dec_stage = 1;
    i = i + 2;
    inst = i_mem[i]; // speq $p1, $r1, $r1

    @(negedge clk);
    flush_dec_stage = 0;
    i = i + 1;
    inst = i_mem[i]; // jump -8 (annulled)

    @(negedge clk);
    i = i + 1;
    inst = i_mem[i]; // jal -12 (annulled)

    @(negedge clk);
    `FAIL_IF(jump_request); // jump -8 should be annulled
    i = i + 1;
    inst = i_mem[i]; // jump 4

    @(negedge clk);
    `FAIL_IF(jump_request); //jal -12 should be annulled
    i = i + 1;
    inst = i_mem[i]; // addi $r1, $r1, 16

    @(negedge clk);
    `FAIL_UNLESS(jump_request);
    i = i + 1;
    inst = i_mem[i]; // (010) addi $r9, $r9, 100

    @(negedge clk);
    i = i + 1;
    inst = i_mem[i]; // addi $r10, $r9, 101

    @(negedge clk);
    i = i + 1;
    inst = i_mem[i]; // halt
    clk_rst.WAIT_CYCLES(5);

    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[0], 32'd0);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[1], -32'd1);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[2], 32'd2);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[3], -32'd3);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[4], 32'd4);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[5], -32'd5);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[6], 32'd6);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[7], -32'h7)
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[8], 32'h0);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[9], 32'h64);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[10], 32'hC9);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[11], 32'h0);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[12], 32'h0);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[13], 32'h0);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[14], 32'h0);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[15], 32'h0);

  `SVTEST_END

  `SVTEST(mem_test)
    integer i;
    $readmemh("mem_files/test_mem.mem", i_mem);

    inst = 0;

    clk_rst.RESET();
    clk_rst.WAIT_CYCLES(3);

    for(i = 0; i < 50; i = i + 1) begin
      @(negedge clk);
      if(stallo) begin
        @(negedge stallo);
        @(negedge clk);
      end
      inst = i_mem[i];
    end

    //SPI CHIP mem check
    `FAIL_UNLESS_EQUAL(spi_chip1.mem[0], 8'hFF);
    `FAIL_UNLESS_EQUAL(spi_chip1.mem[1], 8'hFF);
    `FAIL_UNLESS_EQUAL(spi_chip1.mem[2], 8'hFF);
    `FAIL_UNLESS_EQUAL(spi_chip1.mem[3], 8'hFF);
    `FAIL_UNLESS_EQUAL(spi_chip1.mem[4], 8'h02);
    `FAIL_UNLESS_EQUAL(spi_chip1.mem[5], 8'h00);
    `FAIL_UNLESS_EQUAL(spi_chip1.mem[6], 8'h00);
    `FAIL_UNLESS_EQUAL(spi_chip1.mem[7], 8'h00);
    `FAIL_UNLESS_EQUAL(spi_chip1.mem[8], 8'hF9);
    `FAIL_UNLESS_EQUAL(spi_chip1.mem[32], 8'hFF);
    `FAIL_UNLESS_EQUAL(spi_chip1.mem[33], 8'hFF);
    `FAIL_UNLESS_EQUAL(spi_chip1.mem[34], 8'hFF);
    `FAIL_UNLESS_EQUAL(spi_chip1.mem[35], 8'hFF);

    //regfile check
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[0], 32'h00000000);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[1], 32'hFFFFFFFF);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[2], 32'h00000002);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[3], 32'hFFFFFFFD);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[4], 32'h00000004);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[5], 32'hFFFFFFFB);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[6], 32'h00000006);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[7], 32'hFFFFFFF9);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[8], 32'hFFFFFFFF);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[9], 32'h00000002);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[10], 32'h00000000);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[11], 32'h00000000);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[12], 32'h00000000);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[13], 32'h00000000);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[14], 32'h00000000);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[15], 32'h00000000);

  `SVTEST_END

  `SVTEST(mem_alternating)
    integer i;
    $readmemh("mem_files/test_mem_alternating.mem", i_mem);

    inst = 0;

    clk_rst.RESET();
    clk_rst.WAIT_CYCLES(3);

    for(i = 0; i < 47; i = i + 1) begin
      @(negedge clk);
      if(stallo) begin
        @(negedge stallo);
        @(negedge clk);
      end
      inst = i_mem[i];
    end

    wait(my_core_m.wb_inst == i_mem[46]); //halt

    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[0], 32'h00000008);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[1], 32'h00000010);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[2], 32'h00000002);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[3], 32'hFFFFFFFD);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[4], 32'h00000004);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[5], 32'h00000009);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[6], 32'h00000006);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[7], 32'hFFFFFFF9);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[8], 32'h00000010);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[9], 32'h00000002);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[10], 32'h00000004);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[11], 32'h12345678);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[12], 32'h00000078);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[13], 32'h00000056);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[14], 32'h00000034);
    `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[15], 32'h00000012);

  `SVTEST_END

  `SVTEST(inbox)
    integer i;
    inst = 0;
    clk_rst.RESET();
    clk_rst.WAIT_CYCLES(3);

    for(i = 0; i < 7; i = i + 1) begin
      inbox_master.WRITE(32'h00000001 * (i+1));
    end
      inst = 32'hA0000000; //in instruction
      inbox_master.WRITE_LAST(32'h00000001 * 8);
      clk_rst.WAIT_CYCLES(2);
      inst = 0;
      clk_rst.WAIT_CYCLES(10);


      `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[1], 1);
      `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[2], 2);
      `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[3], 3);
      `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[4], 4);
      `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[5], 5);
      `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[6], 6);
      `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[7], 7);
      `FAIL_UNLESS_EQUAL(my_core_m.regfile.mem[8], 8);
  `SVTEST_END

  `SVUNIT_TESTS_END

endmodule
