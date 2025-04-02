`timescale 1ns/100ps

module axi_dds (
    // Clock
    input                   aclk,

    // Output Interface
    output                  m_axis_data_tvalid,
    output      [15:0]     m_axis_data_tdata,
    output                  m_axis_phase_tvalid,
    output      [31:0]     m_axis_phase_tdata
);

    // Instantiate DDS compiler with direct port mapping
    dds_compiler_0 dds_inst (
        .aclk(aclk),
        .m_axis_data_tvalid(m_axis_data_tvalid),
        .m_axis_data_tdata(m_axis_data_tdata),
        .m_axis_phase_tvalid(m_axis_phase_tvalid),
        .m_axis_phase_tdata(m_axis_phase_tdata)
    );

endmodule