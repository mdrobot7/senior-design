// adapted from https://ieeexplore.ieee.org/document/563604

module sqrt_m #(
    parameter WIDTH = 32,
    parameter ROOT_WIDTH = WIDTH / 2
) (
    input wire clk_i,
    input wire nrst_i,

    input  wire [`STREAM_SIPORT(WIDTH)] sstream_i,
    output reg  [`STREAM_SOPORT(WIDTH)] sstream_o,

    input  wire [`STREAM_MIPORT(ROOT_WIDTH)] mstream_i,
    output reg  [`STREAM_MOPORT(ROOT_WIDTH)] mstream_o
);

    localparam REQUIRED_STATES = ROOT_WIDTH + 4;

    reg [$clog2(REQUIRED_STATES) - 1:0] state;

    reg [WIDTH - 1:0] D;
    reg [ROOT_WIDTH - 1:0] Q;
    reg signed [ROOT_WIDTH:0] R;
    reg [$clog2(ROOT_WIDTH + 1) - 1:0] i;

    always @(posedge clk_i, negedge nrst_i) begin
        if (!nrst_i) begin
            state <= 0;
        end
        else if (clk_i) begin
            if (state == 0) begin
                if (sstream_i[`STREAM_SI_VALID(WIDTH)]) begin
                    state <= state + 1;

                    D <= sstream_i[`STREAM_SI_DATA(WIDTH)];
                    Q <= 0;
                    R <= 0;
                    i <= ROOT_WIDTH - 1;
                end
            end
            else if (state >= 1 && state <= ROOT_WIDTH) begin
                state <= state + 1;

                if (R >= 0) begin
                    R = (R << 2) | ((D >> (i + i)) & 2'b11);
                    R = R - ((Q << 2) | 1'b1);
                end
                else begin
                    R = (R << 2) | ((D >> (i + i)) & 2'b11);
                    R = R + ((Q << 2) | 2'b11);
                end

                if (R >= 0) begin
                    Q = (Q << 1) | 1'b1;
                end
                else begin
                    Q = (Q << 1) | 1'b0;
                end

                i = i - 1;
            end
            else if (state == 17) begin
                state <= state + 1;

                if (R < 0) R = R + ((Q << 1) | 1'b1);
            end
            else if (state == 18) begin
                if (mstream_i[`STREAM_MI_READY(ROOT_WIDTH)]) begin
                    state <= 0;
                end
            end
        end
    end

    always @(*) begin
        sstream_o[`STREAM_SO_READY(WIDTH)]     = state == 0;

        mstream_o[`STREAM_MO_DATA(ROOT_WIDTH)]  = Q;
        mstream_o[`STREAM_MO_VALID(ROOT_WIDTH)] = state == 18;
        mstream_o[`STREAM_MO_LAST(ROOT_WIDTH)]  = 1'b0;
    end

endmodule
