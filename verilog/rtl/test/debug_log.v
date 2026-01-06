// `define DL_ENABLE

`define DL_NAME_MAX_LEN (256)

`define DL_RED     "\033[31m"
`define DL_GREEN   "\033[32m"
`define DL_YELLOW  "\033[33m"
`define DL_BLUE    "\033[34m"
`define DL_MAGENTA "\033[35m"
`define DL_CYAN    "\033[36m"

`define DL_DEFINE(name, label, color, enabled) \
    localparam name``_label   = label; \
    localparam name``_color   = color; \
    localparam name``_enabled = enabled ? 1'b1 : 1'b0;

`ifdef DL_ENABLE
`define DL(name, msg) \
    begin \
        if (name``_enabled) begin \
            $display("%s[ %s ] %s\033[0m", name``_color, name``_label, $sformatf msg); \
        end \
    end
`else
`define DL(name, msg) \
    begin end
`endif

