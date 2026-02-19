#include "common/defs.s"

; Program to test alternating memory accessses.

; clear regs
clrp (111)

() andi $r0, $r0, 0
() andi $r1, $r0, 0
() andi $r2, $r0, 0
() andi $r3, $r0, 0
() andi $r4, $r0, 0
() andi $r5, $r0, 0
() andi $r6, $r0, 0
() andi $r7, $r0, 0
() andi $r8, $r0, 0
() andi $r9, $r0, 0
() andi $r10, $r0, 0
() andi $r11, $r0, 0
() andi $r12, $r0, 0
() andi $r13, $r0, 0
() andi $r14, $r0, 0
() andi $r15, $r0, 0

; Preload registers
() addi $r0, $r0, 0
() addi $r1, $r1, 16
() addi $r2, $r2, 2
() addi $r3, $r3, -3
() addi $r4, $r4, 4
() addi $r5, $r5, -5
() addi $r6, $r6, 6
() addi $r7, $r7, -7

() sw $r1, 0[$r0]
() lw $r8, 0[$r0]
() sw $r2, 0[$r0]
() lw $r9, 0[$r0]
() sw $r3, 0[$r0]
() lw $r10, 0[$r0]

() addi $r0, $r0, 4
() sw $r0, 0[$r0]
() lw $r10, 0[$r0]

() addi $r0, $r0, 4
() sw $r0, 0[$r0]
() lw $r11, 0[$r0]

() lw $r0, 0[$r0]
() addi $r5, $r0, 1

() lui $r11, 0x1234
() lli $r11, 0x5678
() sw $r11, 0[$r1]
() lb $r12, 0[$r1]
() lb $r13, 1[$r1]
() lb $r14, 2[$r1]
() lb $r15, 3[$r1]

halt
