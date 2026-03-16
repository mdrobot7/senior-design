import sys
from simulator.decode import Instruction

# Usage: hex_to_inst.py DEADBEEF

_, hex_str = sys.argv

print(Instruction(bytes.fromhex(hex_str)))

