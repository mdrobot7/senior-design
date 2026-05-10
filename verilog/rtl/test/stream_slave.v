module stream_slave_m #(
    parameter SIZE = 1,
    parameter BUFFER_SIZE = 1
) (
    input wire clk_i,

    input  wire [`STREAM_SIPORT(SIZE)] sstream_i,
    output wire [`STREAM_SOPORT(SIZE)] sstream_o
);

    integer buffer_head, buffer_size;
    reg [SIZE - 1:0] buffer [BUFFER_SIZE - 1:0];
    
    initial begin : BUFFER_INIT
        integer i;

        buffer_head = 0;
        buffer_size = 0;

        for (i = 0; i < BUFFER_SIZE; i = i + 1) buffer[i] = 0;
    end
    

    assign sstream_o[`STREAM_SO_READY(PORT)] = buffer_size != BUFFER_SIZE;

    initial forever begin
        wait(!clk_i);
        wait(clk_i);

        if (sstream_i[`STREAM_SI_VALID(SIZE)]) begin
            buffer[buffer_head + buffer_size] = sstream_i[`STREAM_SI_DATA(SIZE)];

            buffer_size = buffer_size + 1;
        end
    end

    task READ;
        output [SIZE - 1:0] data;
    begin
        while (buffer_size == 0) begin
            wait(clk_i);
            wait(!clk_i);
        end
        wait(!clk_i);

        data = buffer[buffer_head];

        buffer_head = (buffer_head + 1) % BUFFER_SIZE;
        buffer_size = buffer_size - 1;
    end
    endtask

endmodule