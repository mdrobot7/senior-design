/*
	Predicate module for predication paperwork and storage in uGPU cores

	clk_i:						clock
	nrst_i:						reset
	wr_en_i:					predicate write enable
	wr_mask_i:					write mask for predicate bits
	wr_data_i:					data to write to predicate bits
	instruction_predicate_i:	predicate of the current instruction
	is_predicable_i:			if the instruction is predicable
	status_o:					predicate read status
	equal_o:					instruction predicate == predicate status?
*/
module predicate_m(
	input wire 								clk_i,
	input wire 								nrst_i,
	input wire								wr_en_i,
    input wire[`PREDICATE_BITS_WIDTH-1:0] 	wr_mask_i,
	input wire[`PREDICATE_BITS_WIDTH-1:0] 	wr_data_i,
	input wire[`PREDICATE_BITS_WIDTH-1:0] 	instruction_predicate_i,
	input wire								is_predicable_i,

    output wire[`PREDICATE_BITS_WIDTH-1:0] 	status_o,
	output wire								equal_o
);
	reg[`PREDICATE_BITS_WIDTH-1:0] predicate_bits;

	assign status_o = predicate_bits;
	assign equal_o = (predicate_bits == instruction_predicate_i) | (~is_predicable_i);

	always@(negedge nrst_i, posedge clk_i) begin
		if(!nrst_i) begin : RESET
			predicate_bits <= 0;
		end 
		else if(wr_en_i) begin : WRITE
			integer i;
			for(i = 0; i < `PREDICATE_BITS_WIDTH; i = i + 1) begin
				if(wr_mask_i[i]) begin
					predicate_bits[i] <= wr_data_i[i];
				end
			end
		end
	end

endmodule