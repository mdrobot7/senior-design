#include "common/defs.s"

; Performs a fragment shade on a fragment outputted
; by the rasterizer using Direct Illumination. The
; following global registers need to be preloaded
; by the management core:
; g44: &framebuffer[0][0] (framebuffer being rendered)

; Fragments are loaded directly into registers by the rasterizer.
; r0/tid: unused
; r1: color
; r2: { screen_y, screen_x }

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

() sb $r1, 0[$r2]

halt
