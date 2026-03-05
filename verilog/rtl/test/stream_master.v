module stream_master_m #(
    parameter SIZE = 1
) (
    input wire clk_i,

    input  wire [`STREAM_MIPORT(SIZE)] mstream_i,
    output reg  [`STREAM_MOPORT(SIZE)] mstream_o
);

    initial mstream_o = 0;

    initial begin
        mstream_o = 0;
    end

    task WRITE;
        input [SIZE - 1:0] data;
    begin
        @(posedge clk_i);

        mstream_o[`STREAM_MO_VALID(SIZE)] = 1;

        mstream_o[`STREAM_MO_LAST(SIZE)] = 0;
        mstream_o[`STREAM_MO_DATA(SIZE)] = data;
        @(posedge clk_i);
        while (!mstream_i[`STREAM_MI_READY(SIZE)]) begin
            @(posedge clk_i);
        end
        
        mstream_o[`STREAM_MO_VALID(SIZE)] = 0;

        mstream_o = 0;
    end
    endtask

    task WRITE_LAST;
        input [SIZE - 1:0] data;
    begin
        mstream_o[`STREAM_MO_VALID(SIZE)] = 1;

        mstream_o[`STREAM_MO_LAST(SIZE)] = 1;
        mstream_o[`STREAM_MO_DATA(SIZE)] = data;

        @(posedge clk_i);
        while (!mstream_i[`STREAM_MI_READY(SIZE)]) begin
            @(posedge clk_i);
        end
        
        mstream_o[`STREAM_MO_VALID(SIZE)] = 0;

        mstream_o = 0;
    end
    endtask

endmodule