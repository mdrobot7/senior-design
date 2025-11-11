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