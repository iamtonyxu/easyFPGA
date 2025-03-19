`timescale 1ns/100ps

module util_fir_int_tb;

    // Parameters
    parameter CLK_PERIOD = 10; // 100 MHz
    parameter INT_RATE = 8;   // Interpolation rate
    parameter SAMPLES = 120; // Number of samples, same as in waveform.txt

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

    // waveform file
    integer file, status, i;
    integer index;
    reg [31:0] ifir_in[0:SAMPLES-1];
    reg [31:0] ifir_out[0:SAMPLES*INT_RATE-1];

    // save channel_0 and channel_1 to ifir_out while m_axis_data_tvalid lasts high
    integer file1, jj = 0;
    initial begin
        // Initialize ifir_out
        for (i = 0; i < SAMPLES*INT_RATE; i = i + 1) begin
            ifir_out[i] = 0;
        end

        // delay INT_RATE*(INT_RATE+1) clock periods after m_axis_data_tvalid goes high
        // to compensate ifir delay
        repeat(INT_RATE*(INT_RATE+1)) begin
            @(posedge aclk);
            wait (m_axis_data_tvalid == 1);
        end

        // save channel_0 and channel_1 to ifir_out
        jj = 0;
        repeat(SAMPLES*INT_RATE) begin
            @(posedge aclk);
            if (m_axis_data_tvalid == 1) begin
                ifir_out[jj] = {channel_1, channel_0};
                jj = jj + 1;
            end
        end

        // write ifir_out to file
        file1 = $fopen("../../../../ifir_out_vivado.txt", "w");
        if (file1 == 0) begin
            $display("Error: Could not open file");
            $finish;
        end
        for (jj = 0; jj < SAMPLES*INT_RATE; jj = jj + 1) begin
            $fwrite(file1, "%h\n", ifir_out[jj]);
        end
        $fclose(file1);
        $display("ifir_out.txt file created");
        $finish;
    end

    // Read waveform file
    initial begin
        file = $fopen("../../../../waveform.txt", "r");
        if (file == 0) begin
            $display("Error: Could not open waveform file");
            $finish;
        end

        for (i = 0; i < SAMPLES; i = i + 1) begin
            status = $fscanf(file, "%h", ifir_in[i]);
            if(status != 1) begin
                $display("Error: Failed to read data at line %0d", i + 1);
                $finish;
            end
        end
        $fclose(file);
    end

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
        // Initialize signals
        s_axis_data_tvalid = 0;
        s_axis_data_tdata = 0;
        interpolate = 0;
        dac_read = 0;

        // Wait 100ns for global reset
        #100;

        // Test Case 1: send test data test with interpolate on
        $display("Test Case: send test data test");
        interpolate = 1;
        dac_read = 0;
        
        index = 0;
        repeat(SAMPLES*2) begin
            @(negedge s_axis_data_tready);
            s_axis_data_tvalid = 1;
            s_axis_data_tdata = ifir_in[index];
            index = index + 1;
            if (index == SAMPLES) begin
                index = 0;
            end
        end

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

    // Timeout watchdog
    initial begin
        #100000;  // 100us timeout
        $display("Simulation timeout!");
        $finish;
    end

endmodule