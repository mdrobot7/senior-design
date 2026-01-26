import sys
import os
import subprocess
import json

modulename = sys.argv[1]
openlane_dir = f"openlane/{modulename}"
areas = sys.argv[2:]

if len(areas) % 2 != 0:
    print("Area mismatch: need pairs of x y values")
    sys.exit(1)

if not os.path.exists(openlane_dir):
    print(f"{openlane_dir} does not exist")
    sys.exit(1)

config_path = os.path.join(openlane_dir, "config.json")
if not os.path.exists(config_path):
    print(f"{config_path} does not exist")
    sys.exit(1)

replacements = [f"0 0 {areas[i]} {areas[i+1]}" for i in range(0, len(areas), 2)]
replacements.sort(key=lambda a: int(a.split()[2]) * int(a.split()[3]))

project_root = os.path.abspath(os.path.join(openlane_dir, "..", ".."))
config_path = os.path.join(project_root, openlane_dir, "config.json")

best_area = None
for area in replacements:
    parts = area.split()
    x, y = int(parts[2]), int(parts[3])
    
    print(f"\nTesting area: {area} ({x}x{y})")
    
    with open(config_path, 'r') as f:
        config_data = json.load(f)
    config_data["DIE_AREA"] = area
    with open(config_path, 'w') as f:
        json.dump(config_data, f, indent=4)
    
    cmd = f"bash -c 'source /local/toolchain/activate && cd {project_root} && export OPENLANE_ROOT={project_root}/dependencies/openlane_src && export PDK_ROOT={project_root}/dependencies/pdks && export PDK=sky130A && make {modulename}'"
    
    result = subprocess.run(cmd, shell=True, cwd=project_root)
    
    if result.returncode == 0:
        best_area = area
        print(f"Success: {area}")
        print(f"Smallest successful area: {best_area}")
        break
    else:
        print(f"Failed: {area}")

if best_area:
    print(f"Config updated to smallest successful area: {best_area}")
else:
    print("All areas failed")