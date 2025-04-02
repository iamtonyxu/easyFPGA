source ../../scripts/adi_env.tcl
source $ad_hdl_dir/library/scripts/adi_ip_xilinx.tcl

adi_ip_create axi_dds

set axi_dds [create_ip -name dds_compiler -vendor xilinx.com -library ip -version 6.0 -module_name dds_compiler_0]
set_property -dict [list \
  CONFIG.PartsPresent {Phase_Generator_and_SIN_COS_LUT} \
  CONFIG.DDS_Clock_Rate {100} \
  CONFIG.Channels {1} \
  CONFIG.Mode_of_Operation {Standard} \
  CONFIG.Parameter_Entry {System_Parameters} \
  CONFIG.Spurious_Free_Dynamic_Range {45} \
  CONFIG.Frequency_Resolution {1} \
  CONFIG.Noise_Shaping {Auto} \
  CONFIG.Phase_Increment {Fixed} \
  CONFIG.Phase_Offset {None} \
  CONFIG.Output_Selection {Sine_and_Cosine} \
  CONFIG.Latency_Configuration {Auto} \
  CONFIG.Latency {3} \
  CONFIG.Output_Frequency1 {10} \
] [get_ips dds_compiler_0]
generate_target all [get_files  axi_dds.srcs/sources_1/ip/dds_compiler_0/dds_compiler_0.xci]

adi_ip_files axi_dds [list \
"axi_dds.v" \
"axi_dds_tb.v" \
]

adi_ip_properties_lite axi_dds

ipx::save_core [ipx::current_core]
