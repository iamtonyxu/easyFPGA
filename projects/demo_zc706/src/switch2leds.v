module switch2leds (
    input clk,            // Clock input
    input [3:0] switches, // 4 switch buttons
    output reg [3:0] leds // 4 LEDs
);

always @(posedge clk) begin
    leds <= switches;
end

endmodule