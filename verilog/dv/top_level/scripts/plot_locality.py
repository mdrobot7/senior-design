import sys
import pandas as pd
import matplotlib.pyplot as plt
import os

# Usage: python3 plot_locality.py [input.csv]

df = pd.read_csv(input_csv)

# Plot
plt.figure()
plt.plot(df["distance_in_triangles"], df["count"], marker="o")
plt.xlabel("Distance between reuses (triangles)")
plt.ylabel("Number of occurrences")
plt.title("Vertex Reuse Distance Distribution")
plt.xscale("log") # Optional 
plt.yscale("log") # Optional
plt.grid(True, which="both", linestyle="--", alpha=0.5)
plt.tight_layout()

# Save output as PNG
output_png = os.path.splitext(input_csv)[0] + ".png"
plt.savefig(output_png, dpi=300)
print(f"Plot saved as: {output_png}")

# Show plot interactively
plt.show()
