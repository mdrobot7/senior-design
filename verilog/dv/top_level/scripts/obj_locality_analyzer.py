# reuse_distance_triangles.py
import sys
from collections import Counter, defaultdict
import numpy as np
import open3d as o3d
import os

def triangle_reuse_count(triangles: np.ndarray):
    last_seen = {}                 # vertex_index -> last triangle id it appeared in
    count = Counter()               # distance -> occurrences
    per_index = defaultdict(Counter)

    for ti, (a,b,c) in enumerate(triangles):
        for v in (a, b, c):
            if v in last_seen:
                d = ti - last_seen[v]   # how many triangles between two uses of the same index
                count[d] += 1
                per_index[v][d] += 1
            last_seen[v] = ti
    return count, per_index


obj_files = sys.argv[1:]
if not obj_files:
    print("Usage: python reuse_distance_triangles.py model1.obj model2.obj ...")
    sys.exit(1)

script_dir = os.path.dirname(os.path.abspath(__file__))
outdir = os.path.join(script_dir, "reuse_csvs")
os.makedirs(outdir, exist_ok=True)

for path in obj_files:
    mesh = o3d.io.read_triangle_mesh(path)
    tris = np.asarray(mesh.triangles, dtype=np.int64)  # Nx3
    count, per_idx = triangle_reuse_count(tris)

    print(f"Analyzing: {path}")
    # print("distance_in_triangles,occurences")
    # for d, c in sorted(count.items()):
    #     print(f"{d},{c}")

    # also write a CSV per file
    base = os.path.splitext(os.path.basename(path))[0]
    out_csv = os.path.join(outdir, f"{base}.reuse_count.csv")

    with open(out_csv, "w") as f:
        f.write("distance_in_triangles,occurences\n")
        for d, c in sorted(count.items()):
            f.write(f"{d},{c}\n")
    print(f"wrote {out_csv}")
