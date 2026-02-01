module dummy_core_m(
    input wire clk_i,
    input wire nrst_i,

    input  wire [`WORD] index_i,
    input  wire         run_i,

    input  wire [`STREAM_MIPORT(`SHADED_VERTEX_WIDTH)] mstream_i,
    output wire [`STREAM_MOPORT(`SHADED_VERTEX_WIDTH)] mstream_o
);



endmodule

module pre_rasterizer_tb();

    localparam CORE_COUNT = 3;

    wire clk, nrst;

    clk_rst_m clk_rst(
        .clk_o(clk),
        .nrst_o(nrst)
    );

    reg  [`WORD] cores_index [CORE_COUNT - 1:0];
    reg  cores_run [CORE_COUNT - 1:0];

    wire [`STREAM_MIPORT(`SHADED_VERTEX_WIDTH)] cores_mstreami [CORE_COUNT - 1:0];
    wire [`STREAM_MOPORT(`SHADED_VERTEX_WIDTH)] cores_mstreamo [CORE_COUNT - 1:0];

    reg svc_clear;

    reg  [`WORD] svc_test_index;
    reg  svc_test_valid;
    wire svc_test_found;

    reg  [`SHADED_VERTEX] svc_store_vertex;
    reg  [`WORD] svc_store_index;
    reg  svc_store_valid;

    wire [`STREAM_MIPORT(`SHADED_VERTEX_WIDTH)] svc_mstreami;
    wire [`STREAM_MOPORT(`SHADED_VERTEX_WIDTH)] svc_mstreamo;

    wire [`STREAM_MIPORT(`SHADED_VERTEX_WIDTH)] svf_mstreami;
    wire [`STREAM_MOPORT(`SHADED_VERTEX_WIDTH)] svf_mstreamo;

    generate
        genvar i;

        for (i = 0; i < CORE_COUNT; i = i + 1) begin
            dummy_core_m cores(
                .clk_i(clk),
                .nrst_i(nrst),

                .index_i(cores_index[i]),
                .run_i(cores_run[i]),

                .mstream_i(cores_mstreami[i]),
                .mstream_o(cores_mstreamo[i])
            );
        end
    endgenerate

    shaded_vertex_cache_m #(10) shaded_vertex_buffer(
        .clk_i(clk),
        .nrst_i(nrst),

        .clear_i(svc_clear),
        
        .test_index_i(svc_test_index),
        .test_valid_i(svc_test_valid),
        .test_found_o(svc_test_found),

        .store_vertex_i(svc_store_vertex),
        .store_index_i(svc_store_index),
        .store_valid_i(svc_store_valid),

        .mstream_i(svc_mstreami),
        .mstream_o(svc_mstreamo)
    );

    stream_fifo_m #(`SHADED_VERTEX_WIDTH, 10) shaded_vertex_fifo(
        .clk_i(clk),
        .nrst_i(nrst),

        .sstream_i(svc_mstreamo),
        .sstream_o(svc_mstreami),

        .mstream_i(svf_mstreami),
        .mstream_o(svf_mstreamo)
    );

    initial begin
        #1000;
        $finish;
    end

endmodule
