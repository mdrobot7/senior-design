/*
    sign extension module for the uGPU core

    in_i         : input value
    ext_i        : whether input is zero/sign extended
    imm_size_i   : size of input immediate
    imm_ext_o    : extended output
*/

module signext_m (
    input  wire [`WORD_WIDTH-10:0]        in_i,
    input  wire                           ext_i,
    input  wire[`IMM_CTL_SIZE-1:0]        imm_size_i,

    output wire [`WORD_WIDTH-1:0]         imm_ext_o

);


    wire[`WORD_WIDTH-1:0] sign_ext;
    reg                   temp_sign;
    reg[`WORD_WIDTH-1:0]  masked_sign;
    reg[`WORD_WIDTH-1:0]  extended;

    assign imm_ext_o = extended;
    always @(*) begin

        case(imm_size_i)
            `IMM_5_BIT: begin
                temp_sign = ext_i & in_i[`MSB_5_IMM];
                extended <= {{`PAD_27_BITS{temp_sign}}, in_i[`IMM_5_WIDTH-1:0]};
            end
            `IMM_13_BIT: begin
                temp_sign = ext_i & in_i[`MSB_13_IMM];
                extended <= {{`PAD_19_BITS{temp_sign}}, in_i[`IMM_13_WIDTH-1:0]};
            end
            `IMM_16_BIT: begin
                temp_sign = ext_i & in_i[`MSB_16_IMM];
                extended <= {{`PAD_16_BITS{temp_sign}}, in_i[`IMM_16_WIDTH-1:0]};
            end
            `IMM_23_BIT: begin
                temp_sign = ext_i & in_i[`MSB_23_IMM];
                extended <= {{`PAD_9_BITS{temp_sign}}, in_i[`IMM_23_WIDTH-1:0]};
            end

            default: begin
                temp_sign = ext_i & in_i[`MSB_13_IMM];
                extended <= {{`PAD_19_BITS{temp_sign}}, in_i[`IMM_13_WIDTH-1:0]};
            end

        endcase
    end
endmodule
