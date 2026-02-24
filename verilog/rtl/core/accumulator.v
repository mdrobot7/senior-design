/*
    Accumulator module for the uGPU core
    a_i         : input data to accumulate
    acc_o       : result of accumulator
*/

module accumulator_m (
    input  wire                         clk_i,
    input  wire                         nrst_i,
    input  wire                         en_i,
    input  wire                         clr_i,
    input  wire signed[`WORD_WIDTH-1:0] a_i,

    output reg  signed[`WORD_WIDTH-1:0] acc_o
);

    wire signed [`WORD_WIDTH-1:0] sum;
    add_m #(.WIDTH(`WORD_WIDTH)) adder (.a_i(acc_o), .b_i(a_i), .y_o(sum));
    
    always @(posedge clk_i, negedge nrst_i) begin
        if (!nrst_i) begin : RESET
            acc_o <= 0;
        end else if (clr_i) begin : CLEAR
            acc_o <= 0;
        end else if (en_i) begin : ACCUMULATE
            acc_o <= sum;
        end
    end

endmodule
