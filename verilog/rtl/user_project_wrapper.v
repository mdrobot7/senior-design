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
/*
 *-------------------------------------------------------------
 *
 * user_project_wrapper
 *
 * This wrapper enumerates all of the pins available to the
 * user for the user project.
 *
 * An example user project is provided in this wrapper.  The
 * example should be removed and replaced with the actual
 * user project.
 *
 *-------------------------------------------------------------
 */

module user_project_wrapper #(
    parameter BITS = 32
) (
`ifdef USE_POWER_PINS
    inout vdda1,	// User area 1 3.3V supply
    inout vdda2,	// User area 2 3.3V supply
    inout vssa1,	// User area 1 analog ground
    inout vssa2,	// User area 2 analog ground
    inout vccd1,	// User area 1 1.8V supply
    inout vccd2,	// User area 2 1.8v supply
    inout vssd1,	// User area 1 digital ground
    inout vssd2,	// User area 2 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input  wire wb_clk_i,
    input  wire wb_rst_i,
    input  wire wbs_stb_i,
    input  wire wbs_cyc_i,
    input  wire wbs_we_i,
    input  wire [3:0] wbs_sel_i,
    input  wire [31:0] wbs_dat_i,
    input  wire [31:0] wbs_adr_i,
    output wire wbs_ack_o,
    output wire [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  wire [127:0] la_data_in,
    output wire [127:0] la_data_out,
    input  wire [127:0] la_oenb,

    // IOs
    input  wire [`MPRJ_IO_PADS-1:0] io_in,
    output reg  [`MPRJ_IO_PADS-1:0] io_out,
    output reg  [`MPRJ_IO_PADS-1:0] io_oeb,

    // Analog (direct connection to GPIO pad---use with caution)
    // Note that analog I/O is not available on the 7 lowest-numbered
    // GPIO pads, and so the analog_io indexing is offset from the
    // GPIO indexing by 7 (also upper 2 GPIOs do not have analog_io).
    inout wire [`MPRJ_IO_PADS-10:0] analog_io,

    // Independent clock (on independent integer divider)
    input wire user_clock2,

    // User maskable interrupt signals
    output wire [2:0] user_irq
);

    assign la_data_out = 0;

    assign user_irq = 0;

    wire clk, nrst;
    assign clk = wb_clk_i;
    assign nrst = !wb_rst_i;

    wire spi1_clk;
    wire spi1_cs;
    wire [3:0] spi1_mosi;
    wire [3:0] spi1_miso;
    wire spi1_dqsmi;
    wire spi1_dqsmo;
    wire [3:0] spi1_sio_en;
    wire spi1_dqsm_en;

    wire spi2_clk;
    wire spi2_cs;
    wire [3:0] spi2_mosi;
    wire [3:0] spi2_miso;
    wire spi2_dqsmi;
    wire spi2_dqsmo;
    wire [3:0] spi2_sio_en;
    wire spi2_dqsm_en;

    wire [2:0] red;
    wire [2:0] green;
    wire [1:0] blue;
    wire hsync;
    wire vsync;

    top_level_m top_level(
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .wbs_stb_i(wbs_stb_i),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_we_i(wbs_we_i),
        .wbs_sel_i(wbs_sel_i),
        .wbs_dat_i(wbs_dat_i),
        .wbs_adr_i(wbs_adr_i),
        .wbs_ack_o(wbs_ack_o),
        .wbs_dat_o(wbs_dat_o),
        
        .spi1_clk_o(spi1_clk),
        .spi1_cs_o(spi1_cs),
        .spi1_mosi_o(spi1_mosi),
        .spi1_miso_i(spi1_miso),
        .spi1_dqsm_i(spi1_dqsmi),
        .spi1_dqsm_o(spi1_dqsmo),
        .spi1_sio_en_o(spi1_sio_en),
        .spi1_dqsm_en_o(spi1_dqsm_en),
        
        .spi2_clk_o(spi2_clk),
        .spi2_cs_o(spi2_cs),
        .spi2_mosi_o(spi2_mosi),
        .spi2_miso_i(spi2_miso),
        .spi2_dqsm_i(spi2_dqsmi),
        .spi2_dqsm_o(spi2_dqsmo),
        .spi2_sio_en_o(spi2_sio_en),
        .spi2_dqsm_en_o(spi2_dqsm_en),

        .blue_o(blue),
        .green_o(green),
        .red_o(red),
        .hsync_o(hsync),
        .vsync_o(vsync)
    );

    // assign spi1_miso  = io_in[11:8];
    // assign spi1_dqsmi = io_in[13];

    // assign spi2_miso  = io_in[19:16];
    // assign spi2_dqsmi = io_in[21];

    always @(*) begin
        io_oeb <= 0;
        io_out <= 0;

        io_oeb[11:8] <= spi1_sio_en;
        io_oeb[13]    <= spi1_dqsm_en;

        io_out[11:8] <= spi1_mosi;
        io_out[7]    <= spi1_cs;
        io_out[12]   <= spi1_clk;
        io_out[13]   <= spi1_dqsmo;

        io_oeb[19:16] <= spi2_sio_en;
        io_oeb[21]    <= spi2_dqsm_en;

        io_out[19:16] <= spi2_mosi;
        io_out[15]    <= spi2_cs;
        io_out[20]   <= spi2_clk;
        io_out[21]   <= spi2_dqsmo;

        io_out[26:24] <= red;
        io_out[30:28] <= green;
        { io_out[31], io_out[27] } <= blue;

        io_out[23] <= hsync;
        io_out[22] <= vsync;
    end

endmodule	// user_project_wrapper

`default_nettype wire
