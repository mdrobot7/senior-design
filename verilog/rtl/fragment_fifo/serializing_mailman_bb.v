module serializing_mailman_m(
    input  wire clk_i,
    input  wire nrst_i,
    input  wire clear_i,

    input  wire [257:0] sstream_i,
    output wire [0:0] sstream_o,
    input  wire [2:0] mstream_i,
    output wire [101:0] mstream_o,

    output wire [2:0] selind_o,
    output wire  empty_o,
    output wire  full_o,
    output wire  done_mailing_o
);
endmodule

