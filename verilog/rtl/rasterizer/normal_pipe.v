module normal_pipe_m(
    input wire clk_i,
    input wire nrst_i,

    input  wire run_i,
    input  wire discard_i,
    output wire busy_o,

    input wire signed [`WORD] v0x_i,
    input wire signed [`WORD] v0y_i,
    input wire signed [`WORD] v0z_i,

    input wire signed [`WORD] v1x_i,
    input wire signed [`WORD] v1y_i,
    input wire signed [`WORD] v1z_i,

    input wire signed [`WORD] v2x_i,
    input wire signed [`WORD] v2y_i,
    input wire signed [`WORD] v2z_i,

    input  wire [`STREAM_MIPORT(2 * `DIVIDER_WIDTH)] div_mstream_i,
    output wire [`STREAM_MOPORT(2 * `DIVIDER_WIDTH)] div_mstream_o,

    input  wire [`STREAM_SIPORT(`DIVIDER_WIDTH)] div_sstream_i,
    output wire [`STREAM_SOPORT(`DIVIDER_WIDTH)] div_sstream_o,

    output reg valid_o,
    output reg signed [`WORD] nx_o,
    output reg signed [`WORD] ny_o,
    output reg signed [`WORD] nz_o
);

    wire [`STREAM_SIPORT(2 * `DIVIDER_WIDTH)] div_si;
    wire [`STREAM_SOPORT(2 * `DIVIDER_WIDTH)] div_so;
    wire [`STREAM_MIPORT(`DIVIDER_WIDTH)] div_mi;
    wire [`STREAM_MOPORT(`DIVIDER_WIDTH)] div_mo;

    assign div_so = div_mstream_i;
    assign div_mstream_o = div_si;
    assign div_mo = div_sstream_i;
    assign div_sstream_o = div_mi;

    reg  d1in_valid;
    wire d1in_ready;
    wire d1out_valid;
    wire d1out_ready;
    reg signed [`WORD_WIDTH - 1:0] d1a, d1b;
    wire signed [`WORD_WIDTH - 1:0] d1y;

    wire signed [`DIVIDER_WIDTH - 1:0] d1ae, d1be;
    assign d1ae = d1a;
    assign d1be = d1b;

    assign div_si[`STREAM_SI_DATA(2 * `DIVIDER_WIDTH)] = { d1ae << `DECIMAL_POS, d1be };
    assign div_si[`STREAM_SI_LAST(2 * `DIVIDER_WIDTH)] = 0;
    assign div_si[`STREAM_SI_VALID(2 * `DIVIDER_WIDTH)] = d1in_valid;
    assign d1in_ready = div_so[`STREAM_SO_READY(2 * `DIVIDER_WIDTH)];

    assign div_mi[`STREAM_MI_READY(`DIVIDER_WIDTH)] = d1out_ready;
    assign d1y = div_mo[`STREAM_MO_DATA(`DIVIDER_WIDTH)];
    assign d1out_valid = div_mo[`STREAM_MO_VALID(`DIVIDER_WIDTH)];

    reg sub;
    reg  signed [`WORD_WIDTH - 1:0] as1a; reg  signed [`WORD_WIDTH - 1:0] as1b;
    wire signed [`WORD_WIDTH - 1:0] as1y;
    addsub_m #(`WORD_WIDTH) addsub1( .sub_i(sub), .a_i(as1a), .b_i(as1b), .y_o(as1y) );

    reg  signed [`WORD_WIDTH - 1:0] m1a; reg  signed [`WORD_WIDTH - 1:0] m1b;
    wire signed [`WORD_WIDTH - 1:0] m1y;
    mul_m #(`WORD_WIDTH) mul1( .a_i(m1a), .b_i(m1b), .y_o(m1y) );

    reg  [`WORD] sqrta;
    reg          sqrt_in_valid, sqrt_out_ready;
    wire         sqrt_out_valid, sqrt_in_ready;
    wire [`WORD_WIDTH / 2 - 1:0] sqrty;

    wire [`STREAM_SIPORT(`WORD_WIDTH)] sqrt_si;
    wire [`STREAM_SOPORT(`WORD_WIDTH)] sqrt_so;
    wire [`STREAM_MIPORT(`WORD_WIDTH / 2)] sqrt_mi;
    wire [`STREAM_MOPORT(`WORD_WIDTH / 2)] sqrt_mo;
    sqrt_m #(`WORD_WIDTH) sqrt(
        .clk_i(clk_i),
        .nrst_i(nrst_i),

        .sstream_i(sqrt_si),
        .sstream_o(sqrt_so),

        .mstream_i(sqrt_mi),
        .mstream_o(sqrt_mo)
    );

    assign sqrt_si[`STREAM_SI_DATA(`WORD_WIDTH)]  = sqrta;
    assign sqrt_si[`STREAM_SI_VALID(`WORD_WIDTH)] = sqrt_in_valid;
    assign sqrt_si[`STREAM_SI_LAST(`WORD_WIDTH)]  = 0;
    assign sqrt_in_ready = sqrt_so[`STREAM_SO_READY(`WORD_WIDTH)];

    assign sqrt_mi[`STREAM_MI_READY(`WORD_WIDTH / 2)] = sqrt_out_ready;
    assign sqrty = sqrt_mo[`STREAM_MO_DATA(`WORD_WIDTH / 2)];
    assign sqrt_out_valid = sqrt_mo[`STREAM_MO_VALID(`WORD_WIDTH / 2)];

    reg [4:0] state;

    reg signed [`WORD] temp;

    reg signed vax, vay, vaz;
    reg signed vbx, vby, vbz;

    reg run_reg;

    always @(posedge clk_i, negedge nrst_i) begin
        if (!nrst_i) begin
            state <= 0;

            d1in_valid <= 0;

            run_reg <= 0;
        end
        else if (clk_i) begin
            run_reg <= run_i;

            case (state)
                0: begin
                    if (run_i && !run_reg) begin
                        state <= state + 1;

                        as1a <= v0y_i;
                        as1b <= v1y_i;
                    end
                end

                1: begin
                    state <= state + 1;

                    vay = as1y;

                    as1a <= v1z_i;
                    as1b <= v2z_i;
                end

                2: begin
                    state <= state + 1;

                    vbz = as1y;

                    m1a <= vay;
                    m1b <= vbz;

                    as1a <= v0z_i;
                    as1b <= v1z_i;
                end

                3: begin
                    state <= state + 1;

                    vaz = as1y;

                    as1a <= v1y_i;
                    as1b <= v2y_i;
                end

                4: begin
                    state <= state + 1;

                    vby = as1y;

                    temp <= m1y;

                    m1a <= vaz;
                    m1b <= vby;

                    as1a <= v1x_i;
                    as1b <= v2x_i;
                end

                5: begin
                    state <= state + 1;

                    vbx = as1y;

                    as1a <= temp;
                    as1b <= m1y;

                    m1a <= vaz;
                    m1b <= vbx;
                end

                6: begin
                    state <= state + 1;

                    nx_o <= as1y;

                    temp <= m1y;

                    as1a <= v0x_i;
                    as1b <= v1x_i;
                end

                7: begin
                    state <= state + 1;

                    vax = as1y;

                    m1a <= vax;
                    m1b <= vbz;
                end

                8: begin
                    state <= state + 1;

                    as1a <= temp;
                    as1b <= m1y;

                    m1a <= vax;
                    m1b <= vby;
                end

                9: begin
                    state <= state + 1;

                    ny_o <= as1y;

                    temp <= m1y;

                    m1a <= vay;
                    m1b <= vbx;
                end

                10: begin
                    state <= state + 1;

                    as1a <= temp;
                    as1b <= m1y;

                    m1a <= nx_o;
                    m1b <= nx_o;
                end

                11: begin
                    state <= state + 1;

                    nz_o <= as1y;

                    // add
                    as1a <= m1y;

                    m1a <= ny_o;
                    m1b <= ny_o;
                end

                12: begin
                    state <= state + 1;

                    // add
                    as1b <= m1y;

                    m1a <= nz_o;
                    m1b <= nz_o;
                end

                13: begin
                    state <= state + 1;

                    // add
                    as1a <= as1y;
                    as1b <= m1y;
                end

                14: begin
                    if (sqrt_in_ready) begin
                        state <= state + 1;
                    end
                end

                15: begin
                    if (sqrt_out_valid) begin
                        state <= state + 1;

                        d1in_valid <= 1;
                        d1a <= nx_o;
                        d1b <= sqrty;
                    end
                end

                16: begin
                    if (d1in_ready) begin
                        state <= state + 1;

                        d1a <= ny_o;
                    end
                end

                17: begin
                    if (d1in_ready) begin
                        state <= state + 1;

                        d1a <= nz_o;
                    end
                end

                18: begin
                    if (d1in_ready) begin
                        state <= 0;

                        d1in_valid <= 0;
                    end
                end
            endcase

            if (discard_i && state <= 13) begin
                state <= 0;
            end
        end
    end

    always @(*) begin
        case (state)
            11, 12, 13: sub <= 0;
            default:    sub <= 1;
        endcase

        sqrta <= as1y;
        case (state)
            14:      sqrt_in_valid <= 1;
            default: sqrt_in_valid <= 0;
        endcase

        case (state)
            15:      sqrt_out_ready <= 1;
            default: sqrt_out_ready <= 0;
        endcase
    end

    reg [3:0] out_state;

    always @(posedge clk_i, negedge nrst_i) begin
        if (!nrst_i) begin
            out_state <= 0;

            valid_o <= 0;
        end
        else if (clk_i) begin
            case (out_state)
                0: begin
                    if (run_i && !run_reg) begin
                        out_state <= out_state + 1;

                        valid_o <= 0;
                    end
                end
                
                1: begin
                    if (discard_i) begin
                        out_state <= 0;
                    end
                    else if (d1out_valid) begin
                        out_state <= out_state + 1;

                        nx_o <= d1y;
                    end
                end

                2: begin
                    if (d1out_valid) begin
                        out_state <= out_state + 1;

                        ny_o <= d1y;
                    end
                end

                3: begin
                    if (d1out_valid) begin
                        out_state <= 0;

                        nz_o <= d1y;

                        valid_o <= 1;
                    end
                end
            endcase
        end
    end

    assign d1out_ready = out_state != 0;

    assign busy_o = out_state != 0 || state != 0;

endmodule
