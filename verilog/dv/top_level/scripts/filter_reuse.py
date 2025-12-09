#!/usr/bin/env python3
# Usage:
#   python filter_resuse.py [input.csv] [X] [output.csv]

# Filter out any reuse counts less than X
# If output.csv is given, will save to output.csv otherwise will just print to stdout

import sys
import pandas as pd

infile = sys.argv[1]
threshold = float(sys.argv[2])
outfile = sys.argv[3] if len(sys.argv) > 3 else None

file = pd.read_csv(infile)

# Keep header and rows where second column >= threshold
# Assuming 2nd column is numeric
colname = file.columns[1]
filtered = file[file[colname] >= threshold]

# Output
if outfile:
    filtered.to_csv(outfile, index=False)
    print(filtered.to_csv(index=False), end="")  # Also print to stdout
    print(f"Saved filtered output to: {outfile}", file=sys.stderr)
else:
    print(filtered.to_csv(index=False), end="")
