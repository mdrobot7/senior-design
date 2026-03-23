# Embedded micro-GPU for Fabrication

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

# Table of Contents
- [Embedded micro-GPU for Fabrication](#embedded-micro-gpu-for-fabrication)
- [Table of Contents](#table-of-contents)
- [Overview](#overview)
- [Proposal](#proposal)
- [Consumer Need](#consumer-need)

# Overview
This repository contains a 3D graphics accelerator. Specifically, we created a programmable pipeline embedded GPU (uGPU) that can rasterize 3D user models into 2D space. The data is stored in SRAM chips on an off chip PCBA, which utilize the SPI communication protocol. Then the computation work is done in the ASIC implementation, and is stored in framebuffers in the SRAM chips. When a frame is rendered on the screen, VGA is used to display the pixel information.

# Proposal
The following is our proposed design based on our current development. As described in the overview, we have a PCBA to hold the memory chips, and to hold our VGA port to display to the monitor. A render of this PCBA can be seen below.

<p align="center">
  <img src="docs/source/_static/MemoryVGAPmod.png" alt="3D Render of MemoryVGAPmod">
</p>

This PCBA contains a resistor ladder DAC to convert the digital pixel data to its analog component, which VGA uses. We also plan on having an analog component resistor ladder on chip, but will keep the PCB aleternative open for redundancy. An overview of our SoC can be seen below.

<p align="center">
    <img src="docs/source/_static/OverallDesign.png">
</p>

Our design is in the innermost dashed box. The 3D data enters through the SRAM chips, work is done by the rasterizer and the individual cores, then it is stored as a 2D frame in the offchip memory and read by the VGA module to display on the screen.

//TODO vertex shade

The rasterizer consumes the vertices that are produced by the cores. With them, it determines bounding box of the triangle (the larger rectangle that the triangle can fit into). Then it finds the side that the triangle is facing, and stops doing work for the triangle if it is facing away from the camera. If it is not, it finds the barycentric coordiantes of the pixels in the triangle, then the distance from the pixel to the camera. If the triangle we are currently rasterizing is closer than a previously rasterized triangle, it replaces the old triangle pixel with the new one, because it is closer. Then, we calculate the texture of the pixel and map it to the current pixel. Then we send the data back to the cores for fragment shading.
# Consumer Need
