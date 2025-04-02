`timescale 1ns/100ps

module axi_dds_tb;

    // Parameters
    parameter CLK_PERIOD = 10;  // 100MHz clock
    
    // Signals
    reg         aclk;
    wire        m_axis_data_tvalid;
    wire [15:0] m_axis_data_tdata;
    wire        m_axis_phase_tvalid;
    wire signed[31:0] m_axis_phase_tdata;

    // Clock generation
    initial begin
        aclk = 0;
        forever #(CLK_PERIOD/2) aclk = ~aclk;
    end

    // DUT instantiation
    axi_dds dut (
        .aclk(aclk),
        .m_axis_data_tvalid(m_axis_data_tvalid),
        .m_axis_data_tdata(m_axis_data_tdata),
        .m_axis_phase_tvalid(m_axis_phase_tvalid),
        .m_axis_phase_tdata(m_axis_phase_tdata)
    );

    // Test stimulus
    initial begin
        // Initialize waveform dumping
        //$dumpfile("axi_dds_tb.vcd");
        //$dumpvars(0, axi_dds_tb);

        // Wait for 100 clock cycles to observe DDS output
        #(CLK_PERIOD * 100);

        // Display test completion
        $display("Simulation completed successfully");
        $finish;
    end

/*
    // Monitor DDS outputs
    always @(posedge aclk) begin
        if (m_axis_data_tvalid) begin
            $display("Time=%0t: DDS Data = %h (%d)", 
                    $time, m_axis_data_tdata, $signed(m_axis_data_tdata));
        end
    end

    // Monitor phase outputs
    always @(posedge aclk) begin
        if (m_axis_phase_tvalid) begin
            $display("Time=%0t: Phase = %h (%d)", 
                    $time, m_axis_phase_tdata, m_axis_phase_tdata);
        end
    end
*/
    // Calculate and display frequency
    real prev_phase = 0;
    real phase_diff;
    real freq;
    real curr_phase;
    
    always @(posedge aclk) begin
        if (m_axis_phase_tvalid) begin
            // Convert phase to radians
            curr_phase = (m_axis_phase_tdata * 2.0 * 3.14159) / (32'h07FFFFFF);
            
            // Calculate phase difference
            phase_diff = curr_phase - prev_phase;
            if (phase_diff < 0) phase_diff = phase_diff + 2.0 * 3.14159;
            
            // Calculate frequency
            freq = phase_diff / (CLK_PERIOD * 1e-9) / (2.0 * 3.14159);
            
            if ($time > CLK_PERIOD) begin  // Skip first calculation
                $display("Time=%0t: Frequency = %.2f Hz", $time, freq);
            end
            
            prev_phase = curr_phase;
        end
    end

    // Timeout watchdog
    initial begin
        #10000;  // 10us timeout
        $display("Simulation timeout!");
        $finish;
    end

endmodule