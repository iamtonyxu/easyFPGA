###########################################
# System Top Level TCL Script
# Function: Create block design with button debouncers
###########################################

# Basic configuration
set bd_top "system_top"
set NUM_BUTTONS 4
set IP_REPO_PATH "../../ip_gen"

# Create new block design
if {[catch {create_bd_design ${bd_top}} result]} {
    puts "ERROR: Failed to create block design - $result"
    return -code error
}
update_compile_order -fileset sources_1

# Set IP repository path
if {[catch {
    set_property ip_repo_paths ${IP_REPO_PATH} [current_project]
    update_ip_catalog
} result]} {
    puts "ERROR: Failed to set IP repository path - $result"
    return -code error
}

# Define procedure to create debouncer
proc create_debouncer {index} {
    if {[catch {
        # Create debouncer IP instance
        create_bd_cell -type ip -vlnv xilinx.com:user:PushButton_Debouncer:1.0 PushButton_Debouncer_${index}
        
        # Create and connect ports
        create_bd_port -dir I switch_${index}
        create_bd_port -dir O led_${index}
        
        # Connect clock and signals
        connect_bd_net [get_bd_ports clk] [get_bd_pins PushButton_Debouncer_${index}/clk]
        connect_bd_net [get_bd_ports switch_${index}] [get_bd_pins PushButton_Debouncer_${index}/PB]
        connect_bd_net [get_bd_ports led_${index}] [get_bd_pins PushButton_Debouncer_${index}/PB_state]
    } result]} {
        puts "ERROR: Failed to create debouncer ${index} - $result"
        return -code error
    }
}

# Create clock port
create_bd_port -dir I clk

# Create debouncer instances
startgroup
for {set i 0} {$i < $NUM_BUTTONS} {incr i} {
    create_debouncer $i
}
endgroup

# Generate and save design
if {[catch {
    regenerate_bd_layout
    save_bd_design
} result]} {
    puts "ERROR: Failed to generate or save design - $result"
    return -code error
}

# Create HDL wrapper
set project_name [get_property NAME [current_project]]
set bd_file "./build/${project_name}.srcs/sources_1/bd/${bd_top}/${bd_top}.bd"
set wrapper_file "./build/${project_name}.gen/sources_1/bd/${bd_top}/hdl/${bd_top}_wrapper.v"

if {[catch {
    make_wrapper -files [get_files ${bd_file}] -top
    add_files -norecurse ${wrapper_file}
    update_compile_order -fileset sources_1
    set_property top ${bd_top}_wrapper [current_fileset]
} result]} {
    puts "ERROR: Failed to create or add HDL wrapper - $result"
    return -code error
}

puts "INFO: Block design creation completed successfully"

