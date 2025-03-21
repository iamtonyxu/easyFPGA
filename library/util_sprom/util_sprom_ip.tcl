source ../../scripts/adi_env.tcl
source $ad_hdl_dir/library/scripts/adi_ip_xilinx.tcl

adi_ip_create util_sprom

set sprom_1024x32 [create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name sprom_1024x32]
set_property -dict [list \
  CONFIG.Coe_File {../../../../waveform.coe} \
  CONFIG.Load_Init_File {true} \
  CONFIG.Write_Depth_A {1024} \
  CONFIG.Write_Width_A {32} \
] [get_ips sprom_1024x32]

generate_target {all} [get_files util_sprom.srcs/sources_1/ip/util_sprom/util_sprom.xci]

adi_ip_files util_sprom [list \
"util_sprom.v" \
"util_sprom_tb.v" \
]

adi_ip_properties_lite util_sprom
ipx::save_core [ipx::current_core]