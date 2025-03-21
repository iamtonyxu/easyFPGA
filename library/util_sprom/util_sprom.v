`timescale 1ns/100ps

module util_sprom(
    input               aclk,
    input               rst_n,
    output              s_axis_data_tvalid,
    input               s_axis_data_tready,
    output      [31:0]  s_axis_data_tdata
);

reg     [9:0]   addr;
wire    [31:0]  data;

sprom_1024x32 sprom (
    .clka(aclk),
    .addra(addr),
    .dina(),
    .douta(data),
    .ena(1),
    .wea(0)
);

assign s_axis_data_tvalid = 1;
assign s_axis_data_tdata = data;

// addr increment when s_axis_data_tready is high
always @(posedge aclk)
    if(~rst_n)
        addr <= 0;
    else if(s_axis_data_tready)
        addr <= addr + 1;

endmodule

