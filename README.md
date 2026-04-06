# Embedded GPU for Fabrication

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

# Table of Contents
- [Embedded GPU for Fabrication](#embedded-gpu-for-fabrication)
- [Table of Contents](#table-of-contents)
- [Overview](#overview)
- [Consumer Need](#consumer-need)
- [Design Proposal](#design-proposal)
  - [Data Path \& Software](#data-path)
  - [Hardware](#hardware)
  - [Supporting Circuitry](#supporting-circuitry)
- [Testing](#testing)
- [Further Information](#further-information)
- [Acknowledgements](#acknowledgements)

# Overview
This repository contains the uGPU project: a programmable 3D graphics processor designed using the Caravel harness by the sdmay26-24 senior design team at Iowa State University. The uGPU uses an array of custom processing cores and a fixed-function rasterizer to render 3D scenes and display them over VGA. It slots into a custom PCB, which provides 24MB of QSPI PSRAM for model data and framebuffers. While primarily designed for raster graphics, the uGPU is also capable of GPGPU compute tasks such as image processing and complex simulations.

# Consumer Need
Modern graphics processing units (GPUs) are complex devices. The uGPU is a small footprint educational GPU designed for the members of Iowa State's Chip Forge co-curricular. Chip Forge's focus is to give students an opportunity to experience ASIC design before or alongside their coursework. Students can use the uGPU to interactively learn about graphics architecture, GPU programming, and the chip design process. This project is designed to complement and encourage further self-research and exploration. uGPU is also open for use by makers, hobbyists, enthusiasts, or students at other universities who may be interested in computer graphics but lack access to formal coursework.

# Design Proposal
<p align="center">
    <img src="docs/source/_static/OverallDesign.png"> <br>
</p>

A block diagram of the uGPU, including the Caravel management area and external hardware, is shown above.

## Data Path
Triangle mesh 3D models are loaded into the uGPU's external RAM as a list of vertices in 3D space and a list of vertex connectivity. Each triangle passes through vertex shading, rasterization, fragment shading, and the framebuffer before being displayed to the user.

Vertex shading, a program run on the shader cores, transforms each triangle of a model into Screen Space. First, a given triangle of a model is multiplied by the model matrix to translate it into World Space, placing it into the full 3D scene. Then, the view matrix is then used to transform the vertex to Camera Space, placing the triangle relative to the camera. Then, the perspective matrix adds perspective projection, depth of field, field of view, and clips off any model features outside of a certain depth range. Finally, the screen matrix transforms the triangle into screen coordinates. Once normalized, vertex shading returns the vector [x<sub>screen</sub>, y<sub>screen</sub>, z<sub>depth</sub>].

The rasterizer consumes the vertices that are produced by the cores. It first determines bounding box of the triangle. Then it checks whether the trangle is facing the camera. If a triangle is facing away from the camera it is thrown away. Next, the rasterizer finds the barycentric coordinates of the pixels in the triangle and the distance from the pixel to the camera. If the pixel currently being processed is closer to the camera than the existing pixel at that screen location, the pixel will be overwritten. Otherwise, the pixel will be thrown away. Finally, the rasterizer gives the pixel a color by mapping a texture onto it. The finished pixels, called fragments, are sent back to the shader cores for fragment shading.

Fragment shading applies lighting and post-processing to all fragments coming out of the rasterizer. The exact algorithms are flexible since the shader cores are programmable. The user could implement basic direct illumination or fancier global illumination or ray tracing algorithms. The user could also implement surface smoothing to reduce sharp edges. Fragment shading writes the finished pixels back to the framebuffer (stored in external RAM).

## Hardware
The three major hardware modules are the rasterizer, core controller, and shader cores.

The shader cores implement a custom ISA inspired by MIPS and RISC-V designed for GPU operations. The cores function similar to a SIMD lane. They are given instructions and data by the core controller and perform operations in parallel. Each shader core has a 5 stage pipeline to complete memory accesses, do logical and arithmetic work, and each has a MAC unit for linear algebra computations. Due to area constraints, shader cores do not contain division hardware. A software division procedure is provided instead.

<p align="center">
    <img src="docs/source/_static/core.png"> <br>
</p>


The core controller is connected to the management area RISC-V processor, and it is in charge of providing the cores with data and instructions. The core controller also manages synchronization across the shader cores. That is, if one core wants to jump or stall, all cores must jump or stall in order to keep each core in parallel with the others. The core controller is also responsible for preventing data deadlock. Deadlock can happen when the cores are running a vertex shade and the fragment FIFO fills up, causing the rasterizer pipeline to stall and not consume the computed vertices in the output of the shader cores. The core controller also handles task selection and switchover between vertex and fragment shading.

<p align="center">
    <img src="docs/source/_static/corecontroller.png">
</p>

## Supporting Circuitry
<p align="center">
    <img src="docs/source/_static/MemoryVGAPmod.png" alt="3D Render of MemoryVGAPmod"> <br>
</p>

The uGPU requires additional hardware to support it. The PCB shown above contains 3 8MB QSPI PSRAM chips and a VGA resistor ladder, and is designed to plug into a 4-wide PMOD header for FPGA testing. The final design, provided on the ChipFoundry M.2 carrier board, will slot into a dedicated PCB containing the same PSRAM chips and VGA connector. The final design aims to move the VGA resistor ladder on-chip in an analog design, freeing up 5 IO pins for other functionality.

# Testing
A bulk of our functional testing is not done in `verilog/dv`, but is done with [SVUnit](https://github.com/svunit/svunit) in `verification/unit_tests` using Mentor QuestaSim. SVUnit is used for smaller unit testing, full-system testing and integration is done using the Caravel platform makefiles in `verilog/dv`. FPGA testing is performed on Digilent Arty A7-100T FPGA boards using Chip Forge's testing utilities and AMD Vivado.

# Further Information
Additional information on this project can be found on our [webpage](https://sdmay26-24.sd.ece.iastate.edu/). The [Design Document](https://sdmay26-24.sd.ece.iastate.edu/resources/designdocs/sdmay26-24_FINAL_DesignDoc.pdf) contains a deeper explanation of the uGPU architecture.

# Acknowledgements
Shader core programs are assembled using the [customasm](https://github.com/hlorenzi/customasm) project. Used under the Apache 2.0 license.

Unit testing uses the [SVUnit](https://github.com/svunit/svunit) project. Used under the Apache 2.0 license.

The pipelined divider used in the uGPU rasterizer was adapted from this implementation by [Li Xinbing](https://github.com/risclite/verilog-divider).

The square root module used in the uGPU rasterizer was adapted from the algorithm presented by Li and Chu in "A new non-restoring square root algorithm and its VLSI implementations," IEEE Proceedings International Conference on Computer Design. Accessed [here](https://ieeexplore.ieee.org/document/563604).

Mentor QuestaSim and AMD Vivado are provided to the project by Iowa State University.
