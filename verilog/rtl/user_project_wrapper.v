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

    assign wbs_ack_o = 0;
    assign wbs_dat_o = 0;

    assign la_data_out = 0;

    assign user_irq = 0;

    wire clk, nrst;
    assign clk = wb_clk_i;
    assign nrst = la_data_in[0];

    wire [`BUS_MIPORT] mportai;
    wire [`BUS_MOPORT] mportao;

    wire [`BUS_MIPORT] mportbi;
    wire [`BUS_MOPORT] mportbo;

    wire [`BUS_MIPORT] mportci;
    reg  [`BUS_MOPORT] mportco;

    wire [`BUS_MIPORT] mportdi;
    wire [`BUS_MOPORT] mportdo;

    wire [`BUS_MIPORT] mportei;
    wire [`BUS_MOPORT] mporteo;

    wire [`BUS_MIPORT] mportfi;
    wire [`BUS_MOPORT] mportfo;

    wire [`BUS_SIPORT] sportai;
    wire [`BUS_SOPORT] sportao;

    wire [`BUS_SIPORT] sportbi;
    wire [`BUS_SOPORT] sportbo;

    busarb_m #(5, 2, 2) arbiter(
        .clk_i(clk),
        .nrst_i(nrst),

        .mports_i({ mportfo, mporteo, mportco, mportbo, mportao }),
        .mports_o({ mportfi, mportei, mportci, mportbi, mportai }),

        .sports_i({ sportbo, sportao }),
        .sports_o({ sportbi, sportai })
    );

    wire spi1_clk;
    wire spi1_cs;
    wire [3:0] spi1_mosi;
    reg  [3:0] spi1_miso;
    reg  spi1_dqsmi;
    wire spi1_dqsmo;
    wire [3:0] spi1_sio_en;
    wire spi1_dqsm_en;

    wire spi2_clk;
    wire spi2_cs;
    wire [3:0] spi2_mosi;
    reg  [3:0] spi2_miso;
    reg  spi2_dqsmi;
    wire spi2_dqsmo;
    wire [3:0] spi2_sio_en;
    wire spi2_dqsm_en;

    spi_mem_m #(0, 4000000) spi_mem1(
        .clk_i(clk),
        .nrst_i(nrst),

        .sport_i(sportai),
        .sport_o(sportao),

        .spi_clk_o(spi1_clk),
        .spi_cs_o(spi1_cs),
        .spi_mosi_o(spi1_mosi),
        .spi_miso_i(spi1_miso),
        .spi_dqsm_i(spi1_dqsmi),
        .spi_dqsm_o(spi1_dqsmo),

        .spi_sio_en_o(spi1_sio_en),
        .spi_dqsm_en_o(spi1_dqsm_en)
    );

    spi_mem_m #(4000000, 4000000) spi_mem2(
        .clk_i(clk),
        .nrst_i(nrst),

        .sport_i(sportbi),
        .sport_o(sportbo),

        .spi_clk_o(spi2_clk),
        .spi_cs_o(spi2_cs),
        .spi_mosi_o(spi2_mosi),
        .spi_miso_i(spi2_miso),
        .spi_dqsm_i(spi2_dqsmi),
        .spi_dqsm_o(spi2_dqsmo),

        .spi_sio_en_o(spi2_sio_en),
        .spi_dqsm_en_o(spi2_dqsm_en)
    );

    wire [2:0] red;
    wire [2:0] green;
    wire [1:0] blue;
    wire hsync;
    wire vsync;

    reg enable;

    reg fb;

    vga_m #(`ADDR_FB0, `ADDR_FB1) my_vga (
        .clk_i(clk),
        .nrst_i(nrst),
        .enable_i(enable),
        .prescaler_i(4'd2),
        .resolution_i(`VGA_RES_320x240),
        .base_h_active_i(`VGA_BASE_H_ACTIVE),
        .base_h_fporch_i(`VGA_BASE_H_FPORCH),
        .base_h_sync_i(`VGA_BASE_H_SYNC),
        .base_h_bporch_i(`VGA_BASE_H_BPORCH),
        .base_v_active_i(`VGA_BASE_V_ACTIVE),
        .base_v_fporch_i(`VGA_BASE_V_FPORCH),
        .base_v_sync_i(`VGA_BASE_V_SYNC),
        .base_v_bporch_i(`VGA_BASE_V_BPORCH),
        .mport_i(mportai),
        .mport_o(mportao),
        .fb_i(fb),
        .word_color_i(1'b0),
        .pixel_o({ red, green, blue }), // Remap standard 8 bit color to the correct IO
        .hsync_o(hsync),
        .vsync_o(vsync)
    );

    reg  run;
    wire busy;
    reg [7:0] color;

    reg [`BUS_ADDR_PORT] tex_addr;
    reg [`TEX_DIM] tex_width;

    reg [31:0] t0x;
    reg [31:0] t0y;
    reg [31:0] t1x;
    reg [31:0] t1y;
    reg [31:0] t2x;
    reg [31:0] t2y;

    reg [31:0] v0x;
    reg [31:0] v0y;
    reg [31:0] v0z;
    reg [31:0] v1x;
    reg [31:0] v1y;
    reg [31:0] v1z;
    reg [31:0] v2x;
    reg [31:0] v2y;
    reg [31:0] v2z;

    assign mportbi = mportdi;
    assign mportbo = mportdo;

    // word_stripe_cache_m #(8, 3) word_cache(
    //     .clk_i(clk),
    //     .nrst_i(nrst),

    //     .cached_mport_i(mportdo), 
    //     .cached_mport_o(mportdi),

    //     .mport_i(mportbi),
    //     .mport_o(mportbo)
    // );

    rasterizer_m rasterizer(
        .clk_i(clk),
        .nrst_i(nrst),

        .depth_mport_i({ mportdi }),
        .depth_mport_o({ mportdo }),

        .pix_mport_i({ mportei }),
        .pix_mport_o({ mporteo }),

        .tex_mport_i({ mportfi }),
        .tex_mport_o({ mportfo }),

        .run_i(run),
        .busy_o(busy),

        .tex_addr_i(tex_addr),
        .tex_width_i(tex_width),

        .fb_i(!fb),

        .t0x(t0x),
        .t0y(t0y),
        .t1x(t1x),
        .t1y(t1y),
        .t2x(t2x),
        .t2y(t2y),

        .v0x(v0x),
        .v0y(v0y),
        .v0z(v0z),
        .v1x(v1x),
        .v1y(v1y),
        .v1z(v1z),
        .v2x(v2x),
        .v2y(v2y),
        .v2z(v2z)
    );

    reg [7:0] state;

    reg [31:0] timer;

    reg [31:0] addr;
    reg [31:0] end_addr;

    reg [31:0] temp;
    reg [31:0] yep;

    wire [7:0] addrp0, addrp1, addrp2, addrp3;

    assign addrp0 = addr + 0;
    assign addrp1 = addr + 1;
    assign addrp2 = addr + 2;
    assign addrp3 = addr + 3;

    always @(posedge clk, negedge nrst) begin
        if (!nrst) begin
            state <= 100;

            fb <= 0;

            mportco <= 0;

            timer <= 0;
            addr  <= 0;
            end_addr <= 0;

            enable <= 0;

            temp <= 0;
            yep <= 0;

            tex_addr <= 32'd460800;
        end
        else if (clk) begin
            case (state)
                100: begin
                    state <= 101;

                    timer <= 0;
                end

                0: begin
                    mportco[`BUS_MO_ADDR] <= addr;
                    // mportco[`BUS_MO_DATA] <= { addrp0, addrp1, addrp2, addrp3 };
                    mportco[`BUS_MO_DATA] <= 32'h38383838;
                    mportco[`BUS_MO_SIZE] <= `BUS_SIZE_STREAM;
                    mportco[`BUS_MO_RW]   <= `BUS_WRITE;
                    mportco[`BUS_MO_REQ]  <= 1;
                    mportco[`BUS_MO_SEQMST]  <= 0;

                    temp <= 0;

                    if (mportci[`BUS_MI_ACK]) state <= 1;
                end
                1: begin
                    // mportco[`BUS_MO_DATA] <= { addrp0, addrp1, addrp2, addrp3 };

                    if (!mportco[`BUS_MO_SEQMST]) begin
                        if (mportci[`BUS_MI_SEQSLV]) begin
                            if (addr == end_addr - 8) begin
                                mportco[`BUS_MO_SEQMST]  <= 1;
                            end
                            else if (temp == 160 - 8) begin
                                mportco[`BUS_MO_SEQMST]  <= 1;
                            end
                            else begin
                                temp <= temp + 4;
                                addr <= addr + 4;
                            end
                        end
                    end
                    else begin
                        if (!mportci[`BUS_MI_ACK]) begin
                            if (addr == end_addr - 8) begin
                                state <= 2;
                                addr <= `ADDR_DEPTH_BUFFER;
                            end
                            else begin
                                state <= 0;
                            end

                            mportco[`BUS_MO_SEQMST]  <= 0;

                            mportco[`BUS_MO_REQ]  <= 0;
                        end
                    end
                end

                2: begin
                    mportco[`BUS_MO_ADDR] <= addr;
                    mportco[`BUS_MO_DATA] <= 32'hFFFFFFFF;
                    mportco[`BUS_MO_SIZE] <= `BUS_SIZE_STREAM;
                    mportco[`BUS_MO_RW]   <= `BUS_WRITE;
                    mportco[`BUS_MO_REQ]  <= 1;
                    mportco[`BUS_MO_SEQMST]  <= 0;

                    temp <= 0;

                    if (mportci[`BUS_MI_ACK]) state <= 3;
                end
                3: begin
                    if (!mportco[`BUS_MO_SEQMST]) begin
                        if (mportci[`BUS_MI_SEQSLV]) begin
                            if (addr == `ADDR_DEPTH_BUFFER + 320 * 240 * 4 - 8) begin
                                mportco[`BUS_MO_SEQMST]  <= 1;
                            end
                            else if (temp == 160 - 8) begin
                                mportco[`BUS_MO_SEQMST]  <= 1;
                            end
                            else begin
                                temp <= temp + 4;
                                addr <= addr + 4;
                            end
                        end
                    end
                    else begin
                        if (!mportci[`BUS_MI_ACK]) begin
                            if (addr == `ADDR_DEPTH_BUFFER + 320 * 240 * 4 - 8) begin
                                state <= 4;
                                addr <= 0;
                            end
                            else begin
                                state <= 2;
                            end

                            mportco[`BUS_MO_SEQMST]  <= 0;
                            
                            mportco[`BUS_MO_REQ]  <= 0;
                        end
                    end
                end

                4: begin
                    color <= 8'b00000111;

                    tex_addr <= fb ? `ADDR_FB1 : `ADDR_FB0;
                    tex_width <= 320;

                    v0x = (100 + yep) << `DECIMAL_POS;
                    v0y = (yep) << `DECIMAL_POS;
                    v0z = 80;
                    t0x = 0;
                    t0y = 0;

                    v1x = (100 + 120) << `DECIMAL_POS;
                    v1y = 30 << `DECIMAL_POS;
                    v1z = 240;
                    t1x = 320;
                    t1y = 0;

                    v2x = (100 + 30) << `DECIMAL_POS;
                    v2y = 120 << `DECIMAL_POS;
                    v2z = 240;
                    t2x = 0;
                    t2y = 240;

                    run <= 1;

                    timer <= 0;

                    if (busy) begin
                        state <= 5;

                        run <= 0;
                    end
                end

                5: begin
                    if (!busy) begin
                        if (timer == 1000) state <= 6;
                        else timer <= timer + 1;

                        run <= 0;
                    end
                    else begin
                        timer <= 0;
                    end
                end

                6: begin
                    color <= 8'b00111000;

                    tex_addr <= 32'd460800 + 100;
                    tex_width <= 10;

                    v0x = 5 << `DECIMAL_POS;
                    v0y = 50 << `DECIMAL_POS;
                    v0z = 160;
                    t0x = 0;
                    t0y = 0;
                    
                    v1x = 50 << `DECIMAL_POS;
                    v1y = 5 << `DECIMAL_POS;
                    v1z = 160;
                    t1x = 10;
                    t1y = 0;
                    
                    v2x = 220 << `DECIMAL_POS;
                    v2y = 220 << `DECIMAL_POS;
                    v2z = 160;
                    t2x = 0;
                    t2y = 10;

                    run <= 1;

                    timer <= 0;

                    if (busy) begin
                        state <= 7;

                        run <= 0;
                    end
                end

                7: begin
                    if (!busy) begin
                        if (timer == 1000) begin
                            state <= 10;

                            fb <= !fb;
    
                            timer <= 0;
                        end
                        else timer <= timer + 1;
                    end
                    else begin
                        timer <= 0;
                    end
                end

                10: begin
                    if (timer == 50000000) begin
                        state <= 0;

                        addr <= fb ? `ADDR_FB0 : `ADDR_FB1;
                        end_addr <= (fb ? `ADDR_FB0 : `ADDR_FB1) + (320 * 240);

                        if (yep < 100) yep <= yep + 5;
                        else yep <= 0;
                    end
                    else timer <= timer + 1;
                end

                101: begin
                    if (timer == 10000) begin
                        state <= 10;

                        timer <= 0;
    
                        enable <= 1;
                    end
                    else timer <= timer + 1;
                end

                default: ;
            endcase
        end
    end

    always @(*) begin
        io_oeb <= 0;
        io_out <= 0;

        io_oeb[11:8] <= spi1_sio_en;
        io_oeb[13]    <= spi1_dqsm_en;

        io_out[11:8] <= spi1_mosi;
        io_out[7]    <= spi1_cs;
        io_out[12]   <= spi1_clk;
        io_out[13]   <= spi1_dqsmo;

        spi1_miso  <= io_in[11:8];
        spi1_dqsmi <= io_in[13];

        io_oeb[19:16] <= spi2_sio_en;
        io_oeb[13]    <= spi2_dqsm_en;

        io_out[19:16] <= spi2_mosi;
        io_out[15]    <= spi2_cs;
        io_out[20]   <= spi2_clk;
        io_out[21]   <= spi2_dqsmo;

        spi2_miso  <= io_in[19:16];
        spi2_dqsmi <= io_in[21];

        io_out[26:24] <= red;
        io_out[30:28] <= green;
        { io_out[31], io_out[27] } <= blue;

        io_out[23] <= hsync;
        io_out[22] <= vsync;
    end

endmodule	// user_project_wrapper

`default_nettype wire
