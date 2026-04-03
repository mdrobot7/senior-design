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

	assign uart_tx = mprj_io[6];

	always #10 clock <= (clock === 1'b0);

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
        reg [`WORD] temp [1023:0];

		wait(!RSTB);
		wait(RSTB);

        // sram_1024x32.v.
        $readmemh("../top_level/src/asm/vertex_shader_cached.txt", temp);
        for (i = 0; i < 512; i = i + 1)
            uut.chip_core.mprj.top_level.core_cont.core_controller.inst_fetch.imem.sram.RAM[i] = temp[i];
        $readmemh("../top_level/src/asm/fragment_shader.txt", temp);
        for (i = 0; i < 512; i = i + 1)
            uut.chip_core.mprj.top_level.core_cont.core_controller.inst_fetch.imem.sram.RAM[512 + i] = temp[i];

        for (i = 0; i < 60 * 60; i = i + 1) begin
            WRITE_MEM(`ADDR_FB1 + i, image.tex_data[i]);
        end

        for (i = 0; i < 320 * 240 * 4; i = i + 1) begin
            WRITE_MEM(`ADDR_DEPTH_BUFFER + i, 8'hff);
        end

        // Index buffer
        WRITE_WORD(32'h80000 +  0 * 4, 0);
        WRITE_WORD(32'h80000 +  1 * 4, 2);
        WRITE_WORD(32'h80000 +  2 * 4, 1);
        WRITE_WORD(32'h80000 +  3 * 4, 1);
        WRITE_WORD(32'h80000 +  4 * 4, 2);
        WRITE_WORD(32'h80000 +  5 * 4, 3);

        WRITE_WORD(32'h80000 +  6 * 4, 0);
        WRITE_WORD(32'h80000 +  7 * 4, 4);
        WRITE_WORD(32'h80000 +  8 * 4, 5);
        WRITE_WORD(32'h80000 +  9 * 4, 0);
        WRITE_WORD(32'h80000 + 10 * 4, 5);
        WRITE_WORD(32'h80000 + 11 * 4, 2);

        // Vertex 0
        WRITE_WORD(32'h90000 + 0 * 20 + 0, -(`FP(1) / 4));
        WRITE_WORD(32'h90000 + 0 * 20 + 4, -(`FP(1) / 4));
        WRITE_WORD(32'h90000 + 0 * 20 + 8, `FP(1) / 4);
        WRITE_WORD(32'h90000 + 0 * 20 + 12, `FP(0));
        WRITE_WORD(32'h90000 + 0 * 20 + 16, `FP(0));

        // Vertex 1
        WRITE_WORD(32'h90000 + 1 * 20 + 0, (`FP(1) / 4));
        WRITE_WORD(32'h90000 + 1 * 20 + 4, -(`FP(1) / 4));
        WRITE_WORD(32'h90000 + 1 * 20 + 8, (`FP(1) / 4));
        WRITE_WORD(32'h90000 + 1 * 20 + 12, `FP(60));
        WRITE_WORD(32'h90000 + 1 * 20 + 16, `FP(0));

        // Vertex 2
        WRITE_WORD(32'h90000 + 2 * 20 + 0, -(`FP(1) / 4));
        WRITE_WORD(32'h90000 + 2 * 20 + 4, (`FP(1) / 4));
        WRITE_WORD(32'h90000 + 2 * 20 + 8, (`FP(1) / 4));
        WRITE_WORD(32'h90000 + 2 * 20 + 12, `FP(0));
        WRITE_WORD(32'h90000 + 2 * 20 + 16, `FP(60));

        // Vertex 3
        WRITE_WORD(32'h90000 + 3 * 20 + 0, (`FP(1) / 4));
        WRITE_WORD(32'h90000 + 3 * 20 + 4, (`FP(1) / 4));
        WRITE_WORD(32'h90000 + 3 * 20 + 8, (`FP(1) / 4));
        WRITE_WORD(32'h90000 + 3 * 20 + 12, `FP(60));
        WRITE_WORD(32'h90000 + 3 * 20 + 16, `FP(60));

        // Vertex 4
        WRITE_WORD(32'h90000 + 4 * 20 + 0, -(`FP(1) / 4));
        WRITE_WORD(32'h90000 + 4 * 20 + 4, -(`FP(1) / 4));
        WRITE_WORD(32'h90000 + 4 * 20 + 8, -(`FP(1) / 4));
        WRITE_WORD(32'h90000 + 4 * 20 + 12, `FP(60));
        WRITE_WORD(32'h90000 + 4 * 20 + 16, `FP(0));

        // Vertex 5
        WRITE_WORD(32'h90000 + 5 * 20 + 0, -(`FP(1) / 4));
        WRITE_WORD(32'h90000 + 5 * 20 + 4, (`FP(1) / 4));
        WRITE_WORD(32'h90000 + 5 * 20 + 8, -(`FP(1) / 4));
        WRITE_WORD(32'h90000 + 5 * 20 + 12, `FP(60));
        WRITE_WORD(32'h90000 + 5 * 20 + 16, `FP(60));

		wait(gpio);

        `VGA_WRITE("output.bmp", spi_chip1.mem, `ADDR_FB0, 320, 240, `COLOR_TYPE_RGB332);

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

    spi_chip_m #(`SPI_MEM_SIZE) spi_chip1(
        .clk_i(uut.chip_core.mprj.spi1_clk),
        .cs_i(uut.chip_core.mprj.spi1_cs),
        .mosi_i(uut.chip_core.mprj.spi1_mosi),
        .miso_o(mprj_io[11:8]),
        .dqsm_o(mprj_io[13]),
        .dqsm_i(uut.chip_core.mprj.spi1_dqsmo)
    );

    spi_chip_m #(`SPI_MEM_SIZE) spi_chip2(
        .clk_i(uut.chip_core.mprj.spi2_clk),
        .cs_i(uut.chip_core.mprj.spi2_cs),
        .mosi_i(uut.chip_core.mprj.spi2_mosi),
        .miso_o(mprj_io[19:16]),
        .dqsm_o(mprj_io[21]),
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
            spi_chip1.mem[addr] = data;
        end
        else begin
            spi_chip2.mem[addr - `SPI_MEM_SIZE] = data;
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
