/*
  Direct-mapped SRAM cache.
  Designed for 64-byte BLOCKS.
  Physical SRAM is 1024x32 bit array.
  Uses Write Back Policy with Dirty bit.
  Prioritizes low latency read hits. 
*/

`ifdef SVUNIT
  `default_nettype wire
  `include "../../ip/CF_SRAM_1024x32/hdl/beh_models/CF_SRAM_1024x32.tt_180V_25C.v"
  `default_nettype none
`endif

module metadata_cache_m
#(
  parameter BLOCK_WORD_SIZE = 16
)
(
  input wire clk_i,
  input wire nrst_i,

  input wire [`BUS_SIPORT] s_core_i,
  output reg [`BUS_SOPORT] s_core_o,

  input wire [`BUS_MIPORT] m_mem_i,
  output wire [`BUS_MOPORT] m_mem_o
);

localparam BLOCK_BITS = ($clog2(BLOCK_WORD_SIZE));
localparam BLOCKS = (1024 / BLOCK_WORD_SIZE);
localparam INDEX_BITS = ($clog2(BLOCKS));
localparam OFFSET_BITS = ($clog2(BLOCK_WORD_SIZE << 2));
localparam TAG_BITS = (32 - INDEX_BITS - OFFSET_BITS);

// core
wire core_req_i;
wire [31:0] data_i;
wire [31:0] addr_i;
wire rw_i;
assign core_req_i = s_core_i[`BUS_SI_REQ];
assign data_i = s_core_i[`BUS_SI_DATA];
assign addr_i = s_core_i[`BUS_SI_ADDR];
assign rw_i = s_core_i[`BUS_SI_RW];

// mem
reg mem_req_o;        
reg mem_rw;          
reg mem_seqmst_o;
reg [31:0] mem_addr;
reg [31:0] mem_data_o;
assign m_mem_o[`BUS_MO_REQ] = mem_req_o;
assign m_mem_o[`BUS_MO_RW] = mem_rw;
assign m_mem_o[`BUS_MO_SIZE] = `BUS_SIZE_STREAM; // always stream
assign m_mem_o[`BUS_MO_SEQMST] = mem_seqmst_o;
assign m_mem_o[`BUS_MO_ADDR] = mem_addr;
assign m_mem_o[`BUS_MO_DATA] = mem_data_o;

wire mem_ack_i;
wire mem_seqslv_i;
wire [31:0] mem_data_i;
assign mem_ack_i = m_mem_i[`BUS_MI_ACK];
assign mem_seqslv_i = m_mem_i[`BUS_MI_SEQSLV];
assign mem_data_i = m_mem_i[`BUS_MI_DATA];

// meta
reg                valid [BLOCKS-1:0]; 
reg                dirty [BLOCKS-1:0];
reg [TAG_BITS-1:0] tag   [BLOCKS-1:0];

reg [31:0] req_addr;  
reg [31:0] req_data;  
reg        req_rw; 
reg [TAG_BITS-1:0] req_tag;   
reg [INDEX_BITS-1:0]  req_index;

reg [BLOCK_BITS:0] wb_count;
reg [BLOCK_BITS:0] fill_count;
reg wb_done;

reg [2:0] state;
localparam S_WAIT = 3'd0;
localparam S_TAG = 3'd1;
localparam S_HIT = 3'd2;
localparam S_DIRTY = 3'd3;
localparam S_FILL = 3'd4;
localparam S_MISS_1 = 3'd5;
localparam S_MISS_2 = 3'd6;

// SRAM
reg [9:0] sram_addr;   
reg [31:0] sram_in_data;  // data input to sram
reg sram_rw;              // 0 for write, 1 for read
reg sram_en;            
reg [31:0] sram_out_data; // data output from sram
  
// CF_SRAM_1024x32_macro for rtl sim
CF_SRAM_1024x32 i_sram (
  .DO(sram_out_data), 
  .ScanOutCC(),

  .CLKin(clk_i), 
  .AD(sram_addr), 
  .BEN(32'hFFFFFFFF), 
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

integer i;
always @ (posedge clk_i) begin
  if (!nrst_i) begin
    for (i = 0; i < BLOCKS; i = i+1) begin
      valid[i] <= 1'b0;
      dirty[i] <= 1'b0;
      tag[i] <= {TAG_BITS{1'b0}};
    end
    state <= S_WAIT;
    s_core_o[`BUS_SO_ACK] <= 0;
    s_core_o[`BUS_SO_SEQSLV] <= 0; // not used
    sram_en <= 0;
    mem_req_o <= 0;
    mem_seqmst_o <= 0;
    mem_rw <= `BUS_READ;
    req_addr <= 0;
    req_data <= 0;
    req_rw <= `BUS_READ;
    req_index <= 0;
    req_tag <= 0;
    wb_count <= 0;
    fill_count <= 0;
    wb_done <= 0;
    s_core_o[`BUS_SO_DATA] <= 0;
    sram_rw <= `SRAM_READ;
  end
  else begin
    // defaults
    mem_req_o <= 0;
    mem_rw <= `BUS_READ;
    mem_seqmst_o <= 0;
    sram_en <= 0;
    sram_rw <= `SRAM_READ;

    case (state) 

    S_WAIT: begin
      if (core_req_i) begin
        s_core_o[`BUS_SO_ACK] <= 1;
        req_addr <= addr_i;
        req_rw <= rw_i;         // BUS READ/WRITE NOT SRAM
        req_data <= data_i;
        req_tag <= addr_i[31:(32 - TAG_BITS)];
        req_index <= addr_i [(31-TAG_BITS):(OFFSET_BITS)];
        // pre req from SRAM
        sram_en <= 1;
        sram_rw <= `SRAM_READ;
        sram_addr <= addr_i[11:2];
        state <= S_TAG;
      end
      else begin
        s_core_o[`BUS_SO_ACK] <= 0;
      end
    end


    S_TAG: begin
      if (valid[req_index] && (req_tag == tag[req_index])) begin
        if (req_rw == `BUS_WRITE) begin
          sram_en <= 1;
          sram_rw <= `SRAM_WRITE;
          sram_addr <= req_addr[11:2];
          sram_in_data <= req_data;
          state <= S_HIT;
        end
        // Read Hit, output immediately
        else begin
          s_core_o[`BUS_SO_DATA] <= sram_out_data;
          s_core_o[`BUS_SO_ACK] <= 0;
          state <= S_WAIT;
        end
      end
      else if (dirty[req_index]) begin
        wb_count <= 0;
        state <= S_DIRTY;
      end
      else begin
        fill_count <= 0;
        state <= S_FILL;
      end
    end

    // For write hit
    S_HIT: begin
      dirty[req_index] <= 1;
      s_core_o[`BUS_SO_ACK] <= 0;
      state <= S_WAIT;
    end
    
    S_DIRTY: begin
      // write back to mem
      mem_req_o <= 1;
      mem_rw <= `BUS_WRITE;
      mem_addr <= {tag[req_index], req_index, 6'd0};

      if (mem_ack_i) begin
        if (wb_count == 0) begin
          sram_en <= 1;
          sram_rw <= `SRAM_READ;
          sram_addr <= {req_index, 4'd0};
          wb_count <= 1;
        end
        else
          mem_data_o <= sram_out_data; 
        
        if (mem_seqslv_i) begin
          if (wb_count == BLOCK_WORD_SIZE) begin
            mem_seqmst_o <= 1;
            dirty[req_index] <= 0;
            wb_done <= 1;
          end
          else begin
            sram_en <= 1;
            sram_rw <= `SRAM_READ;
            sram_addr <= {req_index, wb_count[BLOCK_BITS-1:0]};
            wb_count <= wb_count + 1;
          end
        end
      end

      if (wb_done) begin
        mem_req_o <= 0;
        mem_seqmst_o <= 1;
        if (!mem_ack_i) begin
          wb_done <= 0;
          wb_count <= 0;
          state <= S_FILL;
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
        sram_en <= 1;
        sram_rw <= `SRAM_WRITE;
        sram_addr <= {req_index, fill_count[BLOCK_BITS-1:0]};
        sram_in_data <= mem_data_i;

        if (fill_count == BLOCK_WORD_SIZE-1) begin
          mem_seqmst_o <= 1;
          fill_count <= BLOCK_WORD_SIZE;
          valid[req_index] <= 1;
          tag[req_index] <= req_tag;
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
          sram_en <= 1;
          sram_addr <= req_addr[11:2];
          sram_rw <= (req_rw == `BUS_READ) ? `SRAM_READ : `SRAM_WRITE;
          sram_in_data <= req_data;
          state <= S_MISS_1;
        end
      end
    end

    S_MISS_1: begin
      // wait one cycle for sram
      sram_en <= 1;
      sram_addr <= req_addr[11:2];
      sram_rw <= (req_rw == `BUS_READ) ? `SRAM_READ : `SRAM_WRITE;
      sram_in_data <= req_data;
      state <= S_MISS_2; 
    end

    S_MISS_2: begin
      if (req_rw == `BUS_READ)
        s_core_o[`BUS_SO_DATA] <= sram_out_data;
      else
        dirty[req_index] <= 1;
      s_core_o[`BUS_SO_ACK] <= 0;
      state <= S_WAIT;
    end
    
    default:
      state <= S_WAIT;

    endcase
  end
end

endmodule