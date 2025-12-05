module spi_chip_m #(
    parameter LATENCY_COUNT = 7,
    parameter PRE_CYCLES = 1,
    parameter SIZE = 1024
) (
    input  wire       clk_i,
    
    input  wire       cs_i,
    input  wire [3:0] mosi_i,
    output reg  [3:0] miso_o,
    output reg        dqsm_o,
    input  wire       dqsm_i
);

    localparam CMD_READ  = 8'h0A;
    localparam CMD_WRITE = 8'h02;

    reg [7:0] mem [SIZE - 1:0];

    initial begin : MEM_INIT
        integer i;

        for (i = 0; i < SIZE; i = i + 1) mem[i] = i;
    end

    reg [7:0] command;

    reg [31:0] full_address;
    wire [24:0] address;
    assign address = {
        full_address[28:16],
        full_address[13:5]
    };

    initial begin
        #10;

        forever begin : MAIN
            integer i;
            integer clock_per, half_clk, quarter_clk;

            i = $random;
            i = $random;
            i = $random;
            i = $random;
            i = $random;

            miso_o = 0;
            dqsm_o = 0;

            wait(!cs_i);

            $display("START!");

            wait(clk_i);
            command[3:0] = mosi_i;
            wait(!clk_i);

            wait(clk_i);
            command[7:4] = mosi_i;
            wait(!clk_i);

            // $display("Got command 0x%h", command);

            for (i = 0; i < 4; i = i + 1) begin
                wait(clk_i);
                full_address[28 - (i * 8) +: 4] = mosi_i;
                wait(!clk_i);
                full_address[24 - (i * 8) +: 4] = mosi_i;
            end
            #1;

            // $display("Got address 0x%h", address);

            begin : LATENCY
                integer latency;
                reg collision;
                
                collision = {$random} % 2;

                latency = LATENCY_COUNT - 3;

                clock_per = $time;
                wait(clk_i);
                wait(!clk_i);
                clock_per = $time - clock_per;
                half_clk = clock_per / 2;
                quarter_clk = half_clk / 2;

                while (latency != 0) begin
                    for (i = 0; i < latency; i = i + 1) begin
                        wait(!clk_i);
                        wait(clk_i);
                    end

                    // if (command == CMD_READ) begin
                    //     if (!collision) begin
                    //         latency = 0;
                    //     end
                    //     else begin
                    //         // $display("Refresh collision");
                    //         latency = LATENCY_COUNT;
                    //         collision = 0;
                    //     end
                    // end
                    // else begin
                    //     latency = 0;
                    // end
                    latency = 0;
                end
            end

            if (command == CMD_READ) begin : READ
                integer addr;
                integer delay;
                delay = {$random} % 6 + 1;

                // $display("Offset delay: %d ns", delay);

                for (i = 0; i < PRE_CYCLES; i = i + 1) begin
                    wait(clk_i);
                    #delay;
                    dqsm_o = 1;
                    
                    wait(!clk_i);
                    #delay;
                    dqsm_o = 0;
                end

                addr = address;

                wait(clk_i);
                #delay;
                dqsm_o = 1;

                miso_o = mem[addr][7:4];

                while (!cs_i) begin
                    wait(!clk_i || cs_i);
                    #delay;
                    dqsm_o = 0;

                    miso_o = mem[addr][3:0];
                    
                    wait(clk_i || cs_i);
                    #delay;
                    dqsm_o = 1;

                    $display("Read 0x%h from 0x%h", mem[addr], addr);

                    addr = addr + 1;

                    miso_o = mem[addr][7:4];
                end
            end
            else if (command == CMD_WRITE) begin : WRITE
                integer addr;
                reg [7:0] write_data;

                wait(!clk_i);
                wait(clk_i);

                addr = address;

                while (!cs_i) begin
                    wait(clk_i || cs_i);

                    if (!cs_i) begin
                        if (!dqsm_i) begin
                            mem[addr][7:4] = mosi_i;
                            write_data[7:4] = mosi_i;
                        end

                        wait(!clk_i);
                        if (!dqsm_i) begin
                            mem[addr][3:0] = mosi_i;
                            write_data[3:0] = mosi_i;
                        end

                        $display("Write 0x%h to 0x%h", write_data, addr);

                        addr = addr + 1;
                    end
                end
            end

            $display("DONE!");
        end
    end

endmodule
