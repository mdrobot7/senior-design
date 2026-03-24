module addsub_m #(
    parameter WIDTH = `WORD_WIDTH
) (
    input wire sub_i,

    input  wire signed [WIDTH - 1:0] a_i,
    input  wire signed [WIDTH - 1:0] b_i,
    output wire signed [WIDTH - 1:0] y_o
);

    wire signed [WIDTH - 1:0] b;

    assign b = sub_i ? -b_i : b_i;

    add_m #(WIDTH) adder(
        .a_i(a_i),
        .b_i(b),

        .y_o(y_o)
    );

endmodule