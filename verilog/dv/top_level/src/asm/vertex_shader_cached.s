#include "defs.s"

; Performs vertex shading on a single vertex loaded
; from memory. The following global registers must be
; preloaded by the management core:
; g0 -> g15: MVP matrix
; g46: &index_buffer[0]
; g47: &vertex_buffer[0]

; Vectors must be of the form:
; struct vector { u32 x, u32 y, u32 z, u32 tx, u32 ty }

; Thread ID (tid) is the index, loaded into r0 by the core
; controller. Grab our vertex.
() muli $tid, $tid, 20
() add $tid, $tid, $g47
() lw $r1, 0[$tid]; vx
() lw $r2, 4[$tid]; vy
() lw $r3, 8[$tid]; vz
() andi $r4, $r4, 0 ; Homogeneous term
() ori $r4, $r4, 1
() lw $r9, 12[$tid] ; tx
() lw $r10, 16[$tid] ; ty

; Vertex shade
() dot4 $g0, $r1
() macrd $r5
() dot4 $g4, $r2
() macrd $r6
() dot4 $g8, $r3
() macrd $r7
() dot4 $g12, $r4
() macrd $r8

; Ship to rasterizer
() out $r5

halt
