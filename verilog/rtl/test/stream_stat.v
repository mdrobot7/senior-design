module stream_stat_m #(
    parameter SIZE = 1
) (
    input wire clk_i,

    input  wire [`STREAM_MIPORT(SIZE)] mstreami_i,
    input  wire [`STREAM_MOPORT(SIZE)] mstreamo_i
);

    integer total_clocks;
    integer slave_busy_clocks;
    integer master_busy_clocks;
    integer total_busy_clocks;
    integer transfer_clocks;

    initial forever begin
        wait(!clk_i);
        wait(clk_i);

        total_clocks = total_clocks + 1;

        if (mstreamo_i[`STREAM_MO_VALID(SIZE)] && !mstreami_i[`STREAM_MI_READY(SIZE)]) begin
            slave_busy_clocks = slave_busy_clocks + 1;
        end

        if (!mstreamo_i[`STREAM_MO_VALID(SIZE)] && mstreami_i[`STREAM_MI_READY(SIZE)]) begin
            master_busy_clocks = master_busy_clocks + 1;
        end

        if (
            mstreamo_i[`STREAM_MO_VALID(SIZE)] && !mstreami_i[`STREAM_MI_READY(SIZE)] ||
            !mstreamo_i[`STREAM_MO_VALID(SIZE)] && mstreami_i[`STREAM_MI_READY(SIZE)]
        ) begin
            total_busy_clocks = total_busy_clocks + 1;
        end

        if (mstreamo_i[`STREAM_MO_VALID(SIZE)] && mstreami_i[`STREAM_MI_READY(SIZE)]) begin
            transfer_clocks = transfer_clocks + 1;
        end
    end

    task RESET;
    begin
        total_clocks = 0;
        slave_busy_clocks = 0;
        master_busy_clocks = 0;
        total_busy_clocks = 0;
        transfer_clocks = 0;
    end
    endtask

    task PRINT_STATS;
    begin
        $display("Total clocks:       %d", total_clocks);
        $display("Master busy clocks: %d (%f%%)", master_busy_clocks, $itor(master_busy_clocks) / $itor(total_clocks) * 100.0);
        $display("Slave busy clocks:  %d (%f%%)", slave_busy_clocks, $itor(slave_busy_clocks) / $itor(total_clocks) * 100.0);
        $display("Total idle clocks:  %d (%f%%)", total_busy_clocks, $itor(total_busy_clocks) / $itor(total_clocks) * 100.0);
        $display("Transfer clocks:    %d (%f%%)", transfer_clocks, $itor(transfer_clocks) / $itor(total_clocks) * 100.0);
    end
    endtask

endmodule