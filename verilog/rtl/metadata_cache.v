/*
  Metadata Cache for direct-mapped SRAM cache.
  64-byte BLOCKS.
  Physical SRAM is 1024x32 bit array, the cache logically treats it as 64 entries x 16 words each
  Uses Write Back Policy with Dirty bit.
  Prioritizes low latency reads
*/
module metadata_cache
#(
  parameter BLOCK_WORD_SIZE = 16
)
(
  input wire clk_i,
  input wire nrst_i,

  input wire core_req_i,    // request signal by a core
  input wire [31:0] data_i,
  input wire [31:0] addr_i, // 32-bit addr: 20-bit tag.
  input wire rw_i,          // 0 for write, 1 for read
  output reg [31:0] core_data_o,   // Data from SRAM to Core
  output reg core_ack_o,    // output ack for core cache arbiter
  
  output reg [9:0] sram_addr,     // Port AD
  output reg [31:0] sram_data_o,  // Port DI
  output reg sram_rw,             // 0 for write, 1 for read. Port R_WB
  output reg sram_en,             // enable SRAM. Port EN
  input wire [31:0] sram_data_i,  // Data out from SRAM to core. Port DO
  // All 32 SRAM BEN bits must be set high

  output reg mem_req_o,         // memory request signal
  output reg mem_rw,            
  output reg [1:0] mem_size_o,  // size of stream request
  output reg mem_seqmst_o,      // seq request signal - master
  output reg [31:0] mem_addr,   // Address to memory
  output reg [31:0] mem_data_o, // Data to memory on write back
  input wire [31:0] mem_data_i, // Data in from mem to SRAM/core
  input wire mem_ack_i,         // ack for mem request
  input wire mem_seqslv_i       // seq ready signal - slave
);

parameter BLOCK_BITS = ($clog2(BLOCK_WORD_SIZE));
parameter BLOCKS = (1024 / BLOCK_WORD_SIZE);
parameter INDEX_BITS = ($clog2(BLOCKS));
parameter OFFSET_BITS = ($clog2(BLOCK_WORD_SIZE << 2));
parameter TAG_BITS = (32 - INDEX_BITS - OFFSET_BITS);

localparam TAG_ADDR_RANGE = 31:(32 - TAG_BITS);
localparam INDEX_ADDR_RANGE = (31-TAG_BITS):(OFFSET_BITS);
localparam SRAM_ADDR_RANGE = 11:2;

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

reg [2:0] state;
localparam S_WAIT = 3'd0;
localparam S_TAG = 3'd1;
localparam S_HIT = 3'd2;
localparam S_DIRTY = 3'd3;
localparam S_FILL = 3'd4;
localparam S_MISS_1 = 3'd5;
localparam S_MISS_2 = 3'd6;

integer i;
always @ (posedge clk_i) begin
  if (!nrst_i) begin
    for (i = 0; i < BLOCKS; i = i+1) begin
      valid[i] <= 1'b0;
      dirty[i] <= 1'b0;
      tag[i] <= {TAG_BITS{1'b0}};
    end
    state <= S_WAIT;
    core_ack_o <= 0;
    sram_en <= 0;
    mem_req_o <= 0;
    mem_size_o <= `BUS_SIZE_STREAM;
    mem_seqmst_o <= 0;
    req_addr <= 0;
    req_data <= 0;
    req_rw <= `SRAM_READ;
    req_index <= 0;
    req_tag <= 0;
    wb_count <= 0;
    fill_count <= 0;
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
        core_ack_o <= 1;
        req_addr <= addr_i;
        req_rw <= rw_i;
        req_data <= data_i;
        req_tag <= addr_i[TAG_ADDR_RANGE];
        req_index <= addr_i [INDEX_ADDR_RANGE];
        // pre req from SRAM
        sram_en <= 1;
        sram_rw <= `SRAM_READ;
        sram_addr <= addr_i[SRAM_ADDR_RANGE];
        
        state <= S_TAG;
      end
      else begin
        core_ack_o <= 0;
      end
    end


    S_TAG: begin
      if (valid[req_index] && (req_tag == tag[req_index])) begin
        if (!req_rw) begin
          sram_en <= 1;
          sram_rw <= `SRAM_WRITE;
          sram_addr <= req_addr[SRAM_ADDR_RANGE];
          sram_data_o <= req_data;
          state <= S_HIT;
        end
        // Read Hit, output immediately
        else begin
          core_data_o <= sram_data_i;
          core_ack_o <= 1;
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
      core_ack_o <= 0;
      state <= S_WAIT;
    end
    

    S_DIRTY: begin
      // write back to mem
      mem_req_o <= 1;
      mem_rw <= `BUS_WRITE;
      mem_size_o <= `BUS_SIZE_STREAM;
      mem_addr <= {tag[req_index], req_index, 6'd0};

      if (mem_ack_i) begin
        if (wb_count == 0) begin
          sram_en <= 1;
          sram_rw <= `SRAM_READ;
          sram_addr <= {req_index, 4'd0};
          wb_count <= 1;
        end
        else
          mem_data_o <= sram_data_i; 
        
        if (mem_seqslv_i) begin
          if (wb_count == BLOCK_WORD_SIZE) begin
            mem_seqmst_o <= 1;
            dirty[req_index] <= 0;
            wb_count <= BLOCK_WORD_SIZE+1;
          end
          else begin
            sram_en <= 1;
            sram_rw <= `SRAM_READ;
            sram_addr <= {req_index, wb_count[BLOCK_BITS-1:0]};
            wb_count <= wb_count + 1;
          end
        end
      end

      if (wb_count == BLOCK_WORD_SIZE + 1) begin
        mem_seqmst_o <= 1;
        if (!mem_ack_i) begin
          wb_count <= 0;
          // if write, skip Fill
          state <= req_rw ? S_FILL : S_MISS_1;
        end
      end
    end


    S_FILL: begin
      mem_req_o <= 1;
      mem_rw <= `BUS_READ;
      mem_size_o <= `BUS_SIZE_STREAM;
      mem_addr <= {req_tag, req_index, 6'b0};
      mem_seqmst_o <= 0;

      if (mem_ack_i && mem_seqslv_i) begin
        // read from MEM, write to SRAM
        sram_en <= 1;
        sram_rw <= `SRAM_WRITE;
        sram_addr <= {req_index, fill_count[BLOCK_BITS-1:0]};
        sram_data_o <= mem_data_i;

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
          state <= S_MISS_1;
        end
      end
    end


    S_MISS_1: begin
      sram_en <= 1;
      sram_addr <= req_addr[SRAM_ADDR_RANGE];
      sram_rw <= req_rw;
      sram_data_o <= req_data;
      state <= S_MISS_2;
    end

    S_MISS_2: begin
      if (req_rw == `SRAM_READ)
        core_data_o <= sram_data_i;
      else
        dirty[req_index] <= 1;

      core_ack_o <= 0;
      state <= S_WAIT;
    end

    endcase
  end
end

endmodule;