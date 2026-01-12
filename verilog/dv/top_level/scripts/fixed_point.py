import sys
from common.math import fixed_to_float, float_to_unsigned_fixed
from common.bits import signed

"""
    Quick number conversion script for float point values.
    This makes sure all of the math everywhere is consistent
    and correct, I got tired of screwing it up every time.
"""

if len(sys.argv) != 2:
    print("Usage: python fixed_point.py [0x00HEXVAL|3.141592]")
    exit(1)

_, num = sys.argv

if num[0:2] == "0x":
    # Hex value
    if len(num) != 10:
        print("Hex number should be padded to 8 digits (32 bits)")
        exit(1)
    to_convert = signed(int(num, base=16), 32)
    print(fixed_to_float(to_convert))
else:
    # Float value
    print(f"0x{float_to_unsigned_fixed(float(num)):08X}")

