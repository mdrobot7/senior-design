#include "common/defs.s"

; Performs a fragment shade on a fragment outputted
; by the rasterizer using Direct Illumination. The
; following global registers need to be preloaded
; by the management core:
; g41 -> g43: light source normal vector
; g44: &framebuffer[0][0] (framebuffer being rendered)

; Fragments are loaded directly into registers by the rasterizer.
; r0/tid: unused
; r1: color
; r2: { screen_y, screen_x }
; r3: u0
; r4: u1 (triangle's normal vector)
; r5: u2
; r6: u3
; r7: u4 (user-defined metadata)
; r8: u5

clrp (111)

() in

; I hate you jack :) (in instruction needs software pipelining)
() nop
() nop
() nop

; get pix memory address
() sll $r11, $r2, 16
() srl $r10, $r11, 16 ; x
() srl $r2, $r2, 16 ; y
; r2: y
; r10: x
; r11: { x, 0x0000 }
() lui $r11, 320 ; r11: 320.0000000
;  ^ delightfully devilish
() mul $r2, $r2, $r11
() add $r2, $r2, $r10
() add $r2, $r2, $g44

() dot3 $r3, $g41
() macrd $r9

; r9: normal (dot) light dir

() li $r10, 0.7500000
() mul $r9, $r9, $r10

; r9: diffuse

() xor   $r10, $r10, $r10
() splt $p0, $r9, $r10
(001) mov $r9, $r10
clrp (111)

() srl $r10, $r1, 6
() srl $r11, $r1, 3

() andi $r10, $r10, 0b11
() andi $r11, $r11, 0b111
() andi $r12, $r1, 0b111

() mul $r10, $r10, $r9
() mul $r11, $r11, $r9
() mul $r12, $r12, $r9

; add ambient light (not exactly good yet)
; () addi $r10, $r10, 0b01
; () addi $r11, $r11, 0b010
; () addi $r12, $r12, 0b010

() andi $r10, $r10, 0b11
() andi $r11, $r11, 0b111
() andi $r12, $r12, 0b111

() sll $r1,  $r10, 6
() sll $r11, $r11, 3

() or  $r1, $r1, $r11
() or  $r1, $r1, $r12

() sb $r1, 0[$r2]

halt

