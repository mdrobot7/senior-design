#ifndef _PERF_H
#define _PERF_H

#include "demos/demos.h"

#include <stdint.h>

/**
 * Run a performance test on a model. Rotates the model
 * around the Y axis, taking frame times for each render.
 * Returns the average frame time for the whole rotation.
 */
uint32_t perf_test(vertex_t * vertices, uint32_t num_vertices, triangle_t * triangles, uint32_t num_triangles, uint32_t z_shift);

#endif
