BUILD_DIR = build

# FPGA settings
PROJECT = demo_zc706
FPGA_PART = xc7z045ffg900-1
FPGA_TOP = switch2leds

# Files for synthesis
SYN_FILES += $(wildcard src/*.v)

# Constraints
XDC_FILES += constraints/zc706_system_constr.xdc

include ../../scripts/vivado_project.mk