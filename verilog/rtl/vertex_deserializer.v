module vertex_deserializer_m(
    input wire clk_i,
    input wire nrst_i,

    input  wire [`STREAM_SIPORT(`MAILBOX_STREAM_SIZE)] sstream_i,
    output wire [`STREAM_SOPORT(`MAILBOX_STREAM_SIZE)] sstream_o,

    input  wire [`STREAM_MIPORT(`SHADED_VERTEX_WIDTH)] mstream_i,
    output wire [`STREAM_MOPORT(`SHADED_VERTEX_WIDTH)] mstream_o
);

    reg [$clog2(`MAILBOX_STREAM_CYCLES + 1)] pos;

    reg [`SHADED_VERTEX] out_data;

    always @(posedge clk_i, negedge nrst_i) begin
        if (!nrst_i) begin
            state <= 0;

            out_data <= 0;
        end
        else if (clk_i) begin
            if (pos < `MAILBOX_STREAM_CYCLES) begin
                if (sstream_i[`STREAM_SI_VALID(`MAILBOX_STREAM_SIZE)]) begin
                    pos <= pos + 1;

                    out_data[pos * `SHADED_VERTEX_WIDTH+:`SHADED_VERTEX_WIDTH]
                        <= sstream_i[`STREAM_SI_DATA(`MAILBOX_STREAM_SIZE)];
                end
            end
            else begin
                if (mstream_i[`SYREAM_MI_READY(`SHADED_VERTEX_WIDTH)]) begin
                    pos <= 0;
                end
            end
        end
    end

    assign sstream_o[`STREAM_SO_READY(`MAILBOX_STREAM_SIZE)] = pos < `MAILBOX_STREAM_CYCLES;

    assign mstream_o[`STREAM_MO_DATA(`SHADED_VERTEX_WIDTH)] = out_data;
    assign mstream_o[`STREAM_MO_VALID(`SHADED_VERTEX_WIDTH)] = pos == `MAILBOX_STREAM_CYCLES;
    assign mstream_o[`STREAM_MO_LAST(`SHADED_VERTEX_WIDTH)] = 0;

endmodule

