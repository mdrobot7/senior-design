#include "defs.s"

; Performs vertex shading on a full triangle loaded
; from memory. The following global registers must be
; preloaded by the management core:
; g0 -> g15: MVP matrix
; g46: &index_buffer[0]
; g47: &vertex_buffer[0]

; Vectors must be of the form:
; struct vector { u32 x, u32 y, u32 z, u32 tx, u32 ty }

; This program can be done easily with loops, but it was
; unrolled for better performance. Bunching up memory
; accesses will result in better cache hit rates.

; Thread ID (tid) is loaded into r0 by the core controller.
; Calculate the memory address of our triangle.
() muli $tid, $tid, 4
() add $tid, $tid, $g46

; Load triangle indices
() lw $r1, 0[$tid]
() lw $r2, 4[$tid]
() lw $r3, 8[$tid]
() muli $r1, $r1, 20
() muli $r2, $r2, 20
() muli $r3, $r3, 20

; Load vertex 1
() lw $r4, 0[$r1] ; vx
() lw $r5, 4[$r1] ; vy
() lw $r6, 8[$r1] ; vz
() andi $r7, $r7, 0 ; Homogeneous term
() ori $r7, $r7, 1
() lw $r12, 12[$r1] ; tx
() lw $r13, 16[$r1] ; ty

; Vertex shade 1
() dot4 $g0, $r5
() macrd $r8
() dot4 $g4, $r5
() macrd $r9
() dot4 $g8, $r5
() macrd $r10
() dot4 $g12, $r5
() macrd $r11

; Ship to rasterizer
() out $r8

; Load vertex 2
() lw $r4, 0[$r2]
() lw $r5, 4[$r2]
() lw $r6, 8[$r2]
() andi $r7, $r7, 0
() ori $r7, $r7, 1
() lw $r12, 12[$r2]
() lw $r13, 16[$r2]

; Vertex shade 2
() dot4 $g0, $r5
() macrd $r8
() dot4 $g4, $r5
() macrd $r9
() dot4 $g8, $r5
() macrd $r10
() dot4 $g12, $r5
() macrd $r11

; Ship to rasterizer
() out $r8

; Load vertex 3
() lw $r4, 0[$r3]
() lw $r5, 4[$r3]
() lw $r6, 8[$r3]
() andi $r7, $r7, 0
() ori $r7, $r7, 1
() lw $r12, 12[$r3]
() lw $r13, 16[$r3]

; Vertex shade 3
() dot4 $g0, $r5
() macrd $r8
() dot4 $g4, $r5
() macrd $r9
() dot4 $g8, $r5
() macrd $r10
() dot4 $g12, $r5
() macrd $r11

; Ship to rasterizer
() out $r8

halt
