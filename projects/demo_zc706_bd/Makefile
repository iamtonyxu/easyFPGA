BUILD_DIR = build

# FPGA settings
PROJECT = demo_zc706_bd
FPGA_PART = xc7z045ffg900-1
FPGA_TOP = system_top_wrapper

# Files for synthesis
SYN_FILES += $(wildcard src/*.v)
BD_TCL_FILES += src/system_top.tcl

# Constraints
XDC_FILES += constraints/zc706_system_constr.xdc

include ../../scripts/vivado.mk