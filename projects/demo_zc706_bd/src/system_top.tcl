# Create a new project
set bd_top "system_top"
create_bd_design ${bd_top}
update_compile_order -fileset sources_1

# Add sources to the project
set_property  ip_repo_paths  ../../ip_gen [current_project]
update_ip_catalog

# Add IP to the block design
startgroup
create_bd_cell -type ip -vlnv xilinx.com:user:PushButton_Debouncer:1.0 PushButton_Debouncer_0
create_bd_cell -type ip -vlnv xilinx.com:user:PushButton_Debouncer:1.0 PushButton_Debouncer_1
create_bd_cell -type ip -vlnv xilinx.com:user:PushButton_Debouncer:1.0 PushButton_Debouncer_2
create_bd_cell -type ip -vlnv xilinx.com:user:PushButton_Debouncer:1.0 PushButton_Debouncer_3
endgroup

# Add ports to the block design
create_bd_port -dir I clk
connect_bd_net [get_bd_ports clk] [get_bd_pins PushButton_Debouncer_0/clk]
connect_bd_net [get_bd_ports clk] [get_bd_pins PushButton_Debouncer_1/clk]
connect_bd_net [get_bd_ports clk] [get_bd_pins PushButton_Debouncer_2/clk]
connect_bd_net [get_bd_ports clk] [get_bd_pins PushButton_Debouncer_3/clk]

create_bd_port -dir I switch_0
connect_bd_net [get_bd_ports switch_0] [get_bd_pins PushButton_Debouncer_0/PB]
create_bd_port -dir I switch_1
connect_bd_net [get_bd_ports switch_1] [get_bd_pins PushButton_Debouncer_1/PB]
create_bd_port -dir I switch_2
connect_bd_net [get_bd_ports switch_2] [get_bd_pins PushButton_Debouncer_2/PB]
create_bd_port -dir I switch_3
connect_bd_net [get_bd_ports switch_3] [get_bd_pins PushButton_Debouncer_3/PB]

create_bd_port -dir O led_0
connect_bd_net [get_bd_ports led_0] [get_bd_pins PushButton_Debouncer_0/PB_state]
create_bd_port -dir O led_1
connect_bd_net [get_bd_ports led_1] [get_bd_pins PushButton_Debouncer_1/PB_state]
create_bd_port -dir O led_2
connect_bd_net [get_bd_ports led_2] [get_bd_pins PushButton_Debouncer_2/PB_state]
create_bd_port -dir O led_3
connect_bd_net [get_bd_ports led_3] [get_bd_pins PushButton_Debouncer_3/PB_state]

# Generate the block design layout
regenerate_bd_layout

# Save the block design
save_bd_design


set project_name [get_property NAME [current_project]]

make_wrapper -files [get_files ./build/${project_name}.srcs/sources_1/bd/${bd_top}/${bd_top}.bd] -top

add_files -norecurse ./build/${project_name}.gen/sources_1/bd/${bd_top}/hdl/${bd_top}_wrapper.v

update_compile_order -fileset sources_1

set_property top ${bd_top}_wrapper [current_fileset]

