module mul_m #(
    parameter WIDTH = 32,
    parameter OUT_WIDTH = WIDTH
) (
    input  wire signed [WIDTH - 1:0] a_i,
    input  wire signed [WIDTH - 1:0] b_i,
    output wire signed [OUT_WIDTH - 1:0] y_o
);

    wire signed [WIDTH * 2 - 1:0] a, b;
    wire signed [OUT_WIDTH * 2 - 1:0] y;

    assign a = {{WIDTH{a_i[WIDTH - 1]}}, a_i };
    assign b = {{WIDTH{b_i[WIDTH - 1]}}, b_i };

    assign y = a * b;

    assign y_o = y >>> `DECIMAL_POS;

endmodule
