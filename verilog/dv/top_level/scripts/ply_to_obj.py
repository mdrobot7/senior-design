import open3d
import sys

# Usage: python ply_to_obj.py [infile.ply] [outfile.obj]

_, ply, obj = sys.argv

mesh = open3d.io.read_triangle_mesh(ply)
if not mesh.has_vertices():
    print(f"No vertices found in {ply}. It may be a point cloud instead of a mesh.")
    exit(1)
open3d.io.write_triangle_mesh(obj, mesh)
print(f"Converted successfully. Found {len(mesh.triangles)} triangles and {len(mesh.vertices)} vertices.")
