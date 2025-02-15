module uart_tb;

reg clk;
reg rst;
reg tx_en;
reg [7:0] tx_data;
reg rx;
wire tx;
wire [7:0] rx_data;
wire tx_done;
wire rx_done;

// Instantiate the UART module
uart uut (
    .clk(clk),
    .rst(rst),
    .tx_en(tx_en),
    .tx_data(tx_data),
    .rx(rx),
    .tx(tx),
    .rx_data(rx_data),
    .tx_done(tx_done),
    .rx_done(rx_done)
);

// Clock generation
always #10 clk = ~clk;

// Reset signal
initial begin
    clk = 0;
    rst = 1;
    #20 rst = 0;
end

// Test data transmission and reception
initial begin
    tx_en = 0;
    tx_data = 8'b00000000;
    rx = 1; // Initial high state

    // Wait for reset
    #30;

    // Test transmission of 'A' (ASCII 0x41)
    tx_data = 8'b01000001;
    tx_en = 1;
    #20;
    tx_en = 0;

    // Wait for transmission to complete
    wait(tx_done);
    #20;

    // Simulate reception of 'A' (ASCII 0x41)
    rx = 0; // Start bit
    #104160; // Wait for one baud period (1/9600 seconds) at 50 MHz clock
    rx = 1; // Bit 0
    #104160;
    rx = 0; // Bit 1
    #104160;
    rx = 0; // Bit 2
    #104160;
    rx = 0; // Bit 3
    #104160;
    rx = 0; // Bit 4
    #104160;
    rx = 0; // Bit 5
    #104160;
    rx = 1; // Bit 6
    #104160;
    rx = 0; // Bit 7
    #104160;
    rx = 1; // Stop bit

    // Wait for reception to complete
    wait(rx_done);
    #20;

    // Check received data
    if (rx_data == 8'b01000001) begin
        $display("Test passed: Received data matches transmitted data.");
    end else begin
        $display("Test failed: Received data does not match transmitted data.");
    end

    $stop;
end

endmodule