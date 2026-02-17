`include "svunit_defines.svh"
`include "user_defines.v"
`include "test/debug_log.v"
`include "metadata_cache.v"

`include "spi_mem.v"
`include "test/clk_rst.v"
`include "test/spi_chip.v"

module bus_unit_test;
  import svunit_pkg::svunit_testcase;

  string name = "metadata_cache_ut";
  svunit_testcase svunit_ut;

  wire clk, nrst;
  clk_rst_m clk_rst(.clk_o(clk), .nrst_o(nrst));

  localparam MEM_SIZE = 262144; // 256KB

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

  // SRAM memory
  reg [31:0] sram_memory [1023:0];

  //===================================
  // This is the UUT that we're
  // running the Unit Tests on
  //===================================
  metadata_cache #(16) 
  DUT (
    .clk_i(clk),
    .nrst_i(nrst),

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
    .LATENCY_COUNT(5),
    .PRE_CYCLES(1),
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
    if (DUT.state == 3'd6) begin  // S_MISS_2
      $display("[%0t] MISS_2: req_rw=%s sram_out_data=0x%h -> core_data_o=0x%h", 
               $time,
               (DUT.req_rw == `BUS_READ) ? "READ" : "WRITE",
               DUT.sram_out_data,
               DUT.s_core_o[`BUS_SO_DATA]);
    end
  end

  // Monitor MISS_1
  always @(posedge clk) begin
    if (DUT.state == 3'd5) begin  // S_MISS_1
      $display("[%0t] S_MISS_1: sram_en=%0d sram_rw=%0d sram_addr=%0d sram_data=%0h",
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
  task core_read(input [31:0] addr, output [31:0] data);
    integer timeout;
    begin
      timeout = 0;
      
      s_core_i[`BUS_SI_REQ] = 1;
      s_core_i[`BUS_SI_RW] = `BUS_READ;
      s_core_i[`BUS_SI_ADDR] = addr;
      s_core_i[`BUS_SI_SIZE] = `BUS_SIZE_WORD;
      
      // Wait for ack
      while(!s_core_o[`BUS_SO_ACK] && timeout < 1000) begin
        @(posedge clk);
        timeout = timeout + 1;
      end
      
      if (timeout >= 1000) begin
        $display("!!!!! ERROR: Timeout waiting for ACK at addr 0x%h", addr);
      end
      else begin
        $display("[%0t] Got ACK (timeout=%0d)", $time, timeout);
      end
      
      // Wait ack low
      timeout = 0;
      while(s_core_o[`BUS_SO_ACK] && timeout < 10000) begin
        @(posedge clk);
        timeout = timeout + 1;
      end
      
      if (timeout >= 10000) begin
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

  task core_write(input [31:0] addr, input [31:0] data);
    integer timeout;
    begin
      timeout = 0;
      
      s_core_i[`BUS_SI_REQ] = 1;
      s_core_i[`BUS_SI_RW] = `BUS_WRITE;
      s_core_i[`BUS_SI_ADDR] = addr;
      s_core_i[`BUS_SI_SIZE] = `BUS_SIZE_WORD;
      s_core_i[`BUS_SI_DATA] = data;
      
      // Wait for ack
      while(!s_core_o[`BUS_SO_ACK] && timeout < 1000) begin
        @(posedge clk);
        timeout = timeout + 1;
      end
      
      if (timeout >= 1000) begin
        $display("!!!!! ERROR: Timeout waiting for ACK at addr 0x%h", addr);
      end else begin
        $display("[%0t] Got ACK (timeout=%0d)", $time, timeout);
      end
      
      // Wait for ack low
      timeout = 0;
      while(s_core_o[`BUS_SO_ACK] && timeout < 10000) begin
        @(posedge clk);
        timeout = timeout + 1;
      end
      
      if (timeout >= 10000) begin
        $display("!!!!! ERROR: Timeout waiting for ack low addr 0x%h", addr);
      end else begin
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
        spi_chip.mem[{addr[31:2], 2'b11}],
        spi_chip.mem[{addr[31:2], 2'b10}],
        spi_chip.mem[{addr[31:2], 2'b01}],
        spi_chip.mem[{addr[31:2], 2'b00}]
      };

      core_read(addr, actual_data);

      $display("!!!!! Clean Read MISS: Addr: 0x%h, Actual: 0x%h, Expected: 0x%h", addr, actual_data, expected_data);

      `FAIL_UNLESS_EQUAL(actual_data, expected_data);
    `SVTEST_END

    // `SVTEST(read_hit)
    //   reg [31:0] addr;
    //   reg [31:0] actual_data_1;
    //   reg [31:0] actual_data_2;
    //   reg [31:0] expected_data;

    //   addr = {$random} % MEM_SIZE;
      
    //   expected_data = {
    //     spi_chip.mem[{addr[31:2], 2'b11}],
    //     spi_chip.mem[{addr[31:2], 2'b10}],
    //     spi_chip.mem[{addr[31:2], 2'b01}],
    //     spi_chip.mem[{addr[31:2], 2'b00}]
    //   };

    //   core_read(addr, actual_data_1);
    //   core_read(addr+4, actual_data_2);

    //   $display("!!!!! Read HIT: Actual: 0x%h, Expected: 0x%h", actual_data_2, expected_data);
    //   `FAIL_UNLESS_EQUAL(actual_data_1, expected_data);
    //   `FAIL_UNLESS_EQUAL(actual_data_2, expected_data);
    // `SVTEST_END

    // `SVTEST(write_miss)
    //   reg [31:0] addr;
    //   reg [31:0] data_in;
    //   reg [31:0] actual_data;

    //   data_in = {$random};
    //   addr = 32'h000012300;

    //   core_write(addr, data_in);

    //   // wait till ack low
    //   while(s_core_o[`BUS_SO_ACK]) begin
    //     @(posedge clk);
    //   end

    //   core_read(addr, actual_data);

    //   $display("!!!!! Write MISS: Actual: 0x%h, Expected: 0x%h", actual_data, data_in);
    //   `FAIL_UNLESS_EQUAL(actual_data, data_in);
    // `SVTEST_END

    // `SVTEST(write_hit)
    //   reg [31:0] addr;
    //   reg [31:0] data_in;
    //   reg [31:0] actual_data;

    //   data_in = {$random};
    //   addr = {$random} % MEM_SIZE;

    //   core_read(addr, actual_data);

    //   // wait till ack low
    //   while(s_core_o[`BUS_SO_ACK]) begin
    //     @(posedge clk);
    //   end

    //   core_write(addr, data_in);

    //   // wait till ack low
    //   while(s_core_o[`BUS_SO_ACK]) begin
    //     @(posedge clk);
    //   end

    //   core_read(addr, actual_data);

    //   $display("!!!!! Write MISS: Actual: 0x%h, Expected: 0x%h", actual_data, data_in);
    //   `FAIL_UNLESS_EQUAL(actual_data, data_in);
    // `SVTEST_END

    // `SVTEST(write_dirty)
    //   reg [31:0] addr1, addr2;
    //   reg [31:0] write_data;
    //   reg [31:0] read_data;
    //   reg [31:0] actual_data;
    //   integer i;

    //   addr1 = 32'h00001000;
    //   addr2 = 32'h00002000;
    //   write_data = {$random};

    //   core_read(addr1, read_data);

    //   // wait till ack low
    //   while(s_core_o[`BUS_SO_ACK]) begin
    //     @(posedge clk);
    //   end
      
    //   core_write(addr1, write_data);

    //   // wait till ack low
    //   while(s_core_o[`BUS_SO_ACK]) begin
    //     @(posedge clk);
    //   end
      
    //   core_read(addr2, read_data);
      
    //   actual_data = {
    //     spi_chip.mem[{addr1[31:2], 2'b11}],
    //     spi_chip.mem[{addr1[31:2], 2'b10}],
    //     spi_chip.mem[{addr1[31:2], 2'b01}],
    //     spi_chip.mem[{addr1[31:2], 2'b00}]
    //   };

    //   $display("!!!!! Write on Dirty: Actual: 0x%h, Expected: 0x%h", actual_data, write_data);
    //   `FAIL_UNLESS_EQUAL(actual_data, write_data);
    // `SVTEST_END

  `SVUNIT_TESTS_END
endmodule
