module wavg_pipe1_m(
    input wire clk_i,
    input wire nrst_i,

    input wire [`WORD_WIDTH - 1:0] t0x,
    input wire [`WORD_WIDTH - 1:0] t0y,
    input wire [`WORD_WIDTH - 1:0] t1x,
    input wire [`WORD_WIDTH - 1:0] t1y,
    input wire [`WORD_WIDTH - 1:0] t2x,
    input wire [`WORD_WIDTH - 1:0] t2y,

    input wire signed [`WORD_WIDTH - 1:0] v0z,
    input wire signed [`WORD_WIDTH - 1:0] v1z,
    input wire signed [`WORD_WIDTH - 1:0] v2z,

    input  wire [`STREAM_SIPORT(`DIVIDER_WIDTH)] div_sstream_i,
    output wire [`STREAM_SOPORT(`DIVIDER_WIDTH)] div_sstream_o,

    input  wire [`STREAM_MIPORT(2 * `DIVIDER_WIDTH)] div_mstream_i,
    output wire [`STREAM_MOPORT(2 * `DIVIDER_WIDTH)] div_mstream_o
);
    reg av;
    reg signed [`WORD_WIDTH - 1:0] aa; reg signed [`WORD_WIDTH - 1:0] ab;
    wire signed [`WORD_WIDTH - 1:0] ay_c;
    reg  signed [`WORD_WIDTH - 1:0] ay;
    add_m #(`WORD_WIDTH) add ( .a_i(aa), .b_i(ab), .y_o(ay_c) );
    always @(posedge clk_i, negedge nrst_i) if (!nrst_i) ay <= 0; else if (av) ay <= ay_c;

    wire dout_valid;
    reg  dout_ready;
    wire [`WORD] dy;

    assign dout_valid = div_sstream_i[`STREAM_SI_VALID(`DIVIDER_WIDTH)];
    assign dy = div_sstream_i[`STREAM_SI_DATA(`DIVIDER_WIDTH)];
    assign div_sstream_o[`STREAM_SO_READY(`DIVIDER_WIDTH)] = dout_ready;

    reg  din_valid;
    wire din_ready;
    reg signed [`WORD_WIDTH - 1:0] da, db;

    wire signed [`DIVIDER_WIDTH - 1:0] dae, dbe;
    assign dae = da;
    assign dbe = db;

    assign div_mstream_o[`STREAM_MO_DATA(2 * `DIVIDER_WIDTH)] = { dae << `DECIMAL_POS, dbe };
    assign div_mstream_o[`STREAM_MO_LAST(2 * `DIVIDER_WIDTH)] = 0;
    assign div_mstream_o[`STREAM_MO_VALID(2 * `DIVIDER_WIDTH)] = din_valid;
    assign din_ready = div_mstream_i[`STREAM_MI_READY(2 * `DIVIDER_WIDTH)];

    reg [`WORD] tempi, tempo;
    always @(posedge clk_i, negedge nrst_i) if (!nrst_i) tempo <= 0; else tempo <= tempi;

    reg [`WORD] interpi, interpo;
    always @(posedge clk_i, negedge nrst_i) if (!nrst_i) interpo <= 0; else interpo <= interpi;

    reg [3:0] state;
    reg [3:0] state_next;

    always @(posedge clk_i, negedge nrst_i) begin
        if (!nrst_i) begin
            state <= 0;
        end
        else if (clk_i) begin
            state <= state_next;
        end
    end

    always @(*) begin
        state_next <= state;

        tempi <= tempo;

        av <= 0;
        aa <= 0;
        ab <= 0;
        db <= 0;
        db <= 0;
        din_valid <= 0;
        dout_ready <= 0;

        `define ADD(a, b) aa <= (a); ab <= (b); av <= 1
        `define DIV(a, b) da <= (a); db <= (b); din_valid <= 1

        case (state)
            0: begin
                if (dout_valid) begin
                    state_next <= state + 1;
                    
                    tempi <= dy;
                end

                dout_ready <= 1;
            end

            1: begin
                if (dout_valid) begin
                    state_next <= state + 1;

                    `ADD(tempo, dy);
                end

                dout_ready <= 1;
            end

            2: begin
                if (dout_valid) begin
                    state_next <= state + 1;

                    `ADD(ay, dy);
                end

                dout_ready <= 1;
            end

            3: begin
                if (dout_valid) begin
                    state_next <= state + 1;

                    tempi <= dy;
                end

                dout_ready <= 1;

                interpi <= ay;
            end

            4: begin
                if (dout_valid) begin
                    state_next <= state + 1;

                    `ADD(tempo, dy);
                end

                dout_ready <= 1;
            end

            5: begin
                if (dout_valid) begin
                    state_next <= state + 1;

                    `ADD(ay, dy);
                end

                dout_ready <= 1;
            end

            6: begin
                if (din_ready) begin
                    state_next <= state + 1;
                end

                `DIV(ay, interpo);
            end

            7: begin
                if (dout_valid) begin
                    state_next <= state + 1;

                    tempi <= dy;
                end

                dout_ready <= 1;
            end

            8: begin
                if (dout_valid) begin
                    state_next <= state + 1;

                    `ADD(tempo, dy);
                end

                dout_ready <= 1;
            end

            9: begin
                if (dout_valid) begin
                    state_next <= state + 1;

                    `ADD(ay, dy);
                end

                dout_ready <= 1;
            end

            10: begin
                if (din_ready) begin
                    state_next <= 0;
                end

                `DIV(ay, interpo);
            end
        endcase

        `undef ADD
        `undef MUL
        `undef DIV
    end

endmodule