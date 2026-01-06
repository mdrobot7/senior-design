# SPDX-FileCopyrightText: 2020 Efabless Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0

PWDD := $(shell pwd)
BLOCKS := $(shell basename $(PWDD))

# ---- Include Partitioned Makefiles ----

CONFIG = caravel_user_project

include $(MCW_ROOT)/verilog/dv/make/env.makefile
include $(MCW_ROOT)/verilog/dv/make/var.makefile
include $(MCW_ROOT)/verilog/dv/make/cpu.makefile
include $(MCW_ROOT)/verilog/dv/make/sim.makefile

# ---- Include RISC-V Deps ----

# Override the caravel linker script and the ChipForge library linker script
export override LINKER_SCRIPT = $(PWDD)/sections.lds

LIBRARY_DIR := $(PWDD)/../../../library
include $(LIBRARY_DIR)/firmware_vexriscv/verilog/dv/make/lib-overrides.makefile

# ---- Include Firmware Files ----

include $(PWDD)/../firmware/Makefile

SRC_DIR = $(PWDD)/src

SOURCE_FILES += $(shell find $(SRC_DIR) -name "*.c")

# ---- Include ASM Sources ----

ASM_DIR = $(SRC_DIR)/asm
CUSTOMASM_SOURCES = $(ASM_DIR)/coretest.s \
					$(ASM_DIR)/edge_detect.s \
					$(ASM_DIR)/fragment_shader.s \
					$(ASM_DIR)/ray_tracer.s \
					$(ASM_DIR)/vertex_shader_cached.s \
					$(ASM_DIR)/vertex_shader.s

INCLUDE_DIRS += -I$(ASM_DIR)
SOURCE_FILES += $(ASM_DIR)/programs.s

$(BLOCKS).elf: $(BLOCKS).c $(LINKER_SCRIPT) $(VEX_STARTUP) $(SOURCE_FILES) assemble-customasm

include $(PWDD)/../../../customasm/Makefile
