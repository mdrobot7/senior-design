module lerpinator_mid_m(
    input wire clk_i,
    input wire nrst_i,

    input  wire [`STREAM_SIPORT(3 * `WORD_WIDTH)] sstream_i,
    output wire [`STREAM_SOPORT(3 * `WORD_WIDTH)] sstream_o,

    input  wire [`STREAM_SIPORT(`DIVIDER_WIDTH)] div_sstream_i,
    output reg  [`STREAM_SOPORT(`DIVIDER_WIDTH)] div_sstream_o,

    input  wire [`STREAM_MIPORT(2 * `DIVIDER_WIDTH)] div_mstream_i,
    output wire [`STREAM_MOPORT(2 * `DIVIDER_WIDTH)] div_mstream_o
);

    reg av;
    reg signed [`DIVIDER_WIDTH - 1:0] aa; reg signed [`DIVIDER_WIDTH - 1:0] ab;
    wire signed [`DIVIDER_WIDTH - 1:0] ay_c;
    reg  signed [`DIVIDER_WIDTH - 1:0] ay;
    add_m #(`DIVIDER_WIDTH) add ( .a_i(aa), .b_i(ab), .y_o(ay_c) );
    always @(posedge clk_i, negedge nrst_i) if (!nrst_i) ay <= 0; else if (av) ay <= ay_c;

    reg mv;
    reg signed [`DIVIDER_WIDTH - 1:0] ma; reg signed [`DIVIDER_WIDTH - 1:0] mb;
    wire signed [`DIVIDER_WIDTH - 1:0] my_c;
    reg  signed [`DIVIDER_WIDTH - 1:0] my;
    mul_m #(`DIVIDER_WIDTH) mul ( .a_i(ma), .b_i(mb), .y_o(my_c) );
    always @(posedge clk_i, negedge nrst_i) if (!nrst_i) my <= 0; else if (mv) my <= my_c;

    reg div_valid;
    wire div_ready;
    reg signed [`DIVIDER_WIDTH - 1:0] da, db;

    assign div_mstream_o[`STREAM_MO_DATA(2 * `DIVIDER_WIDTH)] = { da, db };
    assign div_mstream_o[`STREAM_MO_LAST(2 * `DIVIDER_WIDTH)] = 0;
    assign div_mstream_o[`STREAM_MO_VALID(2 * `DIVIDER_WIDTH)] = div_valid;
    assign div_ready = div_mstream_i[`STREAM_MI_READY(2 * `DIVIDER_WIDTH)];

    wire signed [`DIVIDER_WIDTH - 1:0] dy;
    assign dy = div_sstream_i[`STREAM_SI_DATA(`DIVIDER_WIDTH)];

    reg signed [`WORD] v0, v1, v2, v0i, v1i, v2i;
    always @(posedge clk_i, negedge nrst_i) begin
        if (!nrst_i) begin
            v0 <= 0;
            v1 <= 0;
            v2 <= 0;
        end
        else begin
            v0 <= v0i;
            v1 <= v1i;
            v2 <= v2i;
        end
    end

    reg signed [`DIVIDER_WIDTH - 1:0] tempi, tempo;
    always @(posedge clk_i, negedge nrst_i) if (!nrst_i) tempo <= 0; else tempo <= tempi;

    reg signed [`DIVIDER_WIDTH - 1:0] num0i, num1i, num2i, num0o, num1o, num2o;
    always @(posedge clk_i, negedge nrst_i) begin
        if (!nrst_i) begin
            num0o <= 0;
            num1o <= 0;
            num2o <= 0;
        end
        else if (clk_i) begin
            num0o <= num0i;
            num1o <= num1i;
            num2o <= num2i;
        end
    end

    reg [2:0] next_state;
    reg [2:0] state;

    always @(posedge clk_i, negedge nrst_i) begin
        if (!nrst_i) begin
            state = 0;
        end
        else if (clk_i) begin
            state = next_state;
        end
    end

    always @(*) begin
        next_state = state;

        div_sstream_o[`STREAM_SO_READY(`DIVIDER_WIDTH)] = 0;

        div_valid = 0;
        da = 0;
        db = 0;
        
        mv = 0;
        ma = 0;
        mb = 0;
        
        av = 0;
        aa = 0;
        ab = 0;

        tempi = tempo;

        num0i = num0o;
        num1i = num1o;
        num2i = num2o;

        v0i = v0;
        v1i = v1;
        v2i = v2;

        `define DIV(a, b) begin da = a; db = b; div_valid = 1; end
        `define MUL(a, b) begin ma = a; mb = b; mv = 1; end
        `define ADD(a, b) begin aa = a; ab = b; av = 1; end
        `define EXTEND(a) ({ a, { `DECIMAL_POS { 1'b0 } } })

        case (state)
            0: begin
                if (sstream_i[`STREAM_SI_VALID(3 * `WORD_WIDTH)]) begin
                    { v0i, v1i, v2i } <= sstream_i[`STREAM_SI_DATA(3 * `WORD_WIDTH)];

                    next_state = state + 1;
                end
            end

            1: begin
                div_sstream_o[`STREAM_SO_READY(`DIVIDER_WIDTH)] = 1;

                if (div_sstream_i[`STREAM_SI_VALID(`DIVIDER_WIDTH)]) begin
                    tempi = div_sstream_i[`STREAM_SI_DATA(`DIVIDER_WIDTH)];

                    `MUL(div_sstream_i[`STREAM_SI_DATA(`DIVIDER_WIDTH)], v0);

                    next_state = state + 1;
                end
            end

            2: begin
                div_sstream_o[`STREAM_SO_READY(`DIVIDER_WIDTH)] = 1;

                if (div_sstream_i[`STREAM_SI_VALID(`DIVIDER_WIDTH)]) begin
                    `ADD(tempo, div_sstream_i[`STREAM_SI_DATA(`DIVIDER_WIDTH)]);

                    `MUL(div_sstream_i[`STREAM_SI_DATA(`DIVIDER_WIDTH)], v1);

                    num0i = my;

                    next_state = state + 1;
                end
            end

            3: begin
                div_sstream_o[`STREAM_SO_READY(`DIVIDER_WIDTH)] = 1;

                if (div_sstream_i[`STREAM_SI_VALID(`DIVIDER_WIDTH)]) begin
                    `ADD(ay, div_sstream_i[`STREAM_SI_DATA(`DIVIDER_WIDTH)]);

                    `MUL(div_sstream_i[`STREAM_SI_DATA(`DIVIDER_WIDTH)], v2);

                    num1i = my;

                    next_state = state + 1;
                end
            end

            4: begin
                num2i = my;
                tempi = ay;

                `ADD(num0o, num1o);

                next_state = state + 1;
            end

            5: begin
                `ADD(ay, num2o);

                next_state = state + 1;
            end

            6: begin
                `DIV(ay, tempo >>> `DECIMAL_POS);

                if (div_ready) begin
                    next_state = 0;
                end
            end
        endcase

        `undef DIV
        `undef ADD
        `undef EXTEND
    end

    assign sstream_o[`STREAM_SO_READY(3 * `WORD_WIDTH)] = state == 0;

endmodule
