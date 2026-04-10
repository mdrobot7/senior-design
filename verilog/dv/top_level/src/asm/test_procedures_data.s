; Test data for test_procedures.s. The C versions are shown below.
; 13 tests per batch. DECIMAL_POS = 16 for the tests as written below.
;
; const uint32_t utests[] = { 0, 1, 2, 9, 10, 1000, 1000000, 1000000000, 0x7FFFFFFF,
;                             0x80000000, 0xAF013F8B, 0xFFFFFFFE, 0xFFFFFFFF };
; const int32_t itests[]  = { 0, 1, 2, 9, 10, 1000, 1000000, 1000000000, 0x7FFFFFFF,
;                             0x80000000, 0xAF013F8B, 0xFFFFFFFE, 0xFFFFFFFF };
; const int32_t fixedtests[] = { DOUBLE_TO_FIXED(0), DOUBLE_TO_FIXED(1), DOUBLE_TO_FIXED(2),
;                                DOUBLE_TO_FIXED(9), DOUBLE_TO_FIXED(10), DOUBLE_TO_FIXED(1000),
;                                DOUBLE_TO_FIXED(10000), DOUBLE_TO_FIXED(32767), DOUBLE_TO_FIXED(-32678),
;                                DOUBLE_TO_FIXED(-16555.123), DOUBLE_TO_FIXED(-12345), DOUBLE_TO_FIXED(-2),
;                                DOUBLE_TO_FIXED(-1) };

; utests
#addr 0x00
#d32 le(0x0`32), le(0x1`32), le(0x2`32), le(0x9`32), le(0xA`32), le(0x3E8`32), le(0xF4240`32), le(0x3B9ACA00`32), le(0x7FFFFFFF`32), le(0x80000000`32), le(0xAF013F8B`32), le(0xFFFFFFFE`32), le(0xFFFFFFFF`32)

; itests
#addr 0x40
#d32 le(0x0`32), le(0x1`32), le(0x2`32), le(0x9`32), le(0xA`32), le(0x3E8`32), le(0xF4240`32), le(0x3B9ACA00`32), le(0x7FFFFFFF`32), le(0x80000000`32), le(0xAF013F8B`32), le(0xFFFFFFFE`32), le(0xFFFFFFFF`32)

; fixedtests
#addr 0x80
#d32 le(0x0`32), le(0x10000`32), le(0x20000`32), le(0x90000`32), le(0xa0000`32), le(0x3e80000`32), le(0x27100000`32), le(0x7fff0000`32), le(0x805a0000`32), le(0xbf54e084`32), le(0xcfc70000`32), le(0xfffe0000`32), le(0xffff0000`32)

; Results go between 0x400 and 0x1C00
#addr 0x400
#res 6144

; Stack area, we're using procedure calls and they need stack space
#addr 0x2000
#res 0x400
#d 0x00000000 ; Trick customasm into adding blocks of 0s
