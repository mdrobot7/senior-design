CUSTOMASM_URL="https://github.com/hlorenzi/customasm/releases/download/v0.13.12/customasm_v0.13.12_linux_musl.zip"
CUSTOMASM_ROOT = $(dir $(lastword $(MAKEFILE_LIST)))
CUSTOMASM=$(CUSTOMASM_ROOT)/customasm

.PHONY: setup-customasm
setup-customasm:
	curl -L $(CUSTOMASM_URL) > $(CUSTOMASM_ROOT)/customasm.zip
	unzip -o $(CUSTOMASM_ROOT)/customasm.zip -d $(CUSTOMASM_ROOT)
	rm $(CUSTOMASM_ROOT)/customasm.zip

CUSTOMASM_SOURCES ?=
CUSTOMASM_BINS := $(CUSTOMASM_SOURCES:.s=.bin)

.PHONY: assemble-customasm
assemble-customasm: $(CUSTOMASM_BINS)

%.bin: %.s
	$(CUSTOMASM) $< -o $@