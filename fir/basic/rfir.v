module rfir (
    input clk,
    input rst,
    input signed [15:0] x, // Input signal
    output reg signed [15:0] y // Output signal
);

parameter N = 4; // Number of taps
parameter signed [15:0] h0 = 16'd1;
parameter signed [15:0] h1 = 16'd2;
parameter signed [15:0] h2 = 16'd3;
parameter signed [15:0] h3 = 16'd4;

reg signed [15:0] x_reg0, x_reg1, x_reg2, x_reg3;

// Shift register for input samples
always @(posedge clk or posedge rst) begin
    if (rst) begin
        x_reg0 <= 16'd0;
        x_reg1 <= 16'd0;
        x_reg2 <= 16'd0;
        x_reg3 <= 16'd0;
    end else begin
        x_reg0 <= x;
        x_reg1 <= x_reg0;
        x_reg2 <= x_reg1;
        x_reg3 <= x_reg2;
    end
end

// FIR filter computation
always @(posedge clk or posedge rst) begin
    if (rst) begin
        y <= 16'd0;
    end else begin
        y <= x_reg0 * h0 + x_reg1 * h1 + x_reg2 * h2 + x_reg3 * h3;
    end
end

endmodule