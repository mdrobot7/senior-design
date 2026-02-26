/*
    Decoder for custom uGPU ISA in the shader cores
    instruction_i   : the entire uGPU ISA instruction
    control_sigs_o  : packet of control sigs from instruction
*/

module decoder_m (
    input  wire[`WORD_WIDTH-1:0] instruction_i,
    output wire[`CTL_SIGS_WIDTH-1:0] control_sigs_o
);
    reg[`CTL_SIGS_WIDTH-1:0] ctl_sigs_reg;
    assign control_sigs_o = ctl_sigs_reg;

    wire[`OPCODE_WIDTH-1:0] opcode = instruction_i[`OPCODE_IDX];

    wire[`REG_SOURCE_WIDTH-1:0] r1_addr = instruction_i[`R1_IDX];
    wire[`REG_SOURCE_WIDTH-1:0] r2_addr = instruction_i[`R2_IDX];

    always @(*) begin
        //use global if either of top 2 bits are set
        ctl_sigs_reg[`R1_USE_GLOBAL_VAL_IDX] = r1_addr[`REG_SOURCE_WIDTH-1] | r1_addr[`REG_SOURCE_WIDTH-2];
        ctl_sigs_reg[`R2_USE_GLOBAL_VAL_IDX] = r2_addr[`REG_SOURCE_WIDTH-1] | r2_addr[`REG_SOURCE_WIDTH-2];

        //IMM_SIZE
        case(opcode)
            `ADDI_OPCODE, `MULI_OPCODE, `ANDI_OPCODE, `ORI_OPCODE, `XORI_OPCODE, `LW_OPCODE,
            `LB_OPCODE, `SW_OPCODE, `SB_OPCODE:
                ctl_sigs_reg[`IMM_SIZE_IDX] = `IMM_13_BIT;
            `LUI_OPCODE, `LLI_OPCODE:
                ctl_sigs_reg[`IMM_SIZE_IDX] = `IMM_16_BIT;
            default:
                ctl_sigs_reg[`IMM_SIZE_IDX] = `IMM_23_BIT;
        endcase

        //SIGN_EXT
        case(opcode)
            `ANDI_OPCODE, `ORI_OPCODE, `XORI_OPCODE, `SLL_OPCODE, `SRL_OPCODE, `SRA_OPCODE:
                ctl_sigs_reg[`SIGN_EXT_IDX] = 0; //0 extend
            default:
                ctl_sigs_reg[`SIGN_EXT_IDX] = 1; //sign extend
        endcase

        //OUT
        ctl_sigs_reg[`OUT_IDX] = (opcode == `OUT_OPCODE) ? 1 : 0;

        //ALU_SRC_A
        case(opcode)
            `JUMP_OPCODE, `JAL_OPCODE:
                ctl_sigs_reg[`ALU_SRC_A_IDX] = `PC_SRC_A;
            `LLI_OPCODE:
                ctl_sigs_reg[`ALU_SRC_A_IDX] = `LLI_SRC_A;
            `LUI_OPCODE:
                ctl_sigs_reg[`ALU_SRC_A_IDX] = `LUI_SRC_A;
            default:
                ctl_sigs_reg[`ALU_SRC_A_IDX] = `REG_SRC_A;
        endcase

        //ALU_SRC_B
        case(opcode)
            `ADDI_OPCODE, `MULI_OPCODE, `ANDI_OPCODE, `ORI_OPCODE, `XORI_OPCODE, `SLL_OPCODE,
            `SRL_OPCODE, `SRA_OPCODE, `LW_OPCODE, `LB_OPCODE, `SW_OPCODE,
            `SB_OPCODE, `JUMP_OPCODE, `JAL_OPCODE:
                ctl_sigs_reg[`ALU_SRC_B_IDX] = `IMM_SRC_B; //use imm
            `LLI_OPCODE:
                ctl_sigs_reg[`ALU_SRC_B_IDX] = `LLI_SRC_B;
            `LUI_OPCODE:
                ctl_sigs_reg[`ALU_SRC_B_IDX] = `LUI_SRC_B;
            default:
                ctl_sigs_reg[`ALU_SRC_B_IDX] = `REG_SRC_B; //dont use imm
        endcase

        //USE_ALU
        ctl_sigs_reg[`USE_ALU_RESULT_IDX] = (opcode == `SPR_OPCODE) ? 0 : 1;

        //ALU_CTL
        case(opcode)
            `ADD_OPCODE, `ADDI_OPCODE, `LW_OPCODE, `LB_OPCODE, `SW_OPCODE, `SB_OPCODE, `JUMP_OPCODE, `JAL_OPCODE:
                ctl_sigs_reg[`ALU_CTL_IDX] = `ALU_ADD_CTL;
            `SUB_OPCODE:
                ctl_sigs_reg[`ALU_CTL_IDX] = `ALU_SUB_CTL;
            `MUL_OPCODE, `MULI_OPCODE, `MAC_OPCODE:
                ctl_sigs_reg[`ALU_CTL_IDX] = `ALU_MULT_CTL;
            `AND_OPCODE, `ANDI_OPCODE:
                ctl_sigs_reg[`ALU_CTL_IDX] = `ALU_AND_CTL;
            `OR_OPCODE, `ORI_OPCODE, `LUI_OPCODE, `LLI_OPCODE:
                ctl_sigs_reg[`ALU_CTL_IDX] = `ALU_OR_CTL;
            `XOR_OPCODE, `XORI_OPCODE:
                ctl_sigs_reg[`ALU_CTL_IDX] = `ALU_XOR_CTL;
            `SPEQ_OPCODE, `SREQ_OPCODE:
                ctl_sigs_reg[`ALU_CTL_IDX] = `ALU_SEQ_CTL;
            `SPLT_OPCODE, `SRLT_OPCODE:
                ctl_sigs_reg[`ALU_CTL_IDX] = `ALU_SLT_CTL;
            `SLL_OPCODE, `SLLV_OPCODE:
                ctl_sigs_reg[`ALU_CTL_IDX] = `ALU_SLL_CTL;
            `SRL_OPCODE, `SRLV_OPCODE:
                ctl_sigs_reg[`ALU_CTL_IDX] = `ALU_SRL_CTL;
            `SRA_OPCODE, `SRAV_OPCODE:
                ctl_sigs_reg[`ALU_CTL_IDX] = `ALU_SRA_CTL;
            `SPLTU_OPCODE, `SRTLU_OPCODE:
                ctl_sigs_reg[`ALU_CTL_IDX] = `ALU_SLTU_CTL;
            `OUT_OPCODE, `MACCL_OPCODE, `MACRD_OPCODE, `CLRP_OPCODE, `SPR_OPCODE, `SRP_OPCODE, `JRET_OPCODE, `HALT_OPCODE:
                ctl_sigs_reg[`ALU_CTL_IDX] = `ALU_NOP_CTL;


        endcase

        //IS_PREDICABLE
        case(opcode)
            `CLRP_OPCODE, `SPR_OPCODE, `JRET_OPCODE, `HALT_OPCODE:
                ctl_sigs_reg[`IS_PREDICABLE_IDX] = 0; //instruction must happen
            default:
                ctl_sigs_reg[`IS_PREDICABLE_IDX] = 1; //instruction is predicable
        endcase

        //PREDICATE_WRITE
        case(opcode)
            `SPEQ_OPCODE, `SPLT_OPCODE, `SPLTU_OPCODE, `CLRP_OPCODE, `SRP_OPCODE:
                ctl_sigs_reg[`PREDICATE_WRITE_IDX] = 1; //can update predicate status
            default:
                ctl_sigs_reg[`PREDICATE_WRITE_IDX] = 0; //cannot update predicate status
        endcase

        //PREDICATE_ALU_OP
        case(opcode)
            `SPEQ_OPCODE, `SPLT_OPCODE, `SPLTU_OPCODE:
                ctl_sigs_reg[`PREDICATE_ALU_OP_IDX] = 1; //ALU providing predicate data
            default:
                ctl_sigs_reg[`PREDICATE_ALU_OP_IDX] = 0; // data is written thru alu with ALU_NOP_CTL
        endcase

        //IS_CLRP
        ctl_sigs_reg[`IS_CLRP_IDX] = (opcode == `CLRP_OPCODE) ? 1 : 0;

        //IS_SRP
        ctl_sigs_reg[`IS_SRP_IDX] = (opcode == `SRP_OPCODE) ? 1 : 0;

        //IS_LOAD
		case(opcode)
			`LB_OPCODE, `LW_OPCODE:
				ctl_sigs_reg[`IS_LOAD_IDX] = 1;
			default:
				ctl_sigs_reg[`IS_LOAD_IDX] = 0;
		endcase

		//IS_STORE
		case(opcode)
			`SW_OPCODE, `SB_OPCODE:
				ctl_sigs_reg[`IS_STORE_IDX] = 1;
			default:
				ctl_sigs_reg[`IS_STORE_IDX] = 0;
		endcase

        //BYTE_MEM
        case(opcode)
            `SB_OPCODE, `LB_OPCODE:
                ctl_sigs_reg[`BYTE_MEM_OP_IDX] = 1;
            default:
                ctl_sigs_reg[`BYTE_MEM_OP_IDX] = 0;
        endcase

		//ACCUM_CLR
		ctl_sigs_reg[`ACCUM_CLR_IDX] = (opcode == `MACCL_OPCODE) ? 1 : 0;

		//IS_ACCUMULATE
		ctl_sigs_reg[`IS_ACCUMULATE_IDX] = (opcode == `MAC_OPCODE) ? 1 : 0;

        //WB_IS_IN
        ctl_sigs_reg[`WB_IS_IN_IDX] = (opcode == `IN_OPCODE) ? 1 : 0;

        //WB_SIG
        case(opcode)
            `MACRD_OPCODE:
                ctl_sigs_reg[`WB_SIG_IDX] = `WB_MAC_RESULT;
            `LW_OPCODE, `LB_OPCODE:
                ctl_sigs_reg[`WB_SIG_IDX] = `WB_MEM_RESULT;
            default:
                ctl_sigs_reg[`WB_SIG_IDX] = `WB_EX_RESULT;
        endcase

        //REGFILE_WRITE
		case(opcode)
			`OUT_OPCODE, `MAC_OPCODE, `MACCL_OPCODE, `SPEQ_OPCODE, `SPLT_OPCODE, `SPLTU_OPCODE,
			`CLRP_OPCODE, `SRP_OPCODE, `SB_OPCODE, `SW_OPCODE, `JUMP_OPCODE, `JAL_OPCODE, `JRET_OPCODE,
            `HALT_OPCODE, `IN_OPCODE:
				ctl_sigs_reg[`REGFILE_WRITE_IDX] = 0; //no regfile change
			default:
				ctl_sigs_reg[`REGFILE_WRITE_IDX] = 1;
		endcase
    end
endmodule
