# This first line retrieves the current firmware directory, it should not be changed
FIRMWARE_DIR := $(dir $(lastword $(MAKEFILE_LIST)))

# Add an include path for users of this library modules to look for header files,
# use #include <...> to include from library. This line should not be changed.
INCLUDE_DIRS += -I$(FIRMWARE_DIR)

# This line adds any required c source files, separated by spaces.
# These will be compiled with all firmware programs that use this library module.
SOURCE_FILES +=
