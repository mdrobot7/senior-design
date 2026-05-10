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

() jump l1
() speq $p0, $r1, $r1
(001) addi $r8, $r8, 10

l1:
() speq $p1, $r1, $r1
() jump l1
() jal l1
(010) jump end
() addi $r1, $r1, 16

end:
(010) addi $r9, $r9, 100
(010) addi $r10, $r9, 101
halt
