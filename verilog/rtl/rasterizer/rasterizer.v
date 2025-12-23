module rasterizer_m #(
    parameter WORD_WIDTH = 32,
    parameter WIDTH = 320,
    parameter HEIGHT = 240
) (
    input wire clk_i,
    input wire nrst_i,

    input  wire [`BUS_MIPORT] mport_i,
    output wire [`BUS_MOPORT] mport_o,

    input  wire run_i,
    output wire busy_o,
    output wire output_ready_o,

    input wire [7:0] color_i,

    input wire [WORD_WIDTH - 1:0] t0x,
    input wire [WORD_WIDTH - 1:0] t0y,
    input wire [WORD_WIDTH - 1:0] t1x,
    input wire [WORD_WIDTH - 1:0] t1y,
    input wire [WORD_WIDTH - 1:0] t2x,
    input wire [WORD_WIDTH - 1:0] t2y,

    input wire signed [WORD_WIDTH - 1:0] v0x,
    input wire signed [WORD_WIDTH - 1:0] v0y,
    input wire signed [WORD_WIDTH - 1:0] v0z,
    input wire signed [WORD_WIDTH - 1:0] v1x,
    input wire signed [WORD_WIDTH - 1:0] v1y,
    input wire signed [WORD_WIDTH - 1:0] v1z,
    input wire signed [WORD_WIDTH - 1:0] v2x,
    input wire signed [WORD_WIDTH - 1:0] v2y,
    input wire signed [WORD_WIDTH - 1:0] v2z
);
    assign output_ready_o = 0;

    localparam WORD_SMAX = 64'd1 << (WORD_WIDTH - 2);

    localparam SC_WIDTH = $clog2(WIDTH > HEIGHT ? WIDTH : HEIGHT);

    reg signed [WORD_WIDTH - 1:0] bbx0;
    reg signed [WORD_WIDTH - 1:0] bby0;
    reg signed [WORD_WIDTH - 1:0] bbx1;
    reg signed [WORD_WIDTH - 1:0] bby1;

    always @(*) begin
        bbx0 = WORD_SMAX;
        bby0 = WORD_SMAX;
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
        if (bbx1 >= WIDTH) bbx1 = WIDTH - 1;
        if (bby1 >= HEIGHT) bby1 = HEIGHT - 1;
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

    reg [SC_WIDTH - 1:0] posx;
    reg [SC_WIDTH - 1:0] posy;

    reg  signed [WORD_WIDTH - 1:0] bary_l0;
    reg  signed [WORD_WIDTH - 1:0] bary_l1;
    reg  signed [WORD_WIDTH - 1:0] bary_l2;

    reg [WORD_WIDTH - 1:0] depth;

    wire [`STREAM_MIPORT(SC_WIDTH * 2)] pos_streami;
    wire [`STREAM_MOPORT(SC_WIDTH * 2)] pos_streamo;
    wire [SC_WIDTH * 2 - 1:0] pos_stream_data;

    wire [`STREAM_MIPORT(SC_WIDTH * 2 + WORD_WIDTH * 3)] bary_streami;
    wire [`STREAM_MOPORT(SC_WIDTH * 2 + WORD_WIDTH * 3)] bary_streamo;

    wire [`STREAM_MIPORT(SC_WIDTH * 2 + WORD_WIDTH * 3)] filt_bary_streami;
    wire [`STREAM_MOPORT(SC_WIDTH * 2 + WORD_WIDTH * 3)] filt_bary_streamo;

    wire [`STREAM_MIPORT(SC_WIDTH * 2 + WORD_WIDTH * 3)] wavg_streami;
    wire [`STREAM_MOPORT(SC_WIDTH * 2 + WORD_WIDTH * 3)] wavg_streamo;

    wire [`STREAM_MIPORT(SC_WIDTH * 2 + WORD_WIDTH * 3)] wavg_fifo_streami;
    wire [`STREAM_MOPORT(SC_WIDTH * 2 + WORD_WIDTH * 3)] wavg_fifo_streamo;

    always @(posedge clk_i, negedge nrst_i) begin
        if (!nrst_i) begin
            state <= STATE_READY;

            posx <= 0;
            posy <= 0;

            bary_run <= 0;
        end
        else if (clk_i) begin
            case (state)
                STATE_READY: begin
                    if (run_i) begin
                        state <= STATE_BARY_BOOT;

                        // TODO: handle edge cases here
                        posx  <= bbx0;
                        posy  <= bby0;

                        bary_last <= 0;
                    end
                end

                STATE_BARY_BOOT: begin
                    if (
                        (bbx0 == bbx1 && bby0 == bby1) ||
                        (bbx0 > bbx1 || bby0 > bby1) ||
                        (bbx0 >= WIDTH || bby0 >= HEIGHT)
                    ) state <= STATE_DONE;
                    else bary_run <= 1;

                    if (bary_init) begin
                        if (bary_discard) state <= STATE_DONE;
                        else state <= STATE_RUN_BARY;

                        bary_run <= 0;
                    end
                end

                STATE_RUN_BARY: begin
                    if (pos_streami[`STREAM_MI_READY(SC_WIDTH * 2)]) state <= STATE_WAIT_BARY;
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
                    if (!run_i) state <= STATE_READY;
                end
            endcase
        end
    end

    assign pos_stream_data = { posx, posy };

    assign pos_streamo[`STREAM_MO_VALID(SC_WIDTH * 2)] = state == STATE_RUN_BARY;
    assign pos_streamo[`STREAM_MO_DATA(SC_WIDTH * 2)] = pos_stream_data;
    assign pos_streamo[`STREAM_MO_LAST(SC_WIDTH * 2)] = bary_last;

    assign busy_o = (state != STATE_READY && state != STATE_DONE) || bary_busy;

    // #(WORD_WIDTH, WIDTH, HEIGHT)
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
        .v2z(v2z)
    );

    bary_check_pipe_m bary_check_pipe(
        .clk_i(clk_i),
        .nrst_i(nrst_i),

        .sstream_i(bary_streamo),
        .sstream_o(bary_streami),

        .mstream_i(filt_bary_streami),
        .mstream_o(filt_bary_streamo)
    );

    wavg_pipe_m wavg_pipe(
        .clk_i(clk_i),
        .nrst_i(nrst_i),

        .sstream_i(filt_bary_streamo),
        .sstream_o(filt_bary_streami),

        .mstream_i(wavg_streami),
        .mstream_o(wavg_streamo),

        .t0x(t0x),
        .t0y(t0y),
        .t1x(t1x),
        .t1y(t1y),
        .t2x(t2x),
        .t2y(t2y),

        .v0z(v0z),
        .v1z(v1z),
        .v2z(v2z)
    );

    stream_fifo_m #(`SC_WIDTH * 2 + `WORD_WIDTH * 3, 5) wavg_fifo_pipe(
        .clk_i(clk_i),
        .nrst_i(nrst_i),

        .sstream_i(wavg_streamo),
        .sstream_o(wavg_streami),

        .mstream_i(wavg_fifo_streami),
        .mstream_o(wavg_fifo_streamo)
    );

    mem_write_m mem_write(
        .clk_i(clk_i),
        .nrst_i(nrst_i),

        .sstream_i(wavg_fifo_streamo),
        .sstream_o(wavg_fifo_streami),

        .mport_i(mport_i),
        .mport_o(mport_o),
        
        .color_i(color_i)
    );

endmodule