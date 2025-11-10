#!/bin/bash
# Usage:
#   ./filter_reuse_hist.sh input.csv X [output.csv]

# Filter out any reuse counts less than X
# If output.csv is given, will save to output.csv otherwise will just print to stdout

if [ $# -lt 2 ]; then
    echo "Usage: $0 input.csv X [output.csv]"
    exit 1
fi

infile="$1"
threshold="$2"
outfile="$3"


if [ -z "$outfile" ]; then
    # Print only
    awk -F, -v th="$threshold" 'NR==1 || $2 >= th {print}' "$infile"
else
    # Print and output to csv
    awk -F, -v th="$threshold" 'NR==1 || $2 >= th {print}' "$infile" | tee "$outfile"
    echo "Saved filtered output to: $outfile" >&2
fi

