module pre_rasterizer_m(
    input wire clk_i,
    input wire nrst_i,

    output wire vob_full_o,
    output wire vob_empty_o,
    input  wire vob_clear_i,

    output wire vrc_busy_o,

    input  wire [`STREAM_SIPORT(`VERTEX_ORDER_WIDTH)] order_sstream_i,
    output wire [`STREAM_SOPORT(`VERTEX_ORDER_WIDTH)] order_sstream_o,

    input  wire [(`STREAM_SIPORT_SIZE(`MAILBOX_STREAM_SIZE) * `NUM_CORES)-1:0] outbox_sstream_i,
    output wire [(`STREAM_SOPORT_SIZE(`MAILBOX_STREAM_SIZE) * `NUM_CORES)-1:0] outbox_sstream_o,

    input  wire [`STREAM_MIPORT(3 * `SHADED_VERTEX_WIDTH)] mstream_i,
    output wire [`STREAM_MOPORT(3 * `SHADED_VERTEX_WIDTH)] mstream_o
);

    wire [(`STREAM_MIPORT_SIZE(`SHADED_VERTEX_WIDTH) * `NUM_CORES)-1:0] core_deser_mstreami;
    wire [(`STREAM_MOPORT_SIZE(`SHADED_VERTEX_WIDTH) * `NUM_CORES)-1:0] core_deser_mstreamo;

    wire [`STREAM_MIPORT(`VERTEX_ORDER_WIDTH)] vob_mstreami;
    wire [`STREAM_MOPORT(`VERTEX_ORDER_WIDTH)] vob_mstreamo;

    wire [`STREAM_MIPORT(`SHADED_VERTEX_WIDTH)] svb_mstreami;
    wire [`STREAM_MOPORT(`SHADED_VERTEX_WIDTH)] svb_mstreamo;

    assign svb_mstreamo = 0;

    vertex_deserializer_m core_deserializer [`NUM_CORES-1:0] (
        .clk_i(clk_i),
        .nrst_i(nrst_i),

        .sstream_i(outbox_sstream_i),
        .sstream_o(outbox_sstream_o),

        .mstream_i(core_deser_mstreami),
        .mstream_o(core_deser_mstreamo)
    );

    vertex_order_buffer_m #(`VOB_SIZE, `VERTEX_ORDER_WIDTH) vob(
        .clk_i(clk_i),
        .nrst_i(nrst_i),

        .sstream_i(order_sstream_i),
        .sstream_o(order_sstream_o),

        .mstream_i(vob_mstreami),
        .mstream_o(vob_mstreamo),

        .full_o(vob_full_o),
        .empty_o(vob_empty_o),
        .clear_i(vob_clear_i)
    );

    vertex_reorder_controller_m #(`NUM_CORES + 1) vrc(
        .clk_i(clk_i),
        .nrst_i(nrst_i),

        .busy_o(vrc_busy_o),

        .order_sstream_i(vob_mstreamo),
        .order_sstream_o(vob_mstreami),

        .sstreams_i({ svb_mstreamo, core_deser_mstreamo }),
        .sstreams_o({ svb_mstreami, core_deser_mstreami }),

        .mstream_i(mstream_i),
        .mstream_o(mstream_o),

        .svc_store_vertex_o(),
        .svc_store_valid_o()
    );

endmodule
