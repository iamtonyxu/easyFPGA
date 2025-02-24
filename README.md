# easyFPGA
easyFPGA主要涉及FPGA通用接口和数字信号处理两部分，所有模块均使用Modelsim进行功能仿真，并在商用FPGA进行功能验证。<br>
通用接口部分包括：UART, SPI, I2C, I2S, SPI, CAN, LVDS/COMS, JESD 204B...<br>
数字信号处理部分包括：FIR, CIC, DDS, DDC, DUC...

**请注意，这里所有的模块和测试用例均采用AI大模型(DeepSeek R1)辅助设计，目的在于探究AI能否会完全替代FPGA工程师，或者说工程师该怎么利用AI来提高工作效率。**

## 设计流程
每一个FPGA模块的设计流程如下：
1. 提示词，提示词，提示词...
2. 手动修改
3. 功能仿真
4. 时序优化
5. 板级测试

**一个简单的例子**
adder文件夹包含如下以下3个文件，分别对应设计模块源代码，测试用例和Modelsim执行脚本。
- adder.v
- adder_tb.v
- run_sim.do <br>
在Modelsim命令行打开当前文件夹: *cd path-of-adder* <br>
命令输入: *do run_sim.do* <br>
测试脚本自动执行，打印仿真波形或者输出日志。<br>
此外，较复杂的模块可能包含步骤时序优化或者板级测试，将会有另外的设计文件或者脚本。
