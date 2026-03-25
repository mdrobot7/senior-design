/*
 * Internal file, DO NOT INCLUDE! Only include user_defines.v!
 */

`define WIDTH (320)
`define HEIGHT (240)

`define WORD_WIDTH (32)
`define WORD `WORD_WIDTH - 1:0

`define DECIMAL_POS (16)

`define NUM_CORES (3)
`define NUM_CORES_WIDTH ($clog2(`NUM_CORES))

`define VOB_SIZE (`NUM_CORES * 2)
`define SVC_SIZE (6)
`define SVC_BUFFER_SIZE (6)

`define SRAM_1024x32_ADDR_WIDTH (10)

// addresses
`define ADDR_FB0          (0)
`define ADDR_FB1          (0 + 320 * 240)
`define ADDR_DEPTH_BUFFER (0 + 320 * 240 + 320 * 240)

// fixed point
`define FP(x) (($signed((x) * (64'b1 << `DECIMAL_POS))) & 32'hFFFFFFFF)

`define REAL_TO_FP(x) ($signed($rtoi((x) * (64'b1 << `DECIMAL_POS))) & 32'hFFFFFFFF)

`define FP_MUL(a, b) (($signed({ {`WORD_WIDTH{a[`WORD_WIDTH - 1]}}, (a) }) * $signed({ {`WORD_WIDTH{b[`WORD_WIDTH - 1]}}, (b) })) >>> `DECIMAL_POS)
`define FP_DIV(a, b) ((($signed({ {`WORD_WIDTH{a[`WORD_WIDTH - 1]}}, (a) }) << `DECIMAL_POS) / $signed({ {`WORD_WIDTH{b[`WORD_WIDTH - 1]}}, (b) })))
`define FP_INV(x) ((1 << (2 * `DECIMAL_POS)) / $signed({ {`WORD_WIDTH{x[`WORD_WIDTH - 1]}}, x }))

`define FP_SMAX (2 ** (`WORD_WIDTH - 1))

// Wishbone reg
`define WBREG_TYPE_REG (0)
`define WBREG_TYPE_W1C (1) // Write 1 to clear
`define WBREG_TYPE_W1S (2) // Write 1 to set
`define WBREG_TYPE_W1T (3) // Write 1 to toggle

`define SPI_MEM_SIZE (32000000 / 8)

