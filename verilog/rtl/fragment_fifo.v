/*
    Fragment Fifo (Mailman) delivers rasterized vertices to cores
*/

module fragment_fifo_m (
    input  wire                         clk_i,
    input  wire                         nrst_i,

    output wire [`NUM_CORES]            sel_o,

    input  wire [`STREAM_SIPORT(SIZE)] sstream_i,
    output wire [`STREAM_SOPORT(SIZE)] sstream_o,

    input  wire [`STREAM_MIPORT(SIZE)] mstream_i,
    output wire [`STREAM_MOPORT(SIZE)] mstream_o

);

stream_fifo_m #( .SIZE(1) .DEPTH(10) ) fifo 
(
    .clk_i(clk_i),
    .nrst_i(nrst_i),
    .sstream_i(sstream_i),
    .sstream_o(sstream_o),
    .mstream_i(mstream_i),
    .mstream_o(mstream_o),

); 
    
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
    always @(*) begin
    
    end

endmodule