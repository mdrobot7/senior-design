`include "svunit_defines.svh"
`include "user_defines.v"

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

  wire [31:0] sram_addr;
  wire [31:0] data_to_sram;
  wire        sram_rw;
  wire        sram_en;
  reg  [31:0] data_from_sram;

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

    .sram_addr(sram_addr),
    .sram_data_o(data_to_sram),
    .sram_rw(sram_rw),
    .sram_en(sram_en),
    .sram_data_i(data_from_sram),

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
  // SRAM
  //===================================
  always @(posedge clk) begin
    if (sram_en) begin
      if (sram_rw == `SRAM_READ) begin
        sram_data_i <= sram_memory[sram_addr];
      end 
      else begin
        sram_memory[sram_addr] <= sram_data_o;
      end
    end
  end

  task init_memory();
    integer i;
    begin
      // init SPI chip mem
      for (i = 0; i < MEM_SIZE; i = i + 1) begin
        spi_chip.mem[i] = {$random};
      end
      
      // init SRAM
      for (i = 0; i < 1024; i = i + 1) begin
        sram_memory[i] = 32'h00000000;
      end
    end
  endtask

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
    `SVTEST(read_miss)
      reg [31:0] addr;
      reg [31:0] actual_data;
      reg [31:0] expected_data;

      addr = 32'h00001000;

      s_core_i[`BUS_SI_REQ] = 1;
      s_core_i[`BUS_SI_RW] = `BUS_READ;
      s_core_i[`BUS_SI_ADDR] = addr;
      s_core_i[`BUS_SI_SIZE] = `BUS_SIZE_WORD;

      expected_data = {
        spi_chip.mem[addr + 3],
        spi_chip.mem[addr + 2],
        spi_chip.mem[addr + 1],
        spi_chip.mem[addr + 0]
      };

      integer timeout
      timeout = 0;
      
      // Wait for ack
      while(!s_core_o[`BUS_SO_ACK] && timeout < 1000) begin
        @(posedge clk);
        timeout = timeout + 1;
      end
      
      if (timeout >= 1000) begin
        $display("ERROR: timeout for ACK high at addr 0x%h", addr);
      end
      
      // Wait for ack low
      timeout = 0;
      while(s_core_o[`BUS_SO_ACK] && timeout < 10000) begin
        @(posedge clk);
        timeout = timeout + 1;
      end
      
      if (timeout >= 10000) begin
        $display("ERROR: timeout for ACK low at addr 0x%h", addr);
      end

      data = s_core_o[`BUS_SO_DATA];
      s_core_i[`BUS_SI_REQ] = 0;

      `FAIL_UNLESS_EQUAL(read_data, expected_data);
    `SVTEST_END



  `SVUNIT_TESTS_END
endmodule
