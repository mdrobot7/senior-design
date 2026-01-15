module core_m(
    input  wire clk_i,
    input  wire nrst_i,
    input  wire[`WORD_WIDTH-1:0] inst_i,
    input  wire[`WORD_WIDTH-1:0] pc_i,
    input  wire[`WORD_WIDTH-1:0] global_r1_data_i,
    input  wire[`WORD_WIDTH-1:0] global_r2_data_i,

    output wire[`WORD_WIDTH-1:0] mem_addr,
    output wire is_load,
    output wire is_store,
    input wire[`WORD_WIDTH-1:0] mem_data,

    // input  wire [`BUS_MIPORT] mport_i,
    // output wire [`BUS_MOPORT] mport_o
);
    localparam NUM_STAGES = 5;
    localparam IF_STAGE =   0;
    localparam DEC_STAGE =  1;
    localparam EX_STAGE =   2;
    localparam MEM_STAGE =  3;
    localparam WB_STAGE =   4;

    reg stall;
    //input pipeline regs
    reg[NUM_STAGES*`WORD_WIDTH-1 : 0] piped_inst;
    reg[NUM_STAGES*`WORD_WIDTH-1 : 0] piped_pc;
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
    wire [`CTL_SIGS_WIDTH-1:0] dec_ctl_sigs;
    wire[`WORD_WIDTH-1:0] dec_inst;
    wire[`WORD_WIDTH-1:0] dec_global_r1_data;
    wire[`WORD_WIDTH-1:0] dec_global_r2_data;
    wire[`WORD_WIDTH-1:0] regfile_r1_data;
    wire[`WORD_WIDTH-1:0] regfile_r2_data;
    wire[`WORD_WIDTH-1:0] dec_r1_data;
    wire[`WORD_WIDTH-1:0] dec_r2_data;
    wire[`WORD_WIDTH-1:0] dec_imm;

    //execute wires
    wire[`WORD_WIDTH-1:0] ex_inst;
    wire[`WORD_WIDTH-1:0] ex_alu_a, ex_alu_b;
    wire[`CTL_SIGS_WIDTH-1:0] ex_ctl_sigs;
    wire[`WORD_WIDTH-1:0] ex_alu_result;
    wire ex_alu_carry;

    wire[`PREDICATE_BITS_WIDTH] ex_predicate_mask;
    wire[`PREDICATE_BITS_WIDTH] ex_predicate_data;
    wire[`PREDICATE_BITS_WIDTH] ex_predicate_status;
    wire predicate_equal;

    //mem wires
    wire[`CTL_SIGS_WIDTH-1:0] mem_ctl_sigs;
    wire[`WORD_WIDTH-1:0] mem_accum_result;

    //wb wires
    wire[`WORD_WIDTH-1:0] wb_inst;
    reg[`WORD_WIDTH-1:0]  wb_data;
    wire[`REG_DEST_WIDTH-1:0] wb_addr;

    //decode modules
    decoder_m decoder (
        .instruction_i(piped_inst[EX_STAGE*`WORD_WIDTH-1 : DEC_STAGE * `WORD_WIDTH]),
        .control_sigs_o(dec_ctl_sigs);
    );

    regfile_m #(`WORD_WIDTH, `CORE_REGFILE_HEIGHT) regfile(
        .clk_i(clk_i),
        .nrst_i(nrst_i),
        .wr_en_i(piped_ctl_sigs[MEM_STAGE*`CTL_SIGS_WIDTH+`REGFILE_WRITE_IDX]), //TODO change to use macro and use wb ctl sig bus
        .wr_data_i(wb_data),
        .wr_addr_i(wb_addr),
        .r1_addr_i(dec_inst[`R1_LOCAL_IDX]),
        .r2_addr_i(dec_inst[`R2_LOCAL_IDX]),

        .r1_data_o(regfile_r1_data),
        .r2_data_o(regfile_r2_data)
    );

    signext_m signext (
        .in_i(dec_inst[22:0]),
        .ext_i(dec_ctl_sigs[`SIGN_EXT_IDX]),
        .imm_size_i(dec_ctl_sigs[`IMM_SIZE_IDX]),

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
        .wr_en_i(ex_ctl_sigs[`PREDICATE_WRITE_IDX]),
        .wr_mask_i(ex_predicate_mask),
        .wr_data_i(ex_predicate_data),
        .instruction_predicate_i(),
        .is_predicable_i(ex_ctl_sigs[`IS_PREDICABLE_IDX]),

        .status_o(),
        .equal_o()
    );

    //mem/acc modules
    accumulator_m accumulator (
        .clk_i(clk_i),
        .nrst_i(nrst_i & (~mem_ctl_sigs[`ACCUM_CLR_IDX])),
        .en_i(mem_ctl_sigs[`IS_ACCUMULATE_IDX]),
        .a_i(piped_alu_result[WB_STAGE*`WORD_WIDTH-1:MEM_STAGE*`WORD_WIDTH]),

        .acc_o(mem_accum_result)
    );

    //decode assignments
    assign dec_inst = piped_inst[EX_STAGE*`WORD_WIDTH-1 : DEC_STAGE*`WORD_WIDTH];
    assign dec_global_r1_data = piped_r1_data[EX_STAGE*`WORD_WIDTH-1 : DEC_STAGE*`WORD_WIDTH];
    assign dec_global_r2_data = piped_r2_data[EX_STAGE*`WORD_WIDTH-1 : DEC_STAGE*`WORD_WIDTH];
    assign dec_r1_data = (dec_ctl_sigs[`R1_USE_GLOBAL_VAL_IDX] == 1) ? dec_global_r1_data : regfile_r1_data;
    assign dec_r2_data = (dec_ctl_sigs[`R2_USE_GLOBAL_VAL_IDX] == 1) ? dec_global_r2_data : regfile_r2_data;    
    
    //execute assignments
    assign ex_inst = piped_inst[`STAGE_SLICE(EX_STAGE, `WORD_WIDTH)];
    assign ex_alu_a = (ex_ctl_sigs[`USE_PC] == 1)       ? piped_pc[`STAGE_SLICE(EX_STAGE, `WORD_WIDTH)]  : piped_r1_data[`STAGE_SLICE(EX_STAGE, `WORD_WIDTH)];
    assign ex_alu_b = (ex_ctl_sigs[`USE_IMM_IDX] == 1)  ? piped_imm[`STAGE_SLICE(EX_STAGE, `WORD_WIDTH)] : piped_r2_data[`STAGE_SLICE(EX_STAGE, `WORD_WIDTH)];
    assign ex_ctl_sigs = piped_ctl_sigs[MEM_STAGE*`CTL_SIGS_WIDTH-1:EX_STAGE*`CTL_SIGS_WIDTH];

    /*
    TODO: add functionality for predicate
    repeat alu logic function output's lsb across the last 3 bits, use the mask as expected
    I think the mask is always in the same spot...
    */

    //mem assignments
    assign mem_ctl_sigs = piped_ctl_sigs[WB_STAGE*`CTL_SIGS_WIDTH-1:MEM_STAGE*`CTL_SIGS_WIDTH];
    
    //wb assignments
    assign wb_ctl_sigs = piped_ctl_sigs[NUM_STAGES*`CTL_SIGS_WIDTH-1:WB_STAGE*`CTL_SIGS_WIDTH];
    assign wb_inst = piped_inst[`STAGE_SLICE(WB_STAGE, `WORD_WIDTH)];
    assign wb_addr = wb_inst[`REG_DEST_IDX];

    always @ (*) begin
        //continuous assignments
        //instruction fetch
        piped_inst[`WORD_WIDTH-1:0] = instruction_i;
        piped_r1_data[`WORD_WIDTH-1:0] = global_r1_data_i;
        piped_r2_data[`WORD_WIDTH-1:0] = global_r2_data_i;

        //decode
        piped_ctl_sigs[`STAGE_SLICE(DEC_STAGE, `CTL_SIGS_WIDTH)] = dec_ctl_sigs;
        piped_imm[`STAGE_SLICE(DEC_STAGE, `WORD_WIDTH)] = dec_imm;

        //ex
        piped_alu_result[`STAGE_SLICE(EX_STAGE, `WORD_WIDTH)] = (ex_ctl_sigs[`USE_ALU_RESULT_IDX] == 1) : ex_alu_result ? ;

        //mem
        piped_accum_result[`STAGE_SLICE(MEM_STAGE, `WORD_WIDTH)] = mem_accum_result;
        piped_mem_result[`STAGE_SLICE(MEM_STAGE, `WORD_WIDTH)] = mem_data_i;

        //wb
        case(wb_ctl_sigs[`WB_SIG_IDX])
            WB_EX_RESULT:   wb_data = piped_alu_result
        endcase
    end

    always @ (posedge clk_i, negedge nrst_i) begin
        if(!nrst_i) begin : RESET
            piped_inst <= 0;
            piped_r1_data <= 0;
            piped_r2_data <= 0;
            piped_ctl_sigs <= 0;
            piped_imm <= 0;
            piped_alu_result <= 0;
            stall <= 0;
        end
        else if (~stall) begin : PIPELINE
            integer i;
            //fetch signal pipelines
            for(i = DEC_STAGE; i < NUM_STAGES; i = i + 1) begin
                piped_inst[`STAGE_SLICE(i, `WORD_WIDTH)] <= piped_inst[`STAGE_SLICE(i-1, `WORD_WIDTH)];
                piped_pc[`STAGE_SLICE(i, `WORD_WIDTH)] <= piped_pc[`STAGE_SLICE(i-1, `WORD_WIDTH)];
            end
            piped_r1_data[`STAGE_SLICE(`DEC_STAGE, `WORD_WIDTH)] <= piped_r1_data[`STAGE_SLICE(`IF_STAGE, `WORD_WIDTH)];
            piped_r1_data[`STAGE_SLICE(`EX_STAGE, `WORD_WIDTH)] <= dec_r1_data;

            piped_r2_data[`STAGE_SLICE(`DEC_STAGE, `WORD_WIDTH)] <= piped_r2_data[`STAGE_SLICE(`IF_STAGE, `WORD_WIDTH)];
            piped_r2_data[`STAGE_SLICE(`EX_STAGE, `WORD_WIDTH)] <= dec_r2_data;
            piped_r2_data[`STAGE_SLICE(`MEM_STAGE, `WORD_WIDTH)] <= piped_r2_data[`STAGE_SLICE(`EX_STAGE, `WORD_WIDTH)];

            //decode signal pipelines
            for(i = EX_STAGE; i < NUM_STAGES; i = i + 1) begin
                piped_ctl_sigs[`STAGE_SLICE(i, `CTL_SIGS_WIDTH)] <= piped_ctl_sigs[`STAGE_SLICE(i-1, `CTL_SIGS_WIDTH)];
            end
            piped_imm[`STAGE_SLICE(EX_STAGE, `WORD_WIDTH)] <= piped_imm[`STAGE_SLICE(DEC_STAGE, `WORD_WIDTH)];

            //ex signal pipelines
            for(i = MEM_STAGE; i < NUM_STAGES; i = i + 1) begin
                piped_alu_result[`STAGE_SLICE(i, `WORD_WIDTH)] <= piped_alu_result[`STAGE_SLICE(i-1, `WORD_WIDTH)];
            end
            //mem signal pipelines
            piped_mem_result[`STAGE_SLICE(WB_STAGE, `WORD_WIDTH)] <= piped_mem_result[`STAGE_SLICE(MEM_STAGE, `WORD_WIDTH)];
            piped_accum_result[`STAGE_SLICE(WB_STAGE, `WORD_WIDTH)] <= piped_accum_result[`STAGE_SLICE(MEM_STAGE, `WORD_WIDTH)];
            
        end
    end
endmodule