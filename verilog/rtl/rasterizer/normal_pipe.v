module normal_pipe_m(
    input wire clk_i,
    input wire nrst_i,

    input wire run_i,

    input wire signed [`WORD] v0x_i,
    input wire signed [`WORD] v0y_i,
    input wire signed [`WORD] v0z_i,

    input wire signed [`WORD] v1x_i,
    input wire signed [`WORD] v1y_i,
    input wire signed [`WORD] v1z_i,

    input  wire [`STREAM_MIPORT(2 * `DIVIDER_WIDTH)] div_mstream_i,
    output wire [`STREAM_MOPORT(2 * `DIVIDER_WIDTH)] div_mstream_o,

    input  wire [`STREAM_SIPORT(`DIVIDER_WIDTH)] div_sstream_i,
    output wire [`STREAM_SOPORT(`DIVIDER_WIDTH)] div_sstream_o

    output wire valid_o,
    output wire signed [`WORD] nx_o,
    output wire signed [`WORD] ny_o,
    output wire signed [`WORD] nz_o
);

    reg  d1in_valid;
    wire d1in_ready;
    wire d1out_valid;
    reg  d1out_ready;
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
    addsub_m #(`WORD_WIDTH) addsub1( sub_i(sub), .a_i(as1a), .b_i(as1b), .y_o(as1y) );

    reg  signed [`WORD_WIDTH - 1:0] m1a; reg  signed [`WORD_WIDTH - 1:0] m1b;
    wire signed [`WORD_WIDTH - 1:0] m1y;
    mul_m #(`WORD_WIDTH) mul1( .a_i(m1a), .b_i(m1b), .y_o(m1y) );

    reg [3:0] state;

    reg signed [`WORD] temp;

    always @(posedge clk_i, negedge nrst_i) begin
        if (!nrst_i) begin
            state <= 0;
        end
        else if (clk_i) begin
            case (state)
                0: begin
                    if (run_i) begin
                        state <= 1;

                        m1a <= v0y_i;
                        m1b <= v1z_i
                    end
                end

                1: begin
                    temp <= m1y;

                    m1a <= v0z_i;
                    m1b <= v1y_i;
                end

                2: begin
                    as1a <= temp;
                    as1b <= m1y;

                    m1a <= v0z_i;
                    m1b <= v1x_i;
                end

                3: begin
                    nx_o <= as1y;

                    temp <= m1y;

                    m1a <= vox_i;
                    m1b <= v1z_i;
                end

                4: begin
                    as1a <= temp;
                    as1b <= m1y;

                    m1a <= v0x_i;
                    m1b <= v1y_i;
                end

                5: begin
                    ny_o <= as1y;

                    temp <= m1y;

                    m1a <= v0y_i;
                    m1b <= v1x_i;
                end

                6: begin
                    as1a <= temp;
                    as1b <= m1y;

                    m1a <= nx_o;
                    m1b <= nx_o;
                end

                7: begin
                    nz_o <= as1y;

                    as1a <= m1y;

                    m1a <= ny_o;
                    m1b <= ny_o;
                end

                8: begin
                    as1b <= m1y;

                    m1a <= nz_o;
                    m1b <= nz_o;
                end

                9: begin
                    as1a <= as1y;
                    as1b <= m1y;
                end

                10: begin
                    
                end
            endcase
        end
    end

    always @(*) begin
        case (state)
            2, 4, 6: sub <= 1;
            default: sub <= 0;
        endcase
    end

endmodule