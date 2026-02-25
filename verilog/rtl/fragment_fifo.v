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

    output wire [`NUM_CORES-1:0]        select_lines,

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

// Select idx core, increment to next core if not ready

//Assign mstreams_o VALID bit for selected core


// Assign MC status bits
always @(*) begin
    // full = 
    // empty = 
    // done_mailing = 
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
