/*
 * Internal file, DO NOT INCLUDE! Only include user_defines.v!
 */

`define SC_WIDTH ((`WIDTH) > (`HEIGHT) ? $clog2(`WIDTH) : $clog2(`HEIGHT))

`define COLOR_WIDTH (8)
`define COLOR `COLOR_WIDTH - 1:0

`define TEX_DIM_WIDTH (16)
`define TEX_DIM `TEX_DIM_WIDTH - 1:0

`define WORD_SMAX (1 << (`WORD_WIDTH - 2))

`define DIVIDER_WIDTH (`DECIMAL_POS + `WORD_WIDTH)
`define DIVIDER_USERS (5)

`define RAST_WAVG_OUT_WIDTH (`SC_WIDTH * 2 + `WORD_WIDTH * 3)
`define RAST_DT_OUT_WIDTH (`SC_WIDTH * 2 + `WORD_WIDTH * 3)

`define WAVG_DIV_SHIFT (6)

`define VERTEX_ORDER_TARGET_CACHE `NUM_CORES
`define VERTEX_ORDER_WIDTH ($clog2(`NUM_CORES + 1))

`define SHADED_VERTEX_WIDTH (32 * 8)
`define SHADED_VERTEX (`SHADED_VERTEX_WIDTH-1):0

`define FRAGMENT_WIDTH (32 * 8)
`define FRAGMENT (`FRAGMENT_WIDTH-1):0
