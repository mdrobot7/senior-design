#include "common/defs.s"

; Program to test the core. Runs every instruction,
; some loops, nested conditionals, and edge cases.

; Global registers should be preloaded with *something*

clrp (111)
; clear regs

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
() addi $r1, $r1, -1
() addi $r2, $r2, 2
() addi $r3, $r3, -3
() addi $r4, $r4, 4
() addi $r5, $r5, -5
() addi $r6, $r6, 6
() addi $r7, $r7, -7


; single store as a test, 
() sw $r1, 32[$r0]
() nop
() nop
() nop
() lw $r1, 32[$r0]
() nop
() nop
() nop


; Store
() sw $r1, 0[$r0]
() sw $r2, 4[$r0]
() sb $r7, 8[$r0]
(001) sw $r1, 12[$r0]
(001) sb $r1, 16[$r0]

; Load
() lw $r8, 0[$r0]
() lb $r9, 4[$r0];
(001) lw $r10, 8[$r0]
(001) lb $r11, 12[$r0]
halt
