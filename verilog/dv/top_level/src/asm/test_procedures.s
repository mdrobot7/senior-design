#include "common/defs.s"

; Program to test the procedures defined in
; common/procedures.s. Assumes the core has
; passed test_core.s beforehand and all base
; functionality works.


; Tests are preloaded into memory at these addresses.
; Test data is in ./test_procedures_data.s and is assembled
; into a bin file.
NUM_TESTS        = 13
U_TESTS_ADDR     = 0x00000000
I_TESTS_ADDR     = 0x00000040
FIXED_TESTS_ADDR = 0x00000080

; Outputs NUM_TESTS * NUM_TESTS words of data by multiplying
; every combination of inputs in each test bank.
UDIV_RESULTS_ADDR     = 0x00000400
IDIV_RESULTS_ADDR     = 0x00000800
FIXEDDIV_RESULTS_ADDR = 0x00000C00
UMOD_RESULTS_ADDR     = 0x00001000
IMOD_RESULTS_ADDR     = 0x00001400
FIXEDMOD_RESULTS_ADDR = 0x00001800

; Test udiv
; r0-r3: Reserved for calling convention
; r4: loop end (same for outer/inner)
; r5: outer loop counter
; r6: inner loop counter
; r7: dest counter
; r8: scratch
() addi $r4, $zero, NUM_TESTS
() sll $r4, $r4, 2
() mov $r5, $zero
() mov $r6, $zero
() addi $r7, $zero, UDIV_RESULTS_ADDR
() splt $p0, $zero, $zero
(001) jump udiv_outer_cond
udiv_outer_loop:                      ; for (i = 0; i < NUM_TESTS; i++)
    (001) addi $r8, $r5, U_TESTS_ADDR
    (001) lw $r0, 0[$r8]
    (001) splt $p1, $zero, $zero
    (011) jump udiv_inner_cond
    udiv_inner_loop:                  ; for (j = 0; j < NUM_TESTS; j++)
        (011) addi $r8, $r6, U_TESTS_ADDR
        (011) lw $r1, 0[$r8]
              spr $r3
        (011) jal __div_uint
        (011) sw $r2, 0[$r7]
        (011) addi $r7, $r7, 4
        (011) addi $r6, $r6, 4
    udiv_inner_cond:
        (011) splt $p1, $r6, $r4
        (011) jump udiv_inner_loop
    (001) addi $r5, $r5, 4
udiv_outer_cond:
    (001) splt $p0, $r5, $r4
    (001) jump udiv_outer_loop

; Test idiv
() mov $r5, $zero
() mov $r6, $zero
() addi $r7, $zero, IDIV_RESULTS_ADDR
() splt $p0, $zero, $zero
(001) jump idiv_outer_cond
idiv_outer_loop:                      ; for (i = 0; i < NUM_TESTS; i++)
    (001) addi $r8, $r5, I_TESTS_ADDR
    (001) lw $r0, 0[$r8]
    (001) splt $p1, $zero, $zero
    (011) jump idiv_inner_cond
    idiv_inner_loop:                  ; for (j = 0; j < NUM_TESTS; j++)
        (011) addi $r8, $r6, I_TESTS_ADDR
        (011) lw $r1, 0[$r8]
              spr $r3
        (011) jal __div_int
        (011) sw $r2, 0[$r7]
        (011) addi $r7, $r7, 4
        (011) addi $r6, $r6, 4
    idiv_inner_cond:
        (011) splt $p1, $r6, $r4
        (011) jump idiv_inner_loop
    (001) addi $r5, $r5, 4
idiv_outer_cond:
    (001) splt $p0, $r5, $r4
    (001) jump idiv_outer_loop

; Test fixeddiv
() mov $r5, $zero
() mov $r6, $zero
() addi $r7, $zero, FIXEDDIV_RESULTS_ADDR
() splt $p0, $zero, $zero
(001) jump fixeddiv_outer_cond
fixeddiv_outer_loop:                      ; for (i = 0; i < NUM_TESTS; i++)
    (001) addi $r8, $r5, FIXED_TESTS_ADDR
    (001) lw $r0, 0[$r8]
    (001) splt $p1, $zero, $zero
    (011) jump fixeddiv_inner_cond
    fixeddiv_inner_loop:                  ; for (j = 0; j < NUM_TESTS; j++)
        (011) addi $r8, $r6, FIXED_TESTS_ADDR
        (011) lw $r1, 0[$r8]
              spr $r3
        (011) jal __div_fixed
        (011) sw $r2, 0[$r7]
        (011) addi $r7, $r7, 4
        (011) addi $r6, $r6, 4
    fixeddiv_inner_cond:
        (011) splt $p1, $r6, $r4
        (011) jump fixeddiv_inner_loop
    (001) addi $r5, $r5, 4
fixeddiv_outer_cond:
    (001) splt $p0, $r5, $r4
    (001) jump fixeddiv_outer_loop

; Test umod
() mov $r5, $zero
() mov $r6, $zero
() addi $r7, $zero, UMOD_RESULTS_ADDR
() splt $p0, $zero, $zero
(001) jump umod_outer_cond
umod_outer_loop:                      ; for (i = 0; i < NUM_TESTS; i++)
    (001) addi $r8, $r5, U_TESTS_ADDR
    (001) lw $r0, 0[$r8]
    (001) splt $p1, $zero, $zero
    (011) jump umod_inner_cond
    umod_inner_loop:                  ; for (j = 0; j < NUM_TESTS; j++)
        (011) addi $r8, $r6, U_TESTS_ADDR
        (011) lw $r1, 0[$r8]
              spr $r3
        (011) jal __mod_uint
        (011) sw $r2, 0[$r7]
        (011) addi $r7, $r7, 4
        (011) addi $r6, $r6, 4
    umod_inner_cond:
        (011) splt $p1, $r6, $r4
        (011) jump umod_inner_loop
    (001) addi $r5, $r5, 4
umod_outer_cond:
    (001) splt $p0, $r5, $r4
    (001) jump umod_outer_loop

; Test imod
() mov $r5, $zero
() mov $r6, $zero
() addi $r7, $zero, IMOD_RESULTS_ADDR
() splt $p0, $zero, $zero
(001) jump imod_outer_cond
imod_outer_loop:                      ; for (i = 0; i < NUM_TESTS; i++)
    (001) addi $r8, $r5, I_TESTS_ADDR
    (001) lw $r0, 0[$r8]
    (001) splt $p1, $zero, $zero
    (011) jump imod_inner_cond
    imod_inner_loop:                  ; for (j = 0; j < NUM_TESTS; j++)
        (011) addi $r8, $r6, I_TESTS_ADDR
        (011) lw $r1, 0[$r8]
              spr $r3
        (011) jal __mod_int
        (011) sw $r2, 0[$r7]
        (011) addi $r7, $r7, 4
        (011) addi $r6, $r6, 4
    imod_inner_cond:
        (011) splt $p1, $r6, $r4
        (011) jump imod_inner_loop
    (001) addi $r5, $r5, 4
imod_outer_cond:
    (001) splt $p0, $r5, $r4
    (001) jump imod_outer_loop

; Test fixedmod
() mov $r5, $zero
() mov $r6, $zero
() addi $r7, $zero, FIXEDMOD_RESULTS_ADDR
() splt $p0, $zero, $zero
(001) jump fixedmod_outer_cond
fixedmod_outer_loop:                      ; for (i = 0; i < NUM_TESTS; i++)
    (001) addi $r8, $r5, FIXED_TESTS_ADDR
    (001) lw $r0, 0[$r8]
    (001) splt $p1, $zero, $zero
    (011) jump fixedmod_inner_cond
    fixedmod_inner_loop:                  ; for (j = 0; j < NUM_TESTS; j++)
        (011) addi $r8, $r6, FIXED_TESTS_ADDR
        (011) lw $r1, 0[$r8]
              spr $r3
        (011) jal __mod_fixed
        (011) sw $r2, 0[$r7]
        (011) addi $r7, $r7, 4
        (011) addi $r6, $r6, 4
    fixedmod_inner_cond:
        (011) splt $p1, $r6, $r4
        (011) jump fixedmod_inner_loop
    (001) addi $r5, $r5, 4
fixedmod_outer_cond:
    (001) splt $p0, $r5, $r4
    (001) jump fixedmod_outer_loop

halt


; Must come last, the procedure defs will be
; placed here in IMEM. Use the constants below
; to enable/disable procedures (all constants
; must be set to a true/false value).
DIV_UINT  = true
DIV_FIXED = true
DIV_INT   = true
MOD_UINT  = true
MOD_FIXED = true
MOD_INT   = true
#include "common/procedures.s"
