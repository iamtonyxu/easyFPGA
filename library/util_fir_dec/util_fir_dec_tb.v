`timescale 1ns/100ps

module tb_util_fir_dec;

    // Parameters
    parameter CLK_PERIOD = 16;    // 61.44MHz clock
    parameter DEC_FACTOR = 8;     // Decimation factor
    
    // Signals
    reg         aclk;
    reg         s_axis_data_tvalid;
    wire        s_axis_data_tready;
    reg  [15:0] channel_0;
    reg  [15:0] channel_1;
    reg         decimate;
    wire        m_axis_data_tvalid;
    wire [31:0] m_axis_data_tdata;

    // Clock generation
    initial begin
        aclk = 0;
        forever #(CLK_PERIOD/2) aclk = ~aclk;
    end

    // DUT instantiation
    util_fir_dec dut (
        .aclk(aclk),
        .s_axis_data_tvalid(s_axis_data_tvalid),
        .s_axis_data_tready(s_axis_data_tready),
        .channel_0(channel_0),
        .channel_1(channel_1),
        .decimate(decimate),
        .m_axis_data_tvalid(m_axis_data_tvalid),
        .m_axis_data_tdata(m_axis_data_tdata)
    );

    // Test stimulus
    initial begin
        // Initialize waveform dumping
        $dumpfile("tb_util_fir_dec.vcd");
        $dumpvars(0, tb_util_fir_dec);

        // Initialize signals
        s_axis_data_tvalid = 0;
        channel_0 = 0;
        channel_1 = 0;
        decimate = 0;

        // Wait 100ns for global reset
        #100;

        // Test Case 1: Direct path (no decimation)
        $display("Test Case 1: Direct path testing");
        decimate = 0;
        
        repeat(10) begin
            @(posedge aclk);
            s_axis_data_tvalid = 1;
            channel_0 = 16'h2000;
            channel_1 = 16'h4000;
            #(CLK_PERIOD);
        end
        s_axis_data_tvalid = 0;
        #(CLK_PERIOD * 10);

        // Test Case 2: Decimation path
        $display("Test Case 2: Decimation path testing");
        decimate = 1;

        // Send high-frequency test pattern
        repeat(DEC_FACTOR * 4) begin
            @(posedge aclk);
            s_axis_data_tvalid = 1;
            // Generate sine wave pattern
            channel_0 = $signed($rtoi($sin(2.0 * 3.14159 * $time / 100.0) * 32767));
            channel_1 = $signed($rtoi($cos(2.0 * 3.14159 * $time / 100.0) * 32767));
            #(CLK_PERIOD);
        end
        s_axis_data_tvalid = 0;
        #(CLK_PERIOD * 20);

        // Test Case 3: Dynamic switching
        $display("Test Case 3: Dynamic switching test");
        repeat(3) begin
            decimate = ~decimate;
            
            repeat(DEC_FACTOR) begin
                @(posedge aclk);
                s_axis_data_tvalid = 1;
                channel_0 = 16'h1111;
                channel_1 = 16'h2222;
                #(CLK_PERIOD);
            end
            s_axis_data_tvalid = 0;
            #(CLK_PERIOD * 10);
        end

        // Test Case 4: Back-to-back data with decimation
        $display("Test Case 4: Back-to-back data test with decimation");
        decimate = 1;
        
        repeat(DEC_FACTOR * 2) begin
            @(posedge aclk);
            s_axis_data_tvalid = 1;
            channel_0 = $random;
            channel_1 = $random;
            #(CLK_PERIOD);
        end
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
            $display("Time=%0t: Output data = %h (CH1=%h, CH0=%h)", 
                    $time, m_axis_data_tdata, 
                    m_axis_data_tdata[31:16], m_axis_data_tdata[15:0]);
        end
    end

    // Monitor ready signal
    always @(s_axis_data_tready) begin
        $display("Time=%0t: s_axis_data_tready changed to %b", 
                $time, s_axis_data_tready);
    end

    // Monitor decimated output rate
    reg [31:0] output_count = 0;
    always @(posedge aclk) begin
        if (m_axis_data_tvalid) begin
            output_count <= output_count + 1;
            if (decimate) begin
                if (output_count % DEC_FACTOR == 0) begin
                    $display("Time=%0t: Decimated output %d", 
                            $time, output_count / DEC_FACTOR);
                end
            end
        end
    end

    // Check data path multiplexing
    always @(posedge aclk) begin
        if (m_axis_data_tvalid) begin
            if (!decimate) begin
                // In direct path, output should exactly match input
                if (m_axis_data_tdata !== {channel_1, channel_0}) begin
                    $display("Error: Direct path mismatch at time %t", $time);
                    $display("Expected: %h, Got: %h", {channel_1, channel_0}, m_axis_data_tdata);
                end
            end
        end
    end

    // Timeout watchdog
    initial begin
        #100000;  // 100us timeout
        $display("Simulation timeout!");
        $finish;
    end

endmodule