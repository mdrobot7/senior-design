// adapted from https://github.com/risclite/verilog-divider/blob/master/divfunc.v

`ifdef SIM
// enable this when you want any performance
// `define SIM_DIV
`endif

module div_pipe_m #(
    parameter WIDTH = 32,
    parameter [WIDTH - 1:0] STAGE_LOCS = 0,

    parameter IN_SIZE = 2 * WIDTH,
    parameter OUT_SIZE = WIDTH
) (
    input wire clk_i,
    input wire nrst_i,

    input  wire [`STREAM_SIPORT(IN_SIZE)] sstream_i,
    output reg  [`STREAM_SOPORT(IN_SIZE)] sstream_o,

`ifdef SIM_DIV
    input  wire [`STREAM_MIPORT(OUT_SIZE)] mstream_i,
    output wire [`STREAM_MOPORT(OUT_SIZE)] mstream_o
`else
    input  wire [`STREAM_MIPORT(OUT_SIZE)] mstream_i,
    output reg  [`STREAM_MOPORT(OUT_SIZE)] mstream_o
`endif
);

`ifdef SIM_DIV

    wire [`STREAM_MIPORT(OUT_SIZE)] temp_streami;
    reg  [`STREAM_MOPORT(OUT_SIZE)] temp_streamo;

    wire [WIDTH * 2 - 1:0] in_data;
    assign in_data = sstream_i[`STREAM_SI_DATA(IN_SIZE)];
    
    wire signed [WIDTH - 1:0] y;

    assign y = in_data[1 * WIDTH+:WIDTH] / in_data[0 * WIDTH+:WIDTH];

    // div_m #(2 * WIDTH) div (
    //     .a_i(in_data[1 * WIDTH+:WIDTH]),
    //     .b_i(in_data[0 * WIDTH+:WIDTH]),
    //     .y_o(y)
    // );

    always @(*) begin
        sstream_o[`STREAM_SO_READY(IN_SIZE)]  <= temp_streami[`STREAM_MI_READY(OUT_SIZE)];
        temp_streamo[`STREAM_MO_LAST(OUT_SIZE)]  <= sstream_i[`STREAM_SI_LAST(IN_SIZE)];
        temp_streamo[`STREAM_MO_VALID(OUT_SIZE)] <= sstream_i[`STREAM_SI_VALID(IN_SIZE)];
        temp_streamo[`STREAM_MO_DATA(OUT_SIZE)]  <= y;
    end

    stream_fifo_m #(OUT_SIZE, 4) fifo(
        .clk_i(clk_i),
        .nrst_i(nrst_i),

        .sstream_i(temp_streamo),
        .sstream_o(temp_streami),
        
        .mstream_i(mstream_i),
        .mstream_o(mstream_o)
    );

`else

    wire [WIDTH * 2 - 1:0] in_data;
    assign in_data = sstream_i[`STREAM_SI_DATA(IN_SIZE)];

    wire signed [WIDTH - 1:0] a, b;
    assign a = in_data[1 * WIDTH+:WIDTH];
    assign b = in_data[0 * WIDTH+:WIDTH];

    reg               negate   [WIDTH:0];
    reg               present  [WIDTH:0];
    reg               ready    [WIDTH:0];
    reg [WIDTH - 1:0] dividend [WIDTH:0];
    reg [WIDTH - 1:0] divisor  [WIDTH:0];
    reg [WIDTH - 1:0] quotient [WIDTH:0];

    always @(*) begin
        negate[0]       <= (a < 0) ^ (b < 0);
        present[0]      <= sstream_i[`STREAM_SI_VALID(IN_SIZE)];
        ready[WIDTH]    <= mstream_i[`STREAM_MI_READY(OUT_SIZE)];
       
        if (a < 0) dividend[0]     <= -a;
        else       dividend[0]     <= a;

        if (b < 0) divisor[0]      <= -b;
        else       divisor[0]      <= b;
        
        quotient[0]     <= 0;
    end

    always @(*) begin
        sstream_o[`STREAM_SO_READY(IN_SIZE)] <= ready[0];

        mstream_o[`STREAM_MO_VALID(OUT_SIZE)] <= present[WIDTH];

        if (negate[WIDTH]) begin
            mstream_o[`STREAM_MO_DATA(OUT_SIZE)]  <= -quotient[WIDTH];
        end
        else begin
            mstream_o[`STREAM_MO_DATA(OUT_SIZE)]  <= quotient[WIDTH];
        end

        mstream_o[`STREAM_MO_LAST(OUT_SIZE)]  <= 0;
    end

    generate
        genvar i;

        for (i = 0; i < WIDTH; i = i + 1) begin
            wire [i:0]         m;
            wire [i:0]         n;
            wire               q;
            wire [i:0]         t;
            wire [WIDTH - 1:0] u;
            wire [WIDTH - 1:0] d;

            assign m = dividend[i] >> (WIDTH - i - 1);
            assign n = divisor[i];
            assign q = (|(divisor[i] >> (i + 1))) ? 1'b0 : (m >= n);
            assign t = q ? (m - n) : m;
            assign u = dividend[i] << (i + 1);
            assign d = { t, u } >> (i + 1);

            if (STAGE_LOCS[WIDTH - i - 1]) begin
                always @(posedge clk_i, negedge nrst_i) begin
                    if (!nrst_i) begin
                        present[i + 1]  <= 0;
                        dividend[i + 1] <= 0;
                        divisor[i + 1]  <= 0;
                        quotient[i + 1] <= 0;
                    end
                    else if (clk_i) begin
                        if (ready[i + 1]) begin
                            negate[i + 1]   <= negate[i];
                            present[i + 1]  <= present[i];
                            dividend[i + 1] <= d;
                            divisor[i + 1]  <= divisor[i];
                            quotient[i + 1] <= quotient[i] | (q << (WIDTH - i - 1));
                        end
                    end
                end
            end
            else begin
                always @(*) begin
                    negate[i + 1]   <= negate[i];
                    present[i + 1]  <= present[i];
                    dividend[i + 1] <= d;
                    divisor[i + 1]  <= divisor[i];
                    quotient[i + 1] <= quotient[i] | (q << (WIDTH - i - 1));
                end
            end

            always @(*) begin
                ready[i] <= !present[i] || ready[i + 1];
            end
        end
    endgenerate

`endif

endmodule