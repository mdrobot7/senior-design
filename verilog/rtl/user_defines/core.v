/*
 * Internal file, DO NOT INCLUDE! Only include user_defines.v!
 */

// ALU
`define ALU_CTL_SIZE 4

`define ALU_ADD_CTL     (`ALU_CTL_SIZE'b0000)
`define ALU_SUB_CTL     (`ALU_CTL_SIZE'b0001)
`define ALU_MULT_CTL    (`ALU_CTL_SIZE'b0010)
`define ALU_AND_CTL     (`ALU_CTL_SIZE'b0011)
`define ALU_OR_CTL      (`ALU_CTL_SIZE'b0100)
`define ALU_XOR_CTL     (`ALU_CTL_SIZE'b0101)
`define ALU_SEQ_CTL     (`ALU_CTL_SIZE'b0110)
`define ALU_SLT_CTL     (`ALU_CTL_SIZE'b0111)
`define ALU_SLL_CTL     (`ALU_CTL_SIZE'b1000)
`define ALU_SRL_CTL     (`ALU_CTL_SIZE'b1001)
`define ALU_SRA_CTL     (`ALU_CTL_SIZE'b1010)
`define ALU_SLTU_CTL    (`ALU_CTL_SIZE'b1011)
`define ALU_NOP_CTL     (`ALU_CTL_SIZE'b1100)

//SIGN EXT
`define IMM_CTL_SIZE 2
`define IMM_13_BIT 0
`define IMM_16_BIT 1
`define IMM_23_BIT 2
`define IMM_13_WIDTH 13
`define IMM_16_WIDTH 16
`define IMM_23_WIDTH 23
`define PAD_19_BITS 19
`define PAD_16_BITS 16
`define PAD_9_BITS 9
`define MSB_13_IMM 12
`define MSB_16_IMM 15
`define MSB_23_IMM 22

//ISA
`define OPCODE_WIDTH            6
`define OPCODE_IDX              31:26
`define PREDICATE_BITS_WIDTH	3
`define PREDICATE_IDX           25:23
`define REG_DEST_WIDTH          4
`define REG_DEST_IDX            22:19
`define REG_SOURCE_WIDTH        6
`define R1_IDX                  18:13
`define R2_IDX                  12:7
`define SHIFT_WIDTH             5
`define SHIFT_IDX               4:0
`define JUMP_WIDTH              23
`define JUMP_IDX                22:0

`define ADD_OPCODE      (`OPCODE_WIDTH'h00)
`define ADDI_OPCODE     (`OPCODE_WIDTH'h01)
`define SUB_OPCODE      (`OPCODE_WIDTH'h02)
`define MUL_OPCODE      (`OPCODE_WIDTH'h03)
`define MULI_OPCODE     (`OPCODE_WIDTH'h04)
`define AND_OPCODE      (`OPCODE_WIDTH'h05)
`define ANDI_OPCODE     (`OPCODE_WIDTH'h06)
`define OR_OPCODE       (`OPCODE_WIDTH'h07)
`define ORI_OPCODE      (`OPCODE_WIDTH'h08)
`define XOR_OPCODE      (`OPCODE_WIDTH'h09)
`define XORI_OPCODE     (`OPCODE_WIDTH'h0A)
`define SLL_OPCODE      (`OPCODE_WIDTH'h0B)
`define SRL_OPCODE      (`OPCODE_WIDTH'h0C)
`define SRA_OPCODE      (`OPCODE_WIDTH'h0D)
`define SLLV_OPCODE     (`OPCODE_WIDTH'h0E)
`define SRLV_OPCODE     (`OPCODE_WIDTH'h0F)
`define SRAV_OPCODE     (`OPCODE_WIDTH'h10)
`define LUI_OPCODE      (`OPCODE_WIDTH'h11)
`define LLI_OPCODE      (`OPCODE_WIDTH'h12)
`define OUT_OPCODE      (`OPCODE_WIDTH'h13)
`define MAC_OPCODE      (`OPCODE_WIDTH'h14)
`define MACCL_OPCODE    (`OPCODE_WIDTH'h15)
`define MACRD_OPCODE    (`OPCODE_WIDTH'h16)
`define SPEQ_OPCODE     (`OPCODE_WIDTH'h17)
`define SPLT_OPCODE     (`OPCODE_WIDTH'h18)
`define SPLTU_OPCODE    (`OPCODE_WIDTH'h19)
`define CLRP_OPCODE     (`OPCODE_WIDTH'h1A)
`define SPR_OPCODE      (`OPCODE_WIDTH'h1B)
`define SRP_OPCODE      (`OPCODE_WIDTH'h1C)
`define SREQ_OPCODE     (`OPCODE_WIDTH'h1D)
`define SRLT_OPCODE     (`OPCODE_WIDTH'h1E)
`define SRTLU_OPCODE    (`OPCODE_WIDTH'h1F)
`define LW_OPCODE       (`OPCODE_WIDTH'h20)
`define LB_OPCODE       (`OPCODE_WIDTH'h21)
`define SW_OPCODE       (`OPCODE_WIDTH'h22)
`define SB_OPCODE       (`OPCODE_WIDTH'h23)
`define JUMP_OPCODE     (`OPCODE_WIDTH'h24)
`define JAL_OPCODE      (`OPCODE_WIDTH'h25)
`define JRET_OPCODE     (`OPCODE_WIDTH'h26)
`define HALT_OPCODE     (`OPCODE_WIDTH'h27)

`define WB_SIG_WIDTH    2
`define WB_EX_RESULT   (`WB_SIG_WIDTH'h0)
`define WB_MEM_RESULT   (`WB_SIG_WIDTH'h1)
`define WB_MAC_RESULT   (`WB_SIG_WIDTH'h2)
//decoder
//decode ctl sigs
`define R1_USE_GLOBAL_VAL_IDX   (0)
`define R2_USE_GLOBAL_VAL_IDX   (`R1_USE_GLOBAL_VAL_IDX + 1)
`define IMM_SIZE_IDX            (`R2_USE_GLOBAL_VAL_IDX + `IMM_CTL_SIZE):(`R2_USE_GLOBAL_VAL_IDX + 1)
`define SIGN_EXT_IDX            (`R2_USE_GLOBAL_VAL_IDX + `IMM_CTL_SIZE + 1)
`define OUT_IDX                 (`SIGN_EXT_IDX + 1)
//ex ctl sigs
`define USE_IMM_IDX         (`OUT_IDX + 1)
`define USE_PC_IDX          (`USE_IMM_IDX + 1)
`define USE_ALU_RESULT_IDX  (`USE_PC_IDX + 1)
`define ALU_CTL_IDX         (`USE_IMM_IDX + `ALU_CTL_SIZE):(`USE_ALU_RESULT_IDX + 1)
`define IS_PREDICABLE_IDX   (`USE_IMM_IDX + `ALU_CTL_SIZE + 1)
`define PREDICATE_WRITE_IDX (`IS_PREDICABLE_IDX + 1)

`define PREDICATE_WRITE_BITS_IDX    (`PREDICATE_WRITE_IDX + `PREDICATE_BITS_WIDTH):(`PREDICATE_WRITE_IDX + 1)
//mem-acc ctl sigs
`define IS_LOAD_IDX         (`PREDICATE_WRITE_IDX + `PREDICATE_BITS_WIDTH + 1)
`define IS_STORE_IDX        (`IS_LOAD_IDX + 1)
`define ACCUM_CLR_IDX       (`IS_STORE_IDX + 1)
`define IS_ACCUMULATE_IDX   (`ACCUM_CLR_IDX + 1)
//wb ctl sigs
`define REGFILE_WRITE_IDX	(`IS_ACCUMULATE_IDX + 1)
`define WB_SIG_IDX          (`REGFILE_WRITE_IDX + `WB_SIG_WIDTH):(`REGFILE_WRITE_IDX + 1)

`define CTL_SIGS_WIDTH      (`REGFILE_WRITE_IDX + `WB_SIG_WIDTH+ 1)

`define CORE_MAILBOX_HEIGHT (8)
