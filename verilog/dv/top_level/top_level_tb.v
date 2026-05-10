// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

`timescale 1 ns / 1 ps

`ifdef GL
`include "../../gl/user_project_wrapper.v"
`endif

module top_level_tb;
	reg clock;
  reg RSTB;
	reg CSB;

	reg power1, power2;

	wire gpio;
	wire uart_tx;
	wire [37:0] mprj_io;

  integer current_cycle;

	assign uart_tx = mprj_io[6];

	always #10 clock <= (clock === 1'b0);

  always @(posedge clock) begin
    if (!RSTB) begin
      current_cycle = 0;
    end
    else begin
      current_cycle = current_cycle + 1;
    end
  end

	initial begin
		clock = 0;
	end

	initial begin
		$dumpfile("top_level.vcd");
		$dumpvars(0, top_level_tb);
	end

	image_m image();

	initial begin : MAIN
    integer i;

    wait(!RSTB);
    wait(RSTB);

    for (i = 0; i < 320 * 240; i = i + 1) begin
      WRITE_MEM(`ADDR_FB0 + i, 0);
    end

    for (i = 0; i < 60 * 60; i = i + 1) begin
      WRITE_MEM(`ADDR_TEX_BUFFER + i, image.tex_data[i]);
    end

    for (i = 0; i < 320 * 240 * 4; i = i + 4) begin
      WRITE_WORD(`ADDR_DEPTH_BUFFER + i, 32'h7fffffff);
    end

		wait(gpio);

    $display("Elapsed %d clock cycles", current_cycle);
    $display("%d FPS at 10 MHz", 10000000.0 / current_cycle);
    $display("%d FPS at 20 MHz", 20000000.0 / current_cycle);
    $display("%d FPS at 30 MHz", 30000000.0 / current_cycle);
    $display("%d FPS at 40 MHz", 40000000.0 / current_cycle);
    $display("%d FPS at 50 MHz", 50000000.0 / current_cycle);
    $display("%d FPS at 100 MHz", 100000000.0 / current_cycle);

    `VGA_WRITE("output.bmp", spi_chip1.mem, 320 * 240 * 1, 320, 240, `COLOR_TYPE_RGB332);

		#100;
		$finish;
	end

	initial begin
		RSTB <= 1'b0;
		CSB  <= 1'b1;		// Force CSB high
		#2000;
		RSTB <= 1'b1;	    	// Release reset
		#170000;
		CSB = 1'b0;		// CSB can be released
	end

	initial begin		// Power-up sequence
		power1 <= 1'b0;
		power2 <= 1'b0;
		#200;
		power1 <= 1'b1;
		#200;
		power2 <= 1'b1;
	end

	wire flash_csb;
	wire flash_clk;
	wire flash_io0;
	wire flash_io1;

	wire VDD1V8;
	wire VDD3V3;
	wire VSS;

	assign VDD3V3 = power1;
	assign VDD1V8 = power2;
	assign VSS = 1'b0;

	caravel uut (
		.vddio	  (VDD3V3),
		.vddio_2  (VDD3V3),
		.vssio	  (VSS),
		.vssio_2  (VSS),
		.vdda	  (VDD3V3),
		.vssa	  (VSS),
		.vccd	  (VDD1V8),
		.vssd	  (VSS),
		.vdda1    (VDD3V3),
		.vdda1_2  (VDD3V3),
		.vdda2    (VDD3V3),
		.vssa1	  (VSS),
		.vssa1_2  (VSS),
		.vssa2	  (VSS),
		.vccd1	  (VDD1V8),
		.vccd2	  (VDD1V8),
		.vssd1	  (VSS),
		.vssd2	  (VSS),
		.clock    (clock),
		.gpio     (gpio),
		.mprj_io  (mprj_io),
		.flash_csb(flash_csb),
		.flash_clk(flash_clk),
		.flash_io0(flash_io0),
		.flash_io1(flash_io1),
		.resetb	  (RSTB)
	);

  spi_chip_m #(`SPI_MEM_SIZE) spi_chip0(
      .clk_i(uut.chip_core.mprj.spi0_clk),
      .cs_i(uut.chip_core.mprj.spi0_cs),
      .mosi_i(uut.chip_core.mprj.spi0_mosi),
      .miso_o(uut.chip_core.mprj.spi0_miso),
      .dqsm_o(uut.chip_core.mprj.spi0_dqsmi),
      .dqsm_i(uut.chip_core.mprj.spi0_dqsmo)
  );

  spi_chip_m #(`SPI_MEM_SIZE) spi_chip1(
      .clk_i(uut.chip_core.mprj.spi1_clk),
      .cs_i(uut.chip_core.mprj.spi1_cs),
      .mosi_i(uut.chip_core.mprj.spi1_mosi),
      .miso_o(uut.chip_core.mprj.spi1_miso),
      .dqsm_o(uut.chip_core.mprj.spi1_dqsmi),
      .dqsm_i(uut.chip_core.mprj.spi1_dqsmo)
  );

  spi_chip_m #(`SPI_MEM_SIZE) spi_chip2(
      .clk_i(uut.chip_core.mprj.spi2_clk),
      .cs_i(uut.chip_core.mprj.spi2_cs),
      .mosi_i(uut.chip_core.mprj.spi2_mosi),
      .miso_o(uut.chip_core.mprj.spi2_miso),
      .dqsm_o(uut.chip_core.mprj.spi2_dqsmi),
      .dqsm_i(uut.chip_core.mprj.spi2_dqsmo)
  );

	spiflash #(
		.FILENAME("top_level.hex")
	) spiflash (
		.csb(flash_csb),
		.clk(flash_clk),
		.io0(flash_io0),
		.io1(flash_io1),
		.io2(),			// not used
		.io3()			// not used
	);

	// Testbench UART
	tbuart tbuart (
		.ser_rx(uart_tx)
	);

  task WRITE_MEM;
    input [31:0] addr;
    input [7:0] data;
  begin
    if (addr < `SPI_MEM_SIZE) begin
      spi_chip0.mem[addr] = data;
    end
    else if (addr < 2 * `SPI_MEM_SIZE) begin
      spi_chip1.mem[addr - `SPI_MEM_SIZE] = data;
    end
    else begin
      spi_chip2.mem[addr - 2 * `SPI_MEM_SIZE] = data;
    end
  end
  endtask

  task WRITE_WORD;
    input [31:0] addr;
    input [31:0] data;
  begin
    WRITE_MEM(addr + 0, data[7:0]);
    WRITE_MEM(addr + 1, data[15:8]);
    WRITE_MEM(addr + 2, data[23:16]);
    WRITE_MEM(addr + 3, data[31:24]);
  end
  endtask

endmodule
`default_nettype wire
