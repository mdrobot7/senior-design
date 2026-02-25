module integration_tb();

    wire clk, nrst;

    clk_rst_m clk_rst(
        .clk_o(clk),
        .nrst_o(nrst)
    );

    localparam WORD_WIDTH = 32;
    localparam WIDTH = 320;
    localparam HEIGHT = 240;

    localparam SC_WIDTH = $clog2(WIDTH > HEIGHT ? WIDTH : HEIGHT);

    wire [`BUS_MIPORT] mportai;
    wire [`BUS_MOPORT] mportao;
    wire [`BUS_MIPORT] mportbi;
    wire [`BUS_MOPORT] mportbo;
    wire [`BUS_MIPORT] mportci;
    wire [`BUS_MOPORT] mportco;
    wire [`BUS_MIPORT] mportdi;
    wire [`BUS_MOPORT] mportdo;
    wire [`BUS_MIPORT] mportei;
    wire [`BUS_MOPORT] mporteo;

    wire [`BUS_SIPORT] sportai;
    wire [`BUS_SOPORT] sportao;
    wire [`BUS_SIPORT] sportbi;
    wire [`BUS_SOPORT] sportbo;

    wire spi1_clk;
    wire spi1_cs;
    wire [3:0] spi1_mosi;
    wire [3:0] spi1_miso;
    wire spi1_dqsmi;
    wire spi1_dqsmo;

    wire spi2_clk;
    wire spi2_cs;
    wire [3:0] spi2_mosi;
    wire [3:0] spi2_miso;
    wire spi2_dqsmi;
    wire spi2_dqsmo;

    spi_chip_m #(5, 1, 500000) spi_chip1(
        .clk_i(spi1_clk),
        .cs_i(spi1_cs),
        .mosi_i(spi1_mosi),
        .miso_o(spi1_miso),
        .dqsm_o(spi1_dqsmi),
        .dqsm_i(spi1_dqsmo)
    );

    spi_chip_m #(5, 1, 500000) spi_chip2(
        .clk_i(spi2_clk),
        .cs_i(spi2_cs),
        .mosi_i(spi2_mosi),
        .miso_o(spi2_miso),
        .dqsm_o(spi2_dqsmi),
        .dqsm_i(spi2_dqsmo)
    );

    wire [`BUS_MIPORT] vga_mporti;
    wire [`BUS_MOPORT] vga_mporto;

    wire [`BUS_MIPORT] rast1_mporti;
    wire [`BUS_MOPORT] rast1_mporto;

    wire [`BUS_MIPORT] rast2_mporti;
    wire [`BUS_MOPORT] rast2_mporto;

    wire [`BUS_MIPORT] core_mporti;
    wire [`BUS_MOPORT] core_mporto;

    wire [`BUS_MIPORT] write_mporti;
    wire [`BUS_MOPORT] write_mporto;

    wire [`BUS_SIPORT] spi1_sporti;
    wire [`BUS_SOPORT] spi1_sporto;

    wire [`BUS_SIPORT] spi2_sporti;
    wire [`BUS_SOPORT] spi2_sporto;

    reg  [`WORD] inst;

    reg  [`WORD] global_r1, global_r2;

    wire jump_request;
    reg  fds;

    reg  stalli;
    wire stallo;

    reg nsync_rst;

    wire [`STREAM_MIPORT(`MAILBOX_STREAM_SIZE)] cc_mstreami;
    reg  [`STREAM_MOPORT(`MAILBOX_STREAM_SIZE)] cc_mstreamo;

    wire [`STREAM_MIPORT(`MAILBOX_STREAM_SIZE)] core_mstreami;
    wire [`STREAM_MOPORT(`MAILBOX_STREAM_SIZE)] core_mstreamo;

    wire [`STREAM_MIPORT(`SHADED_VERTEX_WIDTH)] core_deser_mstreami;
    wire [`STREAM_MOPORT(`SHADED_VERTEX_WIDTH)] core_deser_mstreamo;

    reg svc_clear;

    reg  [`WORD] test_index;
    reg  test_valid;
    wire test_found;

    wire [`SHADED_VERTEX] store_vertex;
    reg  [`WORD] store_index;
    wire store_valid;

    wire [`STREAM_MIPORT(`SHADED_VERTEX_WIDTH)] svc_mstreami;
    wire [`STREAM_MOPORT(`SHADED_VERTEX_WIDTH)] svc_mstreamo;
    wire [`STREAM_MIPORT(`SHADED_VERTEX_WIDTH)] svb_mstreami;
    wire [`STREAM_MOPORT(`SHADED_VERTEX_WIDTH)] svb_mstreamo;

    wire [`STREAM_MIPORT(1)] order_mstreami;
    wire [`STREAM_MOPORT(1)] order_mstreamo;
    wire [`STREAM_MIPORT(1)] vob_mstreami;
    wire [`STREAM_MOPORT(1)] vob_mstreamo;

    wire [`STREAM_MIPORT(3 * `SHADED_VERTEX_WIDTH)] vrc_mstreami;
    wire [`STREAM_MOPORT(3 * `SHADED_VERTEX_WIDTH)] vrc_mstreamo;

    wire [`STREAM_MIPORT(`FRAGMENT_WIDTH)] frag_mstreami;
    wire [`STREAM_MOPORT(`FRAGMENT_WIDTH)] frag_mstreamo;

    busarb_m #(5, 2, 2) arbiter(
        .clk_i(clk),
        .nrst_i(nrst),

        .mports_i({ write_mporto, core_mporto, rast2_mporto, rast1_mporto, vga_mporto }),
        .mports_o({ write_mporti, core_mporti, rast2_mporti, rast1_mporti, vga_mporti }),

        .sports_i({ spi1_sporto, spi2_sporto }),
        .sports_o({ spi1_sporti, spi2_sporti })
    );

    spi_mem_m #(0, `SPI_MEM_SIZE) spi_mem1(
        .clk_i(clk),
        .nrst_i(nrst),

        .sport_i(spi1_sporti),
        .sport_o(spi1_sporto),

        .spi_clk_o(spi1_clk),
        .spi_cs_o(spi1_cs),
        .spi_mosi_o(spi1_mosi),
        .spi_miso_i(spi1_miso),
        .spi_dqsm_i(spi1_dqsmi),
        .spi_dqsm_o(spi1_dqsmo)
    );

    spi_mem_m #(`SPI_MEM_SIZE, `SPI_MEM_SIZE) spi_mem2(
        .clk_i(clk),
        .nrst_i(nrst),

        .sport_i(spi2_sporti),
        .sport_o(spi2_sporto),

        .spi_clk_o(spi2_clk),
        .spi_cs_o(spi2_cs),
        .spi_mosi_o(spi2_mosi),
        .spi_miso_i(spi2_miso),
        .spi_dqsm_i(spi2_dqsmi),
        .spi_dqsm_o(spi2_dqsmo)
    );

    core_m core(
        .clk_i(clk),
        .nrst_i(nrst),

        .inst_i(inst),
        .global_r1_data_i(global_r1),
        .global_r2_data_i(global_r2),

        .jump_request_o(jump_request),
        .flush_dec_stage_i(fds),
        
        .stall_i(stalli),
        .stall_o(stallo),

        .nsync_rst_i(nsync_rst),

        .inbox_sstream_i(cc_mstreamo),
        .inbox_sstream_o(cc_mstreami),

        .outbox_mstream_i(core_mstreami),
        .outbox_mstream_o(core_mstreamo),
        
        .mport_i(core_mporti),
        .mport_o(core_mporto)
    );

    vertex_deserializer_m core_deserializer(
        .clk_i(clk),
        .nrst_i(nrst),

        .sstream_i(core_mstreamo),
        .sstream_o(core_mstreami),

        .mstream_i(core_deser_mstreami),
        .mstream_o(core_deser_mstreamo)
    );

    assign store_valid = core_deser_mstreamo[`STREAM_MO_VALID(`SHADED_VERTEX_WIDTH)];
    assign store_vertex = core_deser_mstreamo[`STREAM_MO_DATA(`SHADED_VERTEX_WIDTH)];

    shaded_vertex_cache_m #(6) svc(
        .clk_i(clk),
        .nrst_i(nrst),

        .clear_i(svc_clear),

        .test_index_i(test_index),
        .test_valid_i(test_valid),
        .test_found_o(test_found),

        .store_vertex_i(store_vertex),
        .store_index_i(store_index),
        .store_valid_i(store_valid),

        .mstream_i(svc_mstreami),
        .mstream_o(svc_mstreamo)
    );

    stream_fifo_m #(`SHADED_VERTEX_WIDTH, 10) svb(
        .clk_i(clk),
        .nrst_i(nrst),

        .sstream_i(svc_mstreamo),
        .sstream_o(svc_mstreami),

        .mstream_i(svb_mstreami),
        .mstream_o(svb_mstreamo)
    );

    stream_master_m #(1) order_master(
        .clk_i(clk),

        .mstream_i(order_mstreami),
        .mstream_o(order_mstreamo)
    );

    vertex_order_buffer_m #(6, 1) vob(
        .clk_i(clk),
        .nrst_i(nrst),
        
        .sstream_i(order_mstreamo),
        .sstream_o(order_mstreami),

        .mstream_i(vob_mstreami),
        .mstream_o(vob_mstreamo),

        .full_o(),
        .empty_o()
    );

    vertex_reorder_controller_m #(2) vrc(
        .clk_i(clk),
        .nrst_i(nrst),

        .order_sstream_i(vob_mstreamo),
        .order_sstream_o(vob_mstreami),

        .sstreams_i({ svb_mstreamo, core_deser_mstreamo }),
        .sstreams_o({ svb_mstreami, core_deser_mstreami }),

        .mstream_i(vrc_mstreami),
        .mstream_o(vrc_mstreamo)
    );

    rasterizer_wrapper_m rasterizer(
        .wb_clk_i(clk),
        .wb_rst_i(!nrst),
        .wbs_stb_i(1'b0),
        .wbs_cyc_i(1'b0),
        .wbs_we_i(1'b0),
        .wbs_sel_i(4'b0),
        .wbs_dat_i(32'h0),
        .wbs_adr_i(32'b0),
        .wbs_ack_o(),
        .wbs_dat_o(),

        .sstream_i(vrc_mstreamo),
        .sstream_o(vrc_mstreami),

        .mstream_i(frag_mstreami),
        .mstream_o(frag_mstreamo),

        .depth_mport_i(rast1_mporti),
        .depth_mport_o(rast1_mporto),

        .tex_mport_i(rast2_mporti),
        .tex_mport_o(rast2_mporto)
    );

    vga_wrapper_m vga(
        .wb_clk_i(clk),
        .wb_rst_i(!nrst),
        .wbs_stb_i(1'b0),
        .wbs_cyc_i(1'b0),
        .wbs_we_i(1'b0),
        .wbs_sel_i(4'b0),
        .wbs_dat_i(32'h0),
        .wbs_adr_i(32'b0),
        .wbs_ack_o(),
        .wbs_dat_o(),

        .mport_i(vga_mporti),
        .mport_o(vga_mporto),

        .pixel_o(),
        .hsync_o(),
        .vsync_o()
    );

    mem_write_m mem_write(
        .clk_i(clk),
        .nrst_i(nrst),

        .busy_o(),
        
        .sstream_i(frag_mstreamo),
        .sstream_o(frag_mstreami),

        .mport_i(write_mporti),
        .mport_o(write_mporto),
        
        .fb_i(1'b0)
    );

    reg [`WORD] insts [1023:0];

    image_m image();

    initial begin : MAIN
        integer i, j;
        integer x, y;

		$dumpfile("integration.vcd");
		$dumpvars(0, integration_tb);

        global_r1 = `SPI_MEM_SIZE;
        global_r2 = `SPI_MEM_SIZE;

        inst = 0;

        fds = 0;

        stalli = 0;

        nsync_rst = 1;

        svc_clear = 0;

        test_index = 0;
        test_valid = 0;

        store_index = 0;

        for (i = 0; i < 1024; i++) insts[i] = 0;
        $readmemh("../top_level/src/asm/vertex_shader_cached.txt", insts);

        clk_rst.RESET();

        for (x = 0; x < 320; x = x + 1) begin
            for (y = 0; y < 240; y = y + 1) begin : DB_FILL
                reg [31:0] value;
                value = 32'hFFFFFFFF;

                WRITE_MEM(`ADDR_DEPTH_BUFFER + (y * 320 + x) * 4 + 0, value[7:0]);
                WRITE_MEM(`ADDR_DEPTH_BUFFER + (y * 320 + x) * 4 + 1, value[15:8]);
                WRITE_MEM(`ADDR_DEPTH_BUFFER + (y * 320 + x) * 4 + 2, value[23:16]);
                WRITE_MEM(`ADDR_DEPTH_BUFFER + (y * 320 + x) * 4 + 3, value[31:24]);
            end
        end

        for (x = 0; x < 60; x = x + 1) begin
            for (y = 0; y < 60; y = y + 1) begin
                WRITE_MEM(`ADDR_FB1 + (y * 60 + x), image.tex_data[y * 60 + x]);
                // WRITE_MEM(`ADDR_FB1 + (y * 60 + x), 8'b11000000);
            end
        end

        wait(!clk);

        svc_clear = 1;
        wait(clk);
        wait(!clk);
        svc_clear = 0;

        WRITE_WORD(`SPI_MEM_SIZE + 0 * 20 + 0, `FP(1));
        WRITE_WORD(`SPI_MEM_SIZE + 0 * 20 + 4, `FP(1));
        WRITE_WORD(`SPI_MEM_SIZE + 0 * 20 + 8, `FP(1));
        WRITE_WORD(`SPI_MEM_SIZE + 0 * 20 + 12, `FP(0));
        WRITE_WORD(`SPI_MEM_SIZE + 0 * 20 + 16, `FP(0));

        WRITE_WORD(`SPI_MEM_SIZE + 1 * 20 + 0, `FP(61));
        WRITE_WORD(`SPI_MEM_SIZE + 1 * 20 + 4, `FP(1));
        WRITE_WORD(`SPI_MEM_SIZE + 1 * 20 + 8, `FP(1));
        WRITE_WORD(`SPI_MEM_SIZE + 1 * 20 + 12, `FP(60));
        WRITE_WORD(`SPI_MEM_SIZE + 1 * 20 + 16, `FP(0));

        WRITE_WORD(`SPI_MEM_SIZE + 2 * 20 + 0, `FP(1));
        WRITE_WORD(`SPI_MEM_SIZE + 2 * 20 + 4, `FP(61));
        WRITE_WORD(`SPI_MEM_SIZE + 2 * 20 + 8, `FP(1));
        WRITE_WORD(`SPI_MEM_SIZE + 2 * 20 + 12, `FP(0));
        WRITE_WORD(`SPI_MEM_SIZE + 2 * 20 + 16, `FP(60));

        WRITE_WORD(`SPI_MEM_SIZE + 3 * 20 + 0, `FP(61));
        WRITE_WORD(`SPI_MEM_SIZE + 3 * 20 + 4, `FP(61));
        WRITE_WORD(`SPI_MEM_SIZE + 3 * 20 + 8, `FP(1));
        WRITE_WORD(`SPI_MEM_SIZE + 3 * 20 + 12, `FP(60));
        WRITE_WORD(`SPI_MEM_SIZE + 3 * 20 + 16, `FP(60));

        EXECUTE_INDEX(0);
        EXECUTE_INDEX(2);
        EXECUTE_INDEX(1);

        EXECUTE_INDEX(1);
        EXECUTE_INDEX(2);
        EXECUTE_INDEX(3);
    end

    initial begin
        #10000000;

        `VGA_WRITE("output.bmp", spi_chip1.mem, `ADDR_FB0, 320, 240, `COLOR_TYPE_RGB332);

        $finish;
    end

    task WRITE_MEM;
        input [31:0] addr;
        input [7:0] data;
    begin
        if (addr < `SPI_MEM_SIZE) begin
            spi_chip1.mem[addr] = data;
        end
        else begin
            spi_chip2.mem[addr - `SPI_MEM_SIZE] = data;
        end
    end
    endtask

    task WRITE_WORD;
        input [31:0] addr;
        input [31:0] data;
    begin
        WRITE_MEM(addr + 0, data[7:0]);
        WRITE_MEM(addr + 1, data[15:8]);
        WRITE_MEM(addr + 2, data[23:16]);
        WRITE_MEM(addr + 3, data[31:24]);
    end
    endtask

    task EXECUTE_INDEX;
        input [15:0] index;

        integer i;
    begin
        wait(!clk);

        store_index = index;
        test_index = index;
        test_valid = 1;
        #1;
        if (test_found) begin
            wait(clk);
            wait(!clk);
            test_valid = 0;

            order_master.WRITE(1);
        end
        else begin
            order_master.WRITE(0);

            test_valid = 0;
            // stalli = 0;

            @(negedge clk);
            if(stallo) begin
                @(negedge stallo);
                @(negedge clk);
            end
            inst = { 6'h12, 3'b000, 4'b0000, 3'b000, index };
            @(negedge clk);
            if(stallo) begin
                @(negedge stallo);
                @(negedge clk);
            end
            inst = { 6'h11, 3'b000, 4'b0000, 3'b000, 16'h0000 };

            for (i = 0; i < 30; i = i + 1) begin
                @(negedge clk);
                if(stallo) begin
                    @(negedge stallo);
                    @(negedge clk);
                end
                inst = insts[i];
            end
            @(negedge clk);
            if(stallo) begin
                @(negedge stallo);
                @(negedge clk);
            end

            // stalli = 1;

            inst = 0;
        end
    end
    endtask

endmodule

