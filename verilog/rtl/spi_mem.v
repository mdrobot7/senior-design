module spi_mem_m #(
    parameter ADDRESS = 0,
    parameter SIZE = 32
) (
    input wire clk_i,
    input wire nrst_i,

    input  wire [`BUS_SIPORT] sport_i,
    output reg  [`BUS_SOPORT] sport_o,

    output reg        spi_clk_o,
    output reg        spi_cs_o,
    output reg  [3:0] spi_mosi_o,
    input  wire [3:0] spi_miso_i,
    input  wire       spi_dqsm_i,
    output reg        spi_dqsm_o,

    output reg  [3:0] spi_sio_en_o,
    output reg        spi_dqsm_en_o
);

    localparam LATENCY_COUNT = 5;

    localparam CMD_READ          = 8'hA0;
    localparam CMD_WRITE         = 8'h20;

    localparam STATE_READY         = 5'h00;
    localparam STATE_COMMAND       = 5'h01;
    localparam STATE_COMMAND_WAIT  = 5'h02;
    localparam STATE_ADDRESS       = 5'h03;
    localparam STATE_READ_LATENCY  = 5'h04;
    localparam STATE_READ_WAIT     = 5'h05;
    localparam STATE_READ          = 5'h06;
    localparam STATE_READ_DELAY    = 5'h07;
    localparam STATE_WRITE_LATENCY = 5'h08;
    localparam STATE_WRITE         = 5'h09;
    localparam STATE_WRITE_DELAY   = 5'h0A;
    localparam STATE_DONE          = 5'h0B;
    localparam STATE_READY_DELAY   = 5'h0C;

    wire [`BUS_DATA_PORT] data_in;
    reg [`BUS_DATA_PORT] out_data;
    reg seqslv;
    assign data_in = sport_i[`BUS_SI_DATA];

    wire [`BUS_ADDR_PORT] bus_addr;
    assign bus_addr = sport_i[`BUS_SI_ADDR] - ADDRESS;

    reg [4:0] state;

    reg [7:0] command;

    reg [2:0]  address_nibble;
    reg [22:0] address;

    wire [31:0] full_address;
    assign full_address = {
        3'b000,
        address[21:9],
        2'b00,
        address[8:0],
        5'b00000
    };

    reg [5:0] latency;
    reg has_2lc;

    reg data_nibble;
    reg [1:0] data_byte;

    reg [`BUS_DATA_PORT] data_buf;
    reg data_ready;

    reg spi_clk;

    reg delayed_dqsm;
    reg [3:0] delayed_miso;

    always @(posedge clk_i, negedge nrst_i) begin
        if (!nrst_i) begin
            state <= STATE_READY;

            spi_mosi_o <= 0;

            out_data <= 0;
            seqslv   <= 0;

            command <= 0;

            address_nibble <= 7;
            address <= 0;

            latency <= 0;
            has_2lc <= 0;

            data_nibble <= 0;
            data_byte   <= 0;

            data_buf <= 0;
            data_ready <= 0;
        end
        else if (clk_i) begin
            seqslv <= 0;

            case (state)
                STATE_READY: begin
                    if (
                        sport_i[`BUS_SI_REQ] &&
                        bus_addr < SIZE &&
                        spi_clk
                    ) begin
                        state <= STATE_READY_DELAY;
                    end
                end

                STATE_READY_DELAY: begin
                    state <= STATE_COMMAND;

                    address_nibble <= 7;
                    address <= bus_addr;

                    if (sport_i[`BUS_SI_RW] == `BUS_READ) command = CMD_READ;
                    else command = CMD_WRITE;

                    spi_mosi_o <= command[4+:4];
                end

                STATE_COMMAND: begin
                    if (!spi_clk) begin
                        state <= STATE_COMMAND_WAIT;

                        spi_mosi_o <= command[0+:4];
                    end
                end

                STATE_COMMAND_WAIT: begin
                    state <= STATE_ADDRESS;

                    spi_mosi_o <= full_address[address_nibble * 4+:4];
                end

                STATE_ADDRESS: begin
                    if (address_nibble == 0) begin
                        if (sport_i[`BUS_SI_RW] == `BUS_READ) begin
                            state <= STATE_READ_LATENCY;

                            if (has_2lc) latency <= LATENCY_COUNT + LATENCY_COUNT - 2;
                            else latency <= LATENCY_COUNT - 2;
                        end
                        else begin
                            state <= STATE_WRITE_LATENCY;

                            if (has_2lc) latency <= LATENCY_COUNT + LATENCY_COUNT - 2;
                            else latency <= LATENCY_COUNT - 2;
                        end
                    end

                    if (address_nibble == 2) has_2lc <= spi_dqsm_i;

                    spi_mosi_o <= full_address[address_nibble * 4+:4];

                    address_nibble <= address_nibble - 1;
                end

                STATE_READ_LATENCY: begin
                    if (!spi_clk_o) begin
                        if (latency == 0) begin
                            state <= STATE_READ_WAIT;

                            data_nibble <= 1;
                            data_byte   <= 0;

                            data_buf    <= 0;
                            data_ready <= 0;
                        end
                        else begin
                            latency <= latency - 1;
                        end
                    end
                end

                STATE_READ_WAIT: begin
                    state <= STATE_READ;
                end

                STATE_READ: begin
                    data_ready <= 0;

                    data_buf[data_byte * 8 + data_nibble * 4+:4] <= delayed_miso;

                    if (data_nibble == 0) begin
                        case (sport_i[`BUS_SI_SIZE])
                            `BUS_SIZE_BYTE: begin
                                state <= STATE_READ_DELAY;
                            end

                            `BUS_SIZE_WORD: begin
                                if (data_byte == 3) begin
                                    state <= STATE_READ_DELAY;
                                end
                            end
                            
                            `BUS_SIZE_TWORD: begin
                            end

                            `BUS_SIZE_STREAM: begin
                                if (data_byte == 3) begin
                                    if (sport_i[`BUS_SI_SEQMST]) begin
                                        state <= STATE_READ_DELAY;
                                    end
                                    else begin
                                        data_ready <= 1;
                                    end
                                end
                            end
                        endcase

                        data_byte <= data_byte + 1;
                    end

                    if (data_ready) begin
                        seqslv <= 1;

                        out_data <= data_buf;
                    end

                    data_nibble <= !data_nibble;
                end

                STATE_READ_DELAY: begin
                    state <= STATE_DONE;

                    out_data <= data_buf;
                end

                STATE_WRITE_LATENCY: begin
                    if (!spi_clk_o) begin
                        if (latency == 0) begin
                            state <= STATE_WRITE;

                            data_nibble <= 0;
                            data_byte   <= 0;

                            data_buf   <= data_in;
                            data_ready <= 0;

                            spi_mosi_o <= data_in[7:4];
                        end
                        else begin
                            latency <= latency - 1;
                        end
                    end
                end

                STATE_WRITE: begin
                    if (data_nibble == 0) begin
                        case (sport_i[`BUS_SI_SIZE])
                            `BUS_SIZE_BYTE: begin
                                state <= STATE_WRITE_DELAY;
                            end

                            `BUS_SIZE_WORD: begin
                                if (data_byte == 3) state <= STATE_WRITE_DELAY;
                            end

                            // TODO: blah

                            `BUS_SIZE_STREAM: begin
                                if (data_byte == 2) begin
                                    seqslv <= 1;
                                end
                                else if (data_byte == 3) begin
                                    if (sport_i[`BUS_SI_SEQMST]) state <= STATE_WRITE_DELAY;
                                    else data_buf <= data_in;
                                end    
                            end
                        endcase

                        data_byte <= (data_byte + 1) % 4;
                    end

                    spi_mosi_o <= data_buf[data_byte * 8 + data_nibble * 4+:4];

                    data_nibble <= !data_nibble;
                end

                STATE_WRITE_DELAY: begin
                    state <= STATE_DONE;
                end

                STATE_DONE: begin
                    if (!sport_i[`BUS_SI_REQ]) state <= STATE_READY;
                end
            endcase
        end
    end

    wire nclk;
    assign nclk = !clk_i;

    always @(posedge nclk, negedge nrst_i) begin
        if (!nrst_i) begin
            spi_clk <= 0;
            delayed_dqsm <= 0;
            delayed_miso <= 0;
        end
        else if (nclk) begin
            spi_clk <= !spi_clk;

            delayed_dqsm <= spi_dqsm_i;
            delayed_miso <= spi_miso_i;
        end
    end

    always @(*) begin
        sport_o[`BUS_SO_DATA] <= out_data;
        sport_o[`BUS_SO_SEQSLV] <= seqslv;

        case (state)
            STATE_READY, STATE_DONE: begin
                sport_o[`BUS_SO_ACK] <= 0;

                spi_cs_o <= 1;
                spi_clk_o <= 0;
            end

            STATE_READY_DELAY: begin
                sport_o[`BUS_SO_ACK] <= 1;
                
                spi_cs_o <= 0;
                spi_clk_o <= 0;
            end

            default: begin
                sport_o[`BUS_SO_ACK] <= 1;
                
                spi_cs_o <= 0;
                spi_clk_o <= spi_clk;
            end
        endcase

        case (state)
            STATE_READY_DELAY, STATE_COMMAND, STATE_COMMAND_WAIT, STATE_ADDRESS, STATE_READ_LATENCY, STATE_READ_WAIT, STATE_READ, STATE_READ_DELAY, STATE_WRITE_LATENCY: begin
                spi_dqsm_en_o <= 1;
            end

            default: begin
                spi_dqsm_en_o <= 0;
            end
        endcase

        case (state)
            STATE_READ_WAIT, STATE_READ, STATE_READ_DELAY: begin
                spi_sio_en_o <= 4'hF;
            end

            default: begin
                spi_sio_en_o <= 4'h0;
            end
        endcase

        case (state)
            STATE_WRITE, STATE_WRITE_DELAY: spi_dqsm_o <= 0;

            default: spi_dqsm_o <= 1;
        endcase
    end

endmodule
