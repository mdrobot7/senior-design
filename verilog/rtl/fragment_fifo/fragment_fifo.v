module fragment_fifo_m #(
    parameter SIZE  = `FRAGMENT_WIDTH,
    parameter DEPTH = 10
) (
    input  wire clk_i,
    input  wire nrst_i,
    input  wire clear_i,

    input  wire [`STREAM_SIPORT(SIZE)] sstream_i,
    output wire [`STREAM_SOPORT(SIZE)] sstream_o,
    input  wire [`STREAM_MIPORT_SIZE(SIZE) * `NUM_CORES - 1:0] mstream_i,
    output reg  [`STREAM_MOPORT_SIZE(SIZE) * `NUM_CORES - 1:0] mstream_o,

    output reg[`NUM_CORES-1:0]  selind_o,
    output reg  empty_o,
    output reg  full_o,
    output reg  done_mailing_o
);

    localparam MI_Size = `STREAM_MIPORT_SIZE(SIZE);
    localparam MO_Size = `STREAM_MOPORT_SIZE(SIZE);

    wire [`STREAM_MIPORT(SIZE)] internal_mstream_i;
    wire [`STREAM_MOPORT(SIZE)] internal_mstream_o;

    integer j;


    stream_fifo_m #(.SIZE(SIZE), .DEPTH(DEPTH) ) fifo (
        .clk_i(clk_i),
        .nrst_i(nrst_i),
        .sstream_i(sstream_i),
        .sstream_o(sstream_o),
        .mstream_i(internal_mstream_i),
        .mstream_o(internal_mstream_o)
    ); 

    // Get READY bits per core from mstream_i
    reg [`NUM_CORES-1:0] core_select;
    reg [`NUM_CORES-1:0] core_ready;
    integer i;
    always @(*) begin
        for (i = 0; i < `NUM_CORES; i = i + 1)
            core_ready[i] = mstream_i[MI_Size * i + `STREAM_MI_READY(SIZE)];
    end

    //Internal valid and ready 
    wire fifo_has_data   = internal_mstream_o[`STREAM_MO_VALID(SIZE)];
    wire cur_core_ready  = |(core_ready & core_select);

    // Select core, increment to next core if not ready
    always @(posedge clk_i or negedge nrst_i) begin
        if (!nrst_i) begin
            // 0th core selected
            core_select <= {{(`NUM_CORES-1){1'b0}}, 1'b1};
        end
        else begin
        // Override only valid bit for selected core
            if (fifo_has_data && !cur_core_ready) begin
                core_select <= (core_select << 1) | (core_select >> (`NUM_CORES - 1));
            end
        end 
    end

    // FIFO pops when the currently selected core is READY or when clearing
    assign internal_mstream_i[`STREAM_MI_READY(SIZE)] = (cur_core_ready || clear_i);

    // Assign MC status bits
    always @(*) begin
        for (j = 0; j < `NUM_CORES; j = j + 1) begin
            mstream_o[j * MO_Size +: MO_Size] <= internal_mstream_o;
            if (!clear_i && core_select[j] && fifo_has_data) begin
                mstream_o[j * MO_Size + `STREAM_MO_VALID(SIZE)] <= 1'b1;
            end
            else begin
                mstream_o[j * MO_Size + `STREAM_MO_VALID(SIZE)] <= 1'b0;
            end
        end

        full_o = ~sstream_o[`STREAM_SO_READY(SIZE)];
        empty_o = ~fifo_has_data;
        selind_o = core_select;
        done_mailing_o = ~core_ready;
    end
endmodule
