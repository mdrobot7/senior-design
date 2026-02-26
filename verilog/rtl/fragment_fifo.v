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

    //Master to N cores
    input  wire [`STREAM_MIPORT(SIZE) * `NUM_CORES] mstream_i,
    output wire [`STREAM_MOPORT(SIZE) * `NUM_CORES] mstream_o

    // Status for MC
    output reg                          empty,
    output reg                          full,
    output reg                          done_mailing


);

localparam MI_Size = `STREAM_MIPORT_SIZE(SIZE)
localparam MO_Size = `STREAM_MOPORT_SIZE(SIZE)


// Internal streamlines for FIFO between rasterizer 
wire [`STREAM_MIPORT(SIZE) internal_mstream_i];
wire [`STREAM_MOPORT(SIZE) internal_mstream_o];


stream_fifo_m #( .SIZE(SIZE) .DEPTH(DEPTH) ) fifo 
(
    .clk_i(clk_i),
    .nrst_i(nrst_i),
    .sstream_i(sstream_i),
    .sstream_o(sstream_o),
    .mstream_i(internal_mstream_i),
    .mstream_o(internal_mstream_o), 

); 

// Get READY bits per core from mstream_i
reg [`NUM_CORES-1:0] sel_i;
reg [`NUM_CORES-1:0] core_ready;
integer i;
always @(*) begin
    for(i = 0; i < `NUM_CORES; i++)
        core_ready[i] = mstream_i[MI_Size*i + `STREAM_MI_READY(size)];
end

wire fifo_has_data   = fifo_mstream_o[`STREAM_MO_VALID(SIZE)];
wire cur_core_ready  = |(core_ready & sel_i);

// Select idx core, increment to next core if not ready
always @(posedge clk_i or negedge nrst_i) begin
    if (!nrst_i) begin
        // 0th core selected
        sel_i <={{(`NUM_CORES-1){1'b0}}, 1'b1};
    end
    else if (fifo_has_data && !cur_core_ready) begin
        sel_i <= {sel_i[`NUM_CORES-2:0], sel_i[`NUM_CORES-1]};
    end
    // else: sel_i stays the same since current core is ready
end

// Assign mstreams_o VALID bit for selected core
integer j;
always @(*) begin
    mstream_o = {MO_Size * `NUM_CORES{1'b0}};
    if (fifo_has_data) begin
        for (j = 0; j< `NUM_CORES; j++) begin
            if (sel_i[j] ) begin
                mstreams_o[j * MO_Size + `STREAM_MOPORT_SIZE(SIZE)] = fifo_mstream_o[`STREAM_MOPORT_SIZE(SIZE)];
                // Valid for selected core
                mstreams_o[j * MO_Size* + STREAM_MO_VALID(SIZE)]=1'b1;
            end                           
        end
    end
end

assign internal_mstream_i[`STREAM_MI_READY(SIZE)] = cur_core_ready;


// Assign MC status bits
always @(*) begin
    full = ~stream_o[`STREAM_SO_READY(SIZE)];
    empty = ~fifo_has_data;
    done_mailing = sel_i[0];
    end
    
/*
    while (1){
        while(idx != num_cores){
            if(core[idx].ready && fifo.notempty){
                core[idx].inbox <- fifo.data    
            }
            idx++
        }
        idx = 0;
        done_mailing = 1;
    }
*/
    

endmodule
