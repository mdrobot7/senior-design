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
; r2: screen_x
; r3: screen_y
; r4: normal_x (triangle's normal vector)
; r5: normal_y
; r6: normal_z
; r7: user0 (user-defined metadata)
; r8: user1

clrp (111)

; Get pixel memory address
() li $r9, 320.000000 ; r9: Scratch
() mul $r3, $r3, $r9
() add $r3, $r3, $r2
() add $r3, $r3, $g44

() dot3 $g41, $r4
() macrd $r9
() splt $p0, $r9, $zero
(001) sb $r1, 0[$r3]
(000) mov $r15, $zero ; sb needs a local register
(000) sb $r15, 0[$r3] ; Surface is facing away from the light, set color to black

halt