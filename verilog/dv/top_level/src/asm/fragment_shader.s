#include "defs.s"

; Performs a fragment shade on a fragment outputted
; by the rasterizer using Direct Illumination. The
; following global registers need to be preloaded
; by the management core:
; g42 -> g44: light source normal vector
; g45: &framebuffer[0][0] (framebuffer being rendered)

; Fragments are loaded directly into registers by the rasterizer.
; r0/tid: unused
; r1: color
; r2: screen_x
; r3: screen_y
; r4: normal_x (triangle's normal vector)
; r5: normal_y
; r6: normal_z
; r7: user0 (user-defined metadata)
; r8: user1

; Get pixel memory address
() muli $r3, $r3, 320
() add $r3, $r3, $r2
() add $r3, $r3, $g45

() andi $r15, $r15, 0 ; Make a 0 register for later

() dot3 $g42, $r4
() macrd $r9
() splt $p0, $r9, $r15
(001) sb $r1, 0[$r3]
(000) sb $r15, 0[$r3] ; Surface is facing away from the light, set color to black

halt