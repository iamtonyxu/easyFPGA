module rfir_tb;

reg clk;
reg rst;
reg signed [15:0] x;
wire signed [15:0] y;

// Instantiate the FIR filter module
rfir uut (
    .clk(clk),
    .rst(rst),
    .x(x),
    .y(y)
);

// Clock generation
always #10 clk = ~clk;

// Reset signal
initial begin
    clk = 0;
    rst = 1;
    #20 rst = 0;
end

// Test input signal
initial begin
    x = 16'd0;

    // Wait for reset
    #30;

    // Apply test input samples
    x = 16'd1;
    #20;
    x = 16'd2;
    #20;
    x = 16'd3;
    #20;
    x = 16'd4;
    #20;
    x = 16'd5;
    #20;
    x = 16'd6;
    #20;
    x = 16'd7;
    #20;
    x = 16'd8;
    #20;
    x = 16'd9;
    #20;
    x = 16'd10;
    #20;

    // End simulation
    $finish;
end

// Monitor output
initial begin
    $monitor("At time %t, x = %d, y = %d", $time, x, y);
end

endmodule