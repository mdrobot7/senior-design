from typing import List
import numpy as np

from .bits import *
from .defs import *

# Fixed point value: signed_int / scale_factor = float_value

"""
Convert a signed fixed point integer into a float.
"""
def fixed_to_float(signed_fixed: int) -> float:
    return signed_fixed / (1 << DECIMAL_POS)

"""
Convert a float to a signed fixed point integer.
"""
def float_to_fixed(signed_float: float) -> int:
    return signed(int(signed_float * (1 << DECIMAL_POS)), FIXED_POINT_SIZE)

"""
Convert a float to an unsigned fixed point integer.

Bitwise identical to the output of float_to_signed(),
but has the negative sign that lets Python interpret
it correctly.
"""
def float_to_unsigned_fixed(signed_float: float) -> int:
    return unsigned(int(signed_float * (1 << DECIMAL_POS)), FIXED_POINT_SIZE)

"""
Convert a vector of floats to a list of fixed point signed integers.
"""
def vertex_to_fixed_point(vertex: np.ndarray) -> List[int]:
    return [float_to_fixed(i) for i in vertex]

"""
Convert a 3-vector to homogeneous coordinates.
"""
def vertex_to_homogeneous(vec: np.ndarray) -> np.ndarray:
    return np.array([vec[0], vec[1], vec[2], 1])

"""
Convert a 4-vector of homogeneous coordinates to a 3-vector.
"""
def homogeneous_to_vertex(homogeneous: np.ndarray) -> np.ndarray:
    if homogeneous[3] == 0:
        raise ValueError("Camera is touching the object (w = 0), cannot convert from homogeneous coordinates. Move the camera.")
    return np.array([homogeneous[0]/homogeneous[3], homogeneous[1]/homogeneous[3], homogeneous[2]/homogeneous[3]])