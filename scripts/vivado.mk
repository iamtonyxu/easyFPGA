###################################################################
# 
# Parameters:
# BUILD_DIR			- 构建时的输出路径, 默认=build
# CONFIG			- 用户配置 Makefile
# PROJECT			- 项目名称, 默认=FPGA_TOP
# FPGA_TOP 			- 顶层模块名, 默认=fpga
# FPGA_SIM_TOP		- 仿真部分的顶层模块
# FPGA_PART 		- FPGA 设备 (例如 xcvu095-ffva2104-2-e)
# SYN_FILES 		- 可综合源文件
# SIM_FILES 		- 仿真文件
# INC_FILES 		- 要包含的文件
# XDC_FILES 		- 约束文件
# XCI_FILES 		- xci 格式的 IP 文件
# IP_TCL_FILES 		- tcl 格式的 IP 文件
# BD_TCL_FILES 		- BD 设计文件
# IP_REPO_PATHS 	- IP 仓库地址
# CONFIG_TCL_FILES 	- tcl 配置文件
# 
# Example:
#
# BUILD_DIR = build
# PROJECT = demo_zc706
# FPGA_PART = xc7z045ffg900-1
# FPGA_TOP = switch2leds
# SYN_FILES += $(wildcard src/*.v)
# XDC_FILES += constraints/zc706_system_constr.xdc
# include ../scripts/vivado_project.mk
# 
###################################################################

# phony targets
.PHONY: fpga vivado clean program config synth impl flash simulate waves

# prevent make from deleting intermediate files and reports
.PRECIOUS: %.xpr %.bit %.mcs %.prm
.SECONDARY:

CONFIG ?= config.mk
-include $(CONFIG)

FPGA_PART ?= xc7z045ffg900-1
BUILD_DIR ?= build
# use the name of the directory as the project name
PROJECT ?= $(shell basename $(shell pwd))
# use the name of the directory as the top module name
FPGA_TOP ?= $(shell basename $(shell pwd))
# use the name of the directory plus '_tb' as the simulation top module name
FPGA_SIM_TOP ?= $(shell basename $(shell pwd))_tb
VIVADO_OPTS += -nojournal -nolog -tempDir $(BUILD_DIR)

BPREFIX = $(BUILD_DIR)/$(PROJECT)

# compile options
COMP_OPTS := \
    --incr \
    --relax \

NUM_JOBS ?= 8

# compile sources
SOURCES_SV := $(filter %.sv,$(SYN_FILES))
SOURCES_V := $(filter %.v,$(SYN_FILES))
SOURCES_VHDL := $(filter %.vhd,$(SYN_FILES))
SOURCES_SV += $(filter %.sv,$(SIM_FILES))
SOURCES_V += $(filter %.v,$(SIM_FILES))
SOURCES_VHDL += $(filter %.vhd,$(SIM_FILES))

###################################################################
# Main Targets
#
# all: build everything
# clean: remove output files and project files
###################################################################
.ONESHELL:
all: fpga

fpga: $(BPREFIX).bit

vivado: $(BPREFIX).xpr
	vivado.bat $(VIVADO_OPTS) $(BPREFIX).xpr

clean:
	rm -rf $(BUILD_DIR)
	rm -rf *.jou *.log *.pb *.wdb xsim.dir .Xil
	rm -rf .*.timestamp *.mti *.mpf *.wlf

###################################################################
# Target implementations
###################################################################

# Vivado project file
$(BUILD_DIR)/create_project.tcl: Makefile $(XCI_FILES) $(IP_TCL_FILES)
	mkdir -p $(BUILD_DIR)
	rm -rf $(BUILD_DIR)/defines.v
	touch $(BUILD_DIR)/defines.v
	for x in $(DEFS); do 
		echo '`define' 
		$$x >> $(BUILD_DIR)/defines.v
	done
	@cat << EOF > $@
		## Auto-generated, do not modify!
	EOF
	@cat << EOF >> $@
		create_project -force -part $(FPGA_PART) $(PROJECT) $(BUILD_DIR)
	EOF
	if [ "$(SYN_FILES)" ]; then echo "add_files -fileset sources_1 $(SYN_FILES)" >> $@; fi
	if [ "$(XDC_FILES)" ]; then echo "add_files -fileset constrs_1 $(XDC_FILES)" >> $@; fi
	if [ "$(SIM_FILES)" ]; then echo "add_files -fileset sim_1 $(SIM_FILES)" >> $@; fi
	if [ "$(IP_REPO_PATHS)" ]; then
		echo "set_property ip_repo_paths [concat $(IP_REPO_PATHS)] [current_project]" >> $@;
		echo "update_ip_catalog" >> $@; fi
	for x in $(XCI_FILES); 			do echo "import_ip $$x"	>> $@; done
	for x in $(IP_TCL_FILES); 		do echo "source $$x" 	>> $@; done
	for x in $(CONFIG_TCL_FILES); 	do echo "source $$x" 	>> $@; done
	for x in $(BD_TCL_FILES); 		do 
		echo "source $$x" 	>> $@;
		echo "make_wrapper -files [get_files [glob $(BPREFIX).srcs/sources_1/bd/**/*.bd]] -top" >> $@
		echo "add_files -fileset sources_1 [glob $(BPREFIX).gen/sources_1/bd/**/hdl/*wrapper.v]" >> $@
	done
	if [ "$(FPGA_TOP)" ]; then echo "set_property top $(FPGA_TOP) [get_filesets sources_1]" >> $@; fi
	if [ "$(FPGA_SIM_TOP)" ]; then echo "set_property top $(FPGA_SIM_TOP) [get_filesets sim_1]" >> $@; fi

$(BUILD_DIR)/update_config.tcl: $(CONFIG_TCL_FILES) $(SYN_FILES) $(INC_FILES) $(XDC_FILES)
	mkdir -p $(BUILD_DIR)
	echo "open_project -quiet $(BPREFIX).xpr" 			> $@
	for x in $(CONFIG_TCL_FILES); do echo "source $$x" >> $@; done

$(BPREFIX).xpr: $(BUILD_DIR)/create_project.tcl $(BUILD_DIR)/update_config.tcl
	mkdir -p $(BUILD_DIR)	
	vivado.bat $(VIVADO_OPTS) -mode batch $(foreach x,$?,-source $x)

# synthesis run
$(BPREFIX).runs/synth_1/$(PROJECT).dcp: $(BUILD_DIR)/create_project.tcl $(BUILD_DIR)/update_config.tcl \
	$(SYN_FILES) $(INC_FILES) $(XDC_FILES) | $(BPREFIX).xpr
	@cat << EOF > $(BUILD_DIR)/run_synth.tcl
		open_project $(BPREFIX).xpr
		reset_run synth_1
		launch_runs -jobs $(NUM_JOBS) synth_1
		wait_on_run synth_1
	EOF
	vivado.bat $(VIVADO_OPTS) -mode batch -source $(BUILD_DIR)/run_synth.tcl

# implementation run
$(BPREFIX).runs/impl_1/$(PROJECT)_routed.dcp: $(BPREFIX).runs/synth_1/$(PROJECT).dcp
	# if XDC_FILES is empty, skip the implementation run
	if [ -z "$(XDC_FILES)" ]; then
		echo "No constraints file found, skipping implementation run!"
		exit 1
	else
		@cat << EOF > $(BUILD_DIR)/run_impl.tcl
			open_project $(BPREFIX).xpr
			reset_run impl_1
			launch_runs -jobs $(NUM_JOBS) impl_1
			wait_on_run impl_1
			open_run impl_1
			report_utilization -file $(BPREFIX)_utilization.rpt
			report_utilization -hierarchical -file $(BPREFIX)_utilization_hierarchical.rpt
		EOF
		vivado.bat $(VIVADO_OPTS) -mode batch -source $(BUILD_DIR)/run_impl.tcl
	fi

# bit file
$(BPREFIX).bit $(BPREFIX).ltx: $(BPREFIX).runs/impl_1/$(PROJECT)_routed.dcp
	@cat << EOF > $(BUILD_DIR)/generate_bit.tcl
		open_project $(BPREFIX).xpr
		open_run impl_1
		write_bitstream -force $(BPREFIX).runs/impl_1/$(PROJECT).bit
		write_debug_probes -force $(BPREFIX).runs/impl_1/$(PROJECT).ltx
	EOF
	vivado.bat $(VIVADO_OPTS) -mode batch -source $(BUILD_DIR)/generate_bit.tcl

	cp -pv $(BPREFIX).runs/impl_1/$(PROJECT).bit $(BUILD_DIR)
	if [ -e $(BPREFIX).runs/impl_1/$(PROJECT).ltx ]; then 
		cp -pv $(BPREFIX).runs/impl_1/$(PROJECT).ltx $(BUILD_DIR)
	fi

	mkdir -p $(BUILD_DIR)/rev
	COUNT=100

	while [ -e $(BUILD_DIR)/rev/$(PROJECT)_rev$$COUNT.bit ]; do 
		COUNT=$$((COUNT+1)) 
	done

	cp -pv $(BPREFIX).runs/impl_1/$(PROJECT).bit $(BUILD_DIR)/rev/$(PROJECT)_rev$$COUNT.bit
	if [ -e $(BPREFIX).runs/impl_1/$(PROJECT).ltx ]; then 
		cp -pv $(BPREFIX).runs/impl_1/$(PROJECT).ltx $(BUILD_DIR)/rev/$(PROJECT)_rev$$COUNT.ltx
	fi

config: $(BPREFIX).xpr
	make $<

synth: $(BPREFIX).runs/synth_1/$(PROJECT).dcp
	make $<

impl: $(BPREFIX).runs/synth_1/$(PROJECT).dcp
	make $<

program: $(BUILD_DIR)/$(PROJECT).bit
	if [ ! -e $< ]; then
		echo "No bit file found, skipping programming!"
		exit 1
	else
		@cat << EOF > $(BUILD_DIR)/program.tcl
			open_hw_manager
			connect_hw_server
			open_hw_target
			current_hw_device [lindex [get_hw_devices] 1]
			refresh_hw_device -update_hw_probes false [current_hw_device]  
			set_property PROGRAM.FILE {$<} [current_hw_device]
			program_hw_devices [current_hw_device]
			exit
		EOF
		vivado.bat $(VIVADO_OPTS) -mode batch -source $(BUILD_DIR)/program.tcl
	fi

%.mcs %.prm: %.bit
	@cat << EOF > $(BUILD_DIR)/generate_mcs.tcl
		write_cfgmem -force -format mcs -size 128 -interface SPIx4 -loadbit {up 0x01002000 $*.bit} -checksum -file $*.mcs
		exit
	EOF
	vivado.bat $(VIVADO_OPTS) -mode batch -source $(BUILD_DIR)/generate_mcs.tcl

	mkdir -p $(BUILD_DIR)/rev
	COUNT=100
	while [ -e $(BUILD_DIR)/rev/$*_rev$$COUNT.bit ]; do 
		COUNT=$$((COUNT+1)) 
	done
	COUNT=$$((COUNT-1))
	for x in .mcs .prm; do
		cp $*$$x $(BUILD_DIR)/rev/$*_rev$$COUNT$$x
		echo "Output: $(BUILD_DIR)/rev/$*_rev$$COUNT$$x" 
	done

ip_gen: $(BPREFIX).xpr
	@cat << EOF > $(BUILD_DIR)/ip_gen.tcl
		open_project $(BPREFIX).xpr
		ipx::package_project -import_files -force -root_dir ../../ip_gen/$(FPGA_TOP)

		# 设置 ip 属性和信息
		set_property vendor              {xilinx.com}            [ipx::current_core]
		set_property library             {user}                  [ipx::current_core]
		set_property taxonomy            {{/demo}}               [ipx::current_core]
		set_property vendor_display_name {tonyxu}                [ipx::current_core]
		set_property company_url         {xilinx.com}            [ipx::current_core]
		set_property supported_families  {
			virtex7    Production \
			qvirtex7   Production \
			kintex7    Production \
			kintex7l   Production \
			qkintex7   Production \
			qkintex7l  Production \
			artix7     Production \
			artix7l    Production \
			aartix7    Production \
			qartix7    Production \
			zynq       Production \
			qzynq      Production \
			azynq      Production \
			zynquplus  Production
		} [ipx::current_core]

		ipx::save_core [ipx::current_core]
		close_project
	EOF
	vivado.bat $(VIVADO_OPTS) -mode batch -source $(BUILD_DIR)/ip_gen.tcl

flash: $(BUILD_DIR)/$(FPGA_TOP).mcs $(BUILD_DIR)/$(FPGA_TOP).prm
	if [ ! -e $(BUILD_DIR)/$(FPGA_TOP).prm ]; then
		echo "No prm file found, skipping flash programming!"
		exit 1
	else
		@cat << EOF > $(BUILD_DIR)/flash.tcl
			open_hw
			connect_hw_server
			open_hw_target
			current_hw_device [lindex [get_hw_devices] 0]
			refresh_hw_device -update_hw_probes false [current_hw_device]
			create_hw_cfgmem -hw_device [current_hw_device] [lindex [get_cfgmem_parts {mt25qu01g-spi-x1_x2_x4}] 0]
			current_hw_cfgmem -hw_device [current_hw_device] [get_property PROGRAM.HW_CFGMEM [current_hw_device]]
			set_property PROGRAM.FILES [list \"$(BUILD_DIR)/$(FPGA_TOP).mcs\"] [current_hw_cfgmem]
			set_property PROGRAM.PRM_FILES [list \"$(BUILD_DIR)/$(FPGA_TOP).prm\"] [current_hw_cfgmem]
			set_property PROGRAM.ERASE 1 [current_hw_cfgmem]
			set_property PROGRAM.CFG_PROGRAM 1 [current_hw_cfgmem]
			set_property PROGRAM.VERIFY 1 [current_hw_cfgmem]
			set_property PROGRAM.CHECKSUM 0 [current_hw_cfgmem]
			set_property PROGRAM.ADDRESS_RANGE {use_file} [current_hw_cfgmem]
			set_property PROGRAM.UNUSED_PIN_TERMINATION {pull-none} [current_hw_cfgmem]
			create_hw_bitstream -hw_device [current_hw_device] [get_property PROGRAM.HW_CFGMEM_BITFILE [current_hw_device]]
			program_hw_devices [current_hw_device]
			refresh_hw_device [current_hw_device]
			program_hw_cfgmem -hw_cfgmem [current_hw_cfgmem]
			boot_hw_device [current_hw_device]
			exit
		EOF
		vivado.bat $(VIVADO_OPTS) -mode batch -source flash.tcl
	fi

###################################################################
# Simulation
###################################################################
# running simulation without drawing waveforms
.PHONY : simulate
simulate : $(FPGA_SIM_TOP)_snapshot.wdb

.PHONY : elaborate
elaborate : .elab.timestamp

.PHONY : compile
compile : .comp_sv.timestamp .comp_v.timestamp .comp_vhdl.timestamp

# drawing waveforms
.PHONY : waves
waves : $(FPGA_SIM_TOP)_snapshot.wdb
	@echo
	@echo "### OPENING WAVES ###"
	xsim --gui $(FPGA_SIM_TOP)_snapshot.wdb

# simulation
$(FPGA_SIM_TOP)_snapshot.wdb : .elab.timestamp
	@echo
	@echo "### RUNNING SIMULATION ###"
	xsim $(FPGA_SIM_TOP)_snapshot -tclbatch ../../scripts/xsim_cfg.tcl

# elaboration
.elab.timestamp : .comp_sv.timestamp .comp_v.timestamp .comp_vhdl.timestamp
	@echo
	@echo "### ELABORATING ###"
	if [ -z "$(FPGA_SIM_TOP)" ]; then
		echo "No top module for simulation found, skipping elaboration!"
		exit 1
	else
		xelab -debug all -top $(FPGA_SIM_TOP) -snapshot $(FPGA_SIM_TOP)_snapshot
		touch .elab.timestamp
	fi

# compiling systemverilog
ifeq ($(strip $(SOURCES_SV)),)
.comp_sv.timestamp :
	@echo
	@echo "### NO SYSTEMVERILOG SOURCES GIVEN ###"
	@echo "### SKIPPED SYSTEMVERILOG COMPILATION ###"
	touch .comp_sv.timestamp
else
.comp_sv.timestamp : $(SOURCES_SV)
	@echo
	@echo "### COMPILING SYSTEMVERILOG ###"
	xvlog --sv $(COMP_OPTS) $(DEFINES_SV) $(SOURCES_SV)
	touch .comp_sv.timestamp
endif

# compiling verilog
ifeq ($(strip $(SOURCES_V)),)
.comp_v.timestamp :
	@echo
	@echo "### NO VERILOG SOURCES GIVEN ###"
	@echo "### SKIPPED VERILOG COMPILATION ###"
	touch .comp_v.timestamp
else
.comp_v.timestamp : $(SOURCES_V)
	@echo
	@echo "### COMPILING VERILOG ###"
	xvlog $(COMP_OPTS) $(DEFINES_V) $(SOURCES_V)
	touch .comp_v.timestamp
endif

# compiling vhdl
ifeq ($(strip $(SOURCES_VHDL)),)
.comp_vhdl.timestamp :
	@echo
	@echo "### NO VHDL SOURCES GIVEN ###"
	@echo "### SKIPPED VHDL COMPILATION ###"
	touch .comp_vhdl.timestamp
else
.comp_vhdl.timestamp : $(SOURCES_VHDL)
	@echo
	@echo "### COMPILING VHDL ###"
	xvhdl $(COMP_OPTS) $(SOURCES_VHDL)
	touch .comp_vhdl.timestamp
endif
