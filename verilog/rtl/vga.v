module vga_wrapper_m (
    // Wishbone
    input wire wb_clk_i,
    input wire wb_rst_i,
    input wire wbs_stb_i,
    input wire wbs_cyc_i,
    input wire wbs_we_i,
    input wire [3:0] wbs_sel_i,
    input wire [`WORD_WIDTH-1:0] wbs_dat_i,
    input wire [`WORD_WIDTH-1:0] wbs_adr_i,
    output reg wbs_ack_o,
    output reg [`WORD_WIDTH-1:0] wbs_dat_o,

    // IRQs
    output reg irq_hblank_o,
    output reg irq_vblank_o,

    // PKBus
    input  wire [`BUS_MIPORT] mport_i, // For pixel data only
    output wire [`BUS_MOPORT] mport_o,

    // GPIO
    output wire [7:0] pixel_o,
    output wire hsync_o,
    output wire vsync_o
);

    localparam NUM_REGS = 6;

    reg [NUM_REGS-1:0] wbs_stbN;
    wire [NUM_REGS-1:0] wbs_ackN;
    wire [`WORD_WIDTH-1:0] wbs_datN [NUM_REGS-1:0];

    wire enable;
    wire [3:0] prescaler;
    wire [3:0] resolution;
    wire [7:0] base_h_fporch;
    wire [7:0] base_h_sync;
    wire [7:0] base_h_bporch;
    wire [7:0] base_v_fporch;
    wire [7:0] base_v_sync;
    wire [7:0] base_v_bporch;
    wire [`WORD] fb_addr;
    wire in_hblank;
    wire in_vblank;

    vga_m vga (
        .clk_i(wb_clk_i),
        .nrst_i(!wb_rst_i),

        .enable_i(enable),
        .prescaler_i(prescaler),
        .resolution_i(resolution),
        .base_h_fporch_i(base_h_fporch),
        .base_h_sync_i(base_h_sync),
        .base_h_bporch_i(base_h_bporch),
        .base_v_fporch_i(base_v_fporch),
        .base_v_sync_i(base_v_sync),
        .base_v_bporch_i(base_v_bporch),

        .mport_i(mport_i),
        .mport_o(mport_o),

        .fb_addr_i(fb_addr),
        .in_hblank(in_hblank),
        .in_vblank(in_vblank),

        .pixel_o(pixel_o),
        .hsync_o(hsync_o),
        .vsync_o(vsync_o),

        .word_color_i(1'b0)
    );

    wire [`WORD] ctrl_reg;
    assign {resolution, prescaler, enable} = ctrl_reg[8:0];
    wishbone_register_m #(32'h00000042, 1, `WBREG_TYPE_REG) ctrl (
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .wbs_stb_i(wbs_stbN[0]),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_we_i(wbs_we_i),
        .wbs_sel_i(wbs_sel_i),
        .wbs_dat_i(wbs_dat_i),
        .wbs_adr_i(wbs_adr_i),
        .wbs_ack_o(wbs_ackN[0]),
        .wbs_dat_o(wbs_datN[0]),

        .access_read_mask_i(32'h000007FF),
        .access_write_mask_i(32'h000001FF),
        .periph_read_mask_i(32'h00000600),

        .enable_prot_i(32'hFFFFFFFE),
        .enable_i(enable),

        .reg_i({21'b0, in_hblank, in_vblank, 9'b0}),
        .reg_o(ctrl_reg)
    );

    wire [`WORD] htiming_reg;
    assign {base_h_bporch, base_h_sync, base_h_fporch} = htiming_reg[23:0];
    wishbone_register_m #(32'h00504010, 1, `WBREG_TYPE_REG) htiming (
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .wbs_stb_i(wbs_stbN[1]),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_we_i(wbs_we_i),
        .wbs_sel_i(wbs_sel_i),
        .wbs_dat_i(wbs_dat_i),
        .wbs_adr_i(wbs_adr_i),
        .wbs_ack_o(wbs_ackN[1]),
        .wbs_dat_o(wbs_datN[1]),

        .access_read_mask_i(32'h00FFFFFF),
        .access_write_mask_i(32'h00FFFFFF),
        .periph_read_mask_i(0),

        .enable_prot_i(32'hFFFFFFFF),
        .enable_i(enable),

        .reg_i(0),
        .reg_o(htiming_reg)
    );

    wire [`WORD] vtiming_reg;
    assign {base_v_bporch, base_v_sync, base_v_fporch} = vtiming_reg[23:0];
    wishbone_register_m #(32'h000D0403, 1, `WBREG_TYPE_REG) vtiming (
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .wbs_stb_i(wbs_stbN[2]),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_we_i(wbs_we_i),
        .wbs_sel_i(wbs_sel_i),
        .wbs_dat_i(wbs_dat_i),
        .wbs_adr_i(wbs_adr_i),
        .wbs_ack_o(wbs_ackN[2]),
        .wbs_dat_o(wbs_datN[2]),

        .access_read_mask_i(32'h00FFFFFF),
        .access_write_mask_i(32'h00FFFFFF),
        .periph_read_mask_i(0),

        .enable_prot_i(32'hFFFFFFFF),
        .enable_i(enable),

        .reg_i(0),
        .reg_o(vtiming_reg)
    );

    wire [`WORD] fbaddr_reg;
    assign {fb_addr} = fbaddr_reg[31:0];
    wishbone_register_m #(32'h00000000, 1, `WBREG_TYPE_REG) fbaddr (
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .wbs_stb_i(wbs_stbN[3]),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_we_i(wbs_we_i),
        .wbs_sel_i(wbs_sel_i),
        .wbs_dat_i(wbs_dat_i),
        .wbs_adr_i(wbs_adr_i),
        .wbs_ack_o(wbs_ackN[3]),
        .wbs_dat_o(wbs_datN[3]),

        .access_read_mask_i(32'hFFFFFFFF),
        .access_write_mask_i(32'hFFFFFFFF),
        .periph_read_mask_i(0),

        .enable_prot_i(32'b0), // fbaddr is special, it latches at the end of a frame
        .enable_i(1'b0),

        .reg_i(0),
        .reg_o(fbaddr_reg)
    );

    wire [`WORD] intmask_reg;
    wire         intmask_hblank = intmask_reg[1];
    wire         intmask_vblank = intmask_reg[0];
    wishbone_register_m #(32'h00000000, 1, `WBREG_TYPE_REG) intmask (
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .wbs_stb_i(wbs_stbN[4]),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_we_i(wbs_we_i),
        .wbs_sel_i(wbs_sel_i),
        .wbs_dat_i(wbs_dat_i),
        .wbs_adr_i(wbs_adr_i),
        .wbs_ack_o(wbs_ackN[4]),
        .wbs_dat_o(wbs_datN[4]),

        .access_read_mask_i(32'h00000003),
        .access_write_mask_i(32'h00000003),
        .periph_read_mask_i(0),

        .enable_prot_i(32'b0),
        .enable_i(1'b0),

        .reg_i(0),
        .reg_o(intmask_reg)
    );

    wire intflag_hblank = wbs_dat_i[1];
    wire intflag_vblank = wbs_dat_i[0];
    wishbone_register_m #(32'h00000000, 1, `WBREG_TYPE_REG) intflag (
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .wbs_stb_i(wbs_stbN[5]),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_we_i(wbs_we_i),
        .wbs_sel_i(wbs_sel_i),
        .wbs_dat_i(wbs_dat_i),
        .wbs_adr_i(wbs_adr_i),
        .wbs_ack_o(wbs_ackN[5]),
        .wbs_dat_o(wbs_datN[5]),

        .access_read_mask_i(32'h00000003),
        .access_write_mask_i(32'h00000003),
        .periph_read_mask_i(32'h00000003),

        .enable_prot_i(32'b0),
        .enable_i(1'b0),

        .reg_i({30'b0, irq_hblank_o, irq_vblank_o}),
        .reg_o()
    );

    // This is terrible and I know it
    reg prev_in_hblank;
    reg prev_in_vblank;
    always @ (posedge wb_clk_i, posedge wb_rst_i) begin
        if (wb_rst_i) begin
            irq_hblank_o <= 0;
            irq_vblank_o <= 0;

            prev_in_hblank <= 0;
            prev_in_vblank <= 0;
        end
        else if (wb_clk_i) begin
            prev_in_hblank <= in_hblank;
            prev_in_vblank <= in_vblank;

            if (in_hblank && !prev_in_hblank)
                irq_hblank_o <= intmask_hblank;
            else if (intflag_hblank && wbs_stbN[5])
                irq_hblank_o <= 0;

            if (in_vblank && !prev_in_vblank)
                irq_vblank_o <= intmask_vblank;
            else if (intflag_vblank && wbs_stbN[5])
                irq_vblank_o <= 0;
        end
    end

    // Mux between the registers (similar to user_project_wrapper's addressing)
    wire [$clog2(NUM_REGS)-1:0] word_offset = {2'b00, wbs_adr_i[31:2]};
    always @ (*) begin
        wbs_stbN = wbs_stb_i << word_offset; // Only one at a time
        wbs_ack_o = wbs_ackN[word_offset];
        wbs_dat_o = wbs_datN[word_offset];
    end

endmodule

/*
    320x240 @ 60Hz (6MHz pixel clock) VGA output module.
    Does line doubling/pixel doubling to get smaller
    resolutions.

    Uses 640x480 @ 60Hz (24MHz pixel clock) as a base resolution.

    Using "stock" 640x480 should give us better monitor
    compatability. Doesn't cost us any performance either
    since lines are burst-read and cached.
*/
module vga_m (
    input wire clk_i, // Must be an integer multiple of 24MHz
    input wire nrst_i,

    input wire enable_i,
    input wire [3:0] prescaler_i,
    input wire [3:0] resolution_i, // 0x2 = 320x240, 0x4 = 160x120, 0x8 = 80x60

    // Base resolution timings, exposed so they can be tuned on-chip
    input wire [7:0] base_h_fporch_i,
    input wire [7:0] base_h_sync_i,
    input wire [7:0] base_h_bporch_i,
    input wire [7:0] base_v_fporch_i,
    input wire [7:0] base_v_sync_i,
    input wire [7:0] base_v_bporch_i,

    input wire [`BUS_MIPORT] mport_i, // For pixel data only
    output reg [`BUS_MOPORT] mport_o,

    input wire [`WORD] fb_addr_i,
    output reg in_hblank,
    output reg in_vblank,
    input wire word_color_i,

    output reg [7:0] pixel_o,
    output reg hsync_o,
    output reg vsync_o
);

    localparam BASE_H_ACTIVE = 640;
    localparam BASE_V_ACTIVE = 480;

    wire [9:0] base_h_total = BASE_H_ACTIVE + base_h_fporch_i + base_h_sync_i + base_h_bporch_i;
    wire [9:0] base_v_total = BASE_V_ACTIVE + base_v_fporch_i + base_v_sync_i + base_v_bporch_i;
    localparam H_SYNC_ACTIVE = 1'b1;
    localparam V_SYNC_ACTIVE = 1'b1;

    reg [9:0] res_h_active;
    reg [9:0] res_v_active;

    reg [8:0] prescaler_counter; // Generates base resolution pixel clock from clk_i
    reg [9:0] base_h_counter;    // Counters at base resolution, including blanking time
    reg [9:0] base_v_counter;
    reg [9:0] res_h_counter;     // Counters at scaled resolution, only for active area
    reg [9:0] res_v_counter;

    reg [3:0] pixel_double_counter;
    reg [3:0] line_double_counter;

    wire in_active_area = !in_hblank && !in_vblank;

    localparam FB_LINE_WIDTH = 320;
    localparam CACHE_WIDTH   = FB_LINE_WIDTH;
    reg [7:0] line_cache[CACHE_WIDTH-1:0]; // 320x240 resolution, cache one line
    reg [9:0] line_cache_idx;

    localparam FB_READ_STATE_READY = 0;
    localparam FB_READ_STATE_PREP  = 1;
    localparam FB_READ_STATE_READ  = 2;
    localparam FB_READ_STATE_DONE  = 3;
    reg [1:0] fb_read_state;

    reg [`WORD] fb_addr;

    wire [`BUS_DATA_SIZE-1:0] pixel_data_in = mport_i[`BUS_MI_DATA];

    integer i;

    always @ (*) begin
        // Color output
        if (in_active_area && enable_i)
            // pixel_o <= line_cache[res_h_counter[8:2]];
            // pixel_o <= line_cache[res_h_counter[8:1]];
            pixel_o = line_cache[res_h_counter[8:0]];
        else
            pixel_o = 0; // Pixel must be black during blanking time

        // HSYNC
        if (base_h_counter >= BASE_H_ACTIVE + base_h_fporch_i
            && base_h_counter < BASE_H_ACTIVE + base_h_fporch_i + base_h_sync_i)
            hsync_o = H_SYNC_ACTIVE;
        else
            hsync_o = ~H_SYNC_ACTIVE;

        // VSYNC
        if (base_v_counter >= BASE_V_ACTIVE + base_v_fporch_i
            && base_v_counter < BASE_V_ACTIVE + base_v_fporch_i + base_v_sync_i)
            vsync_o = V_SYNC_ACTIVE;
        else
            vsync_o = ~V_SYNC_ACTIVE;

        in_hblank = base_h_counter >= BASE_H_ACTIVE;
        in_vblank = base_v_counter >= BASE_V_ACTIVE;

        // Resolution switch
        case (resolution_i)
            `VGA_RES_320x240: begin
                res_h_active = {1'b0, BASE_H_ACTIVE[9:1]};
                res_v_active = {1'b0, BASE_V_ACTIVE[8:1]};
            end
            `VGA_RES_160x120: begin
                res_h_active = {2'b00, BASE_H_ACTIVE[9:2]};
                res_v_active = {2'b00, BASE_V_ACTIVE[8:2]};
            end
            `VGA_RES_80x60: begin
                res_h_active = {3'b000, BASE_H_ACTIVE[9:3]};
                res_v_active = {3'b000, BASE_V_ACTIVE[8:3]};
            end
            default: begin
                res_h_active = {1'b0, BASE_H_ACTIVE[9:1]};
                res_v_active = {1'b0, BASE_V_ACTIVE[8:1]};
            end
        endcase
    end

    always @ (posedge clk_i or negedge nrst_i) begin
        if (!nrst_i) begin
            prescaler_counter <= 0;
            base_h_counter <= 0;
            base_v_counter <= 0;
            res_h_counter <= 0;
            res_v_counter <= 0;
            pixel_double_counter <= 0;
            line_double_counter <= 0;
            for (i = 0; i < CACHE_WIDTH; i = i+1)
                line_cache[i] = 0;
            line_cache_idx <= 0;
            fb_addr <= 0;
            fb_read_state <= FB_READ_STATE_READY;
            mport_o <= 0;
        end
        else if (clk_i) begin
            if (!enable_i) begin
                prescaler_counter <= 0;
                base_h_counter <= 0;
                base_v_counter <= BASE_V_ACTIVE + base_v_fporch_i + base_v_sync_i; // Give us some blanking time to grab the first line
                res_h_counter <= 0;
                res_v_counter <= 0;
                pixel_double_counter <= 0; // Make sure the first pixel gets outputted
                line_double_counter <= 0;
                line_cache_idx <= 0;
                fb_addr <= fb_addr_i;      // Keep this up to date
                fb_read_state <= FB_READ_STATE_READY;
            end
            else begin
                if (prescaler_counter == prescaler_i - 1) begin
                    prescaler_counter <= 0;

                    // Output pixels
                    if (in_active_area) begin
                        if (pixel_double_counter == resolution_i - 1) begin
                            pixel_double_counter <= 0;

                            if (res_h_counter == res_h_active - 1) begin
                                res_h_counter <= 0;
                                if (line_double_counter == resolution_i - 1) begin
                                    line_double_counter <= 0;
                                    if (res_v_counter == res_v_active - 1) begin
                                        res_v_counter <= 0;
                                    end
                                    else begin
                                        res_v_counter <= res_v_counter + 1;
                                    end

                                    if (fb_read_state == FB_READ_STATE_READY) begin
                                        fb_addr <= fb_addr_i;
                                        fb_read_state <= FB_READ_STATE_PREP;
                                    end
                                end
                                else
                                    line_double_counter <= line_double_counter + 1; // Handle line doubling
                            end
                            else
                                res_h_counter <= res_h_counter + 1;
                        end
                        else
                            pixel_double_counter <= pixel_double_counter + 1; // Handle pixel doubling
                    end

                    if (base_h_counter == base_h_total - 1) begin
                        base_h_counter <= 0;
                        res_h_counter <= 0;
                        pixel_double_counter <= 0;

                        if (base_v_counter == base_v_total - 1) begin
                            res_v_counter <= 0;
                            base_v_counter <= 0;
                        end
                        else
                            base_v_counter <= base_v_counter + 1;
                    end
                    else
                        base_h_counter <= base_h_counter + 1;
                end
                else
                    prescaler_counter <= prescaler_counter + 1;

                // Fetch new line
                case (fb_read_state)
                    FB_READ_STATE_PREP: begin
                        if (res_v_counter == 0)
                            mport_o[`BUS_MO_ADDR] <= fb_addr;

                        mport_o[`BUS_MO_RW] <= `BUS_READ;
                        mport_o[`BUS_MO_SIZE] <= `BUS_SIZE_STREAM;
                        mport_o[`BUS_MO_REQ]  <= 1;
                        if (mport_i[`BUS_MI_ACK]) fb_read_state <= FB_READ_STATE_READ;
                    end
                    FB_READ_STATE_READ: begin
                        if (mport_i[`BUS_MI_SEQSLV]) begin
                            if (!word_color_i) begin
                                line_cache[line_cache_idx]     = pixel_data_in[7:0];
                                line_cache[line_cache_idx + 1] = pixel_data_in[15:8];
                                line_cache[line_cache_idx + 2] = pixel_data_in[23:16];
                                line_cache[line_cache_idx + 3] = pixel_data_in[31:24];
                                line_cache_idx <= line_cache_idx + 4;

                                if (line_cache_idx >= res_h_active - 8) begin
                                    mport_o[`BUS_MO_SEQMST] <= 1;
                                end
                            end
                            else begin
                                line_cache[line_cache_idx]     = { pixel_data_in[7:5], 5'b00000 };
                                line_cache_idx <= line_cache_idx + 1;

                                if (line_cache_idx >= res_h_active - 2) begin
                                    mport_o[`BUS_MO_SEQMST] <= 1;
                                end
                            end
                        end

                        if (!mport_i[`BUS_MI_ACK]) begin
                            fb_read_state <= FB_READ_STATE_DONE;
                            line_cache_idx <= 0;
                        end
                    end
                    FB_READ_STATE_DONE: begin
                        fb_read_state <= FB_READ_STATE_READY;

                        mport_o[`BUS_MO_REQ] <= 0;
                        mport_o[`BUS_MO_SEQMST] <= 0;
                        if (!word_color_i) mport_o[`BUS_MO_ADDR] <= mport_o[`BUS_MO_ADDR] + FB_LINE_WIDTH;
                        else mport_o[`BUS_MO_ADDR] <= mport_o[`BUS_MO_ADDR] + 4 * FB_LINE_WIDTH;
                    end
                endcase
            end
        end
    end

endmodule
