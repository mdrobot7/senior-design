/*
    VGA display emulation module, used for testing VGA output.
    Emulates 640x480 @ 60Hz with 8 bit color.
*/

module vga_display_m (
    input wire clk_i, // 640 x 480 pixel clock (24MHz)
    input wire nrst_i,

    input wire [7:0]color_i,
    input wire hsync_i,
    input wire vsync_i,

    output reg resolution_detected_o
);

    localparam H_ACTIVE = 10'd640;
    localparam H_FPORCH = 5'd16;
    localparam H_SYNC = 7'd64;
    localparam H_BPORCH = 7'd80;
    localparam H_TOTAL = H_ACTIVE + H_FPORCH + H_SYNC + H_BPORCH;
    localparam V_ACTIVE = 10'd480;
    localparam V_FPORCH = 2'd3;
    localparam V_SYNC = 3'd4;
    localparam V_BPORCH = 4'd6;
    localparam V_TOTAL = V_ACTIVE + V_FPORCH + V_SYNC + V_BPORCH;
    localparam H_SYNC_ACTIVE = 1'b1;
    localparam V_SYNC_ACTIVE = 1'b1;

    reg [7:0] screen[479:0][639:0];

    reg [9:0] h_counter;
    reg [9:0] v_counter;

    reg vsync_discovered;
    reg full_frame_done;
    reg resolution_good;

    integer i;

    always @ (posedge vsync_i) begin
        if (!vsync_discovered) begin
            vsync_discovered <= 1;
            h_counter <= 0;
            v_counter <= V_ACTIVE + V_FPORCH;
        end
    end

    always @ (posedge clk_i or negedge nrst_i) begin
        if(!nrst_i) begin
            h_counter <= 0;
            v_counter <= 0;
            resolution_detected_o <= 0;
            resolution_good <= 1;
            vsync_discovered <= 0;
            full_frame_done <= 0;
            for (i = 0; i < V_ACTIVE; i++) begin
                for (int j = 0; j < H_ACTIVE; j++)
                    screen[i][j] <= 0;
            end
        end
        else if (clk_i) begin
            // Counting starts at h = 0, v = VACTIVE + VFPORCH.
            // vsync_discovered takes 1 clock (1 pixel) to propogate.
            if (vsync_discovered) begin
                h_counter = h_counter + 1;
                if (h_counter <= H_ACTIVE)
                    screen[v_counter][h_counter - 1] = color_i;
                else if (h_counter > H_ACTIVE + H_FPORCH
                        && h_counter < H_ACTIVE + H_FPORCH + H_SYNC
                        && hsync_i != H_SYNC_ACTIVE) begin
                    resolution_good = 0; // Check HSYNC
                        end
                else if (h_counter >= H_TOTAL) begin
                    h_counter = 0;
                    v_counter = v_counter + 1;
                    if (v_counter >= V_TOTAL) begin
                        v_counter = 0;
                        if (full_frame_done)
                            resolution_detected_o = resolution_good;
                        else
                            full_frame_done = 1;
                    end
                end

                if (v_counter >= V_ACTIVE + V_FPORCH
                    && v_counter < V_ACTIVE + V_FPORCH + V_SYNC
                    && vsync_i != V_SYNC_ACTIVE) begin
                    // Running into some issues here with vsync/CLK changing
                    // at the same time, janky fix:
                    #1;
                    if (vsync_i != V_SYNC_ACTIVE)
                        resolution_good = 0; // Check VSYNC
                end
            end
        end
    end

endmodule
