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
; r2: screen_y
; r3: screen_x
; r4: normal_x (triangle's normal vector)
; r5: normal_y
; r6: normal_z
; r7: user0 (user-defined metadata)
; r8: user1

clrp (111)

() in

; Get pixel memory address.
; Ideally, &pix = 320 * screen_y + screen_x. However,
; fixed point multiplication means that 320 * screen_y
; can overflow.
() li $r9, 320.0000000    ; r9: Scratch, must use fixed point for multiplication
() addi $r10, $zero, 120  ; r10: Scratch
() splt $p0, $r2, $r10
(000) addi $r2, $r2, -120
(000) li $r11, 38400      ; r11: Framebuffer offset
(001) mov $r11, $zero
clrp (111)
() sll $r2, $r2, DECIMAL_POS ; r2 -> fixed point
() mul $r2, $r2, $r9
() srl $r2, $r2, DECIMAL_POS ; r2 -> integer
() add $r2, $r2, $r11
() add $r2, $r2, $r3
() add $r2, $r2, $g44

() sb $r1, 0[$r2]

; () dot3 $g41, $r4
; () macrd $r9
; () splt $p0, $r9, $zero
; (001) sb $r1, 0[$r2]
; (000) mov $r15, $zero ; sb needs a local register
; (000) sb $r15, 0[$r2] ; Surface is facing away from the light, set color to black

halt
