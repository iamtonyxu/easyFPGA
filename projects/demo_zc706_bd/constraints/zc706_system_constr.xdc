
# constraints

# sys_clk
set_property -dict {PACKAGE_PIN H9 IOSTANDARD LVCMOS15} [get_ports clk]

# gpio (switches, leds and such)

set_property -dict {PACKAGE_PIN AB17 IOSTANDARD LVCMOS25} [get_ports {switch_0}]
set_property -dict {PACKAGE_PIN AC16 IOSTANDARD LVCMOS25} [get_ports {switch_1}]
set_property -dict {PACKAGE_PIN AC17 IOSTANDARD LVCMOS25} [get_ports {switch_2}]
set_property -dict {PACKAGE_PIN AJ13 IOSTANDARD LVCMOS25} [get_ports {switch_3}]

set_property -dict {PACKAGE_PIN Y21 IOSTANDARD LVCMOS25} [get_ports {led_3}]
set_property -dict {PACKAGE_PIN G2 IOSTANDARD LVCMOS15}  [get_ports {led_2}]
set_property -dict {PACKAGE_PIN W21 IOSTANDARD LVCMOS25} [get_ports {led_1}]
set_property -dict {PACKAGE_PIN A17 IOSTANDARD LVCMOS15} [get_ports {led_0}]