`timescale 1ns/100ps

module util_sprom_tb;

    // Testbench signals
    reg aclk;                     // Clock signal
    reg rst_n;                    // Reset signal (active low)
    wire s_axis_data_tvalid;      // Output valid signal
    reg s_axis_data_tready;       // Input ready signal
    wire [31:0] s_axis_data_tdata; // Output data signal

    parameter CLK_PERIOD = 10; // 10ns clock period (100MHz)
    parameter ROM_DEPTH = 1024; // 1024x32 ROM

    // Instantiate the DUT (Device Under Test)
    util_sprom dut (
        .aclk(aclk),
        .rst_n(rst_n),
        .s_axis_data_tvalid(s_axis_data_tvalid),
        .s_axis_data_tready(s_axis_data_tready),
        .s_axis_data_tdata(s_axis_data_tdata)
    );

    // Clock generation
    initial aclk = 0;
    always #(CLK_PERIOD/2) aclk = ~aclk; // 10ns clock period (100MHz)

    // Testbench logic
    initial begin
        // Initialize signals
        rst_n = 0;
        s_axis_data_tready = 0;

        // Apply reset
        #20; // Wait for 20ns
        rst_n = 1; // Release reset

        // Test case 1: Simulate data transfer
        #10;
        s_axis_data_tready = 1; // Indicate ready to receive data

        // Wait for a few clock cycles to observe behavior
        repeat(ROM_DEPTH) @(posedge aclk);

        // Test case 2: Stop data transfer
        s_axis_data_tready = 0; // Indicate not ready
        repeat(50) @(posedge aclk);

        // Test case 3: Resume data transfer
        s_axis_data_tready = 1;
        repeat(ROM_DEPTH/2) @(posedge aclk);

        // End simulation
        $stop;
    end

    // Monitor outputs
    initial begin
        $monitor("Time: %0t | Reset: %b | Ready: %b | Valid: %b | Data: %h", 
                 $time, rst_n, s_axis_data_tready, s_axis_data_tvalid, s_axis_data_tdata);
    end

endmodule