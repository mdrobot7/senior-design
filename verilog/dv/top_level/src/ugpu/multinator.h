#pragma once

#include "ugpu.h"

#include <stdint.h>

typedef struct __packed {
    int32_t a, b, y;
} multinator_t;

#define MULTINATOR ((volatile multinator_t *) 0x36000000)
