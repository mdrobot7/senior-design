module vertex_serializer_m#(
    parameter PARALLEL_SIZE  = `FRAGMENT_WIDTH,
    parameter SERIAL_SIZE  = `MAILBOX_STREAM_SIZE
)(
    input wire clk_i,
    input wire nrst_i,

    output reg busy_o,

    //Parallel
    input  wire [`STREAM_SIPORT(PARALLEL_SIZE)] sstream_i,
    output reg  [`STREAM_SOPORT(PARALLEL_SIZE)] sstream_o,

    //Serialized
    input  wire [`STREAM_MIPORT(SERIAL_SIZE)] mstream_i,
    output reg [`STREAM_MOPORT(SERIAL_SIZE)] mstream_o
);

    reg [0:0] state;
    reg [2:0] pos;
    reg [PARALLEL_SIZE - 1:0] in_data;

    always @(posedge clk_i, negedge nrst_i) begin
        if (!nrst_i) begin
            state <= 0;

            pos <= 0;

            in_data <= 0;
        end
        else if (clk_i) begin
            case (state)
                0: begin
                    if (sstream_i[`STREAM_SI_VALID(PARALLEL_SIZE)]) begin
                        state <= state + 1;

                        in_data <= sstream_i[`STREAM_SI_DATA(PARALLEL_SIZE)];
                    end
                end

                1: begin
                    if (mstream_i[`STREAM_MI_READY(SERIAL_SIZE)]) begin
                        if (pos == 7) begin
                            state <= 0;
                            pos   <= 0;
                        end
                        else pos <= pos + 1;
                    end
                end
            endcase
        end
    end

    always @(*) begin
        sstream_o[`STREAM_SO_READY(PARALLEL_SIZE)] = state == 0;

        mstream_o[`STREAM_MO_VALID(SERIAL_SIZE)] = state == 1;
        mstream_o[`STREAM_MO_DATA(SERIAL_SIZE)]  = in_data[pos * SERIAL_SIZE +: SERIAL_SIZE];
        mstream_o[`STREAM_MO_LAST(SERIAL_SIZE)]  = 1'b0;

        busy_o = state != 0;
    end

endmodule
