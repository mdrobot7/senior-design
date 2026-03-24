module vertex_serializer_m(
    input wire clk_i,
    input wire nrst_i,

    //Parallel
    input  wire [`STREAM_SIPORT(`FRAGMENT_WIDTH)] sstream_i,
    output wire [`STREAM_SOPORT(`FRAGMENT_WIDTH)] sstream_o,

    //Serialized
    input  wire [`STREAM_MIPORT(`MAILBOX_STREAM_SIZE)] mstream_i,
    output wire [`STREAM_MOPORT(`MAILBOX_STREAM_SIZE)] mstream_o
);

    reg [2:0] count;
    reg last;
    reg [`FRAGMENT_WIDTH-1:0] tmp;
    reg valid;

    always @(posedge clk_i or negedge nrst_i) begin
        if(!nrst_i) begin
            count <= 3'd0;
            last <= 1'b0;
            tmp <= '0;
            valid <= 1'b0;
        end else begin
            if(valid)
            count <= count + 3'd1;
            if ((count == 3'd0) && (sstream_i[`STREAM_SI_VALID(`FRAGMENT_WIDTH)] == 1'b1)) begin
                tmp <= sstream_i[`STREAM_SI_DATA(`FRAGMENT_WIDTH)];
                last <= 1'b0;
                valid <= 1'b1;
            end
            else
                tmp <= (tmp >> 32);
            if (count == 3'd6 && (sstream_i[`STREAM_SI_LAST(`FRAGMENT_WIDTH)] == 1'b1))
                last <= 1'b1;
            if (count == 3'd7)
                valid <= 1'b0;
        end 
    end

    assign sstream_o[`STREAM_SO_READY(`FRAGMENT_WIDTH)] = mstream_i[`STREAM_MI_READY(`MAILBOX_STREAM_SIZE)];


    assign mstream_o[`STREAM_MO_VALID(`MAILBOX_STREAM_SIZE)] = valid;
    assign mstream_o[`STREAM_MO_DATA(`MAILBOX_STREAM_SIZE)] = tmp[31:0];
    assign mstream_o[`STREAM_MO_LAST(`MAILBOX_STREAM_SIZE)] = last;

endmodule