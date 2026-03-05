module inbox_m (
    input  wire clk_i,
    input  wire nrst_i,
    input  wire nsync_rst_i,
    input  wire inbox_read_req_i,
    input  wire[`STREAM_SIPORT(`MAILBOX_STREAM_SIZE)] inbox_sstream_i,
    output reg[`STREAM_SOPORT(`MAILBOX_STREAM_SIZE)] inbox_sstream_o,
    output reg stall_o,
    output wire [`CORE_MAILBOX_HEIGHT*`WORD_WIDTH] inbox_o
);

    reg ready;

    reg [`MAILBOX_STREAM_SIZE - 1:0] inbox [`MAILBOX_STREAM_CYCLES - 1:0];

    reg[`MAILBOX_COUNTER_WIDTH-1:0] counter;


    always @(posedge clk_i, negedge nrst_i) begin
        if(!nrst_i) begin : RESET
            integer i;
            for( i = 0; i < `MAILBOX_STREAM_CYCLES; i = i + 1)
                inbox[i] = 0;

            ready <= 0;
            counter <= 0;
            stall_o <= 0;
        end
        else if (clk_i) begin : CLOCK
            integer i;
            if (nsync_rst_i) begin
                integer i;
                for( i = 0; i < `MAILBOX_STREAM_CYCLES; i = i + 1)
                    inbox[i] = 0;

                ready <= 0;
                counter <= 0;
                stall_o <= 0;
            end
            else begin
                if(ready) begin
                    if(inbox_sstream_i[`STREAM_SI_VALID(`MAILBOX_STREAM_SIZE)]) begin
                        inbox[counter] <= inbox_sstream_i[`STREAM_SI_DATA(`MAILBOX_STREAM_SIZE)];
                        counter = (counter + 1) % `MAILBOX_STREAM_CYCLES;
                    end
                    if(inbox_sstream_i[`STREAM_SI_LAST(`MAILBOX_STREAM_SIZE)])
                        stall_o <= 0;
                        ready <= 0;
                    if(inbox_read_req_i)
                        ready <= 1;
                end
                else begin // !ready
                    if(inbox_read_req_i)
                    //not ready and want to read, gotta stall
                        stall_o <= 1;
                end
            end
        end
    end

endmodule