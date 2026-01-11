#include "common/defs.s"

; Performs vertex shading on a full triangle loaded
; from memory. The following global registers must be
; preloaded by the management core:
; g0 -> g15: MVP matrix
; g45: &index_buffer[0]
; g46: &vertex_buffer[0]

; Vectors must be of the form:
; struct vector { u32 x, u32 y, u32 z, u32 tx, u32 ty }

; This program can be done easily with loops, but it was
; unrolled for better performance. Bunching up memory
; accesses will result in better cache hit rates.

clrp (111)

; Thread ID (tid) is the triangle, loaded into r0 by the
; core controller. Calculate the memory address of our triangle.
() lli $r9, 6.000000
() mul $tid, $tid, $r9
() add $tid, $tid, $g45

; Load triangle indices
() lw $r9,  0[$tid]
() lw $r10, 4[$tid]
() lw $r11, 8[$tid]
() lli $r12, 20.000000
() mul  $r9,  $r9, $r12
() mul $r10, $r10, $r12
() mul $r11, $r11, $r12

; Load vertex 1
() lw $r12, 0[$r9] ; vx
() lw $r13, 4[$r9] ; vy
() lw $r14, 8[$r9] ; vz
() lli $r15, 1.000000 ; Homogeneous term
() lw $r5, 12[$r9] ; tx
() lw $r6, 16[$r9] ; ty

; Vertex shade 1
() dot4 $g0, $r12
() macrd $r1
() dot4 $g4, $r12
() macrd $r2
() dot4 $g8, $r12
() macrd $r3
() dot4 $g12, $r12
() macrd $r4

; Ship to rasterizer
() out

; Load vertex 2
() lw $r12, 0[$r10]
() lw $r13, 4[$r10]
() lw $r14, 8[$r10]
() lw $r5, 12[$r10]
() lw $r6, 16[$r10]

; Vertex shade 2
() dot4 $g0, $r12
() macrd $r1
() dot4 $g4, $r12
() macrd $r2
() dot4 $g8, $r12
() macrd $r3
() dot4 $g12, $r12
() macrd $r4

; Ship to rasterizer
() out

; Load vertex 3
() lw $r12, 0[$r11]
() lw $r13, 4[$r11]
() lw $r14, 8[$r11]
() lw $r5, 12[$r11]
() lw $r6, 16[$r11]

; Vertex shade 3
() dot4 $g0, $r12
() macrd $r1
() dot4 $g4, $r12
() macrd $r2
() dot4 $g8, $r12
() macrd $r3
() dot4 $g12, $r12
() macrd $r4

; Ship to rasterizer
() out

halt
