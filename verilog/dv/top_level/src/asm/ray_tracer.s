#include "defs.s"

; Performs a path trace of a single ray in a scene.
; Assumes all models have been multiplied by their model
; matrices and all triangles have normal vectors calculated
; beforehand. These aren't unreasonable preprocess steps and
; will greatly help performance. It can even be done using
; a separate shader program.

; The following global registers must be
; preloaded by the management core:
; g0 -> g2: camera position
; g3 -> g5: image plane x vector: (0, 0) at top left of screen
; g6 -> g8: image plane y vector
; g43: max ray depth
; g44: &framebuffer[0][0]
; g45: num_triangles (length of index buffer)
; g46: &index_buffer[0]
; g47: &vertex_buffer[0]

; NOTE: Ideally, we have a random number generator to
; randomize ray bounces. As of now we don't, so it'll be
; deterministic (based off of tid and pixel)

; Triangles must be of the form: struct { u32 idx0, u32 idx1, u32 idx2, u32 norm_x, u32 norm_y, u32 norm_z }.
; Vectors must be of the form: struct { u32 x, u32 y, u32 z, u8 color }.
; No texturing supported, we don't have enough registers.

; Constants
samples_per_pixel = 4
width = 320
height = 240

; Get our pixel
() muli $tid, $tid, 1/samples_per_pixel
() muli $r1, $tid, 1/width
() trunc $r1, $r1                       ; r1: current line
() muli $r2, $r1, width
() sub $tid, $tid, $r2                  ; tid: current pixel

; Calculate starting ray: ray = image_plane - camera
() scalev3 $r2, $g3, $tid
() scalev3 $r5, $g6, $r1
() subv3 $r2, $r2, $r5    ; r2: Image plane vector, ray origin
() subv3 $r5, $r2, $g0    ; r5: Ray to trace

; Loop through triangles to find collision
() andi $r15, $r15, 0   ; r15: Bounce loop counter
() splt $p0, $r15, $r15 ; Unconditional predicate set so loop_compare runs
(001) jump loop_compare
loop:
    (001) andi $r14, $r14, 0 ; r14: Triangle loop counter
    triangle_loop:
        (011) jump load_and_check_triangle

        (011) addi $r14, $r14, 1
    triangle_loop_compare:
        (011) splt $p1, $r14, $g45
        (011) jump triangle_loop
    triangle_loop_exit:

    (001) addi $r15, $r15, 1
loop_compare:
    (001) splt $p0, $r15, $g43
    (001) jump loop

loop_end:
    halt


; Subroutine: Load a triangle from memory, calculate
; barycentrics, check for a hit.
;
; Pretend like this is inline, splitting it out so it's
; easier to manage.
load_and_check_triangle:
    ; Load vertices
    (011) muli $r13, $r14, 12
    (011) lw $r12, 0[$r13]
    (011) muli $r12, $r12, 13
    (011) lw $r8, 0[$r12]     ; r8: Loaded vertex
    (011) lw $r9, 4[$r12]
    (011) lw $r10, 8[$r12]
    ; ERROR: Out of registers

    ; Load normal vector

    ; Check ray-plane intersection

    ; Calculate collision time

    ; Split triangle into subtriangles, calculate normals

    ; Calculate barycentrics

    ; Intersection test