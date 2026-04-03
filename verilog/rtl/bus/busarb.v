module busarb_m #(
    parameter MASTER_COUNT      = 1,
    parameter SLAVE_COUNT       = 1,
    parameter CROSSBARS         = 1,
    parameter TIMER_TICK_CLOCKS = 1024
) (
    input  wire clk_i,
    input  wire nrst_i,

    input  wire [(`BUS_MOPORT_SIZE * MASTER_COUNT) - 1:0] mports_i,
    output reg  [(`BUS_MIPORT_SIZE * MASTER_COUNT) - 1:0] mports_o,

    input  wire [(`BUS_SOPORT_SIZE * SLAVE_COUNT) - 1:0] sports_i,
    output reg  [(`BUS_SIPORT_SIZE * SLAVE_COUNT) - 1:0] sports_o
);

    `DL_DEFINE(logger, "busarb_m", `DL_MAGENTA, 1);
    `DL_DEFINE(error,  "busarb_m ERROR", `DL_RED, 1);

    localparam STATE_READY = 2'b00;
    localparam STATE_REQ   = 2'b01;
    localparam STATE_ACK   = 2'b10;
    localparam STATE_DONE  = 2'b11;

    reg [1:0] state [CROSSBARS - 1:0];

    reg [MASTER_COUNT - 1:0] master_handled;
    reg [SLAVE_COUNT - 1:0]  slave_handled;

    reg [$clog2(MASTER_COUNT) - 1:0] master_sel [CROSSBARS - 1:0];
    reg [$clog2(SLAVE_COUNT) - 1:0]  slave_sel  [CROSSBARS - 1:0];

    reg [$clog2(CROSSBARS + 1) - 1:0] crossbar;

    reg [$clog2(TIMER_TICK_CLOCKS + 1) - 1:0] timer;

    always @(posedge clk_i, negedge nrst_i) begin
        if (!nrst_i) begin : RESET
            integer i;

            master_handled <= 0;
            slave_handled  <= 0;

            for (i = 0; i < CROSSBARS; i = i + 1) begin
                state[i] <= STATE_READY;

                master_sel[i] <= 0;
                slave_sel[i]  <= 0;
            end

            crossbar <= 0;

            timer <= 0;
        end
        else if (clk_i) begin : CLOCK
            integer cb;

            for (cb = 0; cb < CROSSBARS; cb = cb + 1) begin
                case (state[cb])
                    STATE_READY: begin : READY
                        integer i;

                        if (crossbar == cb) begin
                            for (i = MASTER_COUNT - 1; i >= 0; i = i - 1) begin
                                if (!master_handled[i] && mports_i[`BUS_MOPORT_SIZE * i + `BUS_MO_REQ]) begin
                                    state[cb] = STATE_REQ;

                                    master_sel[cb] = i;
                                end
                            end

                            if (state[cb] == STATE_REQ) begin
                                master_handled[master_sel[cb]] = 1;

                                `DL(logger, ("Master handled: port = %0d, crossbar = %0d", master_sel[cb], cb));
                            end
                        end
                    end

                    STATE_REQ: begin : REQ
                        integer i;

                        if (crossbar == cb) begin
                            for (i = SLAVE_COUNT - 1; i >= 0; i = i - 1) begin
                                if (!slave_handled[i] && sports_i[`BUS_SOPORT_SIZE * i + `BUS_SO_ACK]) begin
                                    state[cb] = STATE_ACK;

                                    slave_sel[cb] = i;
                                end
                            end

                            if (state[cb] == STATE_ACK) begin
                                slave_handled[slave_sel[cb]] = 1;

                                timer <= 0;

                                `DL(logger, ("Slave handled: port = %0d, crossbar = %0d", slave_sel[cb], cb));
                            end
                            else begin
                                if (timer == TIMER_TICK_CLOCKS) begin
                                    `DL(error, ("ACCESS TO UNASSIGNED ADDRESS! (0x%x)", mports_i[`BUS_MOPORT_SIZE * master_sel[cb] + `BUS_DATA_SIZE+:`BUS_ADDR_SIZE]));

                                    $finish;
                                end
                                else timer <= timer + 1;
                            end
                        end
                    end

                    STATE_ACK: begin
                        if (!sports_i[`BUS_SOPORT_SIZE * slave_sel[cb] + `BUS_SO_ACK]) begin
                            if (!mports_i[`BUS_MOPORT_SIZE * master_sel[cb] + `BUS_MO_REQ]) begin
                                state[cb] = STATE_DONE;
                            end
                        end
                    end

                    STATE_DONE: begin
                        slave_handled[slave_sel[cb]] = 0;
                        master_handled[master_sel[cb]] = 0;

                        state[cb] = STATE_READY;
                    end
                endcase
            end

            if (state[crossbar] == STATE_ACK) begin
                crossbar = 0;
                for (cb = CROSSBARS - 1; cb >= 0; cb = cb - 1) begin
                    if (state[cb] == STATE_READY) crossbar = cb;
                end
            end
        end
    end

    always @(*) begin : COMB
        integer cb;

        sports_o <= 0;
        mports_o <= 0;

        for (cb = 0; cb < CROSSBARS; cb = cb + 1) begin
            case (state[cb])
                default: ;

                STATE_REQ: begin : REQ_COMB
                    integer i;

                    for (i = 0; i < SLAVE_COUNT; i = i + 1) begin
                        if (!slave_handled[i]) begin
                            sports_o[`BUS_SIPORT_SIZE * i +: `BUS_SIPORT_SIZE]
                                <= mports_i[`BUS_MOPORT_SIZE * master_sel[cb] +: `BUS_MOPORT_SIZE];
                        end
                    end
                end

                STATE_ACK: begin
                    sports_o[`BUS_SIPORT_SIZE * slave_sel[cb] +: `BUS_SIPORT_SIZE]
                        <= mports_i[`BUS_MOPORT_SIZE * master_sel[cb] +: `BUS_MOPORT_SIZE];

                    mports_o[`BUS_MIPORT_SIZE * master_sel[cb] +: `BUS_MIPORT_SIZE]
                        <= sports_i[`BUS_SOPORT_SIZE * slave_sel[cb] +: `BUS_SOPORT_SIZE];
                end
            endcase
        end
    end

endmodule
