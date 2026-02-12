import sys
import os
import subprocess
import json
import math
import argparse
import time

def run_cmd(cmd, project_root):
    ok = False
    proc = subprocess.Popen(
        cmd,
        shell=True,
        cwd=project_root,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        universal_newlines=True,
        bufsize=1,
    )
    for line in proc.stdout:
        sys.stdout.write(line)
        if "STEP 35" in line:
            ok = True
            try:
                proc.terminate()
            except ProcessLookupError:
                pass
            try:
                proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                proc.kill()
            break
    else:
        proc.wait()
        ok = proc.returncode == 0
    return ok

p = argparse.ArgumentParser(description="Area optimizer: maximize density then minimize die area.")
p.add_argument("modulename", help="openlane design name")
p.add_argument("-a", "--area", type=int, metavar="N", default=None,
                help="best guess area in μm²; start optimization from this area and work down")
p.add_argument("-r", "--rect", action="store_true",default=False, 
                help="try rectangular dimensions once an optimal square area has been found")
p.add_argument("-d", "--density", metavar="N", type=float, default=None,
                help="set a known target density, will skip target density optimization")
p.add_argument("-s", "--start-density", metavar="N", type=float, default=None,
                help="starting density for search")
p.add_argument("-y", "--synth-strategy", metavar="NAME", type=str, default=None,
                help="Choose a SYNTH_STRATEGY to start with default being AREA 0")
args = p.parse_args()

modulename = args.modulename
best_guess_area = args.area
rect = args.rect
selected_density = args.density
start_density = args.start_density
synth_strat = args.synth_strategy

openlane_dir = f"openlane/{modulename}"
if not os.path.exists(openlane_dir):
    print(f"{openlane_dir} does not exist")
    sys.exit(1)

project_root = os.path.abspath(os.path.join(openlane_dir, "..", ".."))
config_path = os.path.join(project_root, openlane_dir, "config.json")
runs_dir = os.path.join(project_root, openlane_dir, "runs")
run_symlink = os.path.join(runs_dir, modulename)
best_run_path = None
start_time = time.time()

cmd = f"bash -c 'source /local/toolchain/activate 2>/dev/null || true; cd {project_root} && export OPENLANE_ROOT={project_root}/dependencies/openlane_src && export PDK_ROOT={project_root}/dependencies/pdks && export PDK=sky130A && make {modulename}'"

density_interval = 0.05
max_density = 1.0


with open(config_path, 'r') as f:
    config_data = json.load(f)

#Synth strats
synth_candidates = ["AREA 0", "AREA 1", "AREA 2", "AREA 3"]
chosen_synth = None

if synth_strat is not None:
    parsed_index = None
    is_area = synth_strat.startswith("AREA ")
    is_delay = synth_strat.startswith("DELAY ")
    
    if is_area or is_delay:
        parts = synth_strat.split()
        if len(parts) == 2:
            try:
                parsed_index = int(parts[1])
            except ValueError:
                parsed_index = None
    
    # If AREA 0-3: try starting from that index, fallback to next AREA candidates
    if is_area and parsed_index is not None and 0 <= parsed_index <= 3:
        start_index = parsed_index
        print(f"Starting SYNTH_STRATEGY search from {synth_strat}")
        for i in range(start_index, len(synth_candidates)):
            strategy = synth_candidates[i]
            print(f"Trying SYNTH_STRATEGY = {strategy}")
            config_data["SYNTH_STRATEGY"] = strategy
            with open(config_path, 'w') as f:
                json.dump(config_data, f, indent=4)
            ok = run_cmd(cmd, project_root)

            if ok:
                chosen_synth = strategy
                print(f"SYNTH_STRATEGY {strategy} works; using it for optimization.\n")
                break
            else:
                print(f"SYNTH_STRATEGY {strategy} failed, trying next.\n")
        if chosen_synth is None:
            print("No working SYNTH_STRATEGY found in AREA 0–AREA 3 range. Check your config (area may be too small).")
            sys.exit(1)
    else:
        # Other synth strats
        config_data["SYNTH_STRATEGY"] = synth_strat
        with open(config_path, 'w') as f:
            json.dump(config_data, f, indent=4)
        print(f"Trying SYNTH_STRATEGY = {synth_strat}")
        ok = run_cmd(cmd, project_root)

        if ok:
            chosen_synth = synth_strat
            print(f"SYNTH_STRATEGY {synth_strat} works")
        else:
            print(f"SYNTH_STRATEGY {synth_strat} failed; config does not synthesize.")
            sys.exit(1)
else:
    print("No SYNTH_STRATEGY override provided trying AREA 0, AREA 1, AREA 2, AREA 3.")
    for strategy in synth_candidates:
        print(f"Trying SYNTH_STRATEGY = {strategy}")
        config_data["SYNTH_STRATEGY"] = strategy
        with open(config_path, 'w') as f:
            json.dump(config_data, f, indent=4)
        ok = run_cmd(cmd, project_root)

        if ok:
            chosen_synth = strategy
            print(f"SYNTH_STRATEGY {strategy} works; using it for optimization.\n")
            break
        else:
            print(f"SYNTH_STRATEGY {strategy} failed, trying next.\n")

    if chosen_synth is None:
        print("None of AREA 0–AREA 3 synthesized successfully. Check your config (area may be too small).")
        sys.exit(1)

# ensure config_data has the chosen strategy
config_data["SYNTH_STRATEGY"] = chosen_synth

base_density_lo = start_density if start_density is not None else config_data["PL_TARGET_DENSITY"]
density_lo, density_hi = base_density_lo, max_density
tg_density = selected_density if selected_density is not None else density_lo
run_count = 0

stepping_ok = False
if best_guess_area is not None:
    side = max(1, int(math.sqrt(best_guess_area)))
    dim_x, dim_y = side, side
    area0 = dim_x * dim_y
    config_data["PL_TARGET_DENSITY"] = tg_density
    for dx, dy in [(0, 0), (5, 5), (10, 10)]:
        try_x, try_y = dim_x + dx, dim_y + dy
        config_data["DIE_AREA"] = f"0 0 {try_x} {try_y}"
        with open(config_path, 'w') as f:
            json.dump(config_data, f, indent=4)
        print(f"Trying {try_x}x{try_y} ...", end=" ", flush=True)
        run_count += 1
        ok = run_cmd(cmd, project_root)

        if ok:
            dim_x, dim_y = try_x, try_y
            area0 = dim_x * dim_y
            stepping_ok = True
            print("OK")
            if os.path.islink(run_symlink):
                best_run_path = os.path.realpath(run_symlink)
            break
        print("FAIL")
    else:
        print("Best guess and stepped dimensions (x+5,y+5), (x+10,y+10) all failed.")
        sys.exit(1)
    print(f"Maximizing PL_TARGET_DENSITY (starting area {area0} = {dim_x}x{dim_y})")
else:
    parts = config_data["DIE_AREA"].split()
    dim_x, dim_y = int(parts[2]), int(parts[3])
    area0 = dim_x * dim_y
    print(f"Maximizing PL_TARGET_DENSITY (fixed area {dim_x}x{dim_y} = {area0})")

# maximize PL_TARGET_DENSITY
if(selected_density is None):
    if start_density is not None:
        config_data["DIE_AREA"] = f"0 0 {int(dim_x)} {int(dim_y)}"
        config_data["PL_TARGET_DENSITY"] = start_density
        with open(config_path, 'w') as f:
            json.dump(config_data, f, indent=4)
        print(f"\nTrying starting density {start_density}\n")
        run_count += 1
        ok = run_cmd(cmd, project_root)
        if ok:
            tg_density = start_density
            density_lo = start_density
            if os.path.islink(run_symlink):
                best_run_path = os.path.realpath(run_symlink)
        else:
            density_hi = start_density
            density_lo = 0.55

    while density_hi - density_lo > density_interval:
        density_mid = round((density_lo + density_hi) / 2, 4)
        config_data["DIE_AREA"] = f"0 0 {int(dim_x)} {int(dim_y)}"
        config_data["PL_TARGET_DENSITY"] = density_mid
        with open(config_path, 'w') as f:
            json.dump(config_data, f, indent=4)
        print(f"\nTrying density {density_mid}\n")
        run_count += 1
        ok = run_cmd(cmd, project_root)

        if ok:
            tg_density = density_mid
            density_lo = density_mid
            if os.path.islink(run_symlink):
                best_run_path = os.path.realpath(run_symlink)
        else:
            density_hi = density_mid

    print(f"Optimal target density found = {tg_density}\n")
else:
    tg_density = selected_density
    print(f"\nSkipping density optimization and running with target density = {tg_density}\n")

# minimize area (square)
print("Binary search for minimum area")
area_hi = area0
area_lo = 0
past_areas = {}
print("setting die area and target density")
config_data["DIE_AREA"] = f"0 0 {int(dim_x)} {int(dim_y)}"
config_data["PL_TARGET_DENSITY"] = tg_density
with open(config_path, 'w') as f:
    json.dump(config_data, f, indent=4)

if stepping_ok:
    initial_ok = True
    print(f"\nArea {area0} ({dim_x}x{dim_y}) (cached OK)\n")
else:
    ok = run_cmd(cmd, project_root)
    initial_ok = ok
past_areas[(dim_x, dim_y)] = initial_ok
if initial_ok:
    if os.path.islink(run_symlink):
        best_run_path = os.path.realpath(run_symlink)
    while area_lo < area_hi - 1:
        area_mid = (area_lo + area_hi) // 2
        side = max(1, int(math.sqrt(area_mid)))
        dim_x, dim_y = side, side
        key = (dim_x, dim_y)
        if key in past_areas:
            ok = past_areas[key]
            print(f"\nArea {area_mid} ({dim_x}x{dim_y}) (cached {'OK' if ok else 'FAIL'})\n")
        else:
            with open(config_path, 'r') as f:
                config_data = json.load(f)
            config_data["DIE_AREA"] = f"0 0 {int(dim_x)} {int(dim_y)}"
            config_data["PL_TARGET_DENSITY"] = tg_density
            with open(config_path, 'w') as f:
                json.dump(config_data, f, indent=4)
            print(f"\nArea {area_mid} ({dim_x}x{dim_y})\n")
            run_count += 1
            ok = run_cmd(cmd, project_root)
            past_areas[key] = ok
            if ok and os.path.islink(run_symlink):
                best_run_path = os.path.realpath(run_symlink)
        if ok:
            area_hi = area_mid
        else:
            area_lo = area_mid + 1
best_area = dim_x * dim_y
best_square_x, best_square_y = dim_x, dim_y
with open(config_path, 'r') as f:
    config_data = json.load(f)
config_data["DIE_AREA"] = f"0 0 {int(dim_x)} {int(dim_y)}"
config_data["PL_TARGET_DENSITY"] = tg_density
with open(config_path, 'w') as f:
    json.dump(config_data, f, indent=4)
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
        ok = run_cmd(cmd, project_root)

        if ok:
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

# write optimizer log in runs directory
elapsed = time.time() - start_time
log_path = os.path.join(runs_dir, "optimizer.log")
with open(log_path, "a") as f:
    ts = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())
    f.write(
        f"[{ts}] module={modulename} area={dim_x}x{dim_y} "
        f"density={tg_density} time_sec={elapsed:.1f}\n"
    )
print(f"Optimizer log written to: {log_path}")
