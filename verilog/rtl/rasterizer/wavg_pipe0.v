module wavg_pipe0_m(
    input wire clk_i,
    input wire nrst_i,

    input  wire [`STREAM_SIPORT(`SC_WIDTH * 2 + `WORD_WIDTH * 3)] sstream_i,
    output reg  [`STREAM_SOPORT(`SC_WIDTH * 2 + `WORD_WIDTH * 3)] sstream_o,

    input  wire [`STREAM_MIPORT(`WORD_WIDTH + `SC_WIDTH * 2)] mstream_i,
    output reg  [`STREAM_MOPORT(`WORD_WIDTH + `SC_WIDTH * 2)] mstream_o,

    input wire [`WORD_WIDTH - 1:0] t0x,
    input wire [`WORD_WIDTH - 1:0] t0y,
    input wire [`WORD_WIDTH - 1:0] t1x,
    input wire [`WORD_WIDTH - 1:0] t1y,
    input wire [`WORD_WIDTH - 1:0] t2x,
    input wire [`WORD_WIDTH - 1:0] t2y,

    input wire signed [`WORD_WIDTH - 1:0] v0z,
    input wire signed [`WORD_WIDTH - 1:0] v1z,
    input wire signed [`WORD_WIDTH - 1:0] v2z,

    input  wire [`STREAM_MIPORT(2 * `DIVIDER_WIDTH)] div_mstream_i,
    output wire [`STREAM_MOPORT(2 * `DIVIDER_WIDTH)] div_mstream_o
);
    reg mv;
    reg signed [`WORD_WIDTH - 1:0] ma; reg signed [`WORD_WIDTH - 1:0] mb;
    wire signed [`WORD_WIDTH - 1:0] my_c;
    reg  signed [`WORD_WIDTH - 1:0] my;
    mul_m #(`WORD_WIDTH) mul ( .a_i(ma), .b_i(mb), .y_o(my_c) );
    always @(posedge clk_i, negedge nrst_i) if (!nrst_i) my <= 0; else if (mv) my <= my_c;

    reg av;
    reg signed [`WORD_WIDTH - 1:0] aa; reg signed [`WORD_WIDTH - 1:0] ab;
    wire signed [`WORD_WIDTH - 1:0] ay_c;
    reg  signed [`WORD_WIDTH - 1:0] ay;
    add_m #(`WORD_WIDTH) add ( .a_i(aa), .b_i(ab), .y_o(ay_c) );
    always @(posedge clk_i, negedge nrst_i) if (!nrst_i) ay <= 0; else if (av) ay <= ay_c;

    wire [`STREAM_SIPORT(2 * `DIVIDER_WIDTH)] div_si;
    wire [`STREAM_SOPORT(2 * `DIVIDER_WIDTH)] div_so;

    assign div_so = div_mstream_i;
    assign div_mstream_o = div_si;

    reg  din_valid;
    wire din_ready;
    reg signed [`WORD_WIDTH - 1:0] da, db;

    wire signed [`DIVIDER_WIDTH - 1:0] dae, dbe;
    assign dae = da;
    assign dbe = db;

    assign div_si[`STREAM_SI_DATA(2 * `DIVIDER_WIDTH)] = { dae << `DECIMAL_POS, dbe };
    assign div_si[`STREAM_SI_LAST(2 * `DIVIDER_WIDTH)] = 0;
    assign div_si[`STREAM_SI_VALID(2 * `DIVIDER_WIDTH)] = din_valid;
    assign din_ready = div_so[`STREAM_SO_READY(2 * `DIVIDER_WIDTH)];

    reg [`WORD] tempi, tempo;
    always @(posedge clk_i, negedge nrst_i) if (!nrst_i) tempo <= 0; else tempo <= tempi;

    reg [`WORD] depthi, deptho;
    always @(posedge clk_i, negedge nrst_i) if (!nrst_i) deptho <= 0; else deptho <= depthi;

    reg [3:0] state;
    reg [3:0] state_next;

    reg [`WORD_WIDTH + `SC_WIDTH * 2 - 1:0] out_data;

    reg [`SC_WIDTH * 2 + `WORD_WIDTH * 3 - 1:0] in_data;
    wire [`SC_WIDTH - 1:0] posx, posy;
    wire signed [`WORD_WIDTH - 1:0] l0, l1, l2;

    assign { posx, posy, l0, l1, l2 } = in_data;

    always @(posedge clk_i, negedge nrst_i) begin
        if (!nrst_i) begin
            state <= 0;
        end
        else if (clk_i) begin
            state <= state_next;

            case (state)
                0: begin
                    in_data <= sstream_i[`STREAM_SI_DATA(`SC_WIDTH * 2 + `WORD_WIDTH * 3)];
                end

                10: begin
                    out_data <= { deptho, posx, posy };
                end

                default: ;
            endcase
        end
    end

    always @(*) begin
        sstream_o[`STREAM_SO_READY(`SC_WIDTH * 2 + `WORD_WIDTH * 3)] <= 0;

        mstream_o[`STREAM_MO_DATA(2 * `SC_WIDTH + `WORD_WIDTH)]  <= out_data;
        mstream_o[`STREAM_MO_VALID(2 * `SC_WIDTH + `WORD_WIDTH)] <= 1;

        state_next <= state;

        tempi <= tempo;

        depthi <= deptho;

        mv <= 0;
        ma <= 0;
        mb <= 0;
        av <= 0;
        aa <= 0;
        ab <= 0;
        da <= 0;
        db <= 0;

        `define ADD(a, b) aa <= (a); ab <= (b); av <= 1
        `define MUL(a, b) ma <= (a); mb <= (b); mv <= 1
        `define DIV(a, b) da <= (a); db <= (b); din_valid <= 1

        case (state)
            0: begin
                sstream_o[`STREAM_SO_READY(`SC_WIDTH * 2 + `WORD_WIDTH * 3)] <= 1;

                if (sstream_i[`STREAM_SI_VALID(`SC_WIDTH * 2 + `WORD_WIDTH * 3)]) begin
                    state_next <= state + 1;
                end
            end

            1: begin
                if (din_ready) begin
                    state_next <= state + 1;

                    `MUL(v0z, l0);
                end

                `DIV(l0, v0z);
            end

            2: begin
                if (din_ready) begin
                    state_next <= state + 1;

                    tempi <= my;

                    `MUL(v1z, l1);
                end

                `DIV(l1, v1z);
            end

            3: begin
                if (din_ready) begin
                    state_next <= state + 1;

                    `ADD(my, tempo);

                    `MUL(v2z, l2);
                end

                `DIV(l2, v2z);
            end

            4: begin
                state_next <= state + 1;

                `ADD(my, ay);

                `MUL(l0, t0x);
            end

            5: begin
                if (din_ready) begin
                    state_next <= state + 1;

                    `MUL(l1, t1x);
                end

                depthi <= ay;

                `DIV(my, v0z);
            end

            6: begin
                if (din_ready) begin
                    state_next <= state + 1;

                    `MUL(l2, t2x);
                end

                `DIV(my, v1z);
            end

            7: begin
                if (din_ready) begin
                    state_next <= state + 1;

                    `MUL(l0, t0y);
                end

                `DIV(my, v2z);
            end

            8: begin
                if (din_ready) begin
                    state_next <= state + 1;

                    `MUL(l1, t1y);
                end

                `DIV(my, v0z);
            end

            9: begin
                if (din_ready) begin
                    state_next <= state + 1;

                    `MUL(l2, t2y);
                end

                `DIV(my, v1z);
            end

            10: begin
                if (din_ready) begin
                    state_next <= state + 1;
                end

                `DIV(my, v2z);
            end

            11: begin
                if (mstream_i[`STREAM_MI_READY(2 * `SC_WIDTH + `WORD_WIDTH)]) begin
                    state_next <= state + 1;
                end

                mstream_o[`STREAM_MO_VALID(2 * `SC_WIDTH + `WORD_WIDTH)] <= 1;
            end

        endcase

        `undef ADD
        `undef MUL
        `undef DIV
    end

endmodule