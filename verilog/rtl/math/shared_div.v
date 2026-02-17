module shared_div_m #(
    parameter WIDTH = 32,
    parameter [WIDTH - 1:0] STAGE_LOCS = 0,

    parameter USERS = 1,

    parameter EXTRA_WIDTH = $clog2(USERS),

    parameter IN_SIZE = 2 * WIDTH,
    parameter OUT_SIZE = WIDTH
) (
    input  wire clk_i,
    input  wire nrst_i,

    input  wire [`STREAM_SIPORT_SIZE(IN_SIZE) * USERS - 1:0] sstreams_i,
    output reg  [`STREAM_SOPORT_SIZE(IN_SIZE) * USERS - 1:0] sstreams_o,

    input  wire [`STREAM_MIPORT_SIZE(OUT_SIZE) * USERS - 1:0] mstreams_i,
    output reg  [`STREAM_MOPORT_SIZE(OUT_SIZE) * USERS - 1:0] mstreams_o
);

    reg [`STREAM_SIPORT(IN_SIZE)] sstreami [USERS - 1:0];
    reg [`STREAM_SOPORT(IN_SIZE)] sstreamo [USERS - 1:0];

    always @(*) begin : INPUT_BREAKOUT_COMB
        integer i;

        for (i = 0; i < USERS; i = i + 1) begin
            sstreami[i] <= sstreams_i[`STREAM_SIPORT_SIZE(IN_SIZE) * i+:`STREAM_SIPORT_SIZE(IN_SIZE)];
            sstreams_o[`STREAM_SOPORT_SIZE(IN_SIZE) * i+:`STREAM_SOPORT_SIZE(IN_SIZE)] <= sstreamo[i];
        end
    end

    reg  [`STREAM_SIPORT(IN_SIZE + EXTRA_WIDTH)] div_sstreami;
    wire [`STREAM_SOPORT(IN_SIZE + EXTRA_WIDTH)] div_sstreamo;

    always @(*) begin : INPUT_COMB
        integer i;
        reg [EXTRA_WIDTH - 1:0] user;

        user = 0;
        for (i = USERS - 1; i >= 0; i = i - 1) begin
            if (sstreami[i][`STREAM_SI_VALID(IN_SIZE)]) begin
                user = i;
            end
        end

        div_sstreami[`STREAM_SI_DATA(IN_SIZE + EXTRA_WIDTH)] <= { user, sstreami[user][`STREAM_SI_DATA(IN_SIZE)] };
        div_sstreami[`STREAM_SI_VALID(IN_SIZE + EXTRA_WIDTH)] <= sstreami[user][`STREAM_SI_VALID(IN_SIZE)];
        div_sstreami[`STREAM_SI_LAST(IN_SIZE + EXTRA_WIDTH)] <= 0;


        for (i = 0; i < USERS; i = i + 1) begin
            if (i == user) begin
                sstreamo[i][`STREAM_SO_READY(IN_SIZE)] = div_sstreamo[`STREAM_SO_READY(IN_SIZE + EXTRA_WIDTH)];
            end
            else begin
                sstreamo[i][`STREAM_SO_READY(IN_SIZE)] <= 0;
            end
        end
    end

    reg  [`STREAM_MIPORT(OUT_SIZE + EXTRA_WIDTH)] div_mstreami;
    wire [`STREAM_MOPORT(OUT_SIZE + EXTRA_WIDTH)] div_mstreamo;

    div_pipe_m #(
        WIDTH,
        STAGE_LOCS,
        EXTRA_WIDTH
    ) div_pipe(
        .clk_i(clk_i),
        .nrst_i(nrst_i),

        .sstream_i(div_sstreami),
        .sstream_o(div_sstreamo),

        .mstream_i(div_mstreami),
        .mstream_o(div_mstreamo)
    );

    reg [EXTRA_WIDTH - 1:0] div_user;
    reg [WIDTH - 1:0] div_data;

    always @(*) begin
        { div_user, div_data } <= div_mstreamo[`STREAM_MO_DATA(OUT_SIZE + EXTRA_WIDTH)];
    end

    reg [`STREAM_MIPORT(OUT_SIZE)] mstreami [USERS - 1:0];
    reg [`STREAM_MOPORT(OUT_SIZE)] mstreamo [USERS - 1:0];

    always @(*) begin : OUTPUT_BREAKOUT_COMB
        integer i;

        for (i = 0; i < USERS; i = i + 1) begin
            mstreami[i] <= mstreams_i[`STREAM_MIPORT_SIZE(OUT_SIZE) * i+:`STREAM_MIPORT_SIZE(OUT_SIZE)];
            mstreams_o[`STREAM_MOPORT_SIZE(OUT_SIZE) * i+:`STREAM_MOPORT_SIZE(OUT_SIZE)] <= mstreamo[i];
        end
    end

    always @(*) begin : OUTPUT_COMB
        integer i;

        for (i = 0; i < USERS; i = i + 1) begin
            if (i == div_user) begin
                mstreamo[i][`STREAM_MO_DATA(OUT_SIZE)] <= div_data;
                mstreamo[i][`STREAM_MO_VALID(OUT_SIZE)] <= div_mstreamo[`STREAM_MO_VALID(OUT_SIZE + EXTRA_WIDTH)];
                div_mstreami[`STREAM_MI_READY(OUT_SIZE + EXTRA_WIDTH)] <= mstreami[i][`STREAM_MI_READY(OUT_SIZE)];
            end
            else begin
                mstreamo[i] <= 0;
            end
        end
    end

endmodule
