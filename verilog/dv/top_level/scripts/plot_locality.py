import pandas as pd
import matplotlib.pyplot as plt

df = pd.read_csv("bunny.obj.reuse_hist.csv")

plt.figure()
plt.plot(df["distance_in_triangles"], df["count"], marker="o")
plt.xlabel("Distance between reuses (triangles)")
plt.ylabel("Number of occurrences")
plt.title("Vertex Reuse Distance Distribution")
plt.xscale("log")   # optional — makes long-tail reuse distances easier to see
plt.yscale("log")   # optional — if the range of counts is large
plt.grid(True, which="both", linestyle="--", alpha=0.5)
plt.tight_layout()
plt.show()
