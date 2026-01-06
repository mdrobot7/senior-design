; Test data for test_procedures.s. The C versions are shown below.
; 13 tests per batch. DECIMAL_POS = 10 for the tests as written below.
;
; const uint32_t utests[] = { 0, 1, 2, 9, 10, 1000, 1000000, 1000000000, 0x7FFFFFFF,
;                             0x80000000, 0xAF013F8B, 0xFFFFFFFE, 0xFFFFFFFF };
; const int32_t itests[]  = { 0, 1, 2, 9, 10, 1000, 1000000, 1000000000, 0x7FFFFFFF,
;                             0x80000000, 0xAF013F8B, 0xFFFFFFFE, 0xFFFFFFFF };
; const int32_t fixedtests[] = { FLOAT_TO_FIXED(0), FLOAT_TO_FIXED(1), FLOAT_TO_FIXED(2), FLOAT_TO_FIXED(9),
;                                FLOAT_TO_FIXED(10), FLOAT_TO_FIXED(1000), FLOAT_TO_FIXED(1000000), FLOAT_TO_FIXED(2097151),
;                                FLOAT_TO_FIXED(-2097152), FLOAT_TO_FIXED(-221947.123), FLOAT_TO_FIXED(-123457), FLOAT_TO_FIXED(-2),
;                                FLOAT_TO_FIXED(-1) };

; utests
#addr 0x00
#d32 le(0x0`32), le(0x1`32), le(0x2`32), le(0x9`32), le(0xA`32), le(0x3E8`32), le(0xF4240`32), le(0x3B9ACA00`32), le(0x7FFFFFFF`32), le(0x80000000`32), le(0xAF013F8B`32), le(0xFFFFFFFE`32), le(0xFFFFFFFF`32)

; itests
#addr 0x40
#d32 le(0x0`32), le(0x1`32), le(0x2`32), le(0x9`32), le(0xA`32), le(0x3E8`32), le(0xF4240`32), le(0x3B9ACA00`32), le(0x7FFFFFFF`32), le(0x80000000`32), le(0xAF013F8B`32), le(0xFFFFFFFE`32), le(0xFFFFFFFF`32)

; fixedtests
#addr 0x80
#d32 le(0x0`32), le(0x400`32), le(0x800`32), le(0x2400`32), le(0x2800`32), le(0xFA000`32), le(0x3D090000`32), le(0x7FFFFC00`32), le(0x80000000`32), le(0xF2741380`32), le(0xF876FC00`32), le(0xFFFFF800`32), le(0xFFFFFC00`32)

; Results go between 0x400 and 0x1C00
#addr 0x1C00
