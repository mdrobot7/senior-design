module full_adder_m #(parameter WIDTH = 32) (
    input  wire signed [WIDTH-1 : 0] a_i,
    input  wire signed [WIDTH-1 : 0] b_i,
    input  wire                      carry_i,
    output wire signed [WIDTH-1 : 0] y_o,
    output wire signed               carry_o
);

    assign {carry_o, y_o} = a_i + b_i + carry_i;

endmodule