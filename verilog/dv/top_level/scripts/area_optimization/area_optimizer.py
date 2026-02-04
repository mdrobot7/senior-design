import sys
import os
import subprocess
import json
import math
import argparse

p = argparse.ArgumentParser(description="Area optimizer: maximize density then minimize die area.")
p.add_argument("modulename", help="openlane design name")
p.add_argument("-a", "--area", type=int, metavar="N", default=None,
                help="best guess area in μm²; start optimization from this area and work down")
p.add_argument("-r", "--rect", action="store_true",default=False, 
                help="try rectangular dimensions once an optimal square area has been found")
args = p.parse_args()

modulename = args.modulename
best_guess_area = args.area
rect = args.rect

openlane_dir = f"openlane/{modulename}"
if not os.path.exists(openlane_dir):
    print(f"{openlane_dir} does not exist")
    sys.exit(1)

project_root = os.path.abspath(os.path.join(openlane_dir, "..", ".."))
config_path = os.path.join(project_root, openlane_dir, "config.json")
runs_dir = os.path.join(project_root, openlane_dir, "runs")
run_symlink = os.path.join(runs_dir, modulename)
best_run_path = None

cmd = f"bash -c 'source /local/toolchain/activate && cd {project_root} && export OPENLANE_ROOT={project_root}/dependencies/openlane_src && export PDK_ROOT={project_root}/dependencies/pdks && export PDK=sky130A && make {modulename}'"

density_interval = 0.05
max_density = 1.0
AREA_TOL = 100

# maximize PL_TARGET_DENSITY
with open(config_path, 'r') as f:
    config_data = json.load(f)
if best_guess_area is not None:
    side = max(1, int(math.sqrt(best_guess_area)))
    dim_x, dim_y = side, side
    area0 = dim_x * dim_y
    print(f"Maximizing PL_TARGET_DENSITY (best guess area {area0} = {dim_x}x{dim_y})")
else:
    parts = config_data["DIE_AREA"].split()
    dim_x, dim_y = int(parts[2]), int(parts[3])
    area0 = dim_x * dim_y
    print(f"Maximizing PL_TARGET_DENSITY (fixed area {dim_x}x{dim_y} = {area0})")

density_lo, density_hi = 0.55, max_density
tg_density = density_lo
run_count = 0

while density_hi - density_lo > density_interval:
    density_mid = round((density_lo + density_hi) / 2, 4)
    config_data["DIE_AREA"] = f"0 0 {int(dim_x)} {int(dim_y)}"
    config_data["PL_TARGET_DENSITY"] = density_mid
    with open(config_path, 'w') as f:
        json.dump(config_data, f, indent=4)
    print(f"  Trying density {density_mid}")
    run_count += 1
    if subprocess.run(cmd, shell=True, cwd=project_root).returncode == 0:
        tg_density = density_mid
        density_lo = density_mid
        if os.path.islink(run_symlink):
            best_run_path = os.path.realpath(run_symlink)
    else:
        density_hi = density_mid

print(f"Optimal target density found = {tg_density}\n")

# minimize area (square)
print("Binary search for minimum area")
area_hi = area0
area_lo = 0
config_data["DIE_AREA"] = f"0 0 {int(dim_x)} {int(dim_y)}"
config_data["PL_TARGET_DENSITY"] = tg_density
with open(config_path, 'w') as f:
    json.dump(config_data, f, indent=4)

if subprocess.run(cmd, shell=True, cwd=project_root).returncode == 0:
    if os.path.islink(run_symlink):
        best_run_path = os.path.realpath(run_symlink)
    while area_lo + AREA_TOL < area_hi:
        area_mid = (area_lo + area_hi) // 2
        side = max(1, int(math.sqrt(area_mid)))
        dim_x, dim_y = side, side
        with open(config_path, 'r') as f:
            config_data = json.load(f)
        config_data["DIE_AREA"] = f"0 0 {int(dim_x)} {int(dim_y)}"
        config_data["PL_TARGET_DENSITY"] = tg_density
        with open(config_path, 'w') as f:
            json.dump(config_data, f, indent=4)
        print(f"Area {area_mid} ({dim_x}x{dim_y})")
        run_count += 1
        if subprocess.run(cmd, shell=True, cwd=project_root).returncode == 0:
            area_hi = area_mid
            if os.path.islink(run_symlink):
                best_run_path = os.path.realpath(run_symlink)
        else:
            area_lo = area_mid + 1
best_area = dim_x * dim_y
best_square_x, best_square_y = dim_x, dim_y
print(f"Smallest square area = {best_area} ({dim_x}x{dim_y})\n")

# try rectangular dimensions
if rect:
    print("Trying rectangular dimensions")
    ratios = [1.25, 1.5, 2.0, 2.5]
    improved = False
    for r in ratios:
        dim_x = max(1, int(math.sqrt(best_area * r)))
        dim_y = max(1, int(best_area / dim_x))
        if dim_x * dim_y < best_area:
            dim_y += 1
        if dim_x <= 0 or dim_y <= 0:
            continue
        with open(config_path, 'r') as f:
            config_data = json.load(f)
        config_data["DIE_AREA"] = f"0 0 {int(dim_x)} {int(dim_y)}"
        config_data["PL_TARGET_DENSITY"] = tg_density
        with open(config_path, 'w') as f:
            json.dump(config_data, f, indent=4)
        print(f"{dim_x}x{dim_y}",)
        run_count += 1
        if subprocess.run(cmd, shell=True, cwd=project_root).returncode == 0:
            print("OK")
            best_area = dim_x * dim_y
            improved = True
            if os.path.islink(run_symlink):
                best_run_path = os.path.realpath(run_symlink)
        else:
            print("FAIL")
    if not improved:
        dim_x, dim_y = best_square_x, best_square_y
        with open(config_path, 'r') as f:
            config_data = json.load(f)
        config_data["DIE_AREA"] = f"0 0 {int(dim_x)} {int(dim_y)}"
        config_data["PL_TARGET_DENSITY"] = tg_density
        with open(config_path, 'w') as f:
            json.dump(config_data, f, indent=4)

print(f"\nResult: DIE_AREA = 0 0 {dim_x} {dim_y}, PL_TARGET_DENSITY = {tg_density}")

if best_run_path:
    best_run_tag = os.path.basename(best_run_path)
    result_path = os.path.join(project_root, openlane_dir, "area_optimizer_result.txt")
    with open(result_path, 'w') as f:
        f.write(f"run={best_run_tag}\n")
        f.write(f"run_path={best_run_path}\n")
        f.write(f"DIE_AREA=0 0 {dim_x} {dim_y}\n")
        f.write(f"PL_TARGET_DENSITY={tg_density}\n")
    print(f"Best result tracked in: {result_path} (run: {best_run_tag})")
