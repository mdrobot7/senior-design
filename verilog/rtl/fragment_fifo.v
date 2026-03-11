/*
    Fragment Fifo (Mailman) delivers fragments from rasterizer
    Master to cores
    Slave to rasterizer
*/

module fragment_fifo_m #(
    parameter SIZE  = 1,
    parameter DEPTH = 10
) (
    input  wire                         clk_i,
    input  wire                         nrst_i,

    //Slave to rasterizer
    input  wire [`STREAM_SIPORT(SIZE)] sstream_i,
    output wire [`STREAM_SOPORT(SIZE)] sstream_o,

    // Master to N cores (packed array of master streams)
    input  wire [`STREAM_MIPORT_SIZE(SIZE) * `NUM_CORES - 1:0] mstream_i,
    output reg  [`STREAM_MOPORT_SIZE(SIZE) * `NUM_CORES - 1:0] mstream_o,

    // Status for MC
    output reg                          empty,
    output reg                          full,
    output reg                          done_mailing


);

localparam MI_Size = `STREAM_MIPORT_SIZE(SIZE);
localparam MO_Size = `STREAM_MOPORT_SIZE(SIZE);


// Internal streamlines for FIFO between rasterizer 
wire [`STREAM_MIPORT(SIZE)] internal_mstream_i;
wire [`STREAM_MOPORT(SIZE)] internal_mstream_o;


stream_fifo_m #( .SIZE(SIZE), .DEPTH(DEPTH) ) fifo 
(
    .clk_i(clk_i),
    .nrst_i(nrst_i),
    .sstream_i(sstream_i),
    .sstream_o(sstream_o),
    .mstream_i(internal_mstream_i),
    .mstream_o(internal_mstream_o)
); 

// Get READY bits per core from mstream_i
reg [`NUM_CORES-1:0] sel_i;
reg [`NUM_CORES-1:0] core_ready;
integer i;
always @(*) begin
    for (i = 0; i < `NUM_CORES; i = i + 1)
        core_ready[i] = mstream_i[MI_Size * i + `STREAM_MI_READY(SIZE)];
end

wire fifo_has_data   = internal_mstream_o[`STREAM_MO_VALID(SIZE)];
wire cur_core_ready  = |(core_ready & sel_i);

// Select core, increment to next core if not ready
always @(posedge clk_i or negedge nrst_i) begin
    if (!nrst_i) begin
        // 0th core selected
        sel_i <= {{(`NUM_CORES-1){1'b0}}, 1'b1};
    end
    else if (fifo_has_data && !cur_core_ready) begin
        sel_i <= {sel_i[`NUM_CORES-2:0], sel_i[`NUM_CORES-1]};
    end
    // else: sel_i stays the same since current core is ready
end

// Assign mstream_o VALID bit for selected core
integer j;
always @(*) begin
    // Assign all outputs from internal FIFO default 
    for (j = 0; j < `NUM_CORES; j = j + 1) begin
        mstream_o[j * MO_Size +: MO_Size] = internal_mstream_o;
    end

    // Override only  valid bit for selected core
    for (j = 0; j < `NUM_CORES; j = j + 1) begin
        if (sel_i[j] && fifo_has_data && internal_mstream_o[`STREAM_MO_VALID(SIZE)])
            mstream_o[j * MO_Size + `STREAM_MO_VALID(SIZE)] = 1'b1;
        else
            mstream_o[j * MO_Size + `STREAM_MO_VALID(SIZE)] = 1'b0;
    end
end

// FIFO pops when the currently selected core is READY.
assign internal_mstream_i[`STREAM_MI_READY(SIZE)] = cur_core_ready;

// Assign MC status bits
always @(*) begin
    full = ~sstream_o[`STREAM_SO_READY(SIZE)];
    empty = ~fifo_has_data;
    done_mailing = sel_i[0];
end
    

endmodule
