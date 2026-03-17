module inbox_m (
    input  wire clk_i,
    input  wire nrst_i,
    input  wire nsync_rst_i,
    input  wire inbox_read_req_i, // 1: Read from inbox to core regfile
    input  wire[`STREAM_SIPORT(`MAILBOX_STREAM_SIZE)] inbox_sstream_i,
    output reg[`STREAM_SOPORT(`MAILBOX_STREAM_SIZE)] inbox_sstream_o,
    output reg stall_o, // 1: Attempted to read from empty inbox, stall until inbox is filled
    output reg [`CORE_MAILBOX_HEIGHT*`WORD_WIDTH-1:0] inbox_o
);

    reg ready; // 1: Inbox can accept incoming fragment data. Prevents overwriting full inbox

    reg [`MAILBOX_STREAM_SIZE - 1:0] inbox [`MAILBOX_STREAM_CYCLES - 1:0];

    reg[`MAILBOX_COUNTER_WIDTH:0] counter;


    always @(*) begin : ASSIGNMENT
        integer i;
        for(i = 0; i < `MAILBOX_STREAM_CYCLES; i = i + 1) begin
            inbox_o[(i*`WORD_WIDTH) +: `WORD_WIDTH] <= inbox[i];
        end

        ready <= (counter != `MAILBOX_STREAM_CYCLES);

        stall_o <= ready;

        inbox_sstream_o[`STREAM_SO_READY(`MAILBOX_STREAM_SIZE)] <= ready;
    end

    always @(posedge clk_i, negedge nrst_i) begin
        if(!nrst_i) begin : RESET
            integer i;
            for( i = 0; i < `MAILBOX_STREAM_CYCLES; i = i + 1)
                inbox[i] = 0;

            counter <= 0;
            stall_o <= 0;
        end
        else if (clk_i) begin : CLOCK
            integer i;
            if (!nsync_rst_i) begin : SYNC_RESET
                integer i;
                for( i = 0; i < `MAILBOX_STREAM_CYCLES; i = i + 1)
                    inbox[i] = 0;

                counter <= 0;
                stall_o <= 0;
            end
            else begin
                if(ready && inbox_sstream_i[`STREAM_SI_VALID(`MAILBOX_STREAM_SIZE)]) begin
                    inbox[counter] <= inbox_sstream_i[`STREAM_SI_DATA(`MAILBOX_STREAM_SIZE)];
                    counter <= counter + 1;
                end

                if (!ready && inbox_read_req_i)
                    counter <= 0;
            end
        end
    end

endmodule
