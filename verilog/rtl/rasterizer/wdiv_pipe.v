module wdiv_pipe_m(
    input  wire clk_i,
    input  wire nrst_i,

    input  wire [`STREAM_MIPORT(2 * `DIVIDER_WIDTH)] div_mstream_i,
    output wire [`STREAM_MOPORT(2 * `DIVIDER_WIDTH)] div_mstream_o,

    input  wire [`STREAM_SIPORT(`DIVIDER_WIDTH)] div_sstream_i,
    output wire [`STREAM_SOPORT(`DIVIDER_WIDTH)] div_sstream_o,

    input  wire run_i,
    output reg  run_o,

    input  wire busy_i,

    input  wire signed [`WORD] v0x_i,
    input  wire signed [`WORD] v0y_i,
    input  wire signed [`WORD] v0z_i,
    input  wire signed [`WORD] v0w_i,

    input  wire signed [`WORD] v1x_i,
    input  wire signed [`WORD] v1y_i,
    input  wire signed [`WORD] v1z_i,
    input  wire signed [`WORD] v1w_i,

    input  wire signed [`WORD] v2x_i,
    input  wire signed [`WORD] v2y_i,
    input  wire signed [`WORD] v2z_i,
    input  wire signed [`WORD] v2w_i,

    output reg  signed [`WORD] v0x_o,
    output reg  signed [`WORD] v0y_o,
    output reg  signed [`WORD] v0z_o,

    output reg  signed [`WORD] v1x_o,
    output reg  signed [`WORD] v1y_o,
    output reg  signed [`WORD] v1z_o,

    output reg  signed [`WORD] v2x_o,
    output reg  signed [`WORD] v2y_o,
    output reg  signed [`WORD] v2z_o
);

    reg  din_valid;
    wire din_ready;
    reg  [`WORD] da, db;
    wire [`DIVIDER_WIDTH - 1:0] dae = da, dbe = db;

    assign div_mstream_o[`STREAM_MO_DATA(2 * `DIVIDER_WIDTH)] = { dae << `DECIMAL_POS, dbe };
    assign div_mstream_o[`STREAM_MO_LAST(2 * `DIVIDER_WIDTH)] = 0;
    assign div_mstream_o[`STREAM_MO_VALID(2 * `DIVIDER_WIDTH)] = din_valid;
    assign din_ready = div_mstream_i[`STREAM_MI_READY(2 * `DIVIDER_WIDTH)];

    wire dout_valid;
    reg  dout_ready;
    wire [`WORD] dy;

    assign dout_valid = div_sstream_i[`STREAM_SI_VALID(`DIVIDER_WIDTH)];
    assign dy = div_sstream_i[`STREAM_SI_DATA(`DIVIDER_WIDTH)];
    assign div_sstream_o[`STREAM_SO_READY(`DIVIDER_WIDTH)] = dout_ready;

    reg [3:0] in_state, next_in_state;
    reg [3:0] out_state, next_out_state;

    always @(posedge clk_i, negedge nrst_i) begin
        if (!nrst_i) begin
            in_state <= 0;
        end
        else if (clk_i) begin
            in_state <= next_in_state;
        end
    end

    always @(*) begin
        next_in_state <= in_state;

        da <= 0;
        db <= 0;
        din_valid <= 0;

        `define DIV(a, b) begin \
                if (din_ready) next_in_state <= in_state + 1; \
                da <= (a); db <= (b); din_valid <= 1; \
            end

        case (in_state)
            0: begin
                if (run_i) begin
                    next_in_state <= in_state + 1;
                end
            end

            1: `DIV(v0x_i, v0w_i)
            2: `DIV(v0y_i, v0w_i)
            3: `DIV(v0z_i, v0w_i)

            4: `DIV(v1x_i, v1w_i)
            5: `DIV(v1y_i, v1w_i)
            6: `DIV(v1z_i, v1w_i)

            7: `DIV(v2x_i, v2w_i)
            8: `DIV(v2y_i, v2w_i)
            9: `DIV(v2z_i, v2w_i)

            10: begin
                if (busy_i) next_in_state <= in_state + 1;
            end

            11: begin
                if (!busy_i) next_in_state <= 0;
            end
        endcase

        `undef DIV
    end

    always @(posedge clk_i, negedge nrst_i) begin
        if (!nrst_i) begin
            out_state <= 0;
        end
        else if (clk_i) begin
            out_state <= next_out_state;

            case (out_state) 
                0: v0x_o <= dy;
                1: v0y_o <= dy;
                2: v0z_o <= dy;

                3: v1x_o <= dy;
                4: v1y_o <= dy;
                5: v1z_o <= dy;

                6: v2x_o <= dy;
                7: v2y_o <= dy;
                8: v2z_o <= dy;
            endcase
        end
    end

    always @(*) begin
        next_out_state <= out_state;

        run_o <= 0;

        dout_ready <= 0;

        case (out_state)
            0, 1, 2,
            3, 4, 5,
            6, 7, 8: begin
                if (dout_valid) begin
                    next_out_state <= out_state + 1;
                end
                dout_ready <= 1;
            end

            9: begin
                if (busy_i) next_out_state <= out_state + 1;

                run_o <= 1;
            end

            10: begin
                if (!busy_i) next_out_state <= 0;
            end
        endcase
    end

endmodule