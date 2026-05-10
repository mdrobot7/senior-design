module inv_m #(parameter WIDTH = 32) (
    input  wire signed [WIDTH - 1:0] a_i,
    output wire signed [WIDTH - 1:0] y_o
);

    wire signed [WIDTH * 2 - 1:0] a, b;

    assign a = {{WIDTH{a_i[WIDTH - 1]}}, a_i };

    assign y_o = ((64'd1 << `DECIMAL_POS) << `DECIMAL_POS) / a;

endmodule