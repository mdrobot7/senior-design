module stream_fifo_m #(
    parameter SIZE = 1,
    parameter DEPTH = 10
) (
    input wire clk_i,
    input wire nrst_i,

    input  wire [`STREAM_SIPORT(SIZE)] sstream_i,
    output wire [`STREAM_SOPORT(SIZE)] sstream_o,

    input  wire [`STREAM_MIPORT(SIZE)] mstream_i,
    output wire [`STREAM_MOPORT(SIZE)] mstream_o
);

    localparam DEPTH_LOG = $clog2(DEPTH);

    reg [DEPTH_LOG - 1:0] head, size;
    reg [SIZE - 1:0] buffer[DEPTH - 1:0];

    assign sstream_o[`STREAM_SO_READY(SIZE)] = size != DEPTH;

    assign mstream_o[`STREAM_MO_VALID(SIZE)] = size != 0;
    assign mstream_o[`STREAM_MO_LAST(SIZE)] = 0;
    assign mstream_o[`STREAM_MO_DATA(SIZE)] = buffer[head];

    always @(posedge clk_i, negedge nrst_i) begin
        if (!nrst_i) begin : RESET
            integer i;

            head <= 0;
            size <= 0;

            for (i = 0; i < DEPTH; i = i + 1) buffer[i] <= 0;
        end
        else if (clk_i) begin : CLOCK
            reg [DEPTH_LOG - 1:0] new_size;

            new_size = size;

            if (sstream_i[`STREAM_SI_VALID(SIZE)] && sstream_o[`STREAM_SO_READY(SIZE)]) begin
                buffer[(head + size) % DEPTH] <= sstream_i[`STREAM_SI_DATA(SIZE)];

                new_size = new_size + 1;
            end

            if (mstream_i[`STREAM_MI_READY(SIZE)] && mstream_o[`STREAM_MO_VALID(SIZE)]) begin
                head <= (head + 1) % DEPTH;
                new_size = new_size - 1;
            end

            size = new_size;
        end
    end

endmodule