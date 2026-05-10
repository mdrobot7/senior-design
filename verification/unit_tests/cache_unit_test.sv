`include "svunit_defines.svh"
`include "user_defines.v"
`include "test/debug_log.v"
`include "cache.v"

`include "spi_mem.v"
`include "test/clk_rst.v"
`include "test/spi_chip.v"
`include "sram_1024x32.v"

module cache_unit_test;
  import svunit_pkg::svunit_testcase;

  string name = "cache_ut";
  svunit_testcase svunit_ut;

  wire clk, nrst;
  clk_rst_m clk_rst(.clk_o(clk), .nrst_o(nrst));

  localparam MEM_SIZE = 262144; // in bytes. 256KB
  localparam BLOCKS = 64;
  localparam BLOCK_SIZE = 16;

  reg flush;
  wire flush_comp;

  reg [`BUS_SIPORT] s_core_i;
  wire [`BUS_SOPORT] s_core_o;

  wire [`BUS_MIPORT] m_mem_i;
  wire [`BUS_MOPORT] m_mem_o;

  // SPI signals
  wire spi_clk;
  wire spi_cs;
  wire [3:0] spi_mosi;
  wire [3:0] spi_miso;
  wire spi_dqsmi;
  wire spi_dqsmo;

  integer rand_req;

  //===================================
  // This is the UUT that we're
  // running the Unit Tests on
  //===================================
  cache_m #(BLOCK_SIZE) 
  DUT (
    .clk_i(clk),
    .nrst_i(nrst),

    .enable_i(1),
    .flush_i(flush),
    .flush_comp_o(flush_comp),

    .s_core_i(s_core_i),
    .s_core_o(s_core_o),

    .m_mem_i(m_mem_i),
    .m_mem_o(m_mem_o)
  );

  spi_mem_m #(
    .ADDRESS(0),
    .SIZE(MEM_SIZE)
  )
  spi_memory (
    .clk_i(clk),
    .nrst_i(nrst),
    
    // Connect to cache's memory master port
    .sport_i(m_mem_o),
    .sport_o(m_mem_i),
    
    // SPI signals to chip
    .spi_clk_o(spi_clk),
    .spi_cs_o(spi_cs),
    .spi_mosi_o(spi_mosi),
    .spi_miso_i(spi_miso),
    .spi_dqsm_i(spi_dqsmi),
    .spi_dqsm_o(spi_dqsmo)
  );

  spi_chip_m #(
    .SIZE(MEM_SIZE)
  ) 
  spi_chip (
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
  // Monitor
  //===================================
  
  // Monitor cache state changes
  reg [2:0] prev_state;
  always @(posedge clk) begin
    if (DUT.state != prev_state) begin
      $display("[%0t] STATE CHANGE: %s -> %s", 
               $time,
               state_name(prev_state),
               state_name(DUT.state));
      prev_state <= DUT.state;
    end
  end

  function string state_name(input [2:0] state);
    case(state)
      3'd0: state_name = "S_WAIT";
      3'd1: state_name = "S_TAG";
      3'd2: state_name = "S_HIT";
      3'd3: state_name = "S_DIRTY";
      3'd4: state_name = "S_FILL";
      3'd5: state_name = "S_MISS_1";
      3'd6: state_name = "S_MISS_2";
      default: state_name = "UNKNOWN";
    endcase
  endfunction

  // Monitor FILL operations
  always @(posedge clk) begin
    if (DUT.state == 3'd4) begin  // S_FILL
      if (DUT.mem_ack_i && DUT.mem_seqslv_i) begin
        $display("[%0t] FILL: Writing SRAM[%0d] = 0x%h (fill_count=%0d)", 
                 $time, DUT.sram_addr, DUT.mem_data_i, DUT.fill_count);
      end
      else if (DUT.mem_req_o) begin
        $display("[%0t] FILL: Waiting for data (ack=%0d, seqslv=%0d)", 
                 $time, DUT.mem_ack_i, DUT.mem_seqslv_i);
      end
    end
  end

  // Monitor memory bus
  always @(posedge clk) begin
    if (m_mem_o[`BUS_MO_REQ]) begin
      $display("[%0t] MEM_BUS: REQ addr=0x%h rw=%s ack=%0d seqslv=%0d seqmst=%0d data=0x%h", 
               $time, 
               m_mem_o[`BUS_MO_ADDR],
               m_mem_o[`BUS_MO_RW] ? "READ" : "WRITE",
               m_mem_i[`BUS_MI_ACK],
               m_mem_i[`BUS_MI_SEQSLV],
               m_mem_o[`BUS_MO_SEQMST],
               m_mem_i[`BUS_MI_DATA]);
    end
  end

  // Monitor SRAM operations
  always @(posedge clk) begin
    if (DUT.sram_en) begin
      if (DUT.sram_rw == `SRAM_READ) begin
        $display("[%0t] SRAM: READ addr=%0d -> data=0x%h (next cycle)", 
                 $time, DUT.sram_addr, DUT.sram_out_data);
      end
      else begin
        $display("[%0t] SRAM: WRITE addr=%0d <- data=0x%h", 
                 $time, DUT.sram_addr, DUT.sram_in_data);
      end
    end
  end

  // Monitor final output in MISS_2
  always @(posedge clk) begin
    if (DUT.state == 3'd6) begin
      $display("[%0t] MISS_2: req_rw=%s sram_out_data=0x%h -> core_data_o=0x%h", 
               $time,
               (DUT.req_rw == `BUS_READ) ? "READ" : "WRITE",
               DUT.sram_out_data,
               DUT.s_core_o[`BUS_SO_DATA]);
    end
  end

  // Monitor MISS_1
  always @(posedge clk) begin
    if (DUT.state == 3'd5) begin 
      $display("[%0t] MISS_1: sram_en=%0d sram_rw=%0d sram_addr=%0d sram_data=%0h",
              $time, DUT.sram_en, DUT.sram_rw, DUT.sram_addr, DUT.sram_in_data);
    end
  end

  //===================================
  // Setup for running the Unit Tests
  //===================================
  task setup();
    svunit_ut.setup();
    /* Place Setup Code Here */
    
    s_core_i = 0;
    flush = 0;

    init_memory();

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

  //==========================
  // tasks
  //==========================
  task core_read(input [31:0] addr, input [1:0] size, output [31:0] data);
    integer timeout;
    begin
      timeout = 0;
      
      s_core_i[`BUS_SI_REQ] = 1;
      s_core_i[`BUS_SI_RW] = `BUS_READ;
      s_core_i[`BUS_SI_ADDR] = addr;
      s_core_i[`BUS_SI_SIZE] = size;
      
      // Wait for ack
      while(!s_core_o[`BUS_SO_ACK] && timeout < 500) begin
        @(posedge clk);
        timeout = timeout + 1;
      end
      
      if (timeout >= 500) begin
        $display("!!!!! ERROR: Timeout waiting for ACK at addr 0x%h", addr);
      end
      else begin
        $display("[%0t] Got ACK (timeout=%0d)", $time, timeout);
      end
      
      // Wait ack low
      timeout = 0;
      while(s_core_o[`BUS_SO_ACK] && timeout < 2000) begin
        @(posedge clk);
        timeout = timeout + 1;
      end
      
      if (timeout >= 2000) begin
        $display("!!!!! ERROR: Timeout waiting for ack low at addr 0x%h", addr);
      end
      else begin
        $display("[%0t] ACK low (timeout=%0d)", $time, timeout);
      end
      
      data = s_core_o[`BUS_SO_DATA];
      s_core_i[`BUS_SI_REQ] = 0;
      @(posedge clk);
      
      $display("!!!!! CORE READ COMPLETE: data=0x%h\n", data);
    end
  endtask

  task core_write(input [31:0] addr, input [1:0] size, input [31:0] data);
    integer timeout;
    begin
      timeout = 0;
      
      s_core_i[`BUS_SI_REQ] = 1;
      s_core_i[`BUS_SI_RW] = `BUS_WRITE;
      s_core_i[`BUS_SI_ADDR] = addr;
      s_core_i[`BUS_SI_SIZE] = size;
      s_core_i[`BUS_SI_DATA] = data;
      
      // Wait for ack
      while(!s_core_o[`BUS_SO_ACK] && timeout < 500) begin
        @(posedge clk);
        timeout = timeout + 1;
      end
      
      if (timeout >= 500) begin
        $display("!!!!! ERROR: Timeout waiting for ACK at addr 0x%h", addr);
      end 
      else begin
        $display("[%0t] Got ACK (timeout=%0d)", $time, timeout);
      end
      
      // Wait for ack low
      timeout = 0;
      while(s_core_o[`BUS_SO_ACK] && timeout < 2000) begin
        @(posedge clk);
        timeout = timeout + 1;
      end
      
      if (timeout >= 2000) begin
        $display("!!!!! ERROR: Timeout waiting for ack low addr 0x%h", addr);
      end 
      else begin
        $display("[%0t] ACK low (timeout=%0d)", $time, timeout);
      end
      
      s_core_i[`BUS_SI_REQ] = 0;
      @(posedge clk);
      
      $display("!!!!! CORE WRITE COMPLETE");
    end
  endtask

  task init_memory();
    integer i;
    begin
      for (i = 0; i < MEM_SIZE; i = i + 1) begin
        spi_chip.mem[i] = {$random};
      end
    end
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
    `SVTEST(clean_read_miss)
      reg [31:0] addr;
      reg [31:0] actual_data;
      reg [31:0] expected_data;

      addr = {$random} % MEM_SIZE;
      
      expected_data = {
        spi_chip.mem[{addr[31:2], 2'h3}],
        spi_chip.mem[{addr[31:2], 2'h2}],
        spi_chip.mem[{addr[31:2], 2'h1}],
        spi_chip.mem[{addr[31:2], 2'h0}]
      };

      core_read(addr, `BUS_SIZE_WORD, actual_data);

      $display("!!!!! Clean Read MISS: Addr: 0x%h, Actual: 0x%h, Expected: 0x%h", addr, actual_data, expected_data);

      `FAIL_UNLESS_EQUAL(actual_data, expected_data);
    `SVTEST_END

    `SVTEST(clean_read_miss_byte)
      reg [31:0] addr;
      reg [31:0] actual_data;
      reg [31:0] expected_data;

      addr = {$random} % MEM_SIZE;
      
      expected_data = {24'b0, spi_chip.mem[addr[31:0]]};

      core_read(addr, `BUS_SIZE_BYTE, actual_data);

      $display("!!!!! Byte Read MISS: Addr: 0x%h, Actual: 0x%h, Expected: 0x%h", addr, actual_data, expected_data);

      `FAIL_UNLESS_EQUAL(actual_data, expected_data);
    `SVTEST_END

    `SVTEST(read_hit)
      reg [31:0] addr1;
      reg [31:0] addr2;
      reg [31:0] actual_data_1;
      reg [31:0] actual_data_2;
      reg [31:0] expected_data1;
      reg [31:0] expected_data2;

      addr1 = {$random} % MEM_SIZE;
      addr2 = addr1 + 5;
      
      expected_data1 = {
        spi_chip.mem[{addr1[31:2], 2'h3}],
        spi_chip.mem[{addr1[31:2], 2'h2}],
        spi_chip.mem[{addr1[31:2], 2'h1}],
        spi_chip.mem[{addr1[31:2], 2'h0}]
      };

      expected_data2 = {
        spi_chip.mem[{addr2[31:2], 2'h3}],
        spi_chip.mem[{addr2[31:2], 2'h2}],
        spi_chip.mem[{addr2[31:2], 2'h1}],
        spi_chip.mem[{addr2[31:2], 2'h0}]
      };

      core_read(addr1, `BUS_SIZE_WORD, actual_data_1);

      // wait till ack low
      while(s_core_o[`BUS_SO_ACK]) begin
        @(posedge clk);
      end

      core_read(addr2, `BUS_SIZE_WORD, actual_data_2);

      $display("!!!!! Read HIT: Actual: 0x%h, Expected: 0x%h", actual_data_2, expected_data2);
      `FAIL_UNLESS_EQUAL(actual_data_1, expected_data1);
      `FAIL_UNLESS_EQUAL(actual_data_2, expected_data2);
    `SVTEST_END

    `SVTEST(read_hit_byte)
      reg [31:0] addr1;
      reg [31:0] addr2;
      reg [31:0] actual_data_1;
      reg [31:0] actual_data_2;
      reg [31:0] expected_data1;
      reg [31:0] expected_data2;

      addr1 = {$random} % MEM_SIZE;
      addr2 = addr1 + 5;
      
      expected_data1 = {
        spi_chip.mem[{addr1[31:2], 2'h3}],
        spi_chip.mem[{addr1[31:2], 2'h2}],
        spi_chip.mem[{addr1[31:2], 2'h1}],
        spi_chip.mem[{addr1[31:2], 2'h0}]
      };

      expected_data2 = {24'b0, spi_chip.mem[addr2[31:0]]};

      core_read(addr1, `BUS_SIZE_WORD, actual_data_1);

      // wait till ack low
      while(s_core_o[`BUS_SO_ACK]) begin
        @(posedge clk);
      end

      core_read(addr2, `BUS_SIZE_BYTE, actual_data_2);

      $display("!!!!! Read HIT: Actual: 0x%h, Expected: 0x%h", actual_data_2, expected_data2);
      `FAIL_UNLESS_EQUAL(actual_data_1, expected_data1);
      `FAIL_UNLESS_EQUAL(actual_data_2, expected_data2);
    `SVTEST_END

    `SVTEST(write_miss)
      reg [31:0] addr;
      reg [31:0] data_in;
      reg [31:0] actual_data;

      data_in = {$random};
      addr = {$random} % MEM_SIZE;

      core_write(addr, `BUS_SIZE_WORD, data_in);

      // wait till ack low
      while(s_core_o[`BUS_SO_ACK]) begin
        @(posedge clk);
      end

      core_read(addr, `BUS_SIZE_WORD, actual_data);

      $display("!!!!! Write MISS: Actual: 0x%h, Expected: 0x%h", actual_data, data_in);
      `FAIL_UNLESS_EQUAL(actual_data, data_in);
    `SVTEST_END

    `SVTEST(write_miss_byte)
      reg [31:0] addr;
      reg [7:0] data_in;
      reg [31:0] actual_data;
      reg [31:0] expected_data;

      data_in = {$random};
      addr = {{$random} % (MEM_SIZE/4), 2'b01};

      expected_data = {
        spi_chip.mem[{addr[31:2], 2'h3}],
        spi_chip.mem[{addr[31:2], 2'h2}],
        data_in[7:0],
        spi_chip.mem[{addr[31:2], 2'h0}]
      };

      core_write(addr, `BUS_SIZE_BYTE, {24'b0, data_in});

      // wait till ack low
      while(s_core_o[`BUS_SO_ACK]) begin
        @(posedge clk);
      end

      core_read(addr, `BUS_SIZE_WORD, actual_data);

      $display("!!!!! Write MISS: Addr: 0x%h, Actual: 0x%h, Expected: 0x%h", addr, actual_data, expected_data);
      `FAIL_UNLESS_EQUAL(actual_data, expected_data);
    `SVTEST_END

    `SVTEST(write_hit)
      reg [31:0] addr;
      reg [31:0] data_in;
      reg [31:0] actual_data;

      data_in = {$random};
      addr = {$random} % MEM_SIZE;

      core_read(addr, `BUS_SIZE_WORD, actual_data);

      // wait till ack low
      while(s_core_o[`BUS_SO_ACK]) begin
        @(posedge clk);
      end

      core_write(addr, `BUS_SIZE_WORD, data_in);

      // wait till ack low
      while(s_core_o[`BUS_SO_ACK]) begin
        @(posedge clk);
      end

      core_read(addr, `BUS_SIZE_WORD, actual_data);

      $display("!!!!! Write MISS: Actual: 0x%h, Expected: 0x%h", actual_data, data_in);
      `FAIL_UNLESS_EQUAL(actual_data, data_in);
    `SVTEST_END

    `SVTEST(write_dirty)
      reg [31:0] addr1, addr2;
      reg [31:0] write_data;
      reg [31:0] read_data;
      reg [31:0] actual_data, mem0, mem1, mem2, mem3;
      integer i;

      addr1 = 32'h00001000;
      addr2 = 32'h00002000;
      write_data = {$random};

      mem0 = {
        spi_chip.mem[{addr1[31:2]-1, 2'h3}],
        spi_chip.mem[{addr1[31:2]-1, 2'h2}],
        spi_chip.mem[{addr1[31:2]-1, 2'h1}],
        spi_chip.mem[{addr1[31:2]-1, 2'h0}]
      };

      mem1 = {
        spi_chip.mem[{addr1[31:2], 2'h3}],
        spi_chip.mem[{addr1[31:2], 2'h2}],
        spi_chip.mem[{addr1[31:2], 2'h1}],
        spi_chip.mem[{addr1[31:2], 2'h0}]
      };

      mem2 = {
        spi_chip.mem[{addr1[31:2]+1, 2'h3}],
        spi_chip.mem[{addr1[31:2]+1, 2'h2}],
        spi_chip.mem[{addr1[31:2]+1, 2'h1}],
        spi_chip.mem[{addr1[31:2]+1, 2'h0}]
      };

      mem3 = {
        spi_chip.mem[{addr1[31:2]+2, 2'h3}],
        spi_chip.mem[{addr1[31:2]+2, 2'h2}],
        spi_chip.mem[{addr1[31:2]+2, 2'h1}],
        spi_chip.mem[{addr1[31:2]+2, 2'h0}]
      };

      $display("!!!!! MEM-words before: a-1: 0x%h, a: 0x%h, a+1: 0x%h, a+2: 0x%h", mem0, mem1, mem2, mem3);

      core_read(addr1, `BUS_SIZE_WORD, read_data);

      // wait till ack low
      while(s_core_o[`BUS_SO_ACK]) begin
        @(posedge clk);
      end
      
      core_write(addr1, `BUS_SIZE_WORD, write_data);

      // wait till ack low
      while(s_core_o[`BUS_SO_ACK]) begin
        @(posedge clk);
      end
      
      core_read(addr2, `BUS_SIZE_WORD, read_data);
      
      actual_data = {
        spi_chip.mem[{addr1[31:2], 2'h3}],
        spi_chip.mem[{addr1[31:2], 2'h2}],
        spi_chip.mem[{addr1[31:2], 2'h1}],
        spi_chip.mem[{addr1[31:2], 2'h0}]
      };

      mem0 = {
        spi_chip.mem[{addr1[31:2]-1, 2'h3}],
        spi_chip.mem[{addr1[31:2]-1, 2'h2}],
        spi_chip.mem[{addr1[31:2]-1, 2'h1}],
        spi_chip.mem[{addr1[31:2]-1, 2'h0}]
      };

      mem2 = {
        spi_chip.mem[{addr1[31:2]+1, 2'h3}],
        spi_chip.mem[{addr1[31:2]+1, 2'h2}],
        spi_chip.mem[{addr1[31:2]+1, 2'h1}],
        spi_chip.mem[{addr1[31:2]+1, 2'h0}]
      };

      mem3 = {
        spi_chip.mem[{addr1[31:2]+2, 2'h3}],
        spi_chip.mem[{addr1[31:2]+2, 2'h2}],
        spi_chip.mem[{addr1[31:2]+2, 2'h1}],
        spi_chip.mem[{addr1[31:2]+2, 2'h0}]
      };

      $display("!!!!! MEM words: a-1: 0x%h, a: 0x%h, a+1: 0x%h, a+2: 0x%h", mem0, actual_data, mem2, mem3);
      $display("!!!!! Write on Dirty: Actual: 0x%h, Expected: 0x%h", actual_data, write_data);
      `FAIL_UNLESS_EQUAL(actual_data, write_data);
    `SVTEST_END

    `SVTEST(read_dirty)
      reg [31:0] addr1, addr2;
      reg [31:0] write_data;
      reg [31:0] read_data;
      reg [31:0] actual_data;
      reg [31:0] first_word, mem0, mem1, mem2;
      integer i;

      addr1 = 32'h00001FF0;
      addr2 = 32'h00002FF0;
      write_data = {$random};

      first_word = {
        spi_chip.mem[32'h00001FC3],
        spi_chip.mem[32'h00001FC2],
        spi_chip.mem[32'h00001FC1],
        spi_chip.mem[32'h00001FC0]
      };

      mem0 = {
        spi_chip.mem[{addr1[31:2]-1, 2'h3}],
        spi_chip.mem[{addr1[31:2]-1, 2'h2}],
        spi_chip.mem[{addr1[31:2]-1, 2'h1}],
        spi_chip.mem[{addr1[31:2]-1, 2'h0}]
      };

      mem1 = {
        spi_chip.mem[{addr1[31:2], 2'h3}],
        spi_chip.mem[{addr1[31:2], 2'h2}],
        spi_chip.mem[{addr1[31:2], 2'h1}],
        spi_chip.mem[{addr1[31:2], 2'h0}]
      };

      mem2 = {
        spi_chip.mem[{addr1[31:2]+1, 2'h3}],
        spi_chip.mem[{addr1[31:2]+1, 2'h2}],
        spi_chip.mem[{addr1[31:2]+1, 2'h1}],
        spi_chip.mem[{addr1[31:2]+1, 2'h0}]
      };

      $display("!!!!! MEM-words before: first: 0x%h, a-1: 0x%h, a: 0x%h, a+1: 0x%h", first_word, mem0, mem1, mem2);

      core_read(addr1, `BUS_SIZE_WORD, read_data);

      // wait till ack low
      while(s_core_o[`BUS_SO_ACK]) begin
        @(posedge clk);
      end
      
      core_write(addr1, `BUS_SIZE_WORD, write_data);

      // wait till ack low
      while(s_core_o[`BUS_SO_ACK]) begin
        @(posedge clk);
      end
      
      core_read(addr2, `BUS_SIZE_WORD, read_data);

      // wait till ack low
      while(s_core_o[`BUS_SO_ACK]) begin
        @(posedge clk);
      end

      core_read(addr1, `BUS_SIZE_WORD, read_data);
      
      first_word = {
        spi_chip.mem[32'h00001FC3],
        spi_chip.mem[32'h00001FC2],
        spi_chip.mem[32'h00001FC1],
        spi_chip.mem[32'h00001FC0]
      };

      mem0 = {
        spi_chip.mem[{addr1[31:2]-1, 2'h3}],
        spi_chip.mem[{addr1[31:2]-1, 2'h2}],
        spi_chip.mem[{addr1[31:2]-1, 2'h1}],
        spi_chip.mem[{addr1[31:2]-1, 2'h0}]
      };

      mem1 = {
        spi_chip.mem[{addr1[31:2], 2'h3}],
        spi_chip.mem[{addr1[31:2], 2'h2}],
        spi_chip.mem[{addr1[31:2], 2'h1}],
        spi_chip.mem[{addr1[31:2], 2'h0}]
      };

      mem2 = {
        spi_chip.mem[{addr1[31:2]+1, 2'h3}],
        spi_chip.mem[{addr1[31:2]+1, 2'h2}],
        spi_chip.mem[{addr1[31:2]+1, 2'h1}],
        spi_chip.mem[{addr1[31:2]+1, 2'h0}]
      };

      $display("!!!!! MEM words: first: 0x%h, a-1: 0x%h, a: 0x%h, a+1: 0x%h", first_word, mem0, mem1, mem2);
      $display("!!!!! Read on Dirty: Written: 0x%h, Read: 0x%h", write_data, read_data);
      `FAIL_UNLESS_EQUAL(write_data, read_data);
    `SVTEST_END

    `SVTEST(random)
      reg [31:0] addr;
      reg [31:0] write_data;
      reg [31:0] read_data;
      reg [31:0] expected_data;
      reg [31:0] test_word [0:(MEM_SIZE/4)-1];
      integer i, op;

      $display("\n----- random test start -------");

      // test word memory from spi_chip
      for (i = 0; i < MEM_SIZE/4; i = i + 1) begin
        test_word[i] = {
          spi_chip.mem[(i*4)+3],
          spi_chip.mem[(i*4)+2],
          spi_chip.mem[(i*4)+1],
          spi_chip.mem[(i*4)+0]
        };
      end

      for (rand_req = 0; rand_req < 10000; rand_req = rand_req + 1) begin
        addr = ({$random} % (MEM_SIZE-3));

        op = {$random} % 2;

        if (op == 0) begin
          // READ:
          core_read(addr, `BUS_SIZE_WORD, read_data);

          // wait till ack low
          while(s_core_o[`BUS_SO_ACK]) begin
            @(posedge clk);
          end

          expected_data = test_word[addr/4];
          $display("!!!!! RANDOM[%0d] READ addr=0x%h index=0x%h, actual=0x%h expected=0x%h", rand_req, addr, addr[11:6], read_data, expected_data);
          `FAIL_UNLESS_EQUAL(read_data, expected_data);
        end
        else begin
          // WRITE:
          write_data = {$random};
          core_write(addr, `BUS_SIZE_WORD, write_data);
          test_word[addr/4] = write_data;

          // wait till ack low
          while(s_core_o[`BUS_SO_ACK]) begin
            @(posedge clk);
          end

          // read back
          core_read(addr, `BUS_SIZE_WORD, read_data);

          // wait till ack low
          while(s_core_o[`BUS_SO_ACK]) begin
            @(posedge clk);
          end

          $display("!!!!! RANDOM[%0d] WRITE+READ addr=0x%h index=0x%h written=0x%h readback=0x%h", rand_req, addr, addr[11:6], write_data, read_data);
          `FAIL_UNLESS_EQUAL(read_data, write_data);

          expected_data = {
            spi_chip.mem[{addr[31:2], 2'h3}],
            spi_chip.mem[{addr[31:2], 2'h2}],
            spi_chip.mem[{addr[31:2], 2'h1}],
            spi_chip.mem[{addr[31:2], 2'h0}]
          };
        end
      end
    `SVTEST_END

    `SVTEST(flush_test)
      reg [31:0] addr [BLOCKS * BLOCK_SIZE: 0];
      reg [31:0] data;
      reg [31:0] written_data [BLOCKS * BLOCK_SIZE: 0];
      reg [31:0] actual_data;
      integer i, flush_cycles;

      for (i = 0; i < BLOCKS * BLOCK_SIZE; i = i + 1) begin // 64 blocks
        addr[i] = i * 4;
        written_data[i] = {$random};

        core_write(addr[i], `BUS_SIZE_WORD, written_data[i]);
  
        // wait till ack low
        while(s_core_o[`BUS_SO_ACK])
          @(posedge clk);
      end

      // verify all blocks dirty
      for (i = 0; i < BLOCKS; i = i + 1) begin
        `FAIL_UNLESS(DUT.dirty[i])
      end

      // pulse flush
      flush_cycles = 0;
      flush = 1;
      @(posedge clk);
      flush = 0;
      while (flush_comp == 0) begin
        flush_cycles = flush_cycles + 1;
        @(posedge clk);
      end

      // verify blocks are clean
      for (i = 0; i < BLOCKS; i = i + 1) begin
        `FAIL_UNLESS(!DUT.dirty[i])
      end

      // check all mem values that should've flushed
      for (i = 0; i < BLOCKS * BLOCK_SIZE; i = i + 1) begin
          actual_data = {
            spi_chip.mem[{addr[i][31:2], 2'h3}],
            spi_chip.mem[{addr[i][31:2], 2'h2}],
            spi_chip.mem[{addr[i][31:2], 2'h1}],
            spi_chip.mem[{addr[i][31:2], 2'h0}]
          };
          $display("!!!!! FLUSH[%0d] addr=0x%h written=0x%h actual=0x%h", i, addr[i], written_data[i], actual_data);
          `FAIL_UNLESS_EQUAL(actual_data, written_data[i]);
      end
    `SVTEST_END

  `SVUNIT_TESTS_END
endmodule
