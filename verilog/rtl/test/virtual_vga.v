`define VIRTUAL_VGA_MAX_BUFFER_SIZE (3000000)
`define VIRTUAL_VGA_MAX_COLOR_SIZE (64)

`define COLOR_TYPE_RGB332 (1)
`define COLOR_TYPE_GSW (2)

`define COLOR_SIZE(color) (((color) == `COLOR_TYPE_RGB332) ? 8 : (((color) == `COLOR_TYPE_GSW) ? 32 : 1))

`define VGA_WRITE(path, in_buffer, offset, width, height, color_type) \
    begin : VGA_WRITE_PROC_`__LINE__ \
        integer i; \
        reg [`VIRTUAL_VGA_MAX_BUFFER_SIZE - 1:0] flat_buffer; \
        \
        for (i = 0; i < (width) * (height) * `COLOR_SIZE((color_type)) / 8; i = i + 1) begin \
            flat_buffer[i * 8+:8] = { \
                in_buffer[offset + i][0], \
                in_buffer[offset + i][1], \
                in_buffer[offset + i][2], \
                in_buffer[offset + i][3], \
                in_buffer[offset + i][4], \
                in_buffer[offset + i][5], \
                in_buffer[offset + i][6], \
                in_buffer[offset + i][7] \
            }; \
        end \
        \
        begin : MAIN \
            integer fd; \
            integer WIDTH; \
            integer HEIGHT; \
            integer COLOR_TYPE; \
            reg [`VIRTUAL_VGA_MAX_BUFFER_SIZE - 1:0] buffer; \
            reg [31:0] size_bytes; \
            reg [31:0] image_offset; \
 \
            fd = $fopen((path), "wb"); \
            WIDTH = (width); \
            HEIGHT = (height); \
            COLOR_TYPE = (color_type); \
            buffer = flat_buffer; \
 \
            size_bytes = 14 + 12 + WIDTH * HEIGHT * 3; \
            image_offset = 14 + 12; \
 \
            $fwrite(fd, "BM%c%c%c%c%c%c%c%c%c%c%c%c", size_bytes[7:0], size_bytes[15:8], size_bytes[23:16], size_bytes[31:24], 0, 0, 0, 0, image_offset[7:0], image_offset[15:8], image_offset[23:16], image_offset[31:24]); \
 \
            $fwrite(fd, "%c%c%c%c%c%c%c%c%c%c%c%c", 8'h0C, 0, 0, 0, WIDTH[7:0], WIDTH[15:8], HEIGHT[7:0], HEIGHT[15:8], 1, 0, 24, 0); \
 \
            begin : DRAW_IMAGE \
                integer x, y; \
 \
                for (y = 0; y < HEIGHT; y = y + 1) begin \
                    for (x = 0; x < WIDTH; x = x + 1) begin : INNER_2 \
                        integer i, j; \
                        reg [`VIRTUAL_VGA_MAX_COLOR_SIZE - 1:0] color; \
                        reg [7:0] r, g, b; \
 \
                        for (i = 0; i < `COLOR_SIZE(COLOR_TYPE) / 8; i = i + 1) begin \
                            for (j = 0; j < 8; j = j + 1) begin \
                                color[7 - j + i * 8] = buffer[(y * WIDTH + x) * `COLOR_SIZE(COLOR_TYPE) + i * 8 + j]; \
                            end \
                        end \
 \
                        case (COLOR_TYPE) \
                            `COLOR_TYPE_RGB332: begin \
                                r = color[2:0] * 255.0 / 7.0; \
                                g = color[5:3] * 255.0 / 7.0; \
                                b = color[7:6] * 255.0 / 3.0; \
                            end \
 \
                            `COLOR_TYPE_GSW: begin : GSW \
                                reg [31:0] abs; \
                                if ($signed(color) < 0) abs = -$signed(color); \
                                else abs = color; \
                                abs = color; \
                                r = abs[31:24]; \
                                g = r; \
                                b = r; \
                            end \
                        endcase \
 \
                        begin : WRITE \
                            $fwrite(fd, "%c%c%c", b, g, r); \
                        end \
                    end \
                end \
            end \
 \
            $fclose(fd); \
        end \
    end
