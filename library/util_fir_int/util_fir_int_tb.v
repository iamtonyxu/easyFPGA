`timescale 1ns/100ps

module util_fir_int_tb;

    // Parameters
    parameter CLK_PERIOD = 16; // 61.44MHz clock (based on util_fir_int_ip_1.tcl)

    // Signals
    reg         aclk;
    reg         s_axis_data_tvalid;
    wire        s_axis_data_tready;
    reg  [31:0] s_axis_data_tdata;
    wire [15:0] channel_0;
    wire [15:0] channel_1;
    wire        m_axis_data_tvalid;
    reg         interpolate;
    reg         dac_read;

    // Clock generation
    initial begin
        aclk = 0;
        forever #(CLK_PERIOD/2) aclk = ~aclk;
    end

    // DUT instantiation
    util_fir_int dut (
        .aclk(aclk),
        .s_axis_data_tvalid(s_axis_data_tvalid),
        .s_axis_data_tready(s_axis_data_tready),
        .s_axis_data_tdata(s_axis_data_tdata),
        .channel_0(channel_0),
        .channel_1(channel_1),
        .m_axis_data_tvalid(m_axis_data_tvalid),
        .interpolate(interpolate),
        .dac_read(dac_read)
    );

    // Test stimulus
    initial begin
        // Initialize waveform dumping
        $dumpfile("tb_util_fir_int.vcd");
        $dumpvars(0, util_fir_int_tb);

        // Initialize signals
        s_axis_data_tvalid = 0;
        s_axis_data_tdata = 0;
        interpolate = 0;
        dac_read = 0;

        // Wait 100ns for global reset
        #100;

        // Test Case 1: Direct path (no interpolation)
        $display("Test Case 1: Direct path testing");
        interpolate = 0;
        dac_read = 1;
        
        // Send test pattern
        repeat(5) begin
            @(posedge aclk);
            s_axis_data_tvalid = 1;
            s_axis_data_tdata = {16'h4000, 16'h2000}; // Test values for both channels
            @(posedge aclk);
            s_axis_data_tvalid = 0;
            #(CLK_PERIOD * 2);
        end
        
        #(CLK_PERIOD * 10);

        // Test Case 2: Interpolation path
        $display("Test Case 2: Interpolation path testing");
        interpolate = 1;
        dac_read = 0;

        // Send test pattern with interpolation
        repeat(5) begin
            @(posedge aclk);
            s_axis_data_tvalid = 1;
            s_axis_data_tdata = {16'h7FFF, 16'h3FFF}; // Maximum and half scale
            @(posedge aclk);
            s_axis_data_tvalid = 0;
            #(CLK_PERIOD * 8); // Wait for interpolated outputs
        end

        #(CLK_PERIOD * 20);

        // Test Case 3: Dynamic switching
        $display("Test Case 3: Dynamic switching test");
        repeat(3) begin
            interpolate = ~interpolate;
            dac_read = ~dac_read;
            
            repeat(3) begin
                @(posedge aclk);
                s_axis_data_tvalid = 1;
                s_axis_data_tdata = {16'h1111, 16'h2222};
                @(posedge aclk);
                s_axis_data_tvalid = 0;
                #(CLK_PERIOD * 4);
            end
            
            #(CLK_PERIOD * 10);
        end

        // Test Case 4: Back-to-back data
        $display("Test Case 4: Back-to-back data test");
        interpolate = 1;
        dac_read = 0;
        
        repeat(10) begin
            @(posedge aclk);
            s_axis_data_tvalid = 1;
            s_axis_data_tdata = {$random, $random}; // Random test data
        end
        @(posedge aclk);
        s_axis_data_tvalid = 0;

        // Wait for processing to complete
        #(CLK_PERIOD * 100);

        // End simulation
        $display("Simulation completed successfully");
        $finish;
    end

    // Monitor outputs
    always @(posedge aclk) begin
        if (m_axis_data_tvalid) begin
            $display("Time=%0t: channel_0=%h, channel_1=%h", 
                    $time, channel_0, channel_1);
        end
    end

    // Monitor ready signal
    always @(s_axis_data_tready) begin
        $display("Time=%0t: s_axis_data_tready changed to %b", 
                $time, s_axis_data_tready);
    end

    // Timeout watchdog
    initial begin
        #100000;  // 100us timeout
        $display("Simulation timeout!");
        $finish;
    end

endmodule