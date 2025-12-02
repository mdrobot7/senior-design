module div_m #(parameter WIDTH = 32) (
    input  wire signed [WIDTH - 1:0] a_i,
    input  wire signed [WIDTH - 1:0] b_i,
    output wire signed [WIDTH - 1:0] y_o
);

    wire signed [WIDTH * 2 - 1:0] a, b;
    wire signed [WIDTH * 2 - 1:0] y;

    wire signed [WIDTH * 2 - 1:0] temp;

    // assign a = {{WIDTH{a_i[WIDTH - 1]}}, a_i };
    // assign b = {{WIDTH{b_i[WIDTH - 1]}}, b_i };

    // assign temp = (64'd1 << (3 * `DECIMAL_POS)) / b;

    // assign y = a * temp;

    // assign y_o = y >>> (2 * `DECIMAL_POS);

    assign a = {{WIDTH{a_i[WIDTH - 1]}}, a_i };
    assign b = {{WIDTH{b_i[WIDTH - 1]}}, b_i };

    assign y = ((a << `DECIMAL_POS) / b);

    assign y_o = y;

endmodule