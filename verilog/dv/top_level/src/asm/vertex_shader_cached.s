#include "common/defs.s"

; Performs vertex shading on a single vertex loaded
; from memory. The following global registers must be
; preloaded by the management core:
; g0 -> g15: MVP matrix
; g45: &index_buffer[0]
; g46: &vertex_buffer[0]

; Vectors must be of the form:
; struct vector { u32 x, u32 y, u32 z, u32 tx, u32 ty }

clrp (111)

; Thread ID (tid) is the index, loaded into r0 by the core
; controller. Grab our vertex.
() li $r1, 20.000000
() mul $tid, $tid, $r1
() add $tid, $tid, $g46
() lw $r1, 0[$tid]; vx
() lw $r2, 4[$tid]; vy
() lw $r3, 8[$tid]; vz
() lli $r4, 1.000000 ; Homogeneous term
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
