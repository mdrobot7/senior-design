module wavg_pipe_in_m(
    input wire clk_i,
    input wire nrst_i,

    input wire [3:0] user_count_i,

    input  wire [`STREAM_SIPORT(`RAST_DT_OUT_WIDTH)] sstream_i,
    output reg  [`STREAM_SOPORT(`RAST_DT_OUT_WIDTH)] sstream_o,

    input  wire [`STREAM_MIPORT(2 * `SC_WIDTH)] mstream_i,
    output reg  [`STREAM_MOPORT(2 * `SC_WIDTH)] mstream_o,

    input wire [`WORD_WIDTH - 1:0] t0x,
    input wire [`WORD_WIDTH - 1:0] t0y,
    input wire [`WORD_WIDTH - 1:0] t1x,
    input wire [`WORD_WIDTH - 1:0] t1y,
    input wire [`WORD_WIDTH - 1:0] t2x,
    input wire [`WORD_WIDTH - 1:0] t2y,

    input wire signed [`WORD_WIDTH - 1:0] v0z,
    input wire signed [`WORD_WIDTH - 1:0] v1z,
    input wire signed [`WORD_WIDTH - 1:0] v2z,

    input wire [`WORD] u0a_i,
    input wire [`WORD] u0b_i,
    input wire [`WORD] u0c_i,
    input wire [`WORD] u0d_i,
    input wire [`WORD] u0e_i,
    input wire [`WORD] u0f_i,

    input wire [`WORD] u1a_i,
    input wire [`WORD] u1b_i,
    input wire [`WORD] u1c_i,
    input wire [`WORD] u1d_i,
    input wire [`WORD] u1e_i,
    input wire [`WORD] u1f_i,

    input wire [`WORD] u2a_i,
    input wire [`WORD] u2b_i,
    input wire [`WORD] u2c_i,
    input wire [`WORD] u2d_i,
    input wire [`WORD] u2e_i,
    input wire [`WORD] u2f_i,

    input  wire [`STREAM_MIPORT(`LERPINATOR_IN_WIDTH)] lerp_mstream_i,
    output wire [`STREAM_MOPORT(`LERPINATOR_IN_WIDTH)] lerp_mstream_o
);

    wire [`RAST_DT_OUT_WIDTH - 1:0] in_data;
    assign in_data = sstream_i[`STREAM_SI_DATA(`RAST_DT_OUT_WIDTH)];

    reg signed [`WORD] l0, l1, l2;

    reg signed [`WORD] lerp0, lerp1, lerp2;

    reg lerp_valid;
    wire lerp_ready;
    reg [`LERPINATOR_IN] lerp_data;
    
    assign lerp_mstream_o[`STREAM_MO_VALID(`LERPINATOR_IN_WIDTH)] = lerp_valid;
    assign lerp_mstream_o[`STREAM_MO_DATA(`LERPINATOR_IN_WIDTH)] = lerp_data;
    assign lerp_mstream_o[`STREAM_MO_LAST(`LERPINATOR_IN_WIDTH)] = 0;
    assign lerp_ready = lerp_mstream_i[`STREAM_MI_READY(`LERPINATOR_IN_WIDTH)];

    reg [3:0] state;
    reg [3:0] next_state;

    always @(posedge clk_i, negedge nrst_i) begin
        if (!nrst_i) begin
            state <= 0;
        end
        else if (clk_i) begin
            if (state == 0) begin
                { l0, l1, l2 } <= in_data;
            end

            state <= next_state;
        end
    end

    always @(*) begin
        next_state = state;

        sstream_o = 0;

        mstream_o = 0;
        mstream_o[`STREAM_MO_DATA(2 * `SC_WIDTH)] = in_data[3 * `WORD_WIDTH+:2 * `SC_WIDTH];

        lerp_valid = 0;
        lerp_data = 0;

        case (state)
            0: begin
                if (
                    sstream_i[`STREAM_SI_VALID(`RAST_DT_OUT_WIDTH)] &&
                    mstream_i[`STREAM_MI_READY(2 * `SC_WIDTH)]
                ) begin
                    sstream_o[`STREAM_SO_READY(`RAST_DT_OUT_WIDTH)] = 1;
                    mstream_o[`STREAM_MO_VALID(2 * `SC_WIDTH)] = 1;

                    next_state = state + 1;
                end
            end

            1: begin
                lerp_valid = 1;
                lerp_data = `LERPINATOR_IN_PACKET(l0, l1, l2, t0x, t1x, t2x);
            end

            2: begin
                lerp_valid = 1;
                lerp_data = `LERPINATOR_IN_PACKET(l0, l1, l2, t0y, t1y, t2y);
            end

            3: begin
                lerp_valid = 1;
                lerp_data = `LERPINATOR_IN_PACKET(l0, l1, l2, u0a_i, u1a_i, u2a_i);
            end

            4: begin
                lerp_valid = 1;
                lerp_data = `LERPINATOR_IN_PACKET(l0, l1, l2, u0b_i, u1b_i, u2b_i);
            end

            5: begin
                lerp_valid = 1;
                lerp_data = `LERPINATOR_IN_PACKET(l0, l1, l2, u0c_i, u1c_i, u2c_i);
            end

            6: begin
                lerp_valid = 1;
                lerp_data = `LERPINATOR_IN_PACKET(l0, l1, l2, u0d_i, u1d_i, u2d_i);
            end

            7: begin
                lerp_valid = 1;
                lerp_data = `LERPINATOR_IN_PACKET(l0, l1, l2, u0e_i, u1e_i, u2e_i);
            end

            8: begin
                lerp_valid = 1;
                lerp_data = `LERPINATOR_IN_PACKET(l0, l1, l2, u0f_i, u1f_i, u2f_i);

                if (lerp_ready) begin
                    next_state = 0;
                end
            end
        endcase

        case (state)
            1, 2, 3, 4, 5, 6, 7: begin
                if (lerp_ready) begin
                    if (state == user_count_i + 2) begin
                        next_state = 0;
                    end
                    else begin
                        next_state = state + 1;
                    end
                end
            end
        endcase
    end

endmodule
