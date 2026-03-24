import sys

_, in_name, out_name = sys.argv

with open(in_name, "rb") as f:
    in_data = f.read()

with open(out_name, "w") as f:
    for i in range(0, len(in_data), 4):
        inst = in_data[i : i + 4]
        f.write(inst.hex() + "\n")
