/*
    Direct mapped, write through cache
    Should be fully paramaterized such that we can scale up or down depending on where the cache will be placed, 
    and from the results we got from our locality analysis
*/

module cache #(
    paramater ADDR_WIDTH = (32),        // Size of memory address
    paramater DATA_WIDTH = (32),        // Size of word
    paramater CACHE_LINES = (),         // Number of lines, must be power of 2
) (
    input wire clk,
    input wire addr[ADDR_WIDTH-1:0],    //
    output reg Data[DATA_WIDTH-1:0],    //
    output reg hit,                     // Response if we have a cache hit or miss
    
);