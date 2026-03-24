module vertex_reorder_controller_m #(
    parameter INPUT_COUNT = 4,

    parameter INPUT_INDEX_WIDTH = $clog2(INPUT_COUNT)
) (
    input  wire clk_i,
    input  wire nrst_i,

    input  wire [`STREAM_SIPORT(INPUT_INDEX_WIDTH)] order_sstream_i,
    output wire [`STREAM_SOPORT(INPUT_INDEX_WIDTH)] order_sstream_o,

    input  wire [(`STREAM_SIPORT_SIZE(`SHADED_VERTEX_WIDTH) * INPUT_COUNT) - 1:0] sstreams_i,
    output wire [(`STREAM_SOPORT_SIZE(`SHADED_VERTEX_WIDTH) * INPUT_COUNT) - 1:0] sstreams_o,

    output wire [`STREAM_MIPORT(`SHADED_VERTEX_WIDTH * 3)] mstream_i,
    output wire [`STREAM_MOPORT(`SHADED_VERTEX_WIDTH * 3)] mstream_o,

    output reg [`SHADED_VERTEX] svc_store_vertex_o,
    output reg svc_store_valid_o
);

    wire [`STREAM_SIPORT(`SHADED_VERTEX_WIDTH)] sstreamsi [INPUT_COUNT - 1:0];
    reg  [`STREAM_SOPORT(`SHADED_VERTEX_WIDTH)] sstreamso [INPUT_COUNT - 1:0];
    
    generate begin : STREAMS_GEN
        genvar i;

        for (i = 0; i < INPUT_COUNT; i = i + 1) begin
            assign sstreamsi[i] = sstreams_i[`STREAM_SIPORT_SIZE(`SHADED_VERTEX_WIDTH) * i +: `STREAM_SIPORT_SIZE(`SHADED_VERTEX_WIDTH)];
            assign sstreams_o[`STREAM_SOPORT_SIZE(`SHADED_VERTEX_WIDTH) * i +: `STREAM_SOPORT_SIZE(`SHADED_VERTEX_WIDTH)] = sstreamso[i];
        end
    end endgenerate

    wire [INPUT_INDEX_WIDTH - 1:0] order_index;
    assign order_index = order_sstream_i[`STREAM_SI_DATA(INPUT_INDEX_WIDTH)];

    reg  [`STREAM_SIPORT(`SHADED_VERTEX_WIDTH)] sstreami;
    wire [`STREAM_SOPORT(`SHADED_VERTEX_WIDTH)] sstreamo;

    always @(*) begin : INDEXED_STREAMS_GEN
        integer i;

        sstreami <= sstreamsi[order_index];

        for (i = 0; i < INPUT_COUNT; i = i + 1) begin
            if (i == order_index) sstreamso[i] <= sstreamo;
            else sstreamso[i] <= 0;
        end
    end

    wire [`SHADED_VERTEX] in_vert;
    wire in_valid;
    wire in_ready;

    assign in_vert  = sstreami[`STREAM_SI_DATA(`SHADED_VERTEX_WIDTH)];
    assign in_valid = sstreami[`STREAM_SI_VALID(`SHADED_VERTEX_WIDTH)] && order_sstream_i[`STREAM_SI_VALID(INPUT_INDEX_WIDTH)];

    assign order_sstream_o[`STREAM_SO_READY(INPUT_INDEX_WIDTH)] = in_ready && in_valid;
    assign sstreamo[`STREAM_SO_READY(`SHADED_VERTEX_WIDTH)] = in_ready && in_valid;

    localparam VERT_V0   = 2'h0;
    localparam VERT_V1   = 2'h1;
    localparam VERT_V2   = 2'h2;
    localparam VERT_DONE = 2'h3;

    reg [1:0] current_vertex;
    reg [`SHADED_VERTEX] v0, v1, v2;

    assign mstream_o[`STREAM_MO_DATA(`SHADED_VERTEX_WIDTH * 3)] = { v0, v1, v2 };

    assign mstream_o[`STREAM_MO_VALID(`SHADED_VERTEX_WIDTH * 3)] = current_vertex == VERT_DONE;
    assign mstream_o[`STREAM_MO_LAST(`SHADED_VERTEX_WIDTH * 3)] = 0;

    assign in_ready = current_vertex != VERT_DONE;

    always @(posedge clk_i, negedge nrst_i) begin
        if (!nrst_i) begin
            current_vertex <= VERT_V0;

            v0 <= 0;
            v1 <= 0;
            v2 <= 0;
        end
        else if (clk_i) begin : CLOCK
            case (current_vertex)
                VERT_V0: begin
                    if (in_valid) begin
                        v0 <= in_vert;

                        current_vertex <= VERT_V1;
                    end
                end

                VERT_V1: begin
                    if (in_valid) begin
                        v1 <= in_vert;

                        current_vertex <= VERT_V2;
                    end
                end

                VERT_V2: begin
                    if (in_valid) begin
                        v2 <= in_vert;

                        current_vertex <= VERT_DONE;
                    end
                end

                VERT_DONE: begin
                    if (mstream_i[`STREAM_MI_READY(`SHADED_VERTEX_WIDTH * 3)]) begin
                        current_vertex <= VERT_V0;
                    end
                end
            endcase
        end
    end

    always @(*) begin
        svc_store_vertex_o <= in_vert;

        if (in_valid && current_vertex != VERT_DONE) begin
            svc_store_valid_o <= 1;
        end
        else begin
            svc_store_valid_o <= 0;
        end
    end

endmodule
