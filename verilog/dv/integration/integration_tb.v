module integration_tb();

    wire clk, nrst;

    clk_rst_m clk_rst(
        .clk_o(clk),
        .nrst_o(nrst)
    );

    wire wb_clk;
    wire wb_rst;
    wire wbs_stb;
    wire wbs_cyc;
    wire wbs_we;
    wire [3:0] wbs_sel;
    wire [`WORD_WIDTH-1:0] wbs_dato;
    wire [`WORD_WIDTH-1:0] wbs_adr;
    wire wbs_ack;
    wire [`WORD_WIDTH-1:0] wbs_dati;

    wire spi1_clk;
    wire spi1_cs;
    wire [3:0] spi1_mosi;
    wire [3:0] spi1_miso;
    wire spi1_dqsmi;
    wire spi1_dqsmo;
    wire [3:0] spi1_sio_en;
    wire spi1_dqsm_en;

    wire spi2_clk;
    wire spi2_cs;
    wire [3:0] spi2_mosi;
    wire [3:0] spi2_miso;
    wire spi2_dqsmi;
    wire spi2_dqsmo;
    wire [3:0] spi2_sio_en;
    wire spi2_dqsm_en;

    wishbone_master_m wbmst(
        .clk_i(clk),
        .nrst_i(nrst),

        .wb_clk_o(wb_clk),
        .wb_rst_o(wb_rst),
        .wbs_stb_o(wbs_stb),
        .wbs_cyc_o(wbs_cyc),
        .wbs_we_o(wbs_we),
        .wbs_sel_o(wbs_sel),
        .wbs_dat_o(wbs_dati),
        .wbs_adr_o(wbs_adr),
        .wbs_ack_i(wbs_ack),
        .wbs_dat_i(wbs_dato)
    );

    top_level_m top_level(
        .wb_clk_i(wb_clk),
        .wb_rst_i(wb_rst),
        .wbs_stb_i(wbs_stb),
        .wbs_cyc_i(wbs_cyc),
        .wbs_we_i(wbs_we),
        .wbs_sel_i(wbs_sel),
        .wbs_dat_i(wbs_dati),
        .wbs_adr_i(wbs_adr),
        .wbs_ack_o(wbs_ack),
        .wbs_dat_o(wbs_dato),

        .spi1_clk_o(spi1_clk),
        .spi1_cs_o(spi1_cs),
        .spi1_mosi_o(spi1_mosi),
        .spi1_miso_i(spi1_miso),
        .spi1_dqsm_i(spi1_dqsmi),
        .spi1_dqsm_o(spi1_dqsmo),
        .spi1_sio_en_o(spi1_sio_en),
        .spi1_dqsm_en_o(spi1_dqsm_en),

        .spi2_clk_o(spi2_clk),
        .spi2_cs_o(spi2_cs),
        .spi2_mosi_o(spi2_mosi),
        .spi2_miso_i(spi2_miso),
        .spi2_dqsm_i(spi2_dqsmi),
        .spi2_dqsm_o(spi2_dqsmo),
        .spi2_sio_en_o(spi2_sio_en),
        .spi2_dqsm_en_o(spi2_dqsm_en),

        .blue_o(),
        .green_o(),
        .red_o(),
        .hsync_o(),
        .vsync_o()
    );

    initial begin : RUN
        integer i;
        reg [`WORD] temp [1023:0];

        $dumpfile("integration.vcd");
        $dumpvars(0, integration_tb);

        clk_rst.RESET();

        // If you get a cannot bind error here, add `define FPGA to the top of
        // sram_1024x32.v.
        $readmemh("../top_level/src/asm/vertex_shader_cached.txt", temp);
        for (i = 0; i < 128; i = i + 1)
            top_level.core_cont.core_controller.inst_fetch.imem.sram.RAM[i] = temp[i];
        $readmemh("../top_level/src/asm/fragment_shader.txt", temp);
        for (i = 0; i < 128; i = i + 1)
            top_level.core_cont.core_controller.inst_fetch.imem.sram.RAM[128 + i] = temp[i];

        // Index buffer
        WRITE_WORD(32'h80000 + 0 * 4, 0);
        WRITE_WORD(32'h80000 + 1 * 4, 2);
        WRITE_WORD(32'h80000 + 2 * 4, 1);

        // Vertex 0
        WRITE_WORD(32'h90000 + 0 * 20 + 0, `FP(1));
        WRITE_WORD(32'h90000 + 0 * 20 + 4, `FP(1));
        WRITE_WORD(32'h90000 + 0 * 20 + 8, `FP(1));
        WRITE_WORD(32'h90000 + 0 * 20 + 12, `FP(0));
        WRITE_WORD(32'h90000 + 0 * 20 + 16, `FP(0));

        // Vertex 1
        WRITE_WORD(32'h90000 + 1 * 20 + 0, `FP(61));
        WRITE_WORD(32'h90000 + 1 * 20 + 4, `FP(1));
        WRITE_WORD(32'h90000 + 1 * 20 + 8, `FP(1));
        WRITE_WORD(32'h90000 + 1 * 20 + 12, `FP(60));
        WRITE_WORD(32'h90000 + 1 * 20 + 16, `FP(0));

        // Vertex 2
        WRITE_WORD(32'h90000 + 2 * 20 + 0, `FP(1));
        WRITE_WORD(32'h90000 + 2 * 20 + 4, `FP(61));
        WRITE_WORD(32'h90000 + 2 * 20 + 8, `FP(1));
        WRITE_WORD(32'h90000 + 2 * 20 + 12, `FP(0));
        WRITE_WORD(32'h90000 + 2 * 20 + 16, `FP(60));

        // Vertex 3
        WRITE_WORD(32'h90000 + 3 * 20 + 0, `FP(61));
        WRITE_WORD(32'h90000 + 3 * 20 + 4, `FP(61));
        WRITE_WORD(32'h90000 + 3 * 20 + 8, `FP(1));
        WRITE_WORD(32'h90000 + 3 * 20 + 12, `FP(60));
        WRITE_WORD(32'h90000 + 3 * 20 + 16, `FP(60));

        // Rasterizer config
        wbmst.WRITE(32'h30000000 + 0 * 4, `ADDR_FB1); // Texture addr
        wbmst.WRITE(32'h30000000 + 1 * 4, 60); // Texture height
        wbmst.WRITE(32'h30000000 + 2 * 4, 60); // Texture width

        // Core controller config
        wbmst.WRITE(32'h28000000 + 2 * 4, 6'b111111); // Enable all cores

        wbmst.WRITE(32'h28000000 + 5 * 4, 32'h00000000); // GPGPU entry point
        wbmst.WRITE(32'h28000000 + 6 * 4, 32'h00000000); // Vert shade entry point
        wbmst.WRITE(32'h28000000 + 7 * 4, 32'h00000200); // Frag shade entry point (word 128 -> byte 512)

        wbmst.WRITE(32'h28000000 + 8 * 4, 32'h00080000); // Index buffer addr

        wbmst.WRITE(32'h28000000 + 9 * 4, 32'd3); // Job/index count

        wbmst.WRITE(32'h28000000 + (10 + 46) * 4, 32'h00090000); // r46 = 0x00090000

        wbmst.WRITE(32'h28000000 + 0 * 4, 5'b01010); // Dispatch indices, start

        $display("Regs written");

        // cores->core_en = 0b111111;
        // cores->int_mask = 0b00;

        // cores->compute_entry = 0;
        // cores->vertex_entry = 0;
        // cores->frag_entry = 0;

        // cores->index_addr = 0x80000;

        // cores->job_count = 6;

        // cores->greg[46] = 0x90000;

        // cores->control = 0b1010;
    end

    initial begin
        #1000000;

        `VGA_WRITE("output.bmp", spi_chip1.mem, `ADDR_FB0, 320, 240, `COLOR_TYPE_RGB332);

        $finish;
    end

    spi_chip_m #(5, 1, 600000) spi_chip1(
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

endmodule
