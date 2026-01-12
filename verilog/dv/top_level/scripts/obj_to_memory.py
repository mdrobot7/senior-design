import open3d as o3d
import numpy as np
import sys

from common.math import *

# Usage: python3 obj_to_bins.py [model.obj] [memory.bin] [globals.bin]

# Vectors are of the form: struct vector { u32 x, u32 y, u32 z, u32 tx, u32 ty }
# Global register allocations, taken from vertex shader:
# g0 -> g15: MVP matrix
# g46: &index_buffer[0]
# g47: &vertex_buffer[0]

MVP_MATRIX = [[10,  0,  0,  10],
              [ 0, 10,  0,  10],
              [ 0,  0, 10,  10],
              [ 0,  0,  0,   1]]

_, model_path, memory_path, globals_path = sys.argv

mesh = o3d.io.read_triangle_mesh(model_path)
vertices = np.asarray(mesh.vertices) # List of vertex coordinates [x, y, z]
triangles = np.asarray(mesh.triangles) # List of vertex indices that make up triangles [i_v1, i_v2, i_v3]

with open(memory_path, "wb") as f:
    vertex_addr = 0
    for v in vertices:
        vertex_bits = b""
        for i in v:
            vertex_bits += float_to_fixed(i).to_bytes(FIXED_POINT_SIZE_BYTES, byteorder="little", signed=True)

        # No texture coordinates, fill in 2 words
        vertex_bits += b"\0" * 8
        f.write(vertex_bits)

    index_addr = f.tell()

    for t in triangles:
        triangle_bits = b""
        for i in t:
            # Indices are just integers, not fixed point data
            triangle_bits += int(i).to_bytes(FIXED_POINT_SIZE_BYTES, byteorder="little", signed=False)

        f.write(triangle_bits)

    memory_usage = f.tell()

with open(globals_path, "wb") as f:
    global_bits = b""
    for i in MVP_MATRIX: # g0-g15: MVP Matrix
        for j in i:
            global_bits += float_to_fixed(j).to_bytes(REGISTER_SIZE_BYTES, byteorder="big", signed=True)

    global_bits += b"\0\0\0\0" * 30 # Padding

    global_bits += index_addr.to_bytes(REGISTER_SIZE_BYTES, byteorder="big", signed=False) # g46
    global_bits += vertex_addr.to_bytes(REGISTER_SIZE_BYTES, byteorder="big", signed=False) # g47

    f.write(global_bits)

print(f"Done. Vertices: {len(vertices)}, Triangles: {len(triangles)}")
print(f"Vertex buffer: 0x{vertex_addr:08X}, Index buffer: 0x{index_addr:08X}, Memory usage: {memory_usage} bytes")