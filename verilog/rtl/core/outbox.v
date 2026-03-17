module outbox_m (
    input  wire clk_i,
    input  wire nrst_i,
    input  wire nsync_rst_i,
    input  wire outbox_write_req_i, // 1: Latch outbox_i into the outbox
    input  wire [`STREAM_MIPORT(`MAILBOX_STREAM_SIZE)] outbox_mstream_i,
    output reg  [`STREAM_MOPORT(`MAILBOX_STREAM_SIZE)] outbox_mstream_o,
    output reg  stall_o, // 1: Attempted to write to a full outbox, stall until the outbox is emptied
    input  wire [`CORE_MAILBOX_HEIGHT*`WORD_WIDTH-1:0] outbox_i
);

    reg ready; // 1: Ready to accept new data from the core.

    reg [`MAILBOX_STREAM_SIZE - 1:0] outbox [`MAILBOX_STREAM_CYCLES - 1:0];

    reg [`MAILBOX_COUNTER_WIDTH:0] counter;


    always @(*) begin : ASSIGNMENT
        ready <= (counter == `MAILBOX_STREAM_CYCLES);

        stall_o <= !ready;

        outbox_mstream_o <= 0;
        outbox_mstream_o[`STREAM_MO_VALID(`MAILBOX_STREAM_SIZE)] <= !ready;
        if (!ready)
          outbox_mstream_o[`STREAM_MO_DATA(`MAILBOX_STREAM_SIZE)] <= outbox[counter];
    end

    always @(posedge clk_i, negedge nrst_i) begin
        if(!nrst_i) begin : RESET
            integer i;
            for( i = 0; i < `MAILBOX_STREAM_CYCLES; i = i + 1)
                outbox[i] = 0;

            stall_o <= 0;
            counter <= `MAILBOX_STREAM_CYCLES;
        end
        else if (clk_i) begin : CLOCK
            integer i;
            if (!nsync_rst_i) begin : SYNC_RESET
                integer i;
                for( i = 0; i < `MAILBOX_STREAM_CYCLES; i = i + 1)
                    outbox[i] = 0;

                stall_o <= 0;
                counter <= `MAILBOX_STREAM_CYCLES;
            end
            else begin
                for(i = 0; i < `MAILBOX_STREAM_CYCLES; i = i + 1) begin
                    if (outbox_write_req_i && ready)
                        outbox[i] <= outbox_i[(i*`WORD_WIDTH) +: `WORD_WIDTH];
                    else
                        outbox[i] <= outbox[i];
                end

                if(!ready && outbox_mstream_i[`STREAM_MI_READY(`MAILBOX_STREAM_SIZE)]) begin
                    counter <= counter + 1;
                end

                if (ready && outbox_write_req_i)
                    counter <= 0;
            end
        end
    end

endmodule
