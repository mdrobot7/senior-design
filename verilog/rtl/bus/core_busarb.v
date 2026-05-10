module core_busarb_m #(
    parameter MASTER_COUNT      = `NUM_CORES,
    parameter SLAVE_COUNT       = 1,
    parameter CROSSBARS         = 1
) (
    input  wire clk_i,
    input  wire nrst_i,

    input  wire [(`BUS_MOPORT_SIZE * MASTER_COUNT) - 1:0] mports_i,
    output wire [(`BUS_MIPORT_SIZE * MASTER_COUNT) - 1:0] mports_o,

    input  wire [(`BUS_SOPORT_SIZE * SLAVE_COUNT) - 1:0] sports_i,
    output wire [(`BUS_SIPORT_SIZE * SLAVE_COUNT) - 1:0] sports_o
);
    busarb_m #(MASTER_COUNT, SLAVE_COUNT, CROSSBARS) busarb(
        .clk_i(clk_i),
        .nrst_i(nrst_i),
        
        .mports_i(mports_i),
        .mports_o(mports_o),

        .sports_i(sports_i),
        .sports_o(sports_o)
    );
endmodule

