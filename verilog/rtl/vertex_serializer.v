module vertex_serializer_m(
    input wire clk_i,
    input wire nrst_i,

    input  wire [`STREAM_SIPORT(`FRAGMENT_WIDTH)] sstream_i,
    output wire [`STREAM_SOPORT(`FRAGMENT_WIDTH)] sstream_o,

    input  wire [`STREAM_MIPORT(`MAILBOX_STREAM_SIZE)] mstream_i,
    output wire [`STREAM_MOPORT(`MAILBOX_STREAM_SIZE)] mstream_o
);

    reg [2:0] count;
    reg ready;
    reg last;

    always @(posedge clk_i) begin
        count <= count + 3'd1;
    end

    reg [`FRAGMENT_WIDTH-1:0] tmp;
    always @(posedge clk_i) begin
        if ((count == 3'd0) && (sstream_i[`STREAM_SI_VALID(`FRAGMENT_WIDTH)] == 1'b1)) begin
            tmp <= sstream_i[`STREAM_SI_DATA(`FRAGMENT_WIDTH)];
            ready <= 0'b0;
            last <= 1'b0;
        end
        else
            tmp <= (tmp >> 32);

        if (count == 3'd7)
            ready <= 1'b1;
            last <= 1'b1;
    end

    assign sstream_o[`STREAM_SO_READY(`FRAGMENT_WIDTH)] = ready;

    assign mstream_o[`STREAM_MO_VALID(`MAILBOX_STREAM_SIZE)] = sstream_i[`STREAM_SI_VALID(`FRAGMENT_WIDTH)];
    assign mstream_o[`STREAM_MO_DATA(`MAILBOX_STREAM_SIZE)] = tmp[31:0];
    assign mstream_o[`STREAM_MO_LAST(`MAILBOX_STREAM_SIZE)] = last;

endmodule