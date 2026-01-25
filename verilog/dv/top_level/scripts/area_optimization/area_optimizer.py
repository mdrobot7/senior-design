# Usage:
#   python3 area_optimizer.py [openlane_dir_name] [area_x1 area_y1 area_x2 area_y2 ...]
# Example:
#   python3 area_optimizer.py core_accumulator
import sys
import os
import subprocess

modulename = sys.argv[1]
openlane_dir = f"openlane/{modulename}"
areas = sys.argv[2:]

subprocess.run(["pwd"], check=False)

ls = subprocess.run(["ls", openlane_dir], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
if len(areas) % 2 != 0:
    print("Area mismatch input format:\narea_optimizer.py [openlane_dir_name] [area_x1 area_y1 area_x2 area_y2 ...]")
    sys.exit(1)

if ls.returncode != 0:
    print(openlane_dir + " does not exist")
    sys.exit(1)

config = openlane_dir + "/config.json"

print("pwd:")

ls = subprocess.run(["ls", config], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
if ls.returncode != 0:
    print(config + " does not exist in " + openlane_dir)
    sys.exit(1)


area_pattern = r'"DIE_AREA"\s*:\s*"[0-9 ]+"'

replacements = []

for i in range(0, len(areas), 2):
    x = areas[i]
    y = areas[i + 1]
    replacements.append(f"0 0 {x} {y}")


# for each area run make:
if len(replacements) > 0:
    project_root = os.path.abspath(os.path.join(openlane_dir, "..", ".."))
    # print(f"proj root: {project_root}")

    cmd = f"bash -c 'source /local/toolchain/activate && cd {project_root} && \
    export OPENLANE_ROOT={project_root}/dependencies/openlane_src && \
    export PDK_ROOT={project_root}/dependencies/pdks && \
    export PDK=sky130A && make {modulename}'"
    
    # print(cmd)
    subprocess.run(cmd, shell=True, cwd=project_root)

    # subprocess.run(["make", modulename.strip()])