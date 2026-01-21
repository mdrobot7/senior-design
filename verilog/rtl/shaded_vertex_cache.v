module shaded_vertex_cache_m #(
    parameter ENTRIES = 1
) (
    input wire clk_i,
    input wire nrst_i,

    input wire clear_i,

    input  wire [`WORD] test_index_i,
    input  wire         test_valid_i,
    output wire         test_found_o,

    input  wire [`SHADED_VERTEX] store_vertex_i,
    input  wire [`WORD]          store_index_i,
    input  wire                  store_valid_i,

    input  wire [`STREAM_MIPORT(`SHADED_VERTEX_WIDTH)] mstream_i,
    output reg  [`STREAM_MOPORT(`SHADED_VERTEX_WIDTH)] mstream_o
);

    localparam ENTRY_INDEX_WIDTH = $clog2(ENTRIES);

    reg [ENTRY_INDEX_WIDTH - 1:0] current_entry;

    reg                  valid   [ENTRIES - 1:0];
    reg [`WORD]          index   [ENTRIES - 1:0];
    reg [`SHADED_VERTEX] vertex  [ENTRIES - 1:0];

    reg                           found;
    reg [ENTRY_INDEX_WIDTH - 1:0] found_index;

    assign test_found_o = found;

    always @(*) begin : FOUND_COMB
        integer i;

        found <= 0;
        found_index <= 0;

        for (i = 0; i < ENTRIES; i = i + 1) begin
            if (valid[i]) begin
                if (index[i] == test_index_i) begin
                    found <= 1;
                    found_index <= i;
                end
            end
        end
    end

    always @(*) begin
        mstream_o[`STREAM_MO_DATA(`SHADED_VERTEX_WIDTH)] <= vertex[found_index];
        mstream_o[`STREAM_MO_LAST(`SHADED_VERTEX_WIDTH)] <= 0;
        mstream_o[`STREAM_MO_VALID(`SHADED_VERTEX_WIDTH)] <= test_valid_i && found;
    end

    always @(posedge clk_i, negedge nrst_i) begin
        if (!nrst_i) begin : RESET
            integer i;

            current_entry <= 0;

            for (i = 0; i < ENTRIES; i = i + 1) begin
                valid[i]  <= 0;
                index[i]  <= 0;
                vertex[i] <= 0;
            end
        end
        else if (clk_i) begin : CLOCK
            integer i;

            if (clear_i) begin
                for (i = 0; i < ENTRIES; i = i + 1) begin
                    valid[i] <= 0;
                end
            end
            if (store_valid_i) begin
                valid[current_entry]  <= 1;
                index[current_entry]  <= store_index_i;
                vertex[current_entry] <= store_vertex_i;

                current_entry <= (current_entry + 1) % ENTRIES;
            end
        end
    end

endmodule