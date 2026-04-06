module dummy_core_m(
    input wire clk_i,
    input wire nrst_i,

    input  wire [`WORD] index_i,
    input  wire         valid_i,
    output reg          full_o,
    input  wire         run_i,

    input  wire [`STREAM_MIPORT(`SHADED_VERTEX_WIDTH)] mstream_i,
    output reg  [`STREAM_MOPORT(`SHADED_VERTEX_WIDTH)] mstream_o
);

    wire [`SHADED_VERTEX] lut[2:0];

    assign lut[0] = 0;
    assign lut[1] = 0;
    assign lut[2] = 0;

    reg [`WORD] index;

    always @(posedge clk_i, negedge nrst_i) begin
        if (nrst_i) begin
            full_o <= 0;

            mstream_o <= 0;

            index <= 0;
        end
        else if (clk_i) begin
            mstream_o[`STREAM_MO_VALID(`SHADED_VERTEX_WIDTH)] <= 0;

            if (valid_i && !full_o) begin
                index <= index_i;

                full_o <= 1;
            end

            if (run_i && full_o) begin
                mstream_o[`STREAM_MO_DATA(`SHADED_VERTEX_WIDTH)] <= lut[index];
                mstream_o[`STREAM_MO_VALID(`SHADED_VERTEX_WIDTH)] <= 1;
            end
        end
    end

endmodule

module pre_rasterizer_tb();

    localparam CORE_COUNT = 3;

    wire clk, nrst;

    clk_rst_m clk_rst(
        .clk_o(clk),
        .nrst_o(nrst)
    );

    reg  [`WORD] cores_index;
    reg  cores_valid [CORE_COUNT - 1:0];
    wire cores_full [CORE_COUNT - 1:0];
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

    wire [`STREAM_SIPORT(2)] vob_sstreami;
    wire [`STREAM_SOPORT(2)] vob_sstreamo;

    wire [`STREAM_MIPORT(2)] vob_mstreami;
    wire [`STREAM_MOPORT(2)] vob_mstreamo;

    generate
        genvar i;

        for (i = 0; i < CORE_COUNT; i = i + 1) begin
            dummy_core_m cores(
                .clk_i(clk),
                .nrst_i(nrst),

                .index_i(cores_index),
                .valid_i(cores_valid[i]),
                .full_o(cores_full[i]),
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

    stream_master_m #(2) order_master(
        .clk_i(clk),

        .mstream_i(vob_sstreamo),
        .mstream_o(vob_sstreami)
    );

    vertex_order_buffer_m #(10, 2) order_buffer(
        .clk_i(clk),
        .nrst_i(nrst),

        .sstream_i(vob_sstreami),
        .sstream_o(vob_sstreamo),

        .mstream_i(vob_mstreami),
        .mstream_o(vob_mstreamo)

        .clear_i(1'b0),
    );

    initial begin : MAIN
        integer i;

		$dumpfile("pre_rasterizer.vcd");
		$dumpvars(0, pre_rasterizer_tb);

        cores_index[i] = 0;

        for (i = 0; i < CORE_COUNT; i = i + 1) begin
            cores_valid[i] = 0;
        end

        svc_test_index = 0;
        svc_test_valid = 0;

        svc_store_vertex = 0;
        svc_store_index  = 0;
        svc_store_valid  = 0;

        #1000;
        $finish;
    end

    task QUEUE_VERTEX;
        input [`WORD] index;

        integer i;
    begin
        for (i = 0; i < CORE_COUNT; i = i + 1) begin
            if (!cores_full[i]) begin
                cores_index[i] = index;
                cores_valid[i] = 1;

                wait(!clk);
                wait(clk);

                cores[]
            end
        end
    end
    endtask

endmodule
