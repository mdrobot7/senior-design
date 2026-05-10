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

    assign la_data_out[127:1] = 0;

    wire clk, nrst;
    assign clk = wb_clk_i;
    assign nrst = !wb_rst_i;

    wire spi0_clk;
    wire spi0_cs;
    wire [3:0] spi0_mosi;
    wire [3:0] spi0_miso;
    wire spi0_dqsmi;
    wire spi0_dqsmo;
    wire [3:0] spi0_sio_en;
    wire spi0_dqsm_en;

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
`ifdef USE_POWER_PINS
    	.vccd1(vccd1),
    	.vssd1(vssd1),
`endif

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

        .user_irq(user_irq),

        .spi0_clk_o(spi0_clk),
        .spi0_cs_o(spi0_cs),
        .spi0_mosi_o(spi0_mosi),
        .spi0_miso_i(spi0_miso),
        .spi0_dqsm_i(spi0_dqsmi),
        .spi0_dqsm_o(spi0_dqsmo),
        .spi0_sio_en_o(spi0_sio_en),
        .spi0_dqsm_en_o(spi0_dqsm_en),

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

`ifdef HARDENING
    // POWER: vdda1 is 1.8V, vdda2 is 3.3V!!!!!

    CurrentSteering_3bit_rev3 red_dac (
    `ifdef USE_POWER_PINS
        .VDD(vdda2),
        .VSS(vssa2),
    `endif

        .A(red[0]),
        .B(red[1]),
        .C(red[2]),
        .VOUT(analog_io[11]) // mprj_io[19]
    );

    CurrentSteering_3bit_rev3 green_dac (
    `ifdef USE_POWER_PINS
        .VDD(vdda2),
        .VSS(vssa2),
    `endif

        .A(green[0]),
        .B(green[1]),
        .C(green[2]),
        .VOUT(analog_io[10]) // mprj_io[18]
    );

    CurrentSteering_3bit_rev3 blue_dac (
    `ifdef USE_POWER_PINS
        .VDD(vdda2),
        .VSS(vssa2),
    `endif

        .A(1'b0),
        .B(blue[0]),
        .C(blue[1]),
        .VOUT(analog_io[9]) // mprj_io[17]
    );

    assign la_data_out[0] = 1'b0;

    // sdmay26_23_opamp opamp (
    // `ifdef USE_POWER_PINS
        // .VDD(vdda1),
        // .VSS(vssa1),
    // `endif

        // .VINP(analog_io[13]), // mprj_io[21]
        // .VINN(analog_io[12]), // mprj_io[20]
        // .VOUT(analog_io[14])  // mprj_io[22]
    // );

    /*
    inverter reram_inv (
    `ifdef USE_POWER_PINS
        .VDD(vdda1),
        .VSS(vssa1),
    `endif

        .Vin(la_data_in[0]),
        .Vout(la_data_out[0])
    );

    reram_transgate_m reram_transgate (
    `ifdef USE_POWER_PINS
        .vdda1(vdda1),
        .vssa1(vssa1),
    `endif

        .SIG_IN(analog_io[16]),     // mprj_io[24]
        .SIG_OUT(analog_io[17]),    // mprj_io[25]
        .INV_SELECT(la_data_in[1]),
        .SELECT(la_data_in[2])
    );

    opamp_5t reram_opamp (
    `ifdef USE_POWER_PINS
        .VDD(vdda2),
        .VSS(vssa2),
    `endif

        .Vinp(analog_io[19]),  // mprj_io[27]
        .Vinm(analog_io[18]),  // mprj_io[26]
        .VBIAS(analog_io[20]), // mprj_io[28]
        .Vout(analog_io[21])   // mprj_io[29]
    );
    */

`endif

    assign spi0_miso  = io_in[20:17];
    assign spi0_dqsmi = io_in[23];

    assign spi1_miso  = io_in[27:24];
    assign spi1_dqsmi = io_in[30];

    assign spi2_miso  = io_in[34:31];
    assign spi2_dqsmi = io_in[37];

    always @(*) begin
        io_oeb <= 0;
        io_out <= 0;

        io_oeb[20:17] <= spi0_sio_en;
        io_oeb[23]    <= spi0_dqsm_en;

        io_out[20:17] <= spi0_mosi;
        io_out[22]    <= spi0_cs;
        io_out[21]   <= spi0_clk;
        io_out[23]   <= spi0_dqsmo;

        io_oeb[27:24] <= spi1_sio_en;
        io_oeb[30]    <= spi1_dqsm_en;

        io_out[27:24] <= spi1_mosi;
        io_out[29]    <= spi1_cs;
        io_out[28]   <= spi1_clk;
        io_out[30]   <= spi1_dqsmo;

        io_oeb[34:31] <= spi2_sio_en;
        io_oeb[37]    <= spi2_dqsm_en;

        io_out[34:31] <= spi2_mosi;
        io_out[36]    <= spi2_cs;
        io_out[35]   <= spi2_clk;
        io_out[37]   <= spi2_dqsmo;

        io_out[9:7] <= red;
        io_out[12:10] <= green;
        io_out[14:13] <= blue;

        io_out[15] <= hsync;
        io_out[16] <= vsync;
    end

endmodule	// user_project_wrapper

`default_nettype wire
