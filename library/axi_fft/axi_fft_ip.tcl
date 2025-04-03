source ../../scripts/adi_env.tcl
source $ad_hdl_dir/library/scripts/adi_ip_xilinx.tcl

adi_ip_create axi_fft

set axi_fft [create_ip -name xfft -vendor xilinx.com -library ip -version 9.1 -module_name xfft_0]
set_property -dict [list \
  CONFIG.channels {1} \
  CONFIG.complex_mult_type {use_mults_performance} \
  CONFIG.data_format {fixed_point} \
  CONFIG.implementation_options {automatically_select} \
  CONFIG.input_width {16} \
  CONFIG.number_of_stages_using_block_ram_for_data_and_phase_factors {0} \
  CONFIG.output_ordering {natural_order} \
  CONFIG.ovflo {false} \
  CONFIG.phase_factor_width {24} \
  CONFIG.run_time_configurable_transform_length {false} \
  CONFIG.target_data_throughput {50} \
  CONFIG.xk_index {true} \
] [get_ips xfft_0]
generate_target all [get_files  axi_fft.srcs/sources_1/ip/xfft_0/xfft_0.xci]

adi_ip_files axi_fft [list \
"axi_fft.v" \
"axi_fft_tb.v" \
]

adi_ip_properties_lite axi_fft

ipx::save_core [ipx::current_core]
