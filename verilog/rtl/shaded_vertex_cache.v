module shaded_vertex_cache_m #(
    parameter ENTRIES = 1
) (
    input wire clk_i,
    input wire nrst_i,

    input wire clear_i,

    input  wire         valid_i,
    input  wire [`WORD] index_i,

    input  wire [`STREAM_MIPORT(`WORD_WIDTH)] mstream_i,
    output wire [`STREAM_MOPORT(`WORD_WIDTH)] mstream_o
);

    reg         valid   [ENTRIES - 1:0];
    reg [`WORD] index   [ENTRIES - 1:0];

    always @(posedge clk_i, negedge nrst_i) begin
        if (!nrst_i) begin : RESET
            integer i;

            for (i = 0; i < ENTRIES; i = i + 1) begin
                valid[i]   <= 0;
                indices[i] <= 0;
            end
        end
        else if (clk_i) begin : CLOCK
            integer i;
            reg found;

            if (clear_i) begin
                for (i = 0; i < ENTRIES; i = i + 1) begin
                    valid[i]   <= 0;
                    indices[i] <= 0;
                end
            end
            else if (valid_i) begin
                found = 0;

                for (i = 0; i < ENTRIES; i = i + 1) begin
                    if (valid[i]) begin
                        if (index[i] == index_i) begin
                            found = 1;
                        end
                    end
                end
            end
        end
    end

endmodule