module add_m #(parameter WIDTH = 32) (
    input  wire signed [WIDTH - 1:0] a_i,
    input  wire signed [WIDTH - 1:0] b_i,
    output wire signed [WIDTH - 1:0] y_o
);

    assign y_o = a_i + b_i;

endmodule