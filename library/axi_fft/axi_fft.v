`timescale 1ns/100ps

module axi_fft (
    // Clock
    input                   aclk,

    // Configuration Interface
    input       [15:0]     s_axis_config_tdata,
    input                  s_axis_config_tvalid,
    output                 s_axis_config_tready,

    // Input Data Interface
    input       [31:0]     s_axis_data_tdata,
    input                  s_axis_data_tvalid,
    output                 s_axis_data_tready,
    input                  s_axis_data_tlast,

    // Output Data Interface
    output      [31:0]     m_axis_data_tdata,
    output      [15:0]     m_axis_data_tuser,
    output                 m_axis_data_tvalid,
    input                  m_axis_data_tready,
    output                 m_axis_data_tlast,

    // Event Signals
    output                 event_frame_started,
    output                 event_tlast_unexpected,
    output                 event_tlast_missing,
    output                 event_status_channel_halt,
    output                 event_data_in_channel_halt,
    output                 event_data_out_channel_halt
);

    // Instantiate XFFT IP with direct port mapping
    xfft_0 xfft_inst (
        .aclk(aclk),
        
        // Configuration interface
        .s_axis_config_tdata(s_axis_config_tdata),
        .s_axis_config_tvalid(s_axis_config_tvalid),
        .s_axis_config_tready(s_axis_config_tready),
        
        // Input data interface
        .s_axis_data_tdata(s_axis_data_tdata),
        .s_axis_data_tvalid(s_axis_data_tvalid),
        .s_axis_data_tready(s_axis_data_tready),
        .s_axis_data_tlast(s_axis_data_tlast),
        
        // Output data interface
        .m_axis_data_tdata(m_axis_data_tdata),
        .m_axis_data_tuser(m_axis_data_tuser),
        .m_axis_data_tvalid(m_axis_data_tvalid),
        .m_axis_data_tready(m_axis_data_tready),
        .m_axis_data_tlast(m_axis_data_tlast),
        
        // Event signals
        .event_frame_started(event_frame_started),
        .event_tlast_unexpected(event_tlast_unexpected),
        .event_tlast_missing(event_tlast_missing),
        .event_status_channel_halt(event_status_channel_halt),
        .event_data_in_channel_halt(event_data_in_channel_halt),
        .event_data_out_channel_halt(event_data_out_channel_halt)
    );

endmodule