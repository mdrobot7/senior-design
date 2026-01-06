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

script_dir = os.path.dirname(os.path.abspath(__file__))
outdir = os.path.join(script_dir, "reuse_csvs")
os.makedirs(outdir, exist_ok=True)

for path in obj_files:
    print(f"Analyzing: {path}")
    mesh = o3d.io.read_triangle_mesh(path)
    tris = np.asarray(mesh.triangles, dtype=np.int64)  # Nx3
    count, per_idx = triangle_reuse_count(tris)

    total = sum(count.values())
    distances = np.array(sorted(count.keys()))
    occurrences = np.array([count[d] for d in distances])

    if total > 0:
        prefix = np.cumsum(occurrences)             # sum of counts for <= X
        fraction_leq = prefix / total
    else:
        fraction_leq = np.zeros_like(occurrences, dtype=float)

    base = os.path.splitext(os.path.basename(path))[0]
    out_csv = os.path.join(outdir, f"{base}.reuse_count.csv")

    with open(out_csv, "w") as f:
        f.write("reuse_distance,cumulative_fraction_leqX\n")
        for d, c in zip(distances, fraction_leq):
            f.write(f"{d},{c}\n")
    print(f"wrote {out_csv}")
