# Top Level Design TB and Firmware
This folder contains the firmware for the full uGPU design.

The main C file is `top_level.c`, it must be named the same as the directory and Verilog testbench otherwise the Caravel makefiles won't find it properly.

To flash the FPGA or taped out chip during bringup: `make verify-top_level-flash`.

## Directories
- `../../../library/firmware_vexriscv/verilog/dv/firmware`: Caravel common defs
  - `defs.h`: Definitions for Caravel registers
  - `stub.h, stub.c`: Provided utility functions
- `../firmware/`: uGPU common defs
- `assets/`: Test models to render with
  - `bunny.obj`: Stanford bunny, converted to OBJ using `ply_to_obj.py`. 69451 triangles. [Source](http://graphics.stanford.edu/pub/3Dscanrep/bunny.tar.gz)
  - `cheburashka.obj`: Cheburashka. 13334 triangles. Created by Ilya Baran and Jovan Popovic for their paper [here](https://dblp.org/rec/journals/tog/BaranP07.html?view=bibtex). [Source](https://github.com/alecjacobson/common-3d-test-models/blob/master/data/cheburashka.obj)
  - `cow.obj`: Cow. 5804 triangles. Created by DeCarlo et. al. for their paper [here](https://dblp.uni-trier.de/rec/journals/tog/DeCarloFRS03.html?view=bibtex). [Source](https://github.com/alecjacobson/common-3d-test-models/blob/master/data/cow.obj)
  - `cube.obj`: 10x10x10 cube. 12 triangles. Source: Created by Michael Drobot in Autodesk Inventor.
  - `dragon.obj`: Stanford dragon, converted to OBJ using `ply_to_obj.py`. 871414 triangles. [Source](http://graphics.stanford.edu/pub/3Dscanrep/dragon/dragon_recon.tar.gz)
  - `teapot.obj`: Utah Teapot. 6320 triangles. [Source](https://graphics.stanford.edu/courses/cs148-10-summer/as3/code/as3/teapot.obj)
  - `suzanne.obj`: Suzanne, the Blender mascot. 500 triangles. [Source](https://projects.blender.org/blender/blender/src/branch/main/tests/files/io_tests/obj/suzanne_all_data.obj)
- `lib/`: C libraries
- `scripts/`: Python utilities
- `src/`: C sources

## Scripts
All scripts should be run using the Caravel Python venv: `source [path_to_project_root]/venv/bin/activate` to activate.

Pip packages can be installed normally using `pip` after the venv has been activated: `(venv) user@pc $ pip install my_dependency`. Install the dependencies for the script you're trying to run, otherwise it won't work.

- `obj_to_rasterizer.py`: Convert an OBJ 3D model file to verilog code for the rasterizer testbench.
  - Usage: `obj_to_rasterizer.py [model.obj] [output.v]`
  - Dependencies: `open3d, numpy`
- `ply_to_obj.py`: Convert a PLY polygon file model to OBJ format.
  - Usage: `ply_to_obj.py [infile.ply] [outfile.obj]
  - Dependencies: `open3d`
