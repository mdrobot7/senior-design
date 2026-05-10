/*
  Direct-mapped SRAM cache.
  Designed for 64-byte BLOCKS.
  Core Addresses are byte-addressable.
  Word requests are returned word-aligned.
  Physical SRAM is 1024x32-bit array.
  Uses Write Back Policy with Dirty bit.
*/

`ifdef SVUNIT
  `default_nettype wire
  `include "../../ip/CF_SRAM_1024x32/hdl/beh_models/CF_SRAM_1024x32.tt_180V_25C.v"
  `default_nettype none
`endif

module cache_wrapper_m
#(
  parameter BLOCK_WORD_SIZE = 16
)
(
  // wishbone
  input wire wb_clk_i,
  input wire wb_rst_i,
  input wire wbs_stb_i,
  input wire wbs_cyc_i,
  input wire wbs_we_i,
  input wire [3:0] wbs_sel_i,
  input wire [`WORD_WIDTH-1:0] wbs_dat_i,
  input wire [`WORD_WIDTH-1:0] wbs_adr_i,
  output reg wbs_ack_o,
  output reg [`WORD_WIDTH-1:0] wbs_dat_o,

  input wire [`BUS_SIPORT] s_core_i,
  output wire [`BUS_SOPORT] s_core_o,

  input wire [`BUS_MIPORT] m_mem_i,
  output wire [`BUS_MOPORT] m_mem_o
);

wire enable;
wire flush;
wire flush_comp;
wire wbs_ack;
wire [`WORD_WIDTH-1:0] wbs_dat;

cache_m #(BLOCK_WORD_SIZE) cache
(
  .clk_i(wb_clk_i),
  .nrst_i(!wb_rst_i),
  .enable_i(enable),

  .flush_i(flush),
  .flush_comp_o(flush_comp),

  .s_core_i(s_core_i),
  .s_core_o(s_core_o),
  .m_mem_i(m_mem_i),
  .m_mem_o(m_mem_o)
);

wire [`WORD] read_reg;
assign {flush, enable} = read_reg[1:0];
wishbone_register_m #(32'h00000000, 1, `WBREG_TYPE_REG) ctrl (
    .wb_clk_i(wb_clk_i),
    .wb_rst_i(wb_rst_i),
    .wbs_stb_i(wbs_stb_i),
    .wbs_cyc_i(wbs_cyc_i),
    .wbs_we_i(wbs_we_i),
    .wbs_sel_i(wbs_sel_i),
    .wbs_dat_i(wbs_dat_i),
    .wbs_adr_i(wbs_adr_i),
    .wbs_ack_o(wbs_ack),
    .wbs_dat_o(wbs_dat),

    .access_read_mask_i(32'h00000007),
    .access_write_mask_i(32'h0000003),
    .periph_read_mask_i(32'h00000004),

    .enable_prot_i(32'hFFFFFFF9),
    .enable_i(enable),

    .reg_i({29'h0, flush_comp, 2'h0}),
    .reg_o(read_reg)
);

always @(*) begin
  wbs_ack_o = wbs_ack;
  wbs_dat_o = wbs_dat;
end

endmodule

module cache_m
#(
  parameter BLOCK_WORD_SIZE = 16
)
(
  input wire clk_i,
  input wire nrst_i,
  input wire enable_i,

  input wire flush_i,     
  output reg flush_comp_o, // clears once finished and flush_i cleared

  input wire [`BUS_SIPORT] s_core_i,
  output wire [`BUS_SOPORT] s_core_o,

  input wire [`BUS_MIPORT] m_mem_i,
  output wire [`BUS_MOPORT] m_mem_o
);

`DL_DEFINE(logger, "cache_m", `DL_GREEN, 1);
`DL_DEFINE(error,  "cache_m ERROR", `DL_RED, 1);

localparam BLOCK_BITS = ($clog2(BLOCK_WORD_SIZE));
localparam BLOCKS     = (1024 / BLOCK_WORD_SIZE);
localparam INDEX_BITS = ($clog2(BLOCKS));
localparam OFFSET_BITS= ($clog2(BLOCK_WORD_SIZE << 2));
localparam TAG_BITS   = (32 - INDEX_BITS - OFFSET_BITS);

// core
wire core_req_i;
wire core_size;     // word or byte
wire [31:0] data_i;
wire [31:0] addr_i;
wire rw_i;
assign core_req_i = s_core_i[`BUS_SI_REQ];
assign core_size  = s_core_i[`BUS_SI_SIZE];
assign data_i     = s_core_i[`BUS_SI_DATA];
assign addr_i     = s_core_i[`BUS_SI_ADDR];
assign rw_i       = s_core_i[`BUS_SI_RW];   // pk bus

reg core_ack_o;
reg [31:0] core_data_o;
assign s_core_o[`BUS_SO_ACK]    = enable_i ? core_ack_o   : m_mem_i[`BUS_MI_ACK];
assign s_core_o[`BUS_SO_DATA]   = enable_i ? core_data_o  : m_mem_i[`BUS_MI_DATA];
assign s_core_o[`BUS_SO_SEQSLV] = 0;

// mem
reg mem_req_o;
reg mem_rw;
reg mem_seqmst_o;
reg [31:0] mem_addr;
reg [31:0] mem_data_o;
assign m_mem_o[`BUS_MO_REQ]     = enable_i ? mem_req_o        : s_core_i[`BUS_SI_REQ];
assign m_mem_o[`BUS_MO_RW]      = enable_i ? mem_rw           : s_core_i[`BUS_SI_RW];
assign m_mem_o[`BUS_MO_SIZE]    = enable_i ? `BUS_SIZE_STREAM : s_core_i[`BUS_SI_SIZE];
assign m_mem_o[`BUS_MO_SEQMST]  = enable_i ? mem_seqmst_o     : s_core_i[`BUS_SI_SEQMST];
assign m_mem_o[`BUS_MO_ADDR]    = enable_i ? mem_addr         : s_core_i[`BUS_SI_ADDR];
assign m_mem_o[`BUS_MO_DATA]    = enable_i ? mem_data_o       : s_core_i[`BUS_SI_DATA];

wire mem_ack_i;
wire mem_seqslv_i;
wire [31:0] mem_data_i;
assign mem_ack_i    = m_mem_i[`BUS_MI_ACK];
assign mem_seqslv_i = m_mem_i[`BUS_MI_SEQSLV];
assign mem_data_i   = m_mem_i[`BUS_MI_DATA];

// meta
reg                valid [BLOCKS-1:0];
reg                dirty [BLOCKS-1:0];
reg [TAG_BITS-1:0] tag   [BLOCKS-1:0];

// request
reg [31:0]          req_addr;
reg [31:0]          req_data;
reg                 req_rw;
reg [TAG_BITS-1:0]  req_tag;
reg [INDEX_BITS-1:0]req_index;

reg [BLOCK_BITS:0] wb_count;
reg [BLOCK_BITS:0] fill_count;
reg                wb_done;

reg [3:0] state;
localparam S_WAIT   = 4'd0;
localparam S_TAG    = 4'd1;
localparam S_HIT    = 4'd2;
localparam S_DIRTY_0 = 4'd3;
localparam S_DIRTY_1 = 4'd4;
localparam S_DIRTY  = 4'd5;
localparam S_FILL   = 4'd6;
localparam S_MISS_1 = 4'd7;
localparam S_MISS_2 = 4'd8;
localparam S_FLUSH  = 4'd9;

reg flush;
reg [INDEX_BITS-1:0] flush_count; 

// SRAM
reg [9:0]   sram_addr;
reg [31:0]  sram_in_data;  // input to sram
reg         sram_rw;       // 0 for write, 1 for read
reg         sram_en;
reg  [31:0] sram_ben;      // write byte mask
reg  [7:0]  sram_byte;     // masked read
wire [31:0] sram_out_data; // output from sram

`ifdef HARDENING
  // hardening bb (power pins routed in config)
  CF_SRAM_1024x32 i_sram (
    .DO(sram_out_data),
    .ScanOutCC(),

    .CLKin(clk_i),
    .AD(sram_addr),
    .BEN(sram_ben),
    .DI(sram_in_data),
    .EN(sram_en),
    .R_WB(sram_rw),

    .ScanInCC(1'b0),
    .ScanInDL(1'b0),
    .ScanInDR(1'b0),
    .SM(1'b0),
    .TM(1'b0),
    .WLBI(1'b0),
    .WLOFF(1'b0)
  );
`else // FPGA or RTL-testing
  sram_1024x32_m sram(
    .clk_i(clk_i),
    .addr_i(sram_addr),
    .read_en_i(sram_rw),
    .en_i(sram_en),
    .data_i(sram_in_data),
    .ben_i(sram_ben),
    .data_o(sram_out_data)
  );
`endif

// read byte mask
always @(*) begin
  case(req_addr[1:0])
    2'b00 : sram_byte = sram_out_data[7:0];
    2'b01 : sram_byte = sram_out_data[15:8];
    2'b10 : sram_byte = sram_out_data[23:16];
    2'b11 : sram_byte = sram_out_data[31:24];
  endcase
end

// write byte mask
always @(*) begin
  // do not mask while trying to fill sram from mem
  if (req_rw == `BUS_WRITE && core_size == `BUS_SIZE_BYTE && state != S_FILL) begin
    case(req_addr[1:0])
      2'b00 : sram_ben = 32'h000000FF;
      2'b01 : sram_ben = 32'h0000FF00;
      2'b10 : sram_ben = 32'h00FF0000;
      2'b11 : sram_ben = 32'hFF000000;
    endcase
  end
  else
    sram_ben = 32'hFFFFFFFF;
end

integer i;
always @ (posedge clk_i, negedge nrst_i) begin
  if (!nrst_i) begin
    for (i = 0; i < BLOCKS; i = i+1) begin
      valid[i] <= 1'b0;
      dirty[i] <= 1'b0;
      tag[i] <= {TAG_BITS{1'b0}};
    end
    state <= S_WAIT;
    core_ack_o <= 0;
    core_data_o <= 0;
    mem_req_o <= 0;
    mem_seqmst_o <= 0;
    mem_rw <= `BUS_READ;
    mem_addr <= 0;
    mem_data_o <= 0;
    req_addr <= 0;
    req_data <= 0;
    req_rw <= `BUS_READ;
    req_index <= 0;
    req_tag <= 0;
    wb_count <= 0;
    wb_done <= 0;
    fill_count <= 0;
    sram_en <= 1;
    sram_rw <= `SRAM_READ;
    sram_addr <= 0;
    sram_in_data <= 0;
    flush <= 0;
    flush_count <= 0;
    flush_comp_o <= 0;
  end
  else begin
    // defaults
    mem_req_o     <= 0;
    mem_rw        <= `BUS_READ;
    mem_seqmst_o  <= 0;
    sram_en       <= 1;
    sram_rw       <= `SRAM_READ;

    if (enable_i) begin
      if (flush_i) begin
        flush <= 1;
      end
      else begin
        flush_comp_o <= 0;
      end

      case (state)

      S_WAIT: begin
        if (core_req_i) begin
          core_ack_o  <= 1;
          req_addr    <= addr_i;
          req_rw      <= rw_i;         // pk bus read/write values
          req_data    <= data_i;
          req_tag     <= addr_i[31:(32 - TAG_BITS)];
          req_index   <= addr_i[(31-TAG_BITS):(OFFSET_BITS)];

          // pre req from SRAM
          sram_addr <= addr_i[11:2];
          state <= flush ? S_FLUSH : S_TAG;

          `DL(logger, ("Cache %s", rw_i == `BUS_READ ? "READ" : (rw_i == `BUS_WRITE ? "WRITE" : "?????")));
        end
        else begin
          core_ack_o  <= 0;
          state       <= flush ? S_FLUSH : S_WAIT;
        end
      end

      S_TAG: begin

        if (valid[req_index] && (req_tag == tag[req_index])) begin
          sram_addr <= req_addr[11:2];

          if (req_rw == `BUS_WRITE) begin
            sram_rw <= `SRAM_WRITE;
            dirty[req_index] <= 1;
            if (core_size == `BUS_SIZE_BYTE)
              sram_in_data <= req_data << (req_addr[1:0] * 8);
            else
              sram_in_data <= req_data;
          end

          `DL(logger, ("Cache Hit: addr = 0x%h", req_addr));
          state <= S_HIT;
        end
        else if (dirty[req_index] && valid[req_index]) begin
          `DL(logger, ("Cache Dirty: addr = 0x%h", req_addr));
          sram_addr <= {req_index, {BLOCK_BITS{1'b0}}};
          wb_count  <= 0;
          // let wb finish before flushing
          state     <= S_DIRTY_0; 
        end
        else begin
          `DL(logger, ("Cache Miss: addr = 0x%h", req_addr));
          fill_count <= 0;
          state <= flush ? S_FLUSH : S_FILL;
        end
      end

      S_HIT: begin
        core_data_o <= (core_size == `BUS_SIZE_WORD) ? sram_out_data : {24'b0, sram_byte};
        core_ack_o  <= 0;
        state       <= flush ? S_FLUSH : (core_req_i ? S_HIT : S_WAIT); // wait till core deasserts req
      end

      S_DIRTY_0: begin
        sram_addr <= {req_index, {BLOCK_BITS{1'b0}}};
        wb_count  <= 0;
        state     <= S_DIRTY_1;
      end

      S_DIRTY_1: begin
        mem_req_o <= 1;
        mem_rw    <= `BUS_WRITE;
        mem_addr  <= {tag[req_index], req_index, 6'd0};
        mem_data_o <= sram_out_data;

        sram_addr <= {req_index, wb_count[BLOCK_BITS-1:0]};
        wb_count  <= wb_count + 1;

        state <= S_DIRTY;
      end

      S_DIRTY: begin
        mem_req_o <= 1;
        mem_rw    <= `BUS_WRITE;
        mem_addr  <= {tag[req_index], req_index, 6'd0};

        sram_addr <= {req_index, wb_count[BLOCK_BITS-1:0]};

        if (!wb_done) begin
          if (mem_ack_i && mem_seqslv_i) begin
            `DL(logger, ("  Dirty: Mem[0x%h] <= 0x%h <= SRAM[%0d]", mem_addr + (wb_count * 4), sram_out_data, sram_addr));
            mem_data_o <= sram_out_data;
            
            if (wb_count == BLOCK_WORD_SIZE-1) begin
              dirty[req_index] <= 0;
              wb_done          <= 1;
            end 
            else begin
              wb_count  <= wb_count + 1;
            end
          end
        end
        else begin
          mem_seqmst_o <= 1;
          if (!mem_ack_i) begin
            mem_req_o  <= 0;
            wb_done    <= 0;
            fill_count <= 0;
            state      <= flush ? S_FLUSH : S_FILL;
          end
        end
      end

      S_FILL: begin
        mem_req_o <= 1;
        mem_rw <= `BUS_READ;
        mem_addr <= {req_tag, req_index, 6'b0};
        mem_seqmst_o <= 0;

        if (mem_ack_i && mem_seqslv_i) begin
          // read from MEM, write to SRAM
          sram_rw <= `SRAM_WRITE;
          sram_addr <= {req_index, fill_count[BLOCK_BITS-1:0]};
          sram_in_data <= mem_data_i;
          `DL(logger, ("  Fill: Sram[%0d] <= 0x%h <= mem[0x%h]", sram_addr, mem_data_i, mem_addr + (fill_count * 4)));

          if (fill_count == BLOCK_WORD_SIZE-1) begin
            mem_seqmst_o <= 1;
            fill_count <= BLOCK_WORD_SIZE;
            valid[req_index] <= 1;
            tag[req_index]   <= req_tag;
            dirty[req_index] <= 0;
          end
          else begin
            fill_count <= fill_count + 1;
          end
        end

        if (fill_count == BLOCK_WORD_SIZE) begin
          mem_seqmst_o <= 1;
          if (!mem_ack_i) begin
            fill_count <= 0;

            // pre req sram
            sram_addr <= req_addr[11:2];
            sram_rw   <= (req_rw == `BUS_READ) ? `SRAM_READ : `SRAM_WRITE;

            if (req_rw == `BUS_WRITE)
              dirty[req_index] <= 1;

            sram_in_data <= (core_size == `BUS_SIZE_BYTE) ? req_data << (req_addr[1:0] * 8) : req_data;
            state <= flush ? S_FLUSH : S_MISS_1;
          end
        end
      end

      S_MISS_1: begin
        // wait one cycle for sram
        sram_addr     <= req_addr[11:2];
        sram_rw       <= (req_rw == `BUS_READ) ? `SRAM_READ : `SRAM_WRITE;
        sram_in_data  <= (core_size == `BUS_SIZE_BYTE) ? req_data << (req_addr[1:0] * 8) : req_data;
        state         <= S_MISS_2;
      end

      S_MISS_2: begin

        if (req_rw == `BUS_READ)
          core_data_o <= (core_size == `BUS_SIZE_WORD) ? sram_out_data : {24'b0, sram_byte};
        else
          dirty[req_index] <= 1;

        core_ack_o <= 0;
        state <= flush ? S_FLUSH : (core_req_i ? S_MISS_2 : S_WAIT); // wait till core deasserts req
      end

      S_FLUSH: begin
        `DL(logger, ("  FLUSH: %0d", flush_count));

        // loop through and WB all dirty blocks
        if (dirty[flush_count] && valid[flush_count]) begin
          req_index <= flush_count;
          sram_addr <= {flush_count, {BLOCK_BITS{1'b0}}};
          wb_count  <= 0;
          flush_count <= flush_count + 1;
          state     <= S_DIRTY_0;
        end
        else if (flush_comp_o == 0) begin
          
          if (flush_count == BLOCKS-1) begin
            flush <= 0;
            flush_count <= 0;
            flush_comp_o <= 1;
            state <= S_WAIT;
            `DL(logger, ("  Flush Complete"));
          end
          else begin
            flush_count <= flush_count + 1;
          end
        end
        else
          flush <= 0;
      end

      default:
        state <= S_WAIT;

      endcase
    end
  end
end

endmodule
