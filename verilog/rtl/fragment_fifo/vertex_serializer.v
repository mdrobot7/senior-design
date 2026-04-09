module vertex_serializer_m#(
    parameter PARALLEL_SIZE  = `FRAGMENT_WIDTH,
    parameter SERIAL_SIZE  = `MAILBOX_STREAM_SIZE
)(
    input wire clk_i,
    input wire nrst_i,

    //Parallel
    input  wire [`STREAM_SIPORT(PARALLEL_SIZE)] sstream_i,
    output wire [`STREAM_SOPORT(PARALLEL_SIZE)] sstream_o,

    //Serialized
    input  wire [`STREAM_MIPORT(SERIAL_SIZE)] mstream_i,
    output wire [`STREAM_MOPORT(SERIAL_SIZE)] mstream_o
);

    reg [2:0] count;
    reg last;
    reg [PARALLEL_SIZE-1:0] tmp;
    reg valid;
    reg busy;

    always @(posedge clk_i or negedge nrst_i) begin
        if(!nrst_i) begin
            count <= 3'd0;
            last <= 1'b0;
            tmp <= 0;
            valid <= 1'b0;
            busy <= 1'b0; 
        end else begin
            if(valid) begin
                count <= count + 3'd1;
                tmp <= (tmp >> SERIAL_SIZE);
            end
            if (!busy && (sstream_i[`STREAM_SI_VALID(PARALLEL_SIZE)] == 1'b1) && mstream_i[`STREAM_MI_READY(SERIAL_SIZE)]) begin
                tmp <= sstream_i[`STREAM_SI_DATA(PARALLEL_SIZE)];
                last <= 1'b0;
                valid <= 1'b1;
                busy <= 1'b1;
                count <= 3'd0;
            end
            if (count == 3'd6)
                last <= 1;
            if (count == 3'd7) begin
                valid <= 1'b0;
                last <= 1'b0;
                busy <= 1'b0; // Done serializing, allow new data
            end 
        end
    end

    assign sstream_o[`STREAM_SO_READY(PARALLEL_SIZE)] = !busy && mstream_i[`STREAM_MI_READY(SERIAL_SIZE)];

    assign mstream_o[`STREAM_MO_VALID(SERIAL_SIZE)] = valid;
    assign mstream_o[`STREAM_MO_DATA(SERIAL_SIZE)] = tmp[31:0];
    assign mstream_o[`STREAM_MO_LAST(SERIAL_SIZE)] = last;

endmodule