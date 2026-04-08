module rasterizer_m(
    input wire clk_i,
    input wire nrst_i,

    input  wire [`STREAM_MIPORT(`FRAGMENT_WIDTH)] tex_stream_i,
    output wire [`STREAM_MOPORT(`FRAGMENT_WIDTH)] tex_stream_o,

    input  wire [`BUS_MIPORT] depth_mport_i,
    output wire [`BUS_MOPORT] depth_mport_o,

    input  wire [`BUS_MIPORT] tex_mport_i,
    output wire [`BUS_MOPORT] tex_mport_o,

    input  wire run_i,
    output wire busy_o,

    input wire [`BUS_ADDR_PORT] tex_addr_i,
    input wire [`TEX_DIM] tex_width_i,
    input wire [`TEX_DIM] tex_height_i,

    input wire [`WORD] t0x_i,
    input wire [`WORD] t0y_i,
    input wire [`WORD] t1x_i,
    input wire [`WORD] t1y_i,
    input wire [`WORD] t2x_i,
    input wire [`WORD] t2y_i,

    input wire signed [`WORD] v0x_i,
    input wire signed [`WORD] v0y_i,
    input wire signed [`WORD] v0z_i,
    input wire signed [`WORD] v0w_i,

    input wire signed [`WORD] v1x_i,
    input wire signed [`WORD] v1y_i,
    input wire signed [`WORD] v1z_i,
    input wire signed [`WORD] v1w_i,

    input wire signed [`WORD] v2x_i,
    input wire signed [`WORD] v2y_i,
    input wire signed [`WORD] v2z_i,
    input wire signed [`WORD] v2w_i,

    input wire [`WORD] u0_i,
    input wire [`WORD] u1_i
);

    wire [`STREAM_SIPORT(2 * `DIVIDER_WIDTH)] wdiv_div_si;
    wire [`STREAM_SOPORT(2 * `DIVIDER_WIDTH)] wdiv_div_so;
    wire [`STREAM_MIPORT(`DIVIDER_WIDTH)] wdiv_div_mi;
    wire [`STREAM_MOPORT(`DIVIDER_WIDTH)] wdiv_div_mo;

    wire run;

    wire signed [`WORD] v0x;
    wire signed [`WORD] v0y;
    wire signed [`WORD] v0z;
    wire signed [`WORD] v1x;
    wire signed [`WORD] v1y;
    wire signed [`WORD] v1z;
    wire signed [`WORD] v2x;
    wire signed [`WORD] v2y;
    wire signed [`WORD] v2z;

    wdiv_pipe_m wdiv_pipe(
        .clk_i(clk_i),
        .nrst_i(nrst_i),

        .div_mstream_i(wdiv_div_so),
        .div_mstream_o(wdiv_div_si),
        
        .div_sstream_i(wdiv_div_mo),
        .div_sstream_o(wdiv_div_mi),

        .busy_i(busy_o),

        .run_i(run_i),
        .run_o(run),

        .v0x_i(v0x_i),
        .v0y_i(v0y_i),
        .v0z_i(v0z_i),
        .v0w_i(v0w_i),

        .v1x_i(v1x_i),
        .v1y_i(v1y_i),
        .v1z_i(v1z_i),
        .v1w_i(v1w_i),

        .v2x_i(v2x_i),
        .v2y_i(v2y_i),
        .v2z_i(v2z_i),
        .v2w_i(v2w_i),

        .v0x_o(v0x),
        .v0y_o(v0y),
        .v0z_o(v0z),

        .v1x_o(v1x),
        .v1y_o(v1y),
        .v1z_o(v1z),

        .v2x_o(v2x),
        .v2y_o(v2y),
        .v2z_o(v2z)
    );

    reg signed [`WORD] bbx0;
    reg signed [`WORD] bby0;
    reg signed [`WORD] bbx1;
    reg signed [`WORD] bby1;

    always @(*) begin
        bbx0 = `WORD_SMAX;
        bby0 = `WORD_SMAX;
        bbx1 = 0;
        bby1 = 0;

        if (v0x < bbx0) bbx0 = v0x;
        if (v1x < bbx0) bbx0 = v1x;
        if (v2x < bbx0) bbx0 = v2x;

        if (v0y < bby0) bby0 = v0y;
        if (v1y < bby0) bby0 = v1y;
        if (v2y < bby0) bby0 = v2y;

        if (v0x > bbx1) bbx1 = v0x;
        if (v1x > bbx1) bbx1 = v1x;
        if (v2x > bbx1) bbx1 = v2x;

        if (v0y > bby1) bby1 = v0y;
        if (v1y > bby1) bby1 = v1y;
        if (v2y > bby1) bby1 = v2y;

        bbx0 = bbx0 >>> `DECIMAL_POS;
        bby0 = bby0 >>> `DECIMAL_POS;
        bbx1 = bbx1 >>> `DECIMAL_POS;
        bby1 = bby1 >>> `DECIMAL_POS;

        if (bbx0 < 0) bbx0 = 0;
        if (bby0 < 0) bby0 = 0;
        if (bbx1 >= `WIDTH) bbx1 = `WIDTH - 1;
        if (bby1 >= `HEIGHT) bby1 = `HEIGHT - 1;
    end

    localparam STATE_READY     = 3'b000;
    localparam STATE_BARY_BOOT = 3'b001;
    localparam STATE_RUN_BARY  = 3'b010;
    localparam STATE_WAIT_BARY = 3'b011;
    localparam STATE_DONE      = 3'b100;

    reg [2:0] state;

    reg bary_last;
    reg bary_run;
    
    wire bary_init;
    wire bary_discard;
    wire bary_busy;
    wire depth_busy;

    wire bary_check_busy;

    wire normal_busy;
    wire normal_valid;
    wire signed [`WORD] nx, ny, nz;

    reg [15:0] frags_in_flight; // TODO: perhaps smaller

    reg [`SC_WIDTH - 1:0] posx;
    reg [`SC_WIDTH - 1:0] posy;

    reg  signed [`WORD] bary_l0;
    reg  signed [`WORD] bary_l1;
    reg  signed [`WORD] bary_l2;

    reg [`WORD] depth;

    wire [`STREAM_MIPORT(`SC_WIDTH * 2)] pos_streami;
    wire [`STREAM_MOPORT(`SC_WIDTH * 2)] pos_streamo;
    wire [`SC_WIDTH * 2 - 1:0] pos_stream_data;

    wire [`STREAM_MIPORT(`SC_WIDTH * 2 + `WORD_WIDTH * 3)] bary_streami;
    wire [`STREAM_MOPORT(`SC_WIDTH * 2 + `WORD_WIDTH * 3)] bary_streamo;

    wire [`STREAM_MIPORT(`SC_WIDTH * 2 + `WORD_WIDTH * 3)] filt_bary_streami;
    wire [`STREAM_MOPORT(`SC_WIDTH * 2 + `WORD_WIDTH * 3)] filt_bary_streamo;

    wire [`STREAM_MIPORT(`RAST_WAVG_OUT_WIDTH)] wavg_streami;
    wire [`STREAM_MOPORT(`RAST_WAVG_OUT_WIDTH)] wavg_streamo;

    wire [`STREAM_MIPORT(`RAST_WAVG_OUT_WIDTH)] wavg_fifo_streami;
    wire [`STREAM_MOPORT(`RAST_WAVG_OUT_WIDTH)] wavg_fifo_streamo;

    wire [`STREAM_MIPORT(`RAST_DT_OUT_WIDTH)] filt_depth_streami;
    wire [`STREAM_MOPORT(`RAST_DT_OUT_WIDTH)] filt_depth_streamo;

    wire [`STREAM_SIPORT(2 * `DIVIDER_WIDTH)] normal_div_si;
    wire [`STREAM_SOPORT(2 * `DIVIDER_WIDTH)] normal_div_so;
    wire [`STREAM_MIPORT(`DIVIDER_WIDTH)] normal_div_mi;
    wire [`STREAM_MOPORT(`DIVIDER_WIDTH)] normal_div_mo;

    wire [`STREAM_SIPORT(2 * `DIVIDER_WIDTH)] bary_div_si;
    wire [`STREAM_SOPORT(2 * `DIVIDER_WIDTH)] bary_div_so;
    wire [`STREAM_MIPORT(`DIVIDER_WIDTH)] bary_div_mi;
    wire [`STREAM_MOPORT(`DIVIDER_WIDTH)] bary_div_mo;

    wire [`STREAM_SIPORT(2 * `DIVIDER_WIDTH)] wavg0_div_si;
    wire [`STREAM_SOPORT(2 * `DIVIDER_WIDTH)] wavg0_div_so;
    wire [`STREAM_MIPORT(`DIVIDER_WIDTH)] wavg0_div_mi;
    wire [`STREAM_MOPORT(`DIVIDER_WIDTH)] wavg0_div_mo;

    wire [`STREAM_SIPORT(2 * `DIVIDER_WIDTH)] wavg1_div_si;
    wire [`STREAM_SOPORT(2 * `DIVIDER_WIDTH)] wavg1_div_so;
    wire [`STREAM_MIPORT(`DIVIDER_WIDTH)] wavg1_div_mi;
    wire [`STREAM_MOPORT(`DIVIDER_WIDTH)] wavg1_div_mo;

    always @(posedge clk_i, negedge nrst_i) begin
        if (!nrst_i) begin
            state <= STATE_READY;

            posx <= 0;
            posy <= 0;

            frags_in_flight <= 0;

            bary_run <= 0;
        end
        else if (clk_i) begin
            case (state)
                STATE_READY: begin
                    if (run) begin
                        state <= STATE_BARY_BOOT;
                        
                        posx  <= bbx0;
                        posy  <= bby0;

                        bary_last <= 0;

                        frags_in_flight = 0;
                    end
                end

                STATE_BARY_BOOT: begin
                    if (
                        (bbx0 == bbx1 && bby0 == bby1) ||
                        (bbx0 > bbx1 || bby0 > bby1) ||
                        (bbx0 >= `WIDTH || bby0 >= `HEIGHT)
                    ) state <= STATE_DONE;
                    else bary_run <= 1;

                    if (bary_init) begin
                        if (bary_discard) state <= STATE_DONE;
                        else state <= STATE_RUN_BARY;

                        bary_run <= 0;
                    end
                end

                STATE_RUN_BARY: begin
                    if (pos_streami[`STREAM_MI_READY(`SC_WIDTH * 2)]) state <= STATE_WAIT_BARY;
                end

                STATE_WAIT_BARY: begin
                    state <= STATE_RUN_BARY;

                    bary_last <= ((posx == (bbx1 - 1)) && (posy == bby1)) || ((posx == bbx1) && (posy == bby1)) || ((bbx0 == bbx1) && (posy == (bby1 - 1)));

                    if (posx == bbx1) begin
                        posx <= bbx0;
                        posy <= posy + 1;

                        if (posy == bby1) begin
                            state <= STATE_DONE;
                        end
                    end
                    else begin
                        posx <= posx + 1;
                    end
                end

                STATE_DONE: begin
                    if (!busy_o && !run) state <= STATE_READY;
                end
            endcase

            if (
                filt_bary_streamo[`STREAM_MO_VALID(`SC_WIDTH * 2 + `WORD_WIDTH * 3)] &&
                filt_bary_streami[`STREAM_MI_READY(`SC_WIDTH * 2 + `WORD_WIDTH * 3)]
            ) begin
                frags_in_flight = frags_in_flight + 1;
            end

            if (
                wavg_fifo_streamo[`STREAM_MO_VALID(`SC_WIDTH * 2 + `WORD_WIDTH * 3)] &&
                wavg_fifo_streami[`STREAM_MI_READY(`SC_WIDTH * 2 + `WORD_WIDTH * 3)]
            ) begin
                frags_in_flight = frags_in_flight - 1;
            end

            if (
                filt_depth_streamo[`STREAM_MO_VALID(`RAST_DT_OUT_WIDTH)] &&
                filt_depth_streami[`STREAM_MI_READY(`RAST_DT_OUT_WIDTH)]
            ) begin
                frags_in_flight = frags_in_flight + 1;
            end

            if (
                tex_stream_o[`STREAM_MO_VALID(`FRAGMENT_WIDTH)] &&
                tex_stream_i[`STREAM_MI_READY(`FRAGMENT_WIDTH)]
            ) begin
                frags_in_flight = frags_in_flight - 1;
            end
        end
    end

    assign pos_stream_data = { posx, posy };

    assign pos_streamo[`STREAM_MO_VALID(`SC_WIDTH * 2)] = state == STATE_RUN_BARY;
    assign pos_streamo[`STREAM_MO_DATA(`SC_WIDTH * 2)] = pos_stream_data;
    assign pos_streamo[`STREAM_MO_LAST(`SC_WIDTH * 2)] = bary_last;

    // busy = (state != STATE_READY && state != STATE_DONE) || bary_busy
    assign busy_o =
        (state != STATE_READY && state != STATE_DONE) ||
        bary_busy ||
        bary_check_busy ||
        depth_busy ||
        normal_busy ||
        (frags_in_flight != 0); // TODO: make an busy and flushed different

    normal_pipe_m normal_pipe(
        .clk_i(clk_i),
        .nrst_i(nrst_i),

        .run_i(run_i),
        .discard_i(bary_discard),
        .busy_o(normal_busy),

        .v0x_i(v0x_i),
        .v0y_i(v0y_i),
        .v0z_i(v0z_i),
        .v1x_i(v1x_i),
        .v1y_i(v1y_i),
        .v1z_i(v1z_i),
        .v2x_i(v2x_i),
        .v2y_i(v2y_i),
        .v2z_i(v2z_i),

        .div_mstream_i(normal_div_so),
        .div_mstream_o(normal_div_si),

        .div_sstream_i(normal_div_mo),
        .div_sstream_o(normal_div_mi),

        .valid_o(normal_valid),
        .nx_o(nx),
        .ny_o(ny),
        .nz_o(nz)
    );

    bary_pipe_m bary_pipe(
        .clk_i(clk_i),
        .nrst_i(nrst_i),

        .run_i(bary_run),
        .init_o(bary_init),
        .discard_o(bary_discard),
        .busy_o(bary_busy),

        .sstream_i(pos_streamo),
        .sstream_o(pos_streami),

        .mstream_i(bary_streami),
        .mstream_o(bary_streamo),

        .v0x(v0x),
        .v0y(v0y),
        .v0z(v0z),
        .v1x(v1x),
        .v1y(v1y),
        .v1z(v1z),
        .v2x(v2x),
        .v2y(v2y),
        .v2z(v2z),
        
        .div_mstream_i(bary_div_so),
        .div_mstream_o(bary_div_si),

        .div_sstream_i(bary_div_mo),
        .div_sstream_o(bary_div_mi)
    );

    bary_check_pipe_m bary_check_pipe(
        .clk_i(clk_i),
        .nrst_i(nrst_i),

        .sstream_i(bary_streamo),
        .sstream_o(bary_streami),

        .mstream_i(filt_bary_streami),
        .mstream_o(filt_bary_streamo),

        .busy_o(bary_check_busy)
    );

    wavg_pipe_m wavg_pipe(
        .clk_i(clk_i),
        .nrst_i(nrst_i),

        .sstream_i(filt_bary_streamo),
        .sstream_o(filt_bary_streami),

        .mstream_i(wavg_streami),
        .mstream_o(wavg_streamo),

        .t0x(t0x_i),
        .t0y(t0y_i),
        .t1x(t1x_i),
        .t1y(t1y_i),
        .t2x(t2x_i),
        .t2y(t2y_i),

        .v0z(v0z),
        .v1z(v1z),
        .v2z(v2z),

        .div0_mstream_i(wavg0_div_so),
        .div0_mstream_o(wavg0_div_si),

        .div0_sstream_i(wavg0_div_mo),
        .div0_sstream_o(wavg0_div_mi),

        .div1_mstream_i(wavg1_div_so),
        .div1_mstream_o(wavg1_div_si),

        .div1_sstream_i(wavg1_div_mo),
        .div1_sstream_o(wavg1_div_mi)
    );

    stream_fifo_m #(`RAST_WAVG_OUT_WIDTH) wavg_fifo_pipe(
        .clk_i(clk_i),
        .nrst_i(nrst_i),

        .sstream_i(wavg_streamo),
        .sstream_o(wavg_streami),

        .mstream_i(wavg_fifo_streami),
        .mstream_o(wavg_fifo_streamo)
    );

    depth_test_m depth_test(
        .clk_i(clk_i),
        .nrst_i(nrst_i),

        .sstream_i(wavg_fifo_streamo),
        .sstream_o(wavg_fifo_streami),

        .mstream_i(filt_depth_streami),
        .mstream_o(filt_depth_streamo),

        .mport_i(depth_mport_i),
        .mport_o(depth_mport_o),
        
        .busy_o(depth_busy)
    );

    tex_sample_m tex_sample(
        .clk_i(clk_i),
        .nrst_i(nrst_i),

        .sstream_i(filt_depth_streamo),
        .sstream_o(filt_depth_streami),

        .mstream_i(tex_stream_i),
        .mstream_o(tex_stream_o),

        .mport_i(tex_mport_i),
        .mport_o(tex_mport_o),

        .u0_i(u0_i),
        .u1_i(u1_i),

        .tex_addr_i(tex_addr_i),
        .tex_width_i(tex_width_i),
        .tex_height_i(tex_height_i),
        
        .normal_valid_i(normal_valid),
        .nx_i(nx),
        .ny_i(ny),
        .nz_i(nz)
    );

    shared_div_rasterizer_m divider(
        .clk_i(clk_i),
        .nrst_i(nrst_i),

        .sstreams_i({ wdiv_div_si, normal_div_si, bary_div_si, wavg0_div_si, wavg1_div_si }),
        .sstreams_o({ wdiv_div_so, normal_div_so, bary_div_so, wavg0_div_so, wavg1_div_so }),
        
        .mstreams_i({ wdiv_div_mi, normal_div_mi, bary_div_mi, wavg0_div_mi, wavg1_div_mi }),
        .mstreams_o({ wdiv_div_mo, normal_div_mo, bary_div_mo, wavg0_div_mo, wavg1_div_mo })
    );

endmodule
