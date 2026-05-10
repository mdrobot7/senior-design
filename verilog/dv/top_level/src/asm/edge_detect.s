#include "common/defs.s"

; Performs edge detection on an image with a 3x3
; convolution. Uses the Sobel edge detection
; matrices, performs a binary OR of the results of
; the horizonal and vertical edge detection outputs.
; The following global registers must be preloaded
; by the management core:
; g0 -> g8: Sobel horizontal edge matrix
; g43: Image width (pixels)
; g44: Image height (pixels)
; g45: &imageout[0][0]: Grayscale input image (black = 0, white = 255)
; g46: &imagein[0][0]: Black and white input image (black = 0, white = 255)

clrp (111)
() maccl

() add $r1, $tid, $g46 ; r1: Pixel to convolve

; Load pixel data
; Row 1
() sub $r2, $r1, $g43  ; r2: Address of pixel to load
() lb $r7, -1[$r2]     ; r7-15: Pixel data
() lb $r8,  0[$r2]
() lb $r9,  1[$r2]

; Row 2
() lb $r10, -1[$r1]
() lb $r11,  0[$r1]
() lb $r12,  1[$r1]

; Row 3
() add $r3, $r2, $g43
() lb $r13, -1[$r3]
() lb $r14,  0[$r3]
() lb $r15,  1[$r3]

; Horizontal edges
() mac $r7, $g0
() mac $r8, $g1
() mac $r9, $g2
() mac $r10, $g3
() mac $r11, $g4
() mac $r12, $g5
() mac $r13, $g6
() mac $r14, $g7
() mac $r15, $g8

() macrd $r3

; Vertical edges (transpose Sobel matrix)
() mac $r7, $g0
() mac $r8, $g3
() mac $r9, $g6
() mac $r10, $g1
() mac $r11, $g4
() mac $r12, $g7
() mac $r13, $g2
() mac $r14, $g5
() mac $r15, $g8

() macrd $r4

; Normalize(ish) the values: Normalizing requires sqrt(),
; so it'll be normalizing the square of the magnitude.
() mul $r3, $r3, $r3
() mul $r4, $r4, $r4
() add $r4, $r4, $r3
() sll $r4, $r4, 11 ; Max result from each MAC run is 1024. Divide by 2048 so output is 0-255

; Output
() add $r1, $tid, $g45 ; r1: Output destination
() sb $r4, 0[$r1]
halt