/*
    Generic configuration register connected to
    the Wishbone bus. Address must be specified here
    AND using `address_map in user_project_wrapper.
    Address doesn't need to be set if size = 1.

    Allows you to select certain bits for read/write
    perms and set the register reset value. These
    should be constants.

    Uses lib_wishbone_helper, meaning all writes/reads
    have to be in 32-bit (word) sizes. The only allowed
    register sizes are word increments.
*/
module wishbone_register_m #(
    parameter RESET_VALUE = 32'h0,
    parameter SIZE_WORDS = 1,
    parameter TYPE = `WBREG_TYPE_REG,
    parameter ADDRESS = 0
) (
    // Wishbone
    input wire wb_clk_i,
    input wire wb_rst_i,
    input wire wbs_stb_i,
    input wire wbs_cyc_i,
    input wire wbs_we_i,
    input wire [3:0] wbs_sel_i,
    input wire [`WORD_WIDTH-1:0] wbs_dat_i,
    input wire [`WORD_WIDTH-1:0] wbs_adr_i,
    output wire wbs_ack_o,
    output wire [`WORD_WIDTH-1:0] wbs_dat_o,

    // Register
    input wire [(SIZE_WORDS * `WORD_WIDTH)-1:0] access_read_mask_i, // 1, can read, 0 cant read
    input wire [(SIZE_WORDS * `WORD_WIDTH)-1:0] access_write_mask_i, // 1: Bit is writable. If a bit in periph_read_mask_i is set,
                                                                     // the corresponding bit in this field must be cleared.
    input wire [(SIZE_WORDS * `WORD_WIDTH)-1:0] periph_read_mask_i,  // 1: Read from reg_i, 0: read from reg_o.

    input wire [(SIZE_WORDS * `WORD_WIDTH)-1:0] enable_prot_i,       // 1: Bit is enable-protected
    input wire                                  enable_i,            // 1: Downstream device is enabled

    input wire [(SIZE_WORDS * `WORD_WIDTH)-1:0] reg_i,               // Read from peripheral
    output reg [(SIZE_WORDS * `WORD_WIDTH)-1:0] reg_o                // Write to peripheral
);

    wire wbs_we;
    wishbone_helper_m wb_helper(
        .wb_clk_i(wb_clk_i),
        .wbs_we_i(wbs_we_i),
        .wbs_stb_i(wbs_stb_i),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_sel_i(wbs_sel_i),
        .wbs_effective_we_o(wbs_we),
        .wbs_ack_o(wbs_ack_o)
    );

    // (wbs_adr_i - ADDRESS) = 0 should return reg_o[31:0]
    wire [`WORD_WIDTH-1:0] bit_offset = (SIZE_WORDS == 1) ? 0 : {(wbs_adr_i - ADDRESS), 3'b000}; // Bit offset = byte offset * 8
    wire [`WORD_WIDTH-1:0] read_rego = reg_o[bit_offset +: `WORD_WIDTH];
    wire [`WORD_WIDTH-1:0] read_regi = reg_i[bit_offset +: `WORD_WIDTH];

    assign wbs_dat_o =  ((read_rego & ~periph_read_mask_i)
                       | (read_regi &  periph_read_mask_i))
                       & access_read_mask_i;

    integer i;

    always @ (posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin // Wishbone rst is positive
            reg_o <= RESET_VALUE;
        end
        else if (wb_clk_i) begin
            if (wbs_we) begin
                // Should synthesize to a 5-input mux on each bit of the reg
                // with the inputs reg_o[i], din[i], 0, 1, !reg_o[i] corresponding
                // to no change, input data, clear, set, and toggle.
                for (i = 0; i < (SIZE_WORDS * `WORD_WIDTH); i = i + 1) begin
                    if (access_write_mask_i[bit_offset + i] &&
                        (!enable_prot_i[bit_offset + i] || !enable_i)) begin
                        if (TYPE == `WBREG_TYPE_REG)
                            reg_o[bit_offset + i] <= wbs_dat_i[i];
                        if (TYPE == `WBREG_TYPE_W1C && wbs_dat_i[i])
                            reg_o[bit_offset + i] <= 0;
                        if (TYPE == `WBREG_TYPE_W1S && wbs_dat_i[i])
                            reg_o[bit_offset + i] <= 1;
                        if (TYPE == `WBREG_TYPE_W1T && wbs_dat_i[i])
                            reg_o[bit_offset + i] <= !reg_o[bit_offset + i];
                    end
                    // else don't change
                end
            end
        end
    end

endmodule
