/*
    Direct mapped, write through cache
    Should be fully paramaterized such that we can scale up or down depending on where the cache will be placed, 
    and from the results we got from our locality analysis
*/

module cache #(
    paramater ADDR_WIDTH = (32),        // Size of memory address
    paramater DATA_WIDTH = (32),        // Size of word
    paramater CACHE_LINES = (),         // Number of lines, must be power of 2
    paramater TAG_BITS = (),
    paramater INDEX_BITS = (),
    paramater OFFSET_BITS = (),
    
) (
    input wire clk,
    input wire addr[ADDR_WIDTH-1:0],
    input wire write_enable,
    input wire data_in[DATA_WIDTH=1:0],



    input wire hit,                     // From cache unit
    output reg index[],                 // To cache unit
    output reg tag[],                   // To cache unit
    output reg offset[],                // To cache unit
    output reg write_enable_out,        // To cache unit

    output reg data_out[DATA_WIDTH-1:0]    // Out to cores
    
);