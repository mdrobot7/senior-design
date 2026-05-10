import sys
import pandas as pd
import matplotlib.pyplot as plt
import os

# Usage: python3 plot_locality.py [input.csv]
input_csv = sys.argv[1]
df = pd.read_csv(input_csv)

def make_plot(xlog=False):
    plt.figure()
    plt.plot(df["reuse_distance"], df["cumulative_fraction_leqX"], marker="o")
    plt.xlabel("Reuse distance (triangles)")
    plt.ylabel("Cumulative fraction (≤ X)")
    plt.title("Vertex Reuse Distance CDF (≤ X)" + (" [log X]" if xlog else ""))
    if xlog:
        plt.xscale("log")
    plt.grid(True, which="both", linestyle="--", alpha=0.5)
    plt.tight_layout()

    # Save output as PNG
    suffix = "_logx" if xlog else "_linear"
    output_png = os.path.splitext(input_csv)[0] + suffix + ".png"
    plt.savefig(output_png, dpi=300)
    print(f"Plot saved as: {output_png}")
    plt.close()

# Create both plots
make_plot(xlog=False)
make_plot(xlog=True)
