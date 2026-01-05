`define FP(x) (($signed((x) * (64'b1 << `DECIMAL_POS))) & 32'hFFFFFFFF)

`define FP_MUL(a, b) (($signed({ {`WORD_WIDTH{a[`WORD_WIDTH - 1]}}, (a) }) * $signed({ {`WORD_WIDTH{b[`WORD_WIDTH - 1]}}, (b) })) >>> `DECIMAL_POS)
`define FP_DIV(a, b) ((($signed({ {`WORD_WIDTH{a[`WORD_WIDTH - 1]}}, (a) }) << `DECIMAL_POS) / $signed({ {`WORD_WIDTH{b[`WORD_WIDTH - 1]}}, (b) })))
`define FP_INV(x) ((1 << (2 * `DECIMAL_POS)) / $signed({ {`WORD_WIDTH{x[`WORD_WIDTH - 1]}}, x }))
