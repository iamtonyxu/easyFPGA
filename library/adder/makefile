# synth top module name, default is the name of the directory
#FPGA_TOP = adder

# simulation top module name, default is the name of the directory plus '_tb'
#FPGA_SIM_TOP = adder_tb

# Files for synthesis
SYN_FILES += $(wildcard src/*.v)
SYN_FILES += $(wildcard src/*.vhd)

# Files for simulation
SIM_FILES += $(wildcard src/*.sv)

include ../../scripts/vivado.mk