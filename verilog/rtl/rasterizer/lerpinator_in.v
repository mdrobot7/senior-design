module lerpinator_in_m(
    input wire clk_i,
    input wire nrst_i,

    input  wire [`STREAM_MIPORT(3 * `WORD_WIDTH)] mstream_i,
    output reg  [`STREAM_MOPORT(3 * `WORD_WIDTH)] mstream_o,

    input wire signed [`WORD_WIDTH - 1:0] v0z,
    input wire signed [`WORD_WIDTH - 1:0] v1z,
    input wire signed [`WORD_WIDTH - 1:0] v2z,

    input  wire [`STREAM_SIPORT(`LERPINATOR_IN_WIDTH)] sstream_i,
    output reg  [`STREAM_SOPORT(`LERPINATOR_IN_WIDTH)] sstream_o,

    input  wire [`STREAM_MIPORT(2 * `DIVIDER_WIDTH)] div_mstream_i,
    output wire [`STREAM_MOPORT(2 * `DIVIDER_WIDTH)] div_mstream_o
);
    reg div_valid;
    wire div_ready;
    reg signed [`DIVIDER_WIDTH - 1:0] da, db;

    assign div_mstream_o[`STREAM_MO_DATA(2 * `DIVIDER_WIDTH)] = { da, db };
    assign div_mstream_o[`STREAM_MO_LAST(2 * `DIVIDER_WIDTH)] = 1;
    assign div_mstream_o[`STREAM_MO_VALID(2 * `DIVIDER_WIDTH)] = div_valid;
    assign div_ready = div_mstream_i[`STREAM_MI_READY(2 * `DIVIDER_WIDTH)];

    reg [`LERPINATOR_IN] in_datai;
    reg [`LERPINATOR_IN] in_data;

    always @(posedge clk_i, negedge nrst_i) if (!nrst_i) in_data <= 0; else if (clk_i) in_data <= in_datai;

    wire signed [`WORD] l0, l1, l2;
    wire signed [`WORD] v0, v1, v2;

    assign { l0, l1, l2, v0, v1, v2 } = in_datai;

    reg [2:0] next_state;
    reg [2:0] state;

    always @(posedge clk_i, negedge nrst_i) begin
        if (!nrst_i) begin
            state <= 0;
        end
        else if (clk_i) begin
            state <= next_state;
        end
    end

    always @(*) begin
        next_state = state;

        mstream_o = 0;

        div_valid = 0;
        da = 0;
        db = 0;

        in_datai = in_data;
        
        `define DIV(a, b) begin da = a; db = b; div_valid = 1; end
        `define EXTEND(a) ({ a, { (2 * `DECIMAL_POS) { 1'b0 } } })

        sstream_o[`STREAM_SO_READY(`LERPINATOR_IN_WIDTH)] =
            state == 0 &&
            sstream_i[`STREAM_SI_VALID(`LERPINATOR_IN_WIDTH)] &&
            mstream_i[`STREAM_MI_READY(3 * `WORD_WIDTH)];

        case (state)
            0: begin
                in_datai = sstream_i[`STREAM_SI_DATA(`LERPINATOR_IN_WIDTH)];

                if (
                    sstream_i[`STREAM_SI_VALID(`LERPINATOR_IN_WIDTH)] &&
                    mstream_i[`STREAM_MI_READY(3 * `WORD_WIDTH)]
                ) begin
                    mstream_o[`STREAM_MO_VALID(3 * `WORD_WIDTH)] = 1;
                    mstream_o[`STREAM_MO_LAST(3 * `WORD_WIDTH)] = 0;
                    mstream_o[`STREAM_MO_DATA(3 * `WORD_WIDTH)] = { v0, v1, v2 };

                    next_state = state + 1;
                end
            end

            1: begin
                `DIV(`EXTEND(l0), v0z);

                if (div_ready) begin
                    next_state = state + 1;
                end
            end

            2: begin
                `DIV(`EXTEND(l1), v1z);

                if (div_ready) begin
                    next_state = state + 1;
                end
            end

            3: begin
                `DIV(`EXTEND(l2), v2z);

                if (div_ready) begin
                    next_state = 0;
                end
            end
        endcase

        `undef DIV
        `undef EXTEND
    end

endmodule
