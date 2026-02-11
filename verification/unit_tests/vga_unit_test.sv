`include "svunit_defines.svh"
`include "user_defines.v"
`include "vga.v"
`include "bus/busarb.v"
`include "test/vga_display.v"
`include "test/bus_slave.v"
`include "test/clk_rst.v"

module vga_unit_test;
  import svunit_pkg::svunit_testcase;

  string name = "vga_ut";
  svunit_testcase svunit_ut;


  //===================================
  // This is the UUT that we're
  // running the Unit Tests on
  //===================================
  wire clk_slow;
  wire nrst;

  clk_rst_m  #(10, 30) clk_rst_slow (
    .clk_o(clk_slow),
    .nrst_o(nrst)
  );

  wire clk_fast;

  clk_rst_m  #(2, 30) clk_rst_fast (
    .clk_o(clk_fast),
    .nrst_o()
  );

  reg clk_fast_sel;
  wire clk;
  assign clk = clk_fast_sel ? clk_fast : clk_slow;

  wire [`BUS_MIPORT] mportai;
  reg  [`BUS_MOPORT] mportao;

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

  localparam FB_HEIGHT = 10'd320;
  localparam FB_WIDTH = 10'd240;
  localparam MEMORY_SIZE = 2 * FB_HEIGHT * FB_WIDTH;
  localparam FB0_ADDR = 0;
  localparam FB1_ADDR = FB_HEIGHT * FB_WIDTH;

  bus_slave_m #(FB0_ADDR, MEMORY_SIZE) ram (
      .clk_i(clk),
      .nrst_i(nrst),
      .sport_i(sportai),
      .sport_o(sportao)
  );

  reg resolution_detected;

  reg [7:0] pixel;
  reg hsync;
  reg vsync;

  vga_display_m display (
    .clk_i(clk_slow), // Run at slow clock so we can test prescaling
    .nrst_i(nrst),

    .color_i(pixel),
    .hsync_i(hsync),
    .vsync_i(vsync),

    .resolution_detected_o(resolution_detected)
  );

  reg [9:0] base_h_active;
  reg [4:0] base_h_fporch;
  reg [6:0] base_h_sync;
  reg [6:0] base_h_bporch;
  reg [8:0] base_v_active;
  reg [2:0] base_v_fporch;
  reg [2:0] base_v_sync;
  reg [3:0] base_v_bporch;
  reg enable;
  reg [3:0] prescaler;
  reg [3:0] resolution;
  reg [`WORD] fb_addr;

  vga_m my_vga (
    .clk_i(clk),
    .nrst_i(nrst),
    .enable_i(enable),
    .prescaler_i(prescaler),
    .resolution_i(resolution),
    .base_h_active_i(base_h_active),
    .base_h_fporch_i(base_h_fporch),
    .base_h_sync_i(base_h_sync),
    .base_h_bporch_i(base_h_bporch),
    .base_v_active_i(base_v_active),
    .base_v_fporch_i(base_v_fporch),
    .base_v_sync_i(base_v_sync),
    .base_v_bporch_i(base_v_bporch),
    .mport_i(mportai),
    .mport_o(mportao),
    .fb_addr_i(fb_addr),
    .pixel_o(pixel),
    .hsync_o(hsync),
    .vsync_o(vsync)
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
    enable = 0;
    clk_fast_sel = 0;
    clk_rst_slow.RESET();

    // Fill framebuffer, make sure most lines are different
    for (int i = 0; i < FB_HEIGHT; i++) begin
        for (int j = 0; j < FB_WIDTH; j++) begin
            ram.mem[FB0_ADDR + i * FB_WIDTH + j] = (i + j) % FB_WIDTH;
            ram.mem[FB1_ADDR + i * FB_WIDTH + j] = (i + j) % 20;
        end
    end

    base_h_active = `VGA_BASE_H_ACTIVE;
    base_h_fporch = `VGA_BASE_H_FPORCH;
    base_h_sync = `VGA_BASE_H_SYNC;
    base_h_bporch = `VGA_BASE_H_BPORCH;
    base_v_active = `VGA_BASE_V_ACTIVE;
    base_v_fporch = `VGA_BASE_V_FPORCH;
    base_v_sync = `VGA_BASE_V_SYNC;
    base_v_bporch = `VGA_BASE_V_BPORCH;

    clk_rst_slow.WAIT_CYCLES(1); // Make sure we don't enable and leave reset in the same cycle
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

  `SVTEST(test_320x240_fb0)
    prescaler = 1;
    resolution = `VGA_RES_320x240;
    fb_addr = FB0_ADDR;
    clk_rst_slow.WAIT_CYCLES(1);
    enable = 1;
    test_fb(0, `VGA_RES_320x240);
  `SVTEST_END

  `SVTEST(test_160x120_fb0)
    prescaler = 1;
    resolution = `VGA_RES_160x120;
    fb_addr = FB0_ADDR;
    clk_rst_slow.WAIT_CYCLES(1);
    enable = 1;
    test_fb(0, `VGA_RES_160x120);
  `SVTEST_END

  `SVTEST(test_80x60_fb0)
    prescaler = 1;
    resolution = `VGA_RES_80x60;
    fb_addr = FB0_ADDR;
    clk_rst_slow.WAIT_CYCLES(1);
    enable = 1;
    test_fb(0, `VGA_RES_80x60);
  `SVTEST_END

  `SVTEST(test_320x240_fb1)
    prescaler = 1;
    resolution = `VGA_RES_320x240;
    fb_addr = FB1_ADDR;
    clk_rst_slow.WAIT_CYCLES(1);
    enable = 1;
    test_fb(1, `VGA_RES_320x240);
  `SVTEST_END

  `SVTEST(test_160x120_fb1)
    prescaler = 1;
    resolution = `VGA_RES_160x120;
    fb_addr = FB1_ADDR;
    clk_rst_slow.WAIT_CYCLES(1);
    enable = 1;
    test_fb(1, `VGA_RES_160x120);
  `SVTEST_END

  `SVTEST(test_80x60_fb1)
    prescaler = 1;
    resolution = `VGA_RES_80x60;
    fb_addr = FB1_ADDR;
    clk_rst_slow.WAIT_CYCLES(1);
    enable = 1;
    test_fb(1, `VGA_RES_80x60);
  `SVTEST_END

  `SVTEST(test_320x240_fb0_prescaled)
    prescaler = 5;
    resolution = `VGA_RES_320x240;
    fb_addr = FB0_ADDR;
    clk_fast_sel = 1; // clk_fast is 5x faster
    clk_rst_fast.WAIT_CYCLES(3); // TB quirk: VSYNC/HSYNC have to be perfectly in
                                 // phase with clk_slow, so delay a little. Won't
                                 // matter on real devices.
    enable = 1;
    test_fb(0, `VGA_RES_320x240);
  `SVTEST_END

  `SVUNIT_TESTS_END

  task test_fb;
    input fb_num;
    input integer res;

    integer mem_idx;
    integer pixel_double_counter;
    integer line_double_counter;
  begin
    // Wait for the resolution to be detected, takes 1 frame. The memory,
    // memory controller, bus, VGA, and display should all interact
    // on their own.
    for (int i = 0; i < 1000000; i++) begin
      if (resolution_detected)
        break;
      clk_rst_slow.WAIT_CYCLES(1);
    end
    `FAIL_UNLESS_EQUAL(resolution_detected, 1'b1);

    // Compare frames
    mem_idx = fb_num ? FB1_ADDR : FB0_ADDR;
    pixel_double_counter = 0;
    line_double_counter = 0;
    for(int i = 0; i < 480; i++) begin
      for(int j = 0; j < 640; j++) begin
        if (ram.mem[mem_idx] != display.screen[i][j]) begin
          $display("Screen mismatch at line %d, col %d. Expected: 0x%x, got 0x%x", i, j, ram.mem[mem_idx], display.screen[i][j]);
          `FAIL_UNLESS_EQUAL(ram.mem[mem_idx], display.screen[i][j]);
        end

        pixel_double_counter = pixel_double_counter + 1;
        if (pixel_double_counter >= res) begin
          pixel_double_counter = 0;
          mem_idx = mem_idx + 1;
        end
      end

      line_double_counter = line_double_counter + 1;
      if (line_double_counter >= res)
        line_double_counter = 0;
      else
        mem_idx = mem_idx - 640 / res; // Go back to the start of the line, double it
    end
  end
  endtask

endmodule
