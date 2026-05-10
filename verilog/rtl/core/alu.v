/*
    ALU module for the uGPU core
    a_i         : first operand
    b_i         : second operand
    alu_ctl_i   : operation
    result_o    : result of operation
*/

module alu_m (
    input  wire signed[`WORD_WIDTH-1:0]   a_i,
    input  wire signed[`WORD_WIDTH-1:0]   b_i,
    input  wire[`ALU_CTL_SIZE-1:0]        alu_ctl_i,

    output wire signed[`WORD_WIDTH-1:0]  result_o,
    output wire                          adder_carry_out
);

    wire[`WORD_WIDTH-1:0] sum;
    wire[`WORD_WIDTH-1:0] product;
    wire[`WORD_WIDTH-1:0] slt;
    wire[`WORD_WIDTH-1:0] sltu;
    wire[`WORD_WIDTH-1:0] seq;

    wire[`WORD_WIDTH-1:0] adder_b_port;
    wire nadd_sub;

    assign nadd_sub = ((alu_ctl_i == `ALU_SUB_CTL) | (alu_ctl_i == `ALU_SEQ_CTL) | (alu_ctl_i == `ALU_SLT_CTL) | (alu_ctl_i == `ALU_SLTU_CTL));
    assign adder_b_port = (nadd_sub) ? ~b_i : b_i;
    full_adder_m #(`WORD_WIDTH) full_adder (
        .a_i(a_i),
        .b_i(adder_b_port),
        .carry_i(nadd_sub),
        .y_o(sum),
        .carry_o(adder_carry_out)
    );

    assign slt = {31'h0, sum[`WORD_WIDTH-1]};
    assign sltu = {31'h0, !adder_carry_out};
    assign seq = (sum == 0);

    mul_m #(`WORD_WIDTH) multiplier (
        .a_i(a_i),
        .b_i(b_i),
        .y_o(product)
    );

    reg[`WORD_WIDTH-1:0] result;
    assign result_o = result;
    always @(*) begin
        case(alu_ctl_i)
            `ALU_ADD_CTL:       result <= sum;
            `ALU_SUB_CTL:       result <= sum;
            `ALU_MULT_CTL:      result <= product;
            `ALU_AND_CTL:       result <= (a_i & b_i);
            `ALU_OR_CTL:        result <= (a_i | b_i);
            `ALU_XOR_CTL:       result <= (a_i ^ b_i);
            `ALU_SEQ_CTL:       result <= seq;
            `ALU_SLT_CTL:       result <= slt;
            `ALU_SLTU_CTL:      result <= sltu;
            `ALU_SLL_CTL:       result <= (a_i << b_i);
            `ALU_SRL_CTL:       result <= (a_i >> b_i);
            `ALU_SRA_CTL:       result <= (a_i >>> b_i);
            `ALU_NOP_CTL:       result <= a_i;
            default:            result <= a_i;
        endcase
    end
endmodule