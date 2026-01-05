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
; r4: ret
__div_uint:
    clrp (111)
    (000) addi $sp, $sp, -8
    (000) sw $r3, 0[$sp]
    (000) sw $r4, 4[$sp]

    (000) speq $p0, $r0, $zero
    (000) speq $p0, $r1, $zero
    (000) splt $p0, $r0, $r1
    (001) mov $r4, $zero        ; if (n == 0 || d == 0 || n < d) ret = 0;
    (000) addi $r4, $zero, 1
    (000) speq $p1, $r1, $r4
    (010) mov $r4, $r0          ; else if (d == 1) ret = n;
    (000) speq $p2, $r0, $r1    ; else if (n == d) ret = 1; // r4 already set to 1
    spr $r3
    (000) jal __div_loop        ; else ret = __div_loop(n, d)
    (000) mov $r4, $r2

    clrp (111)
    (000) mov $r2, $r4
    (000) lw $r3, 0[$sp]
    (000) lw $r4, 4[$sp]
    (000) addi $sp, $sp, 8
    (000) srp $r3
    jret
}

; r2 = r0 / r1
#if DIV_FIXED {
__div_fixed:
    clrp (111)
    (000) sra $r1, $r1, DECIMAL_POS
    ; Continue to __div_int
}

; r2 = r0 / r1
#if DIV_INT || DIV_FIXED {
; $r4: n
; $r5: d
; $r6: scratch
; $at
__div_int:
    clrp (111)
    (000) addi $sp, $sp, -16
    (000) sw $r3,  0[$sp]
    (000) sw $r4,  4[$sp]
    (000) sw $r5,  8[$sp]
    (000) sw $r6, 12[$sp]

    (000) mov $r4, $r0
    (000) splt $p0, $r0, $zero
    (001) not $r0, $r0
    (001) addi $r0, $r0, 1     ; abs_n = (n < 0) ? -n : n
    clrp (111)

    (000) mov $r5, $r1
    (000) splt $p0, $r1, $zero
    (001) not $r1, $r1
    (001) addi $r1, $r1, 1     ; abs_d = (d < 0) ? -d : d
    clrp (111)

    spr $r3
    (000) jal __div_uint       ; ret = __div_uint(abs_n, abs_d)

    (000) addi $r6, $zero, 1
    (000) sll $r6, $r6, 31
    (000) and $r4, $r4, $r6
    (000) and $r5, $r5, $r6
    (000) speq $p0, $r4, $r5 ; if ((n & 0x80000000) != (d & 0x80000000))
    (000) not $r2, $r2
    (000) addi $r2, $r2, 1     ; ret = -ret

    clrp (111)
    (000) lw $r3,  0[$sp]
    (000) lw $r4,  4[$sp]
    (000) lw $r5,  8[$sp]
    (000) lw $r6, 12[$sp]
    (000) addi $sp, $sp, 16
    (000) srp $r3
    jret
}

; r2 = r0 % r1
#if MOD_UINT || MOD_FIXED || MOD_INT {
; r4: ret
__mod_uint:
    clrp (111)
    (000) addi $sp, $sp, -8
    (000) sw $r3,  0[$sp]
    (000) sw $r4,  4[$sp]

    (000) speq $p0, $r0, $zero
    (000) speq $p0, $r1, $zero
    (000) addi $r4, $zero, 1
    (000) speq $p0, $r1, $r2
    (001) mov $r4, $zero      ; if (n == 0 || d == 0 || d == 1) ret = 0;
    spr $r3
    (000) jal __div_loop      ; else ret = __div_loop(n, d)
    (000) mov $r4, $r0

    clrp (111)
    (000) mov $r4, $r2
    (000) lw $r3,  0[$sp]
    (000) lw $r4,  4[$sp]
    (000) addi $sp, $sp, 8
    (000) srp $r3
    jret
}

; r2 = r0 % r1
#if MOD_FIXED {
__mod_fixed:
    ; Continue to __mod_int
}

; r2 = r0 % r1
#if MOD_INT || MOD_FIXED {
; r4: n
__mod_int:
    clrp (111)
    (000) addi $sp, $sp, -8
    (000) sw $r3,  0[$sp]
    (000) sw $r4,  4[$sp]

    (000) mov $r4, $r0
    (000) splt $p0, $r0, $zero
    (001) not $r0, $r0
    (001) addi $r0, $r0, 1     ; abs_n = (n < 0) ? -n : n
    clrp (111)

    (000) splt $p0, $r1, $zero
    (001) not $r1, $r1
    (001) addi $r1, $r1, 1     ; abs_d = (d < 0) ? -d : d
    clrp (111)

    spr $r3
    (000) jal __div_uint       ; ret = __div_uint(abs_n, abs_d)
    (000) mov $r2, $r0

    (000) speq $p0, $r4, $zero ; if (n < 0)
    (000) not $r2, $r2
    (000) addi $r2, $r2, 1     ; ret = -ret

    clrp (111)
    (000) lw $r3,  0[$sp]
    (000) lw $r4,  4[$sp]
    (000) addi $sp, $sp, 8
    (000) srp $r3
    jret
}

#if DIV_UINT || DIV_FIXED || DIV_INT || MOD_UINT || MOD_FIXED || MOD_INT {
; Private procedure, do not directly call!
; r0: input numerator, returned remainder
; r1: input denominator
; r2: returned quotient
; r3: predicate bits from caller
;
; r4: shift
; r5: (d << shift)
; r6: scratch
__div_loop:
    clrp (111)
    (000) addi $sp, $sp, -12
    (000) sw $r4, 0[$sp]
    (000) sw $r5, 4[$sp]
    (000) sw $r6, 8[$sp]

    (000) mov $r2, $zero
    (000) addi $r4, $zero, 31
    (000) jump __div_loop_cond
__div_loop_start:
    (000) sllv $r5, $r1, $r4
    (000) sub $r6, $r0, $r5
    (000) srlt $r6, $r0, $r6
    (000) speq $p2, $r6, $zero ; (n - (d << shift) <= n)
    (100) srlv $r6, $r5, $r4
    (100) speq $p2, $r6, $r1   ; ((d << shift) >> shift == d)
    (100) sub $r0, $r0, $r5    ; n = n - (d << shift)
    (100) addi $r6, $zero, 1
    (100) sllv $r6, $r6, $r4
    (100) or $r2, $r2, $r6     ; q = q | (1 << shift)
    clrp (100)
    (000) addi $r4, $r4, -1    ; shift = shift - 1
__div_loop_cond:
    (000) splt $p1, $r4, $zero
    (000) speq $p1, $r0, $zero ; while (shift >= 0 && n != 0)
    (000) jump __div_loop_start
__div_exit:
    clrp (111)
    (000) lw $r4, 0[$sp]
    (000) lw $r5, 4[$sp]
    (000) lw $r6, 8[$sp]
    (000) addi $sp, $sp, 12
    (000) srp $r3
    jret
}
