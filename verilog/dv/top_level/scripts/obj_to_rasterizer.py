import open3d as o3d
import numpy as np
import sys
import random
import math

from common.math import *

# Usage: python obj_to_rasterizer.py [model.obj] [output.v]
# NOTE: See design document Vertex Shader section for an explanation of the math

# Clip space absolute limits: The x, y, z range of the rasterizer inputs. Lower bound is 0.
# All values going into the rasterizer are signed fixed-point.
CLIP_LIMIT_X = 320
CLIP_LIMIT_Y = 240
CLIP_LIMIT_Z_FIXED_POINT = 0x7FFFFFFF

###################################  CONFIGURATION  ########################################

OUTPUT_WIDTH = 320
OUTPUT_HEIGHT = 240

COLOR = -1 # Color in range [0-255], -1 for random

CAMERA_POS = [0, 0, 50] # Position in x, y, z
CAMERA_ROTATION = [0, 0, 0] # Rotation around x, y, z axes in radians. 0, 0, 0 is straight up pointing towards -Z.
CAMERA_FOV = 90 # In degrees

# Clip space depth limits: remove objects closer to the camera than ZNEAR and further than ZFAR.
# ZNEAR maps to depth 0, ZFAR is the initial value of the depth buffer.
CAMERA_ZNEAR = 20
CAMERA_ZFAR = 80

# Pre-multiplied model matrix, contains any transformations done to the model
MODEL_MATRIX = np.array(
    [[10, 0, 0, 0],
     [0, 10, 0, 0],
     [0, 0, 10, 0],
     [0, 0, 0, 1]]
)

###########################################################################################

_, infile, outfile = sys.argv

def rotation_matrix(axis, angle_radians) -> np.ndarray:
    if axis == 'x':
        return np.array(
            [[1,                       0,                        0, 0],
             [0, math.cos(angle_radians), -math.sin(angle_radians), 0],
             [0, math.sin(angle_radians),  math.cos(angle_radians), 0],
             [0,                       0,                        0, 1]]
        )
    if axis == 'y':
        return np.array(
            [[ math.cos(angle_radians), 0, math.sin(angle_radians), 0],
             [                       0, 1,                       0, 0],
             [-math.sin(angle_radians), 0, math.cos(angle_radians), 0],
             [                       0, 0,                       0, 1]]
        )
    if axis == 'z':
        return np.array(
            [[math.cos(angle_radians), -math.sin(angle_radians), 0, 0],
             [math.sin(angle_radians),  math.cos(angle_radians), 0, 0],
             [                      0,                        0, 1, 0],
             [                      0,                        0, 0, 1]]
        )

def view_matrix(position, rotation) -> np.ndarray:
    cam_rotation = rotation_matrix('x', rotation[0]) \
                 @ rotation_matrix('y', rotation[1]) \
                 @ rotation_matrix('z', rotation[2])
    camera_matrix = np.array(
        [[cam_rotation[0][0], cam_rotation[0][1],  cam_rotation[0][2], position[0]],
         [cam_rotation[1][0], cam_rotation[1][1],  cam_rotation[1][2], position[1]],
         [cam_rotation[2][0], cam_rotation[2][1],  cam_rotation[2][2], position[2]],
         [                 0,                  0,                  0,           1]]
    )
    return np.linalg.inv(camera_matrix)

def perspective_matrix(fov_degrees, z_near, z_far) -> np.ndarray:
    s = 1 / math.tan(0.5 * fov_degrees * math.pi / 180)

    return np.array(
        [[s, 0,      0,               0],
         [0, s,      0,               0],
         [0, 0, -z_far, -z_far * z_near],
         [0, 0,     -1,               0]]
    )

def screen_matrix(display_width, display_height) -> np.ndarray:
    # Turn screen coordinates (centered on the camera's z axis and the z_near plane)
    # into raster coordinates (origin at the top left of screen, y axis points down).
    # The rasterizer takes in a homogeneous vector that's in screen coordinates (once
    # turned back into a 3vec).
    half_width = display_width / 2
    half_height = display_height / 2

    return np.array(
        [[half_width, 0, 0, half_width],
         [0, -half_height, 0, half_height],
         [0, 0, 1, 0],
         [0, 0, 0, 1]]
    )


# Check inputs
if OUTPUT_WIDTH > CLIP_LIMIT_X:
    print("Display width too large, must be smaller than CLIP_LIMIT_X.")
    exit(1)
if OUTPUT_HEIGHT > CLIP_LIMIT_Y:
    print("Display height too large, must be smaller than CLIP_LIMIT_Y.")
    exit(1)
if COLOR > 255:
    print("Color out of range.")
    exit(1)

# Apply model, then view, then perspective
MVP_MATRIX = screen_matrix(OUTPUT_WIDTH, OUTPUT_HEIGHT) \
           @ perspective_matrix(CAMERA_FOV, CAMERA_ZNEAR, CAMERA_ZFAR) \
           @ view_matrix(CAMERA_POS, CAMERA_ROTATION) \
           @ MODEL_MATRIX

mesh = o3d.io.read_triangle_mesh(infile)
vertices = np.asarray(mesh.vertices) # List of vertex coordinates [x, y, z]
triangles = np.asarray(mesh.triangles) # List of vertex indices that make up triangles [i_v1, i_v2, i_v3]

size_x = max(vertices[:, 0]) - min(vertices[:, 0])
size_y = max(vertices[:, 1]) - min(vertices[:, 1])
size_z = max(vertices[:, 2]) - min(vertices[:, 2])
print(f"Object processed, found {len(triangles)} triangles. Dimensions: {size_x:.3f} x {size_y:.3f} x {size_z:.3f}")

print(f"MVP matrix:\n{MVP_MATRIX}")

with open(outfile, 'w') as out:
    out.write(f"""\
for (x = 0; x < 320; x = x + 1) begin
    for (y = 0; y < 240; y = y + 1) begin : DB_FILL
    reg [31:0] value;
    value = 32'd{CAMERA_ZFAR};
    spi_chip.mem[`ADDR_DEPTH_BUFFER + (y * 320 + x) * 4 + 0] = value[7:0];
    spi_chip.mem[`ADDR_DEPTH_BUFFER + (y * 320 + x) * 4 + 1] = value[15:8];
    spi_chip.mem[`ADDR_DEPTH_BUFFER + (y * 320 + x) * 4 + 2] = value[23:16];
    spi_chip.mem[`ADDR_DEPTH_BUFFER + (y * 320 + x) * 4 + 3] = value[31:24];
    end
end
for (x = 0; x < 320; x = x + 1) begin
    for (y = 0; y < 240; y = y + 1) begin
    spi_chip.mem[y * 320 + x] = 0;
    end
end
run = 0;\n\n""")

    for n, t in enumerate(triangles):
        vertices_transformed = [homogeneous_to_vertex(MVP_MATRIX @ vertex_to_homogeneous(vertices[i])) for i in t]

        triangle_fixed = [vertex_to_fixed_point(vt) for vt in vertices_transformed]

        out.write(f"""\
color = 8'd{COLOR if COLOR != -1 else random.randint(0, 255)};
v0x = {triangle_fixed[0][0]};
v0y = {triangle_fixed[0][1]};
v0z = {triangle_fixed[0][2]};
t0x = 0;
t0y = 0;
v1x = {triangle_fixed[1][0]};
v1y = {triangle_fixed[1][1]};
v1z = {triangle_fixed[1][2]};
t1x = 0;
t1y = 0;
v2x = {triangle_fixed[2][0]};
v2y = {triangle_fixed[2][1]};
v2z = {triangle_fixed[2][2]};
t2x = 0;
t2y = 0;
wait(!clk);
run = 1;
wait(busy);
wait(!busy);
run = 0;
clk_rst.WAIT_CYCLES(10);
$display("Triangle %d", {n});\n\n""")
