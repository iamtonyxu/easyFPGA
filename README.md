# easyFPGA
## Makefile管理Xilinx-FPGA项目开发 (part-1)
**branch name:** __demo_makefile_sim__
这个branch演示如何使用Makefile管理Vivado Simulator流程。

**一个简单的例子**
加法器adder包括了设计文件adder.vhd,仿真文件adder_tb.v和makefile，目录如下：
- libaray
	- adder
		- src
			- adder.vhd
			- adder_tb.v
		- makefile  

makefile的内容如下，用户只需要修改源文件和指定顶层文件，便能在其他项目复用。
```makefile
#添加verilog源文件
SOURCES_V := \
	./src/adder_tb.v \
#添加VHDL源文件
SOURCES_VHDL := \
	./src/adder.vhd \
#指定顶层文件
TB_TOP := adder_tb
#引用VIVADO流程的makefile模块
include ../../scripts/vivado.mk
```

**支持的命令**
```bash
make # same as "make simulate"
make simulate
make waves #check waves in vivado
make compile
make clean
```

make命令的结果输出如下：
``` bash
$ make
### NO SYSTEMVERILOG SOURCES GIVEN ###
### SKIPPED SYSTEMVERILOG COMPILATION ###
touch .comp_sv.timestamp

### COMPILING VERILOG ###
xvlog --incr --relax   ./src/adder_tb.v
INFO: [VRFC 10-2263] Analyzing Verilog file "C:/repo2/easyFPGA/library/adder/src/adder_tb.v" into library work
INFO: [VRFC 10-311] analyzing module adder_tb
touch .comp_v.timestamp

### COMPILING VHDL ###
xvhdl --incr --relax  ./src/adder.vhd
INFO: [VRFC 10-163] Analyzing VHDL file "C:/repo2/easyFPGA/library/adder/src/adder.vhd" into library work
INFO: [VRFC 10-3107] analyzing entity 'adder'
touch .comp_vhdl.timestamp

### ELABORATING ###
xelab -debug all -top adder_tb -snapshot adder_tb_snapshot
Vivado Simulator v2022.2
Copyright 1986-1999, 2001-2022 Xilinx, Inc. All Rights Reserved.
Running: C:/Xilinx/Vivado/2022.2/bin/unwrapped/win64.o/xelab.exe -debug all -top adder_tb -snapshot adder_tb_snapshot
Multi-threading is on. Using 14 slave threads.
Starting static elaboration
Pass Through NonSizing Optimizer
Completed static elaboration
Starting simulation data flow analysis
Completed simulation data flow analysis
Time Resolution for simulation is 1ps
Compiling package std.standard
Compiling package std.textio
Compiling package ieee.std_logic_1164
Compiling package ieee.numeric_std
Compiling architecture behavioral of entity work.adder [adder_default]
Compiling module work.adder_tb
Built simulation snapshot adder_tb_snapshot
touch .elab.timestamp

### RUNNING SIMULATION ###
xsim adder_tb_snapshot -tclbatch ../../scripts/xsim_cfg.tcl

****** xsim v2022.2 (64-bit)
  **** SW Build 3671981 on Fri Oct 14 05:00:03 MDT 2022
  **** IP Build 3669848 on Fri Oct 14 08:30:02 MDT 2022
    ** Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.

source xsim.dir/adder_tb_snapshot/xsim_script.tcl
# xsim {adder_tb_snapshot} -autoloadwcfg -tclbatch {../../scripts/xsim_cfg.tcl}
Time resolution is 1 ps
source ../../scripts/xsim_cfg.tcl
## log_wave -recursive *
## run all
Test Case 1: Adding zeros
Test Case 2: Adding with carry
Test Case 3: Adding different values
Test Case 4: Adding maximum values
Test Case 5: Single bit addition
Test Case 6: All bits set
Test finished!
## exit
INFO: [Common 17-206] Exiting xsim at Thu Feb 27 15:07:30 2025...
```
make waves命令将启动Vivado GUI并导入仿真波形文件：
```bash
$ make waves
### OPENING WAVES ###
xsim --gui adder_tb_snapshot.wdb

****** xsim v2022.2 (64-bit)
  **** SW Build 3671981 on Fri Oct 14 05:00:03 MDT 2022
  **** IP Build 3669848 on Fri Oct 14 08:30:02 MDT 2022
    ** Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.

start_gui

```
![仿真波形](./library/adder/snapshot/make_waves.png)
