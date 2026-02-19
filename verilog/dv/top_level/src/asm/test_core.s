#include "common/defs.s"

; Program to test the core. Runs every instruction,
; some loops, nested conditionals, and edge cases.

; Global registers should be preloaded with *something*

clrp (111)

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
() lli $r9, 4.
() lli $r11, 1234
() mul $r11, $r9, $r0
() lui $r10, 0xFFFF
() lli $r10, -3.140000
() mul $r11, $r9, $r10
() muli $r11, $r11, -3.
() muli $r11, $r11, -1.513000
() muli $r11, $r11, 1/2
() and $r12, $r6, $r11
() andi $r12, $r7, 0b101
() or $r13, $r6, $r9
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
() sllv $r14, $r1, $r2
() sllv $r14, $r14, $r2
() sllv $r14, $r2, $r14
() addi $r14, $zero, -4000
() srlv $r14, $r14, $r2
() addi $r14, $zero, -4000
() srav $r14, $r14, $r2


; Load immediate
() lui $r15, 0x1234
() lli $r15, 0x5678
() lli $r15, 0x9090
() lui $r15, 0x5555


; Outbox
() out


; MAC
() li $r9, 4.123000
() li $r10, 100.
() li $r11, 20.195345
() mac $r9, $r10
() macrd $r12
() maccl
() mac $r9, $r10
() mac $r10, $r11
() mac $r11, $r11
() macrd $r13
() mac $r5, $r6
() macrd $r14
() maccl
() macrd $r15


; Memory
() lw $r8, 0[$r0]
() lw $r8, 4[$r4]
() lw $r8, 6[$r6]
() sw $r8, 0[$r0]
() sb $r8, 5[$r0]
() addi $r10, $r10, 1000
() sw $r11, 0[$r0]
() addi $r11, $zero, 0x1EED
() lw $r11, 0[$r0]
() sw $r10, 0[$r0]
() sw $r10, 4[$r0]
() lb $r12, 2[$r0]
() lb $r13, 5[$r0]


; Predication
clrp (111)
() speq $p0, $r1, $r2
() speq $p0, $r1, $r1    ; p0 -> 1
(001) speq $p1, $r1, $r1 ; p1 -> 1
(001) speq $p2, $r1, $r1 ; Skipped
(011) splt $p2, $r1, $r1 ; p2 -> 0
(011) splt $p2, $r1, $r0 ; p2 -> 1
(111) splt $p2, $r0, $r1 ; p2 -> 0
(011) addi $r15, $zero, -1
(011) splt $p2, $r15, $zero  ; p2 -> 1
(111) spltu $p2, $r15, $zero ; p2 -> 0
clrp (000)
spr $r12
clrp (111)
() srp $r12
(011) addi $r12, $r12, 1
clrp (101)
clrp (111)
() sreq $r14, $r0, $r0
() sreq $r14, $r0, $r1
() srlt $r13, $r0, $r0
() srlt $r13, $r1, $r0
() srlt $r13, $r0, $r1
() srltu $r13, $r0, $r15
() srltu $r13, $r15, $r0


; Control flow
() jump skip
die:
    () mov $r12, $zero
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
    () jal procedure

() addi $r9, $r0, 0xC0F

skip3:


; Pseudoinstructions
() dot4 $r8, $g0
() dot3 $r7, $g4
() cross3 $r12, $r7, $g8
() addv4 $r12, $r7, $g8
() subv4 $r12, $r7, $g8
() addv3 $r12, $r7, $g8
() subv3 $r12, $r7, $g8
() scalev3 $r12, $r7, $g8
() li $r15, 0x12345678
() li $r15, 25.
() li $r15, 67.124000
() li $r15, -15/2
() trunc $r15, $r15
() mov $r10, $r9
() nop
() li $r14, 24
() lb $r13, 5[$r14]


; Conditional: if (r8 == r9) {} else {}
() addi $r8, $g0, 100
() addi $r9, $g0, 100

() speq $p0, $r8, $r9
(001) addi $r8, $r8, 10   ; if {}
(000) addi $r8, $r8, -10  ; else {}
clrp (111)


; Conditional: if (r8 == r9 || r9 == r10) {}
() addi $r8, $r0, 2.500000
() addi $r9, $r0, 7
() addi $r10, $r10, 7

() speq $p0, $r8, $r9
(000) speq $p0, $r9, $r10
(001) addi $r8, $r8, 10   ; if {}
clrp (001)


; Loop: for (i = 0; i < 10; i++)
() andi $r14, $r14, 0 ; r14: Loop counter
() andi $r15, $r15, 0
() addi $r15, $r15, 10 ; r15: Loop end
() speq $p0, $r15, $r15 ; Unconditional predicate set so cond runs
(001) jump cond
loop:
    (001) xor $r10, $r7, $r14 ; Do something productive

    (001) addi $r14, $r14, 1
cond:
    (001) splt $p0, $r14, $r15
    (001) jump loop
exit:
    (000) addi $r10, $g32, -3000
    (000) jump die

procedure:
    () addi $r8, $r8, 3.
    () mul $r8, $r8, $r8
    (110) jal nested_procedure ; Skipped
    () jal nested_procedure
    jret

nested_procedure:
    () xori $r8, $r8, 0x1FFF
    () ori $r8, $r9, 0x111
    () mov $r8, $zero
    jret
