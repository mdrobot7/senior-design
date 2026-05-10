module rasterizer_wrapper_m(
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif

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

    output wire rast_busy_o,

    input  wire [`STREAM_SIPORT(3 * `SHADED_VERTEX_WIDTH)] sstream_i,
    output reg  [`STREAM_SOPORT(3 * `SHADED_VERTEX_WIDTH)] sstream_o,

    input  wire [`STREAM_MIPORT(`FRAGMENT_WIDTH)] mstream_i,
    output wire [`STREAM_MOPORT(`FRAGMENT_WIDTH)] mstream_o,

    input  wire [`BUS_MIPORT] depth_mport_i,
    output wire [`BUS_MOPORT] depth_mport_o,

    input  wire [`BUS_MIPORT] tex_mport_i,
    output wire [`BUS_MOPORT] tex_mport_o
);

    wire clk, nrst;
    assign clk = wb_clk_i;
    assign nrst = !wb_rst_i;

    reg run;
    wire busy;

    wire [`BUS_ADDR_PORT] tex_addr;
    wire [`TEX_DIM] tex_width, tex_height;
    wire [`WORD] tex_width_ex, tex_height_ex;
    assign tex_width = tex_width_ex;
    assign tex_height = tex_height_ex;
    wire [`BUS_ADDR_PORT] depth_addr;
    wire [3:0] user_count;

    reg [`WORD] t0x;
    reg [`WORD] t0y;
    reg [`WORD] t1x;
    reg [`WORD] t1y;
    reg [`WORD] t2x;
    reg [`WORD] t2y;

    reg [`WORD] v0x;
    reg [`WORD] v0y;
    reg [`WORD] v0z;
    reg [`WORD] v0w;
    reg [`WORD] v1x;
    reg [`WORD] v1y;
    reg [`WORD] v1z;
    reg [`WORD] v1w;
    reg [`WORD] v2x;
    reg [`WORD] v2y;
    reg [`WORD] v2z;
    reg [`WORD] v2w;

    reg [`WORD] u0a;
    reg [`WORD] u0b;
    reg [`WORD] u0c;
    reg [`WORD] u0d;
    reg [`WORD] u0e;
    reg [`WORD] u0f;

    reg [`WORD] u1a;
    reg [`WORD] u1b;
    reg [`WORD] u1c;
    reg [`WORD] u1d;
    reg [`WORD] u1e;
    reg [`WORD] u1f;

    reg [`WORD] u2a;
    reg [`WORD] u2b;
    reg [`WORD] u2c;
    reg [`WORD] u2d;
    reg [`WORD] u2e;
    reg [`WORD] u2f;

    assign rast_busy_o = busy || run;

    rasterizer_m rasterizer(
        `ifdef USE_POWER_PINS
            .vccd1(vccd1),	// User area 1 1.8V supply
            .vssd1(vssd1),	// User area 1 digital ground
        `endif

        .clk_i(clk),
        .nrst_i(nrst),

        .tex_stream_i(mstream_i),
        .tex_stream_o(mstream_o),

        .depth_mport_i(depth_mport_i),
        .depth_mport_o(depth_mport_o),

        .tex_mport_i(tex_mport_i),
        .tex_mport_o(tex_mport_o),

        .run_i(run),
        .busy_o(busy),

        .tex_addr_i(tex_addr),
        .tex_width_i(tex_width),
        .tex_height_i(tex_height),

        .depth_addr_i(depth_addr),

        .user_count_i(user_count),

        .t0x_i(t0x),
        .t0y_i(t0y),
        .t1x_i(t1x),
        .t1y_i(t1y),
        .t2x_i(t2x),
        .t2y_i(t2y),

        .v0x_i(v0x),
        .v0y_i(v0y),
        .v0z_i(v0z),
        .v0w_i(v0w),

        .v1x_i(v1x),
        .v1y_i(v1y),
        .v1z_i(v1z),
        .v1w_i(v1w),

        .v2x_i(v2x),
        .v2y_i(v2y),
        .v2z_i(v2z),
        .v2w_i(v2w),

        .u0a_i(u0a),
        .u0b_i(u0b),
        .u0c_i(u0c),
        .u0d_i(u0d),
        .u0e_i(u0e),
        .u0f_i(u0f),

        .u1a_i(u2a),
        .u1b_i(u2b),
        .u1c_i(u2c),
        .u1d_i(u2d),
        .u1e_i(u2e),
        .u1f_i(u2f),

        .u2a_i(u1a),
        .u2b_i(u1b),
        .u2c_i(u1c),
        .u2d_i(u1d),
        .u2e_i(u1e),
        .u2f_i(u1f)
    );

    localparam STATE_READY = 2'd0;
    localparam STATE_RUN   = 2'd1;
    localparam STATE_WAIT  = 2'd2;

    reg [1:0] state;

    reg [4:0] timer;

    always @(posedge clk, negedge nrst) begin
        if (!nrst) begin
            state <= STATE_READY;

            {
                u2f, u2e, u2d, u2c, u2b, u2a,
                t2y, t2x,
                v2w, v2z, v2y, v2x,

                u1f, u1e, u1d, u1c, u1b, u1a,
                t1y, t1x,
                v1w, v1z, v1y, v1x,

                u0f, u0e, u0d, u0c, u0b, u0a,
                t0y, t0x,
                v0w, v0z, v0y, v0x
            } <= 0;
        end
        else if (clk) begin
            case (state)
                STATE_READY: begin
                    if (sstream_i[`STREAM_SI_VALID(3 * `SHADED_VERTEX_WIDTH)]) begin
                        {
                            u2f, u2e, u2d, u2c, u2b, u2a,
                            t2y, t2x,
                            v2w, v2z, v2y, v2x,

                            u1f, u1e, u1d, u1c, u1b, u1a,
                            t1y, t1x,
                            v1w, v1z, v1y, v1x,

                            u0f, u0e, u0d, u0c, u0b, u0a,
                            t0y, t0x,
                            v0w, v0z, v0y, v0x
                        } <= sstream_i[`STREAM_SI_DATA(3 * `SHADED_VERTEX_WIDTH)];

                        state <= STATE_RUN;
                    end
                end

                STATE_RUN: begin
                    if (busy) begin
                        state <= STATE_WAIT;

                        timer <= 0;
                    end
                end

                STATE_WAIT: begin
                    if (!busy) begin
                        if (timer == 31) state <= STATE_READY;
                        else timer <= timer + 1;
                    end
                end
            endcase
        end
    end

    always @(*) begin
        case (state)
            STATE_RUN: run <= 1;
            default: run <= 0;
        endcase

        case (state)
            STATE_READY: sstream_o[`STREAM_SO_READY(3 * `SHADED_VERTEX_WIDTH)] <= 1;
            default: sstream_o[`STREAM_SO_READY(3 * `SHADED_VERTEX_WIDTH)] <= 0;
        endcase
    end

    localparam NUM_REGS = 6;

    reg [NUM_REGS-1:0] wbs_stbN;
    wire [NUM_REGS-1:0] wbs_ackN;
    wire [`WORD_WIDTH-1:0] wbs_datN [NUM_REGS-1:0];

    wishbone_register_m #(32'h00000000, 1, `WBREG_TYPE_REG) addr_reg (
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

        .access_read_mask_i(32'hFFFFFFFF),
        .access_write_mask_i(32'hFFFFFFFF),
        .periph_read_mask_i(32'h00000000),

        .enable_prot_i(32'h00000000),
        .enable_i(1'b0),

        .reg_i(32'h00000000),
        .reg_o(tex_addr)
    );

    wishbone_register_m #(32'h00000000, 1, `WBREG_TYPE_REG) tex_w_reg (
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

        .access_read_mask_i(32'hFFFFFFFF),
        .access_write_mask_i(32'hFFFFFFFF),
        .periph_read_mask_i(32'h00000000),

        .enable_prot_i(32'h00000000),
        .enable_i(1'b0),

        .reg_i(32'd0),
        .reg_o(tex_width_ex)
    );

    wishbone_register_m #(32'h00000000, 1, `WBREG_TYPE_REG) tex_h_reg (
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

        .access_read_mask_i(32'hFFFFFFFF),
        .access_write_mask_i(32'hFFFFFFFF),
        .periph_read_mask_i(32'h00000000),

        .enable_prot_i(32'h00000000),
        .enable_i(1'b0),

        .reg_i(32'd0),
        .reg_o(tex_height_ex)
    );

    wishbone_register_m #(32'h00000000, 1, `WBREG_TYPE_REG) status_reg (
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
        .access_write_mask_i(32'h00000000),
        .periph_read_mask_i(32'hFFFFFFFF),

        .enable_prot_i(32'h00000000),
        .enable_i(1'b0),

        // .reg_i({ rasterizer.frags_in_flight, 12'h000, rasterizer.bary_check_busy, rasterizer.depth_busy, rasterizer.bary_busy, rasterizer.busy_o }),
        .reg_i({ 32'b0 }),
        .reg_o()
    );

    wishbone_register_m #(32'h00000000, 1, `WBREG_TYPE_REG) depth_addr_reg (
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

        .access_read_mask_i(32'hFFFFFFFF),
        .access_write_mask_i(32'hFFFFFFFF),
        .periph_read_mask_i(32'h00000000),

        .enable_prot_i(32'h00000000),
        .enable_i(1'b0),

        .reg_i(32'd0),
        .reg_o(depth_addr)
    );

    wire [31:0] user_count_r;

    wishbone_register_m #(32'h00000000, 1, `WBREG_TYPE_REG) user_count_reg (
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

        .access_read_mask_i(32'hFFFFFFFF),
        .access_write_mask_i(32'hFFFFFFFF),
        .periph_read_mask_i(32'h00000000),

        .enable_prot_i(32'h00000000),
        .enable_i(1'b0),

        .reg_i(32'd0),
        .reg_o(user_count_r)
    );

    assign user_count = user_count_r[3:0];

    // Mux between the registers (similar to user_project_wrapper's addressing)
    wire [$clog2(NUM_REGS)-1:0] word_offset = {2'b00, wbs_adr_i[31:2]};
    always @ (*) begin
        wbs_stbN = wbs_stb_i << word_offset; // Only one at a time
        wbs_ack_o = wbs_ackN[word_offset];   // Mux between wishbone regs, let the index overflow if needed
        wbs_dat_o = wbs_datN[word_offset];
    end

endmodule
