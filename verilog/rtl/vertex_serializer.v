module vertex_serializer_m(
    input wire clk_i,
    input wire nrst_i,

    input  wire [`STREAM_SIPORT(`FRAGMENT_WIDTH)] sstream_i,
    output wire [`STREAM_SOPORT(`FRAGMENT_WIDTH)] sstream_o,

    input  wire [`STREAM_MIPORT(`MAILBOX_STREAM_SIZE)] mstream_i,
    output wire [`STREAM_MOPORT(`MAILBOX_STREAM_SIZE)] mstream_o
);

    reg [2:0] count;

    initial count = 3'd0;
    intial sstream_o[`STREAM_SO_READY(`FRAGMENT_WIDTH)] = 1'b1;

    always @(posedge clk) begin
        if(sstream_o[`STREAM_SO_READY(`FRAGMENT_WIDTH)] == 1'b0)    
            count <= count + 3'd1;
    end

    reg [`MAILBOX_STREAM_SIZE-1:0] tmp;
    always @(posedge clk) begin
        if (count == 3'd0) && (sstream_i[`STREAM_SI_VALID(`FRAGMENT_WIDTH)] == 1'b1)
            tmp <= sstream_i[`STREAM_SI_DATA(`FRAGMENT_WIDTH)];
            sstream_o[`STREAM_SO_READY(`FRAGMENT_WIDTH)] <= 1'b0;

        else
            tmp <= (tmp >> `MAILBOX_STREAM_SIZE);

        if (count == 3'd7)
            sstream_o[`STREAM_SO_READY(`FRAGMENT_WIDTH)] <= 1'b1;
            mstream_o[`STREAM_MO_LAST(`MAILBOX_STREAM_SIZE)] <= 1'b1;
    end

    assign mstream_o[`STREAM_MO_VALID(`MAILBOX_STREAM_SIZE)] = sstream_i[`STREAM_SI_VALID(`FRAGMENT_WIDTH)]
    assign mstream_o[`STREAM_MO_DATA(`MAILBOX_STREAM_SIZE)] = tmp[31:0];

endmodule