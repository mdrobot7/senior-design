#include "defs.s"

; Program to test the core. Runs every instruction,
; some loops, nested conditionals, and edge cases.

; Global registers should be preloaded with *something*


; Preload registers
() andi $r0, $r0, 0
() addi $r0, $r0, 0
() andi $r1, $r1, 0
() addi $r1, $r1, -1
() andi $r2, $r2, 0
() addi $r2, $r2, 2
() andi $r3, $r3, 0
() addi $r3, $r3, -3
() andi $r4, $r4, 0
() addi $r4, $r4, 4
() andi $r5, $r5, 0
() addi $r5, $r5, -5
() andi $r6, $r6, 0
() addi $r6, $r6, 6
() andi $r7, $r7, 0
() addi $r7, $r7, -7


; Math
() add $r8, $r1, $r6
() addi $r9, $r8, 10
() addi $r9, $r9, -10
() sub $r10, $r9, $r0
() sub $r10, $r0, $r9
() mul $r11, $r9, $r4
() muli $r11, $r11, -10
() muli $r11, $r11, -3.
() muli $r11, $r11, -1.513
() muli $r11, $r11, 1/2
() and $r12, $r6, $r11
() andi $r12, $r7, 0b101
() or $r13, $r1, $r6
() ori $r13, $r13, 0xF00
() xor $r13, $r12, $r13
() xori $r13, $r11, 0x555
() sll $r14, $r1, 0
() sll $r14, $r1, 5
() sll $r14, $r1, 31
() srl $r15, $r7, 1
() srl $r15, $r7, 3
() srl $r15, $r7, 31
() addi $r15, $r15, -10
() sra $r15, $r15, 1
() sra $r15, $r15, 10


; Outbox
() out $r0


; MAC
() mac $r1, $r1
() mac $r3, $r4
() mac $r5, $r6
() macrd $r15
() mac $r5, $r6
() macrd $r15
() maccl
() macrd $r15


; Memory
() lw $r8, 0[$r0]
() lw $r8, 4[$r8]
() lw $r8, 4[$r2]
() sw $r8, 0[$r0]
() sb $r8, 5[$r0]
() addi $r10, $r10, 1000
() sw $r11, 0[$r0]
() lw $r11, 0[$r0]
() sw $r10, 1[$r0]
() sw $r10, 3[$r0]
() lw $r12, 2[$r0]
() lw $r13, 0[$r0]
; () lwv ; TODO: Later, we need to think about these a little more
; () swv
; () sbv


; Predication
() speq $p0, $r1, $r2
() speq $p0, $r1, $r1    ; p0 -> 1
(001) speq $p1, $r1, $r1 ; p1 -> 1
(001) speq $p2, $r1, $r1 ; Skipped
(011) splt $p2, $r1, $r1 ; p2 -> 0
(011) splt $p2, $r1, $r0 ; p2 -> 1
(111) splt $p2, $r0, $r1 ; p2 -> 0
(101) clrp (110)         ; Skipped
(011) spr $r15
(011) clrp (111)
() sreq $r14, $r0, $r0
() sreq $r14, $r0, $r1
() srlt $r13, $r0, $r0
() srlt $r13, $r1, $r0
() srlt $r13, $r0, $r1


; Control flow
() jump skip
die:
    halt
skip:
    () jump skip2

() add $r8, $r1, $r6
() addi $r9, $r8, 10
() addi $r9, $r9, -10
() sub $r10, $r9, $r0
() sub $r10, $r0, $r9
() mul $r11, $r9, $r4

skip2:
    (001) jump skip3 ; Not taken on any cores

() addi $r9, $r0, 0xC0F

skip3:


; Conditional: if (r8 == r9) {} else {}
() addi $r8, $g0, 100
() addi $r9, $g0, 100

() speq $p0, $r8, $r9
(001) addi $r8, $r8, 10   ; if {}
(000) addi $r8, $r8, -10  ; else {}
(001) clrp (111)


; Conditional: if (r8 == r9 || r9 == r10) {}
() addi $r8, $r0, 2.5
() addi $r9, $r0, 7
() addi $r10, $r10, 7

() speq $p0, $r8, $r9
(000) speq $p0, $r9, $r10
(001) addi $r8, $r8, 10   ; if {}
(001) clrp (001)


; Loop: for (i = 0; i < 10; i++)
() andi $r14, $r14, 0 ; r14: Loop counter
() andi $r15, $r15, 0
() addi $r15, $r15, 10 ; r15: Loop end
() splt $p0, $r15, $r15 ; Unconditional predicate set so compare runs
(001) jump compare
loop:
    (001) xor $r10, $r7, $r14 ; Do something productive

    (001) addi $r14, $r14, 1
compare:
    (001) splt $p0, $r14, $r15
    (001) jump loop
exit:
    (000) addi $r10, $g32, -3000
    (000) jump die
