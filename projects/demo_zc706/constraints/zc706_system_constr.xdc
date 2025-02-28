
# constraints

# sys_clk
set_property -dict {PACKAGE_PIN H9 IOSTANDARD LVCMOS15} [get_ports clk]

# gpio (switches, leds and such)

set_property -dict {PACKAGE_PIN AB17 IOSTANDARD LVCMOS25} [get_ports {switches[0]}]
set_property -dict {PACKAGE_PIN AC16 IOSTANDARD LVCMOS25} [get_ports {switches[1]}]
set_property -dict {PACKAGE_PIN AC17 IOSTANDARD LVCMOS25} [get_ports {switches[2]}]
set_property -dict {PACKAGE_PIN AJ13 IOSTANDARD LVCMOS25} [get_ports {switches[3]}]

set_property -dict {PACKAGE_PIN Y21 IOSTANDARD LVCMOS25} [get_ports {leds[3]}]
set_property -dict {PACKAGE_PIN G2 IOSTANDARD LVCMOS15}  [get_ports {leds[2]}]
set_property -dict {PACKAGE_PIN W21 IOSTANDARD LVCMOS25} [get_ports {leds[1]}]
set_property -dict {PACKAGE_PIN A17 IOSTANDARD LVCMOS15} [get_ports {leds[0]}]