/*
* Core controller module (aka meta-core, mc, master chief, minecraft, emcee...)
* Handles the PC, instruction fetch, global regfile, job dispatch,
* vertex/fragment shading switchover, index prefetching, and interfacing
* between the management core and the shader cores.
*/
module core_controller_m #(
    parameter INDEX_FETCH_CACHE_LEN_WORDS = 0,
    parameter CALL_STACK_LEN = 8
) (
`ifdef USE_POWER_PINS
    inout wire vccd1,
    inout wire vssd1,
`endif

    input wire clk_i,
    input wire nrst_i,

    // IMEM
    input  wire                       imem_rw_i, // 1 = read, 0 = write
    output wire [`WORD]               imem_do_o,
    input  wire [`WORD]               imem_di_i,
    input  wire [`SRAM_1024x32_ADDR_WIDTH-1:0] imem_addr_i,

    // Global regfile
    input  wire [`REG_SOURCE_WIDTH-1:0] global_regfile_addr_i,
    input  wire                         global_regfile_write_en_i,
    input  wire [`WORD]                 global_regfile_write_data_i,
    output wire [`WORD]                 global_regfile_read_data_o,

    // PCs
    input wire [`SRAM_1024x32_ADDR_WIDTH-1:0] pc_vertex_shading_i,
    input wire [`SRAM_1024x32_ADDR_WIDTH-1:0] pc_fragment_shading_i,
    input wire [`SRAM_1024x32_ADDR_WIDTH-1:0] pc_gpgpu_compute_i,

    // PKBus
    input  wire [`BUS_MIPORT] mport_i,
    output wire [`BUS_MOPORT] mport_o,

    // Shaded vertex cache
    output wire [`WORD] vertcache_test_index_o,
    output wire         vertcache_test_valid_o,
    input  wire         vertcache_test_found_i,
    output wire         vertcache_clear_o,

    // Vertex order buffer
    input  wire [`STREAM_MIPORT(`VERTEX_ORDER_WIDTH)] vertorder_mstream_i,
    output wire [`STREAM_MOPORT(`VERTEX_ORDER_WIDTH)] vertorder_mstream_o,
    input  wire                                       vertorder_full_i,
    input  wire                                       vertorder_empty_i,
    output wire                                       vertorder_clear_o,

    // Vertex reorder controller
    input wire vertcont_busy_i,

    // index buffer
    input  wire [`STREAM_MIPORT(`WORD_WIDTH)] index_mstream_i,
    output wire [`STREAM_MOPORT(`WORD_WIDTH)] index_mstream_o,

    // Rasterizer fragment output FIFO
    input  wire fragfifo_full_i,
    input  wire fragfifo_empty_i,
    output wire fragfifo_clear_o,

    // Rasterizer
    input wire rast_busy_i,

    // Config/control
    input  wire [`NUM_CORES-1:0] core_enable_i,
    input  wire [1:0]            cmd_i,
    input  wire                  cmd_written_i,
    input  wire                  pause_at_halt_i,     // 0: continue to next state after halt. 1: pause at halt instruction
    input  wire [`WORD]          index_buffer_addr_i,
    input  wire [1:0]            dispatch_ctrl_i,
    input  wire [`WORD]          num_dispatches_i,    // Number of jobs (indices or ints) to dispatch
    input  wire                  job_done_clr_i,      // 1: clear job done flag
    output  reg                  job_done_o,          // 1: finished a shader program (i.e. reached a halt)
    input  wire                  batch_done_clr_i,    // 1: clear batch done flag
    output  reg                  batch_done_o,        // 1: finished num_dispatches_i jobs.
    output wire [3:0]            state_o,

    // Shader core interface
    output reg  [`WORD]           inst_o,
    output reg  [`NUM_CORES-1:0]  core_reset_o,         // Core soft reset
    output reg  [`NUM_CORES-1:0]  core_reset_mailbox_o, // Core mailbox soft reset
    input  wire [`NUM_CORES-1:0]  core_stall_i,
    output reg  [`NUM_CORES-1:0]  core_stall_o,         // Per-core stall control
    input  wire [`NUM_CORES-1:0]  core_jump_i,
    output reg                    core_jump_o,          // Flushes decode on all cores
    output reg  [`WORD]           global_regfile_rs1_data_o,
    output reg  [`WORD]           global_regfile_rs2_data_o,

    input  wire [`STREAM_MIPORT_SIZE(`MAILBOX_STREAM_SIZE) * `NUM_CORES - 1:0] core_inbox_mstream_i,
    input  wire [`NUM_CORES-1:0] core_outbox_mstream_valid_i,

    // Performance counters, reset when each draw call starts
    output reg [`WORD] perf_num_vshades_o,
    output reg [`WORD] perf_num_fshades_o,
    output reg [`WORD] perf_vshade_cycles_o,
    output reg [`WORD] perf_fshade_cycles_o
);

    localparam INST_NOP        = 32'h04000000;

    localparam STATE_STOPPED               = 0; // Waiting for program to start from beginning
    localparam STATE_DISPATCHING           = 1; // Dispatching jobs
    localparam STATE_DISPATCH_DELAY        = 2; // Delay while inst fetch starts up
    localparam STATE_VERTEX_SHADING        = 3;
    localparam STATE_FRAGMENT_SHADING      = 4;
    localparam STATE_FRAGMENT_SHADING_LAST = 5; // Last pass of frag shading for the model, will stall cores without fragments
    localparam STATE_GPGPU_COMPUTE         = 6;
    localparam STATE_PAUSED                = 7; // Manual pause by management core or step-through
    localparam STATE_DONE                  = 8; // Decide where to go next
    localparam STATE_STOPPING_DELAY        = 9; // Wait a few cycles to make sure everything is really really done
    localparam STATE_STOPPING              = 10; // Force-stop

    reg [3:0] state;

    // Cur/next programs (vertex shade, fragment shade, gpgpu compute)
    reg [3:0] cur_prog;
    reg [3:0] next_prog;

    reg step_handled;

    // Dispatch
    wire         dispatch_index_fetch_enable     = (state != STATE_STOPPED);
    wire         dispatch_index_fetch_clear      = (state == STATE_STOPPING);
    wire         dispatch_index_fetch_clear_done;
    wire         dispatch_reset                  = (state == STATE_STOPPED);
    wire         dispatch_enable                 = (state == STATE_DISPATCHING);
    wire         dispatch_indices                = (dispatch_ctrl_i == `CORE_CTRL_DISPATCH_INDEX);
    wire [`WORD] dispatch_thread_id;
    wire [`WORD] dispatch_inst;
    wire [`NUM_CORES-1:0] dispatch_core_stall;
    wire         dispatch_done;
    wire         dispatch_model_done;
    dispatch_m #(
        INDEX_FETCH_CACHE_LEN_WORDS
    ) dispatch (
        .clk_i(clk_i),
        .nrst_i(nrst_i),

        .mport_i(mport_i),
        .mport_o(mport_o),

        .vertcache_test_index_o(vertcache_test_index_o),
        .vertcache_test_valid_o(vertcache_test_valid_o),
        .vertcache_test_found_i(vertcache_test_found_i),

        .vertorder_mstream_i(vertorder_mstream_i),
        .vertorder_mstream_o(vertorder_mstream_o),
        .vertorder_full_i(vertorder_full_i),

        .index_mstream_i(index_mstream_i),
        .index_mstream_o(index_mstream_o),

        .index_buffer_addr_i(index_buffer_addr_i),
        .index_fetch_enable_i(dispatch_index_fetch_enable),
        .index_fetch_clear_i(dispatch_index_fetch_clear),
        .index_fetch_clear_done_o(dispatch_index_fetch_clear_done),

        .reset_dispatch_i(dispatch_reset),
        .enable_i(dispatch_enable),
        .dispatch_indices_i(dispatch_indices),
        .num_dispatches_i(num_dispatches_i),
        .core_enable_i(core_enable_i),

        .thread_id_o(dispatch_thread_id),
        .inst_o(dispatch_inst),
        .core_stall_o(dispatch_core_stall),

        .dispatch_done_o(dispatch_done),
        .model_done_o(dispatch_model_done)
    );

    reg [`SRAM_1024x32_ADDR_WIDTH-1:0] instfetch_prog_entry;
    reg                                instfetch_enable;
    reg                                instfetch_enable_comb;
    wire                               instfetch_reset_prog = (state == STATE_STOPPED || state == STATE_DONE);
    wire                               instfetch_step_done;
    wire                               instfetch_prog_done;
    wire [`WORD]                       instfetch_inst;
    wire [`WORD]                       instfetch_global_regfile_rs1_data;
    wire [`WORD]                       instfetch_global_regfile_rs2_data;
    inst_fetch_m #(
        CALL_STACK_LEN
    ) inst_fetch (
`ifdef USE_POWER_PINS
    	.vccd1(vccd1),
    	.vssd1(vssd1),
`endif

        .clk_i(clk_i),
        .nrst_i(nrst_i),

        .imem_rw_i(imem_rw_i),
        .imem_do_o(imem_do_o),
        .imem_di_i(imem_di_i),
        .imem_addr_i(imem_addr_i),

        .global_regfile_addr_i(global_regfile_addr_i),
        .global_regfile_write_en_i(global_regfile_write_en_i),
        .global_regfile_write_data_i(global_regfile_write_data_i),
        .global_regfile_read_data_o(global_regfile_read_data_o),

        .prog_entry_i(instfetch_prog_entry),

        .enable_i(instfetch_enable_comb),
        .reset_prog_i(instfetch_reset_prog),
        .step_done_o(instfetch_step_done),
        .prog_done_o(instfetch_prog_done),

        .inst_o(instfetch_inst),
        .core_stall_i(core_stall_i),
        .core_jump_i(core_jump_i),
        .global_regfile_rs1_data_o(instfetch_global_regfile_rs1_data),
        .global_regfile_rs2_data_o(instfetch_global_regfile_rs2_data)
    );

    assign vertcache_clear_o = (state == STATE_STOPPED);
    assign vertorder_clear_o = (state == STATE_STOPPING);
    assign fragfifo_clear_o  = (state == STATE_STOPPING);
    assign state_o  = state;

    wire is_rasterization = (dispatch_ctrl_i == `CORE_CTRL_DISPATCH_INDEX);
    wire should_dispatch  = (dispatch_ctrl_i != `CORE_CTRL_DISPATCH_DISABLE && next_prog != STATE_FRAGMENT_SHADING && next_prog != STATE_FRAGMENT_SHADING_LAST);
    reg  dispatched;

    reg [`NUM_CORES-1:0] cores_mailed_mask;
    reg cores_not_mailed;
    reg cores_all_mailed;
    reg [`NUM_CORES-1:0] cores_mailed_mask_latch;

    reg [7:0] stopping_delay;

    wire vertshade_deadlock = (fragfifo_full_i);
    wire fragshade_deadlock = (vertorder_empty_i && !vertcont_busy_i && !rast_busy_i && fragfifo_empty_i && !cores_all_mailed);

    always @(posedge clk_i, negedge nrst_i) begin
        if (!nrst_i) begin : RESET
            job_done_o <= 0;
            batch_done_o <= 0;
            perf_num_vshades_o <= 0;
            perf_num_fshades_o <= 0;
            perf_vshade_cycles_o <= 0;
            perf_fshade_cycles_o <= 0;

            instfetch_enable <= 0;

            cur_prog      <= STATE_STOPPED;
            state         <= STATE_STOPPED;
            step_handled  <= 0;
            dispatched    <= 0;
            cores_mailed_mask_latch <= 0;
            stopping_delay <= 0;
        end
        else if (clk_i) begin
            if (job_done_clr_i)
                job_done_o <= 0;
            if (batch_done_clr_i)
                batch_done_o <= 0;
            if (cmd_written_i)
                step_handled <= 0;

            case (state)
                STATE_STOPPED: begin
                    stopping_delay <= 0;

                    if ((cmd_i == `CORE_CTRL_CMD_RUN || cmd_i == `CORE_CTRL_CMD_STEP) && cmd_written_i) begin
                        perf_num_vshades_o <= 0;
                        perf_num_fshades_o <= 0;
                        perf_vshade_cycles_o <= 0;
                        perf_fshade_cycles_o <= 0;

                        if (is_rasterization) begin
                            perf_num_vshades_o <= 1;
                            cur_prog <= STATE_VERTEX_SHADING;
                        end
                        else
                            cur_prog <= STATE_GPGPU_COMPUTE;

                        if (dispatch_ctrl_i != `CORE_CTRL_DISPATCH_DISABLE) begin
                            dispatched <= 1;
                            state <= STATE_DISPATCHING;
                        end
                        else begin
                            dispatched <= 0;
                            state <= STATE_DISPATCH_DELAY;
                        end
                    end
                end
                STATE_DISPATCH_DELAY: begin
                    instfetch_enable <= 1;
                    state <= cur_prog;
                end
                STATE_DISPATCHING: begin
                    if (cmd_i == `CORE_CTRL_CMD_STOP) begin
                        state <= STATE_STOPPING;
                    end
                    else if (dispatch_done) begin
                        instfetch_enable <= 1;
                        state <= cur_prog;
                    end
                end
                STATE_VERTEX_SHADING, STATE_FRAGMENT_SHADING, STATE_FRAGMENT_SHADING_LAST, STATE_GPGPU_COMPUTE: begin
                    case (state)
                        STATE_VERTEX_SHADING:                                perf_vshade_cycles_o <= perf_vshade_cycles_o + 1;
                        STATE_FRAGMENT_SHADING, STATE_FRAGMENT_SHADING_LAST: perf_fshade_cycles_o <= perf_fshade_cycles_o + 1;
                    endcase

                    instfetch_enable <= 0;
                    case (cmd_i)
                        `CORE_CTRL_CMD_STOP:
                            state <= STATE_STOPPING;
                        `CORE_CTRL_CMD_PAUSE:
                            state <= STATE_PAUSED;
                        `CORE_CTRL_CMD_RUN: begin
                            if (instfetch_prog_done ||
                                (state == STATE_FRAGMENT_SHADING && fragshade_deadlock))
                                state <= STATE_DONE;
                            else
                                instfetch_enable <= 1;
                        end
                        `CORE_CTRL_CMD_STEP: begin
                            if (instfetch_step_done)
                                state <= STATE_PAUSED;
                            else
                                instfetch_enable <= 1;
                        end
                    endcase
                end
                STATE_PAUSED: begin
                    if (instfetch_prog_done)
                        state <= STATE_DONE;
                    else begin
                        case (cmd_i)
                        `CORE_CTRL_CMD_RUN:
                            state <= cur_prog;
                        `CORE_CTRL_CMD_STEP: begin
                            if (!step_handled) begin
                                step_handled <= 1;
                                state <= cur_prog;
                            end
                        end
                        `CORE_CTRL_CMD_STOP:
                            state <= STATE_STOPPING;
                        endcase
                    end
                end
                STATE_DONE: begin
                    job_done_o <= 1;

                    cores_mailed_mask_latch <= cores_mailed_mask;

                    cur_prog <= next_prog;
                    if (pause_at_halt_i || next_prog == STATE_STOPPING)
                        state <= STATE_STOPPING_DELAY;
                    else if (should_dispatch) begin
                        dispatched <= 1;
                        state <= STATE_DISPATCHING;
                    end
                    else begin
                        instfetch_enable <= 1;
                        dispatched <= 0;
                        state <= next_prog;
                    end

                    case (next_prog)
                        STATE_VERTEX_SHADING:                                perf_num_vshades_o <= perf_num_vshades_o + 1;
                        STATE_FRAGMENT_SHADING, STATE_FRAGMENT_SHADING_LAST: perf_num_fshades_o <= perf_num_fshades_o + 1;
                    endcase

                    if (cmd_i == `CORE_CTRL_CMD_STOP)
                        state <= STATE_STOPPING;
                end
                STATE_STOPPING_DELAY: begin
                    // Wait 50 clocks and see if anything else comes through the
                    // pipeline. If so, next_prog will point to an active program.
                    // If not, next_prog will be STATE_STOPPING.
                    stopping_delay <= stopping_delay + 1;
                    if (stopping_delay == 50)
                        state <= next_prog;
                    end
                STATE_STOPPING: begin
                    if (dispatch_model_done)
                        batch_done_o <= 1;

                    if (!rast_busy_i && dispatch_index_fetch_clear_done && vertorder_empty_i && !vertcont_busy_i && fragfifo_empty_i)
                        state <= STATE_STOPPED;
                end
            endcase
        end
    end

    always @(*) begin : COMB
        integer i;

        // Instruction muxing
        if (state == STATE_STOPPED || state == STATE_DONE)
            inst_o = INST_NOP;
        else if (state == STATE_DISPATCHING)
            inst_o = dispatch_inst;
        else
            inst_o = instfetch_inst;

        // Core control signals
        if (state == STATE_STOPPED || state == STATE_DONE)
            core_reset_o = 0;
        else if (state == STATE_DISPATCHING)
            core_reset_o = core_enable_i;
        else if (state == STATE_FRAGMENT_SHADING_LAST)
            core_reset_o = core_enable_i & cores_mailed_mask_latch;
        else if (!dispatched)
            // If the dispatcher isn't used, ignore it
            core_reset_o = core_enable_i;
        else
            // Hold disabled and undispatched cores in reset during execution
            core_reset_o = core_enable_i & ~dispatch_core_stall;

        if (state == STATE_STOPPED)
            core_reset_mailbox_o = 0;
        else
            core_reset_mailbox_o = {`NUM_CORES{1'b1}};

        if (state == STATE_DISPATCHING)
            core_stall_o = dispatch_core_stall;
        else if (state == STATE_PAUSED || core_stall_i)
            core_stall_o = {`NUM_CORES{1'b1}};
        else
            core_stall_o = 0;

        core_jump_o  = (core_jump_i  ? 1 : 0);

        cores_mailed_mask = {`NUM_CORES{1'b1}};
        for (i = 0; i < `NUM_CORES; i = i + 1) begin
            if (core_inbox_mstream_i[i * `STREAM_MIPORT_SIZE(`MAILBOX_STREAM_SIZE) + `STREAM_MI_READY(`MAILBOX_STREAM_SIZE)])
                cores_mailed_mask[i] = 0;
        end
        cores_not_mailed = (cores_mailed_mask == 0);
        cores_all_mailed = (cores_mailed_mask == {`NUM_CORES{1'b1}});

        // Next program selection
        if (cur_prog == STATE_GPGPU_COMPUTE) begin
            if (dispatch_model_done)
                next_prog = STATE_STOPPING;
            else
                next_prog = STATE_GPGPU_COMPUTE;
        end
        else begin
            if (dispatch_model_done && vertorder_empty_i && !vertcont_busy_i && !rast_busy_i && fragfifo_empty_i && cores_not_mailed)
                next_prog = STATE_STOPPING;
            else if (fragshade_deadlock && dispatch_model_done)
                next_prog = STATE_FRAGMENT_SHADING_LAST;
            else if ((cores_all_mailed || dispatch_model_done || core_outbox_mstream_valid_i != 0) && state != STATE_STOPPED)
                next_prog = STATE_FRAGMENT_SHADING;
            else
                next_prog = STATE_VERTEX_SHADING;
        end

        // Entry point
        case (next_prog)
            STATE_GPGPU_COMPUTE:
                instfetch_prog_entry = pc_gpgpu_compute_i;
            STATE_VERTEX_SHADING:
                instfetch_prog_entry = pc_vertex_shading_i;
            STATE_FRAGMENT_SHADING, STATE_FRAGMENT_SHADING_LAST:
                instfetch_prog_entry = pc_fragment_shading_i;
            default:
                instfetch_prog_entry = 0;
        endcase

        case (cmd_i)
            `CORE_CTRL_CMD_RUN: instfetch_enable_comb = instfetch_enable;
            `CORE_CTRL_CMD_STEP: instfetch_enable_comb = instfetch_enable && !instfetch_step_done;
            default: instfetch_enable_comb = 0;
        endcase

        // Global regfile/thread ID
        if (state == STATE_DISPATCHING) begin
            global_regfile_rs1_data_o = dispatch_thread_id;
            global_regfile_rs2_data_o = 0;
        end
        else begin
            global_regfile_rs1_data_o = instfetch_global_regfile_rs1_data;
            global_regfile_rs2_data_o = instfetch_global_regfile_rs2_data;
        end
    end

endmodule
