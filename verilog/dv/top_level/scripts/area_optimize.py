# Usage:
#   python3 area_optimizer.py [openlane_dir_name]
# Example:
#   python3 area_optimizer.py core_accumulator
import sys
import os
import subprocess

optimizer = "area_optimizer.py"
# optimizer = "test_print.py"

os.chdir("area_optimization")
subprocess.run(["cp", f"{optimizer}", "../../../../.."])
os.chdir("../../../../..")
subprocess.run(["chmod", "+x", f"{optimizer}"])
subprocess.run(["python3", f"{optimizer}"] + sys.argv[1:])
subprocess.run(["rm", f"{optimizer}"])