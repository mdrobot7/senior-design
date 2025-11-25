#once

#include "defs.s"

; Common procedure implementations.
;
; Enabled through #ifs to generate assembly
; "functions" that don't get assembled unless the
; programmer specifically enables them.
;
; Every procedure takes arguments in $r0, $r1 and
; returns in $r2. Predicates must be stored in $r3
; before the function call. $at is not preserved
; through a function call.
;
; Stack frames build down, lower number registers get
; stored in lower memory addresses.


; r2 = r0 / r1
#if DIV_UINT || DIV_FIXED || DIV_INT {
    ; Regs used: r4, __div_loop
__div_uint:
    clrp (111)
    (000) addi $sp, $sp, -24
    (000) sw $r4,  0[$sp]
    (000) sw $r5,  4[$sp]
    (000) sw $r6,  8[$sp]
    (000) sw $r7, 12[$sp]
    (000) sw $r8, 16[$sp]
    (000) sw $r9, 20[$sp]

    (000) speq $p0, $r0, $zero
    (000) speq $p0, $r1, $zero
    (000) splt $p0, $r0, $r1
    (001) mov $r2, $zero        ; if (n == 0 || d == 0 || n < d) ret = 0;
    (000) addi $r4, $zero, 1
    (000) speq $p1, $r1, $r4
    (010) mov $r2, $r0          ; else if (d == 1) ret = n;
    (000) speq $p2, $r0, $r1
    (100) mov $r2, $r4          ; else if (n == d) ret = 1;
    (000) spr $r4
    (000) addi $r4, $r4, -8
    (000) splt $p0, $r4, $zero  ; Hack to invert speq $p0, $r4, $zero
    (000) mov $r4, $r0
    (000) mov $r5, $r1
    (000) jal __div_loop
    (000) mov $r2, $r6          ; else ret = __div_loop(n, d)

    clrp (111)
    (000) lw $r4,  0[$sp]
    (000) lw $r5,  4[$sp]
    (000) lw $r6,  8[$sp]
    (000) lw $r7, 12[$sp]
    (000) lw $r8, 16[$sp]
    (000) lw $r9, 20[$sp]
    (000) addi $sp, $sp, 24
    (000) srp $r3
    jret
}

; r2 = r0 / r1
#if DIV_FIXED {
; Regs used: __div_int, __div_loop
__div_fixed:
    clrp (111)
    (000) sra $r1, $r1, DECIMAL_POS
    ; Continue to __div_int
}

; r2 = r0 / r1
#if DIV_INT || DIV_FIXED {
; Regs used: $r10, $r11, $r12, $at, __div_uint, __div_loop
__div_int:
    clrp (111)
    (000) addi $sp, $sp, -12
    (000) sw $r10, 0[$sp]
    (000) sw $r11, 4[$sp]
    (000) sw $r12, 8[$sp]

    (000) mov $r10, $r0
    (000) splt $p0, $r0, $zero
    (001) not $r0, $r0
    (001) addi $r0, $r0, 1     ; n = n < 0 ? -n : n
    clrp (111)

    (000) mov $r11, $r1
    (000) splt $p0, $r1, $zero
    (001) not $r1, $r1
    (001) addi $r1, $r1, 1     ; d = d < 0 ? -d : d
    clrp (111)

    (000) mov $r12, $r3
    (000) mov $r3, $zero
    (000) jal __div_uint ; else ret = __div_uint(n, d), call like an inline
    (000) mov $r3, $r12

    (000) addi $r12, $zero, 1
    (000) sll $r12, $r12, 31
    (000) and $r10, $r10, $r4
    (000) and $r11, $r11, $r4
    (000) speq $p0, $r10, $r11
    (000) not $r2, $r2
    (000) addi $r2, $r2, 1    ; if ((n & 0x80000000) != (d & 0x80000000))

    clrp (111)
    (000) lw $r10, 0[$sp]
    (000) lw $r11, 4[$sp]
    (000) lw $r12, 8[$sp]
    (000) addi $sp, $sp, 12
    (000) srp $r3
    jret
}

; r2 = r0 % r1
#if MOD_UINT || MOD_FIXED || MOD_INT {
; Regs used: $r4, __div_loop
__mod_uint:
    clrp (111)
    (000) addi $sp, $sp, -24
    (000) sw $r4,  0[$sp]
    (000) sw $r5,  4[$sp]
    (000) sw $r6,  8[$sp]
    (000) sw $r7, 12[$sp]
    (000) sw $r8, 16[$sp]
    (000) sw $r9, 20[$sp]

    (000) speq $p0, $r0, $zero
    (000) speq $p0, $r1, $zero
    (000) addi $r4, $zero, 1
    (000) speq $p0, $r1, $r4
    (001) mov $r2, $zero      ; if (n == 0 || d == 0 || d == 1) ret = 0;
    (000) mov $r4, $r0
    (000) mov $r5, $r1
    (000) jal __div_loop      ; else ret = __div_loop(n, d)
    (000) mov $r2, $r4

    clrp (111)
    (000) lw $r4,  0[$sp]
    (000) lw $r5,  4[$sp]
    (000) lw $r6,  8[$sp]
    (000) lw $r7, 12[$sp]
    (000) lw $r8, 16[$sp]
    (000) lw $r9, 20[$sp]
    (000) addi $sp, $sp, 24
    (000) srp $r3
    jret
}

; r2 = r0 % r1
#if MOD_FIXED {
; Regs used: __mod_int, __div_loop
__mod_fixed:
    ; Continue to __mod_int
}

; r2 = r0 % r1
#if MOD_INT || MOD_FIXED {
; Regs used: $r10, $r11, $r12, $at, __div_loop
__mod_int:
    clrp (111)
    (000) addi $sp, $sp, -12
    (000) sw $r10,  0[$sp]
    (000) sw $r11,  4[$sp]
    (000) sw $r12,  8[$sp]

    (000) mov $r10, $r0
    (000) splt $p0, $r0, $zero
    (001) not $r0, $r0
    (001) addi $r0, $r0, 1     ; temp_n = n < 0 ? -n : n
    clrp (111)

    (000) mov $r11, $r1
    (000) splt $p0, $r1, $zero
    (001) not $r1, $r1
    (001) addi $r1, $r1, 1     ; temp_d = d < 0 ? -d : d
    clrp (111)

    (000) mov $r12, $r3
    (000) mov $r3, $zero
    (000) jal __mod_uint ; else ret = __mod_uint(n, d), call like an inline
    (000) mov $r3, $r12

    (000) splt $p0, $r10, $zero
    (001) not $r2, $r2
    (001) addi $r2, $r2, 1     ; if (n < 0) ret = -ret;

    clrp (111)
    (000) lw $r10,  0[$sp]
    (000) lw $r11,  4[$sp]
    (000) lw $r12,  8[$sp]
    (000) addi $sp, $sp, 12
    (000) srp $r3
    jret
}

#if DIV_UINT || DIV_FIXED || DIV_INT || MOD_UINT || MOD_FIXED || MOD_INT {
; Private procedure, do not directly call!
; Treated like an inline, doesn't follow calling convention.
; Regs used:
; r4: input numerator, returned remainder
; r5: input denominator
; r6: returned quotient
; r7: shift
; r8: (d << shift)
; r9: scratch
; p1, p2
__div_loop:
    clrp (111)
    (000) mov $r6, $zero
    (000) addi $r7, $zero, 31
    (000) jump __div_loop_compare
__div_loop_start:
    (000) sllv $r8, $r5, $r7
    (000) sub $r9, $r4, $r8
    (000) srlt $r9, $r4, $r9
    (000) speq $p2, $r9, $zero ; (n - (d << shift) <= n)
    (100) srlv $r9, $r8, $r7
    (100) speq $p2, $r9, $r5   ; ((d << shift) >> shift == d)
    (100) sub $r4, $r4, $r8    ; n = n - (d << shift)
    (100) addi $r9, $zero, 1
    (100) sllv $r9, $r9, $r7
    (100) or $r6, $r6, $r9     ; q = q | (1 << shift)
    clrp (100)
    (000) addi $r7, $r7, -1    ; shift = shift - 1
__div_loop_compare:
    (000) splt $p1, $r7, $zero
    (000) speq $p1, $r4, $zero ; while (shift >= 0 && n != 0)
    (000) jump __div_loop_start
__div_exit:
    clrp (111)
    jret
}