import sys
import os
import subprocess
import json
import math
from enum import Enum


#amount to add to density between each increase
density_interval = 0.05


modulename = sys.argv[1]
# areas = sys.argv[2:] #change this from dimensions to predefined areas (μm)
areas = [200*200, 400*400, 600*600, 800*00]

# if len(areas) % 2 != 0:
#     print("Area mismatch: need pairs of x y values")
#     sys.exit(1)

openlane_dir = f"openlane/{modulename}"
if not os.path.exists(openlane_dir):
    print(f"{openlane_dir} does not exist")
    sys.exit(1)

config_path = os.path.join(openlane_dir, "config.json")
if not os.path.exists(config_path):
    print(f"{config_path} does not exist")
    sys.exit(1)



project_root = os.path.abspath(os.path.join(openlane_dir, "..", ".."))
config_path = os.path.join(project_root, openlane_dir, "config.json")

best_area = None
cmd = f"bash -c 'source /local/toolchain/activate && cd {project_root} && export OPENLANE_ROOT={project_root}/dependencies/openlane_src && export PDK_ROOT={project_root}/dependencies/pdks && export PDK=sky130A && make {modulename}'"

# even runs will modify dimensions
# odd runs will modify target density

run_count = 0
last_action = []

max_density = 1.0

class actions(Enum):
    inc_density = 0
    minimize_dimension = 1

dim_x = []
dim_y = []

for area in areas: 
    #Starting Target Density
    tg_density = 0.55

    # To start assume all areas are a square, dimensions will be modified later on.
    x = math.sqrt(area)
    y = dim_y

    #Stack of last dimensions to rollack incase a failure
    dim_x.push(x)
    dim_y.push(y)

    
    while(1):
        if (run_count%2 == 0 & run_count!=0) | tg_density == max_density: 
            x-=25
            y -=25
            last_action.push(actions.minimize_dimension)
        else:
            if tg_density< max_density:
                tg_density += density_interval
                last_action.push(actions.inc_density)
        replacement = f"0 0 {x} {y}"
        with open(config_path, 'r') as f:
            config_data = json.load(f)
        config_data["DIE_AREA"] = replacement
        config_data["PL_TARGET_DENSITY"] = tg_density
        with open(config_path, 'w') as f:
            json.dump(config_data, f, indent=4)

        result = subprocess.run(cmd, shell=True, cwd=project_root)

        if result.returncode !=0:
            undo = last_action.pop
            if undo == actions.minimize_dimension:
                x = dim_x.pop
                y = dim_x.pop
            else:
                tg_density-=density_interval
                max_density = tg_density
        else:
            dim_x.push(x)
            dim_y.push(y)
            
    

# TODO: CHANGE:
#     for area in ("AREA 1", "AREA 2", "AREA 3", "AREA 4"):
#   target_density = [some starting value]
#   dims = [some starting value]
#   while no convergence:
#     increase target_density until Openlane throws routing congestion errors
#     decrease area until Openlane throws routing congestion/area errors
#     back up if necessary (binary search/gradient ascent-style)

# return best area strategy, final dimensions