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
() li $r9, 20.000000
() mul $tid, $tid, $r9
() add $tid, $tid, $g46
() lw $r10, 0[$tid]; vx
() lw $r11, 4[$tid]; vy
() lw $r12, 8[$tid]; vz
() lli $r13, 1.000000 ; Homogeneous term
() lw $r5, 12[$tid] ; tx
() lw $r6, 16[$tid] ; ty

; Vertex shade
() dot4 $g0, $r10
() macrd $r1
() dot4 $g4, $r10
() macrd $r2
() dot4 $g8, $r10
() macrd $r3
() dot4 $g12, $r10
() macrd $r4

; Ship to rasterizer
() out

halt
