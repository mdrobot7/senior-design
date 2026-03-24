/**
*   Core for uGPU on our custom ISA
*   clk_i       : clock
*   nrst_i      : async reset
*   inst_i      : instruction into the decode stage
*   global_r1_data_i : global regfile data
*   global_r2_data_i : global regfile data
*   jump_request_o : high when core wants to jump
*   flush_dec_stage_i : high when decode stage should be flushed
*   stall_i     : stall input, core stalls when high
*   stall_o     : stall output, signals when core is stalling
*   nsync_rst_i : synchrounous reset (everything but mailboxes), active low
*   nsync_rst_mailbox_i : synchronous mailbox reset, active low
*   inbox_sstream_i     : inbox slave stream input interface
*   inbox_sstream_o     : inbox slave stream output interface
*   outbox_mstream_i    : outbox master stream input interface
*   outbox_mstream_o    : outbox master stream output interface
*   mport_i     : pk bus master port in
*   mport_o     : pk bus master port out
*/

module core_m #(
    parameter SP = 32'h00000000
) (
    input  wire clk_i,
    input  wire nrst_i,
    input  wire[`WORD_WIDTH-1:0] inst_i,
    input  wire[`WORD_WIDTH-1:0] global_r1_data_i,
    input  wire[`WORD_WIDTH-1:0] global_r2_data_i,

    output wire jump_request_o,
    input  wire flush_dec_stage_i,
    input  wire stall_i,
    output reg stall_o,
    input  wire nsync_rst_i,
    input  wire nsync_rst_mailbox_i,

    input  wire [`STREAM_SIPORT(`MAILBOX_STREAM_SIZE)] inbox_sstream_i,
    output wire [`STREAM_SOPORT(`MAILBOX_STREAM_SIZE)] inbox_sstream_o,

    input  wire [`STREAM_MIPORT(`MAILBOX_STREAM_SIZE)] outbox_mstream_i,
    output wire [`STREAM_MOPORT(`MAILBOX_STREAM_SIZE)] outbox_mstream_o,

    input  wire [`BUS_MIPORT] mport_i,
    output reg  [`BUS_MOPORT] mport_o
);
    localparam NUM_STAGES = 5;
    localparam IF_STAGE =   0;
    localparam DEC_STAGE =  1;
    localparam EX_STAGE =   2;
    localparam MEM_STAGE =  3;
    localparam WB_STAGE =   4;

    localparam MAILBOX_PREP_STATE = 0;
    localparam MAILBOX_WAIT_STATE = 1;
    localparam MAILBOX_TRANSACTION_STATE = 2;
    localparam MAILBOX_WRITE_STATE = 3;
    wire inbox_read;
    wire outbox_write;

    wire stall;
    //input pipeline regs
    reg[NUM_STAGES*`WORD_WIDTH-1 : 0] piped_inst;
    reg[NUM_STAGES*`WORD_WIDTH-1 : 0] piped_r1_data;
    reg[NUM_STAGES*`WORD_WIDTH-1 : 0] piped_r2_data;

    //decode pipeline regs
    reg[NUM_STAGES*`CTL_SIGS_WIDTH-1 : 0] piped_ctl_sigs;
    reg[NUM_STAGES*`WORD_WIDTH-1 : 0] piped_imm;

    //execute pipeline regs
    reg[NUM_STAGES*`WORD_WIDTH-1 : 0] piped_alu_result;

    //mem pipeline regs
    reg[NUM_STAGES*`WORD_WIDTH-1 : 0] piped_accum_result;
    reg[NUM_STAGES*`WORD_WIDTH-1 : 0] piped_mem_result;

    //decode wires
    wire[`CTL_SIGS_WIDTH-1:0] decoder_output;
    wire[`CTL_SIGS_WIDTH-1:0] dec_ctl_sigs;
    wire[`WORD_WIDTH-1:0] dec_inst;
    wire[`REG_DEST_WIDTH-1:0] dec_r2_addr;
    wire[`WORD_WIDTH-1:0] dec_global_r1_data;
    wire[`WORD_WIDTH-1:0] dec_global_r2_data;
    wire[`WORD_WIDTH-1:0] regfile_r1_data;
    wire[`WORD_WIDTH-1:0] regfile_r2_data;
    wire[`WORD_WIDTH-1:0] dec_r1_data;
    wire[`WORD_WIDTH-1:0] dec_r2_data;
    wire[`WORD_WIDTH-1:0] dec_imm;

    wire [`WORD_WIDTH-1:0] outbox [`CORE_MAILBOX_HEIGHT-1:0];
    wire [`WORD_WIDTH-1:0] inbox [`CORE_MAILBOX_HEIGHT-1:0];

    //execute wires
    wire[`WORD_WIDTH-1:0] ex_inst;
    wire[`WORD_WIDTH-1:0] ex_r1_data;
    wire[`WORD_WIDTH-1:0] ex_r2_data;
    wire[`WORD_WIDTH-1:0] ex_imm;
    reg[`WORD_WIDTH-1:0]  ex_alu_a;
    reg[`WORD_WIDTH-1:0]  ex_alu_b;
    wire[`CTL_SIGS_WIDTH-1:0] ex_ctl_sigs;
    reg[`CTL_SIGS_WIDTH-1:0] ex_predicated_ctl_sigs;
    wire[`WORD_WIDTH-1:0] ex_alu_result;
    wire ex_alu_carry;

    wire ex_predicate_wr;
    wire[`PREDICATE_BITS_WIDTH-1:0] ex_predicate_mask;
    wire[`PREDICATE_BITS_WIDTH-1:0] ex_predicate_data;
    wire[`PREDICATE_BITS_WIDTH-1:0] ex_predicate_status;
    wire ex_predicate_equal;

    //mem wires
    wire[`CTL_SIGS_WIDTH-1:0] mem_ctl_sigs;
    wire [`WORD_WIDTH-1:0] mem_inst;
    wire[`WORD_WIDTH-1:0] mem_alu_result;
    wire[`WORD_WIDTH-1:0] mem_accum_result;
    wire[`WORD] mem_read_data;
    wire mo_req;

    //wb wires
    wire[`WORD_WIDTH-1:0] wb_inst;
    wire[`WORD_WIDTH-1:0] wb_ctl_sigs;
    reg[`WORD_WIDTH-1:0]  wb_data;
    wire[`REG_DEST_WIDTH-1:0] wb_addr;
    wire[`WORD_WIDTH*`CORE_MAILBOX_HEIGHT-1:0] wb_inbox;
    wire[`WORD_WIDTH*`CORE_MAILBOX_HEIGHT-1:0] wb_outbox;

    //forwarding wires
    wire fwd_a;
    wire fwd_b;
    wire[`WORD_WIDTH-1:0] fwd_a_data;
    wire[`WORD_WIDTH-1:0] fwd_b_data;
    reg[`REG_SOURCE_WIDTH-1:0] fwd_r1_addr;
    reg[`REG_SOURCE_WIDTH-1:0] fwd_r2_addr;

    //stall
    wire mem_stall;
    wire outbox_stall;
    wire inbox_stall;
    wire halt_stall;

    //decode modules
    decoder_m decoder (
        .instruction_i(dec_inst),
        .control_sigs_o(decoder_output)
    );

    core_regfile_m #(
        .SP(SP)
    ) regfile (
        .clk_i(clk_i),
        .nrst_i(nrst_i),
        .nsync_rst_i(nsync_rst_i),
        .wr_en_i(wb_ctl_sigs[`REGFILE_WRITE_IDX]),
        .wr_data_i(wb_data),
        .wr_addr_i(wb_addr),
        .r1_addr_i(dec_inst[`R1_LOCAL_IDX]),
        .r2_addr_i(dec_r2_addr),

        .r1_data_o(regfile_r1_data),
        .r2_data_o(regfile_r2_data),

        .inbox_write_i(inbox_read),
        .inbox_i(wb_inbox),
        .outbox_o(wb_outbox)
    );

    signext_m signext (
        .in_i(dec_inst[22:0]),
        .ext_i(decoder_output[`SIGN_EXT_IDX]),
        .imm_size_i(decoder_output[`IMM_SIZE_IDX]),

        .imm_ext_o(dec_imm)
    );

    //execute modules
    alu_m alu (
        .a_i(ex_alu_a),
        .b_i(ex_alu_b),
        .alu_ctl_i(ex_ctl_sigs[`ALU_CTL_IDX]),
        .result_o(ex_alu_result),
        .adder_carry_out(ex_alu_carry)
    );

    predicate_m predicate (
        .clk_i(clk_i),
        .nrst_i(nrst_i),
        .wr_en_i(ex_predicate_wr),
        .wr_mask_i(ex_predicate_mask),
        .wr_data_i(ex_predicate_data),
        .instruction_predicate_i(ex_inst[`PREDICATE_IDX]),
        .is_predicable_i(ex_ctl_sigs[`IS_PREDICABLE_IDX]),

        .status_o(ex_predicate_status),
        .equal_o(ex_predicate_equal)
    );

    //mem/acc modules
    accumulator_m accumulator (
        .clk_i(clk_i),
        .nrst_i(nrst_i),
        .clr_i(mem_ctl_sigs[`ACCUM_CLR_IDX]),
        .en_i(mem_ctl_sigs[`IS_ACCUMULATE_IDX]),
        .a_i(mem_alu_result),

        .acc_o(mem_accum_result)
    );

    mem_bus_m pkmem (
        .clk_i(clk_i),
        .nrst_i(nrst_i),
        .nsync_rst_i(nsync_rst_i),
        .stall_i(stall),
        .stall_o(mem_stall),
        .data_o(mem_read_data),
        .mport_i(mport_i),
        .mo_req_o(mo_req),
        .prep_state_condition((ex_ctl_sigs[`IS_LOAD_IDX] | ex_ctl_sigs[`IS_STORE_IDX]) & (~stall)),
        .repeated_acccess_condition(ex_ctl_sigs[`IS_LOAD_IDX] | ex_ctl_sigs[`IS_STORE_IDX])
    );

    inbox_m inbox_module (
        .clk_i(clk_i),
        .nrst_i(nrst_i),
        .nsync_rst_i(nsync_rst_mailbox_i),
        .inbox_read_req_i(inbox_read),
        .inbox_sstream_i(inbox_sstream_i),
        .inbox_sstream_o(inbox_sstream_o),
        .stall_o(inbox_stall),
        .inbox_o(wb_inbox)
    );

    outbox_m outbox_module (
        .clk_i(clk_i),
        .nrst_i(nrst_i),
        .nsync_rst_i(nsync_rst_mailbox_i),
        .outbox_write_req_i(outbox_write),
        .outbox_mstream_i(outbox_mstream_i),
        .outbox_mstream_o(outbox_mstream_o),
        .stall_o(outbox_stall),
        .outbox_i(wb_outbox)
    );

    //forwarding module
    forward_m forward(
        .ex_r1_addr(fwd_r1_addr),
        .ex_r2_addr(fwd_r2_addr),

        .wb_dest_addr({2'b0, wb_inst[`REG_DEST_IDX]}),
        .wb_data(wb_data),
        .wb_reg_wr(wb_ctl_sigs[`REGFILE_WRITE_IDX]),

        .mem_dest_addr({2'b0, mem_inst[`REG_DEST_IDX]}),
        .mem_data(piped_alu_result[`STAGE_SLICE(MEM_STAGE, `WORD_WIDTH)]),
        .mem_reg_wr(mem_ctl_sigs[`REGFILE_WRITE_IDX]),
        .mem_wb_sig(mem_ctl_sigs[`WB_SIG_IDX]),

        .fwd_a_en_o(fwd_a),
        .fwd_a_data_o(fwd_a_data),
        .fwd_b_en_o(fwd_b),
        .fwd_b_data_o(fwd_b_data)
    );

    //decode assignments
    assign dec_ctl_sigs = (flush_dec_stage_i) ? 0 : decoder_output;
    assign dec_inst = piped_inst[`STAGE_SLICE(DEC_STAGE, `WORD_WIDTH)];
    assign dec_global_r1_data = piped_r1_data[`STAGE_SLICE(DEC_STAGE, `WORD_WIDTH)];
    assign dec_global_r2_data = piped_r2_data[`STAGE_SLICE(DEC_STAGE, `WORD_WIDTH)];
    assign dec_r2_addr = (dec_ctl_sigs[`IS_STORE_IDX]) ? dec_inst[`REG_DEST_IDX] : dec_inst[`R2_LOCAL_IDX];
    assign dec_r1_data = (dec_ctl_sigs[`R1_USE_GLOBAL_VAL_IDX] == 1) ? dec_global_r1_data : regfile_r1_data;
    assign dec_r2_data = (dec_ctl_sigs[`R2_USE_GLOBAL_VAL_IDX] == 1) ? dec_global_r2_data : regfile_r2_data;

    //execute assignments
    assign ex_inst = piped_inst[`STAGE_SLICE(EX_STAGE, `WORD_WIDTH)];
    assign ex_r1_data = (fwd_a)? fwd_a_data : piped_r1_data[`STAGE_SLICE(EX_STAGE, `WORD_WIDTH)];
    assign ex_r2_data = (fwd_b)? fwd_b_data : piped_r2_data[`STAGE_SLICE(EX_STAGE, `WORD_WIDTH)];
    assign ex_imm = piped_imm[`STAGE_SLICE(EX_STAGE, `WORD_WIDTH)];
    assign ex_ctl_sigs = piped_ctl_sigs[`STAGE_SLICE(EX_STAGE, `CTL_SIGS_WIDTH)];

    assign ex_predicate_wr   = (ex_ctl_sigs[`PREDICATE_WRITE_IDX] & ex_predicate_equal);
    assign ex_predicate_mask = (ex_ctl_sigs[`IS_SRP_IDX] == 1) ? `PREDICATE_BITS_WIDTH'b111 :  ex_inst[`PREDICATE_DATA_IDX];

    assign ex_predicate_data =  (ex_ctl_sigs[`PREDICATE_ALU_OP_IDX] == 1)   ? {`PREDICATE_BITS_WIDTH{ex_alu_result[0]}} : //copy lsb 3 times for the write
                                (ex_ctl_sigs[`IS_CLRP_IDX] == 1)            ? (~ex_inst[`PREDICATE_DATA_IDX]) : // invert the mask to set the 0s
                                                                            ex_alu_result[`PREDICATE_BITS_WIDTH-1:0]; //just read from the ALU

    //jump outputs
    assign jump_request_o = (((ex_inst[`OPCODE_IDX] == `JUMP_OPCODE) | (ex_inst[`OPCODE_IDX] == `JAL_OPCODE)) & ex_predicate_equal);

    //mem assignments
    assign mem_ctl_sigs = piped_ctl_sigs[`STAGE_SLICE(MEM_STAGE, `CTL_SIGS_WIDTH)];
    assign mem_inst = piped_inst[`STAGE_SLICE(MEM_STAGE, `WORD_WIDTH)];
    assign mem_alu_result = piped_alu_result[`STAGE_SLICE(MEM_STAGE, `WORD_WIDTH)];

    //wb assignments
    assign wb_ctl_sigs = piped_ctl_sigs[`STAGE_SLICE(WB_STAGE, `CTL_SIGS_WIDTH)];
    assign wb_inst = piped_inst[`STAGE_SLICE(WB_STAGE, `WORD_WIDTH)];
    assign wb_addr = wb_inst[`REG_DEST_IDX];
    assign inbox_read = wb_ctl_sigs[`WB_IS_IN_IDX];
    assign outbox_write = wb_ctl_sigs[`OUT_IDX];
    assign halt_stall = (wb_ctl_sigs[`OPCODE_IDX] == `HALT_OPCODE);

    //fwd assignments
    assign stall = stall_o | stall_i;

    always @ (*) begin : BLOCK1
        //continuous assignments
        integer i;

        //ex
        case(ex_ctl_sigs[`ALU_SRC_A_IDX])
            `PC_SRC_A:  ex_alu_a = ex_r1_data;
            `LUI_SRC_A: ex_alu_a = {16'h0, ex_r1_data[15:0]};
            `LLI_SRC_A: ex_alu_a = {ex_r1_data[`WORD_WIDTH-1:16], 16'h0};
            default:    ex_alu_a = ex_r1_data;
        endcase

        case(ex_ctl_sigs[`ALU_SRC_B_IDX])
            `IMM_SRC_B: ex_alu_b = piped_imm[`STAGE_SLICE(EX_STAGE, `WORD_WIDTH)];
            `LUI_SRC_B: ex_alu_b = {ex_imm[15:0], 16'h0};
            `LLI_SRC_B: ex_alu_b = {16'h0, ex_imm[15:0]};
            default:    ex_alu_b = ex_r2_data;
        endcase

        //fill predicated values (I hope this synthesized nicely)
        for(i = 0; i < `CTL_SIGS_WIDTH; i = i + 1) begin
            case(i)
                `IS_LOAD_IDX, `IS_STORE_IDX, `REGFILE_WRITE_IDX :
                    ex_predicated_ctl_sigs[i] = (ex_ctl_sigs[i] & ex_predicate_equal);
                default:
                    ex_predicated_ctl_sigs[i] = ex_ctl_sigs[i];
            endcase
        end
        //mem
        mport_o[`BUS_MO_ADDR] <= piped_alu_result[`STAGE_SLICE(MEM_STAGE, `WORD_WIDTH)];
        mport_o[`BUS_MO_DATA] <= piped_r2_data[`STAGE_SLICE(MEM_STAGE, `WORD_WIDTH)];
        mport_o[`BUS_MO_SEQMST] <= 0;
        mport_o[`BUS_MO_SIZE] <= (mem_ctl_sigs[`BYTE_MEM_OP_IDX] == 1) ? `BUS_SIZE_BYTE : `BUS_SIZE_WORD;
        mport_o[`BUS_MO_RW] <= (mem_ctl_sigs[`IS_STORE_IDX] == 1) ? `BUS_WRITE : `BUS_READ;
        mport_o[`BUS_MO_REQ] <= mo_req;

        case(wb_ctl_sigs[`WB_SIG_IDX])
            `WB_EX_RESULT:  wb_data = piped_alu_result[`STAGE_SLICE(WB_STAGE, `WORD_WIDTH)];
            `WB_MEM_RESULT: wb_data = piped_mem_result[`STAGE_SLICE(WB_STAGE, `WORD_WIDTH)];
            default:        wb_data = piped_accum_result[`STAGE_SLICE(WB_STAGE, `WORD_WIDTH)];
        endcase

        //fwd
        case(ex_ctl_sigs[`ALU_SRC_A_IDX])
            `LLI_SRC_A, `LUI_SRC_A:
                fwd_r1_addr = {2'b0, ex_inst[`REG_DEST_IDX]};
            default:
                fwd_r1_addr = ex_inst[`R1_IDX];
        endcase

        if(ex_ctl_sigs[`IS_STORE_IDX] | ex_ctl_sigs[`IS_LOAD_IDX])
            fwd_r2_addr = {2'b0, ex_inst[`REG_DEST_IDX]};
        else
            fwd_r2_addr = ex_inst[`R2_IDX];

        stall_o = mem_stall | (inbox_read && inbox_stall) | (outbox_write && outbox_stall) | halt_stall;
    end

    always @ (posedge clk_i, negedge nrst_i) begin : BLOCK2
        integer i;
        if(!nrst_i) begin : RESET
            piped_inst <= 0;
            piped_r1_data <= 0;
            piped_r2_data <= 0;
            piped_ctl_sigs <= 0;
            piped_imm <= 0;
            piped_alu_result <= 0;
            piped_accum_result <= 0;
            piped_mem_result <= 0;
        end
        else if (clk_i) begin : CLOCKED
            if(!nsync_rst_i) begin : SYNC_RESET
                piped_inst <= 0;
                piped_r1_data <= 0;
                piped_r2_data <= 0;
                piped_ctl_sigs <= 0;
                piped_imm <= 0;
                piped_alu_result <= 0;
                piped_accum_result <= 0;
                piped_mem_result <= 0;

            end else
            begin
                if (~stall) begin : PIPELINE
                    //fetch signal pipelines

                    piped_inst[`STAGE_SLICE(DEC_STAGE, `WORD_WIDTH)] <= inst_i;
                    piped_inst[`STAGE_SLICE(EX_STAGE, `WORD_WIDTH)] <= piped_inst[`STAGE_SLICE(DEC_STAGE, `WORD_WIDTH)];
                    piped_inst[`STAGE_SLICE(MEM_STAGE, `WORD_WIDTH)] <= piped_inst[`STAGE_SLICE(EX_STAGE, `WORD_WIDTH)];
                    piped_inst[`STAGE_SLICE(WB_STAGE, `WORD_WIDTH)] <= piped_inst[`STAGE_SLICE(MEM_STAGE, `WORD_WIDTH)];

                    piped_r1_data[`STAGE_SLICE(DEC_STAGE, `WORD_WIDTH)] <= global_r1_data_i;
                    piped_r1_data[`STAGE_SLICE(EX_STAGE, `WORD_WIDTH)] <= dec_r1_data;

                    piped_r2_data[`STAGE_SLICE(DEC_STAGE, `WORD_WIDTH)] <= global_r2_data_i;
                    piped_r2_data[`STAGE_SLICE(EX_STAGE, `WORD_WIDTH)] <= dec_r2_data;
                    piped_r2_data[`STAGE_SLICE(MEM_STAGE, `WORD_WIDTH)] <= ex_r2_data;

                    //decode signal pipelines

                    piped_ctl_sigs[`STAGE_SLICE(EX_STAGE, `CTL_SIGS_WIDTH)] <= dec_ctl_sigs;
                    piped_ctl_sigs[`STAGE_SLICE(MEM_STAGE, `CTL_SIGS_WIDTH)] <= ex_predicated_ctl_sigs;
                    piped_ctl_sigs[`STAGE_SLICE(WB_STAGE, `CTL_SIGS_WIDTH)] <= piped_ctl_sigs[`STAGE_SLICE(MEM_STAGE, `CTL_SIGS_WIDTH)];

                    piped_imm[`STAGE_SLICE(EX_STAGE, `WORD_WIDTH)] <= dec_imm;

                    //ex signal pipelines
                    if(ex_ctl_sigs[`USE_ALU_RESULT_IDX] == 1) begin
                        piped_alu_result[`STAGE_SLICE(MEM_STAGE, `WORD_WIDTH)] <= ex_alu_result;
                    end else begin
                        piped_alu_result[`STAGE_SLICE(MEM_STAGE, `WORD_WIDTH)] <= ex_predicate_status;
                    end
                    piped_alu_result[`STAGE_SLICE(WB_STAGE, `WORD_WIDTH)] <= piped_alu_result[`STAGE_SLICE(MEM_STAGE, `WORD_WIDTH)];

                    //mem signal pipelines
                    piped_mem_result[`STAGE_SLICE(WB_STAGE, `WORD_WIDTH)] <= mem_read_data;
                    piped_accum_result[`STAGE_SLICE(WB_STAGE, `WORD_WIDTH)] <= mem_accum_result;
                end
            end
        end
    end

    wire [`WORD] r0, r1, r2, r9;

    assign r0 = regfile.mem[0];
    assign r1 = regfile.mem[1];
    assign r2 = regfile.mem[2];
    assign r9 = regfile.mem[9];

endmodule
