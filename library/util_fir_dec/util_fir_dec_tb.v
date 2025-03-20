`timescale 1ns/100ps

module tb_util_fir_dec;

    // Parameters
    parameter CLK_PERIOD = 10; // 100 MHz
    parameter DEC_FACTOR = 8;  // Decimation factor
    parameter SAMPLES = DEC_FACTOR*120; // Number of samples, same as in waveform.txt

    // Signals
    reg         aclk;
    reg         s_axis_data_tvalid;
    wire        s_axis_data_tready;
    reg  [15:0] channel_0;
    reg  [15:0] channel_1;
    reg         decimate;
    wire        m_axis_data_tvalid;
    wire [31:0] m_axis_data_tdata;

    // waveform file
    integer file, status, i;
    integer index;
    reg [31:0] ifir_in[0:SAMPLES-1];
    reg [31:0] decfir_out[0:SAMPLES/DEC_FACTOR-1];

    // save channel_0 and channel_1 to decfir_out while m_axis_data_tvalid lasts high
    integer file1, jj = 0;
    initial begin
        // Initialize decfir_out
        for (i = 0; i < SAMPLES/DEC_FACTOR; i = i + 1) begin
            decfir_out[i] = 0;
        end

        // delay FIR_TAPS-1 clock periods after m_axis_data_tvalid goes high
        // to compensate decfir delay
        repeat(DEC_FACTOR+5) begin
            wait (m_axis_data_tvalid == 1);
            @(posedge aclk);
        end

        // save channel_0 and channel_1 to decfir_out
        jj = 0;
        repeat(SAMPLES) begin
            @(posedge aclk);
            if (m_axis_data_tvalid == 1) begin
                decfir_out[jj] = m_axis_data_tdata;
                jj = jj + 1;
                if (jj == SAMPLES/DEC_FACTOR) begin
                    jj = 0;
                end
            end
        end

        // write decfir_out to file
        file1 = $fopen("../../../../decfir_out_vivado.txt", "w");
        if (file1 == 0) begin
            $display("Error: Could not open file");
            $finish;
        end
        for (jj = 0; jj < SAMPLES/DEC_FACTOR; jj = jj + 1) begin
            $fwrite(file1, "%h\n", decfir_out[jj]);
        end
        $display("Output data written to decfir_out_vivado.txt");
        $fclose(file1);
        $finish;
    end

    // Read waveform file
    initial begin
        // Open waveform file
        file = $fopen("../../../../waveform.txt", "r");
        if (file == 0) begin
            $display("Error: Could not open file");
            $finish;
        end

        // Read waveform file
        for (i = 0; i < SAMPLES; i = i + 1) begin
            status = $fscanf(file, "%h\n", ifir_in[i]);
            if (status == 0) begin
                $display("Error: End of file reached");
                $finish;
            end
        end

        // Close waveform file
        $fclose(file);
    end

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
        // Initialize signals
        s_axis_data_tvalid = 0;
        channel_0 = 0;
        channel_1 = 0;
        decimate = 0;

        // Wait 100ns for global reset
        #100;

        // Test Case 1: send test data with decimation
        $display("Test Case 1: send test data with decimation");
        decimate = 1;

        index = 0;
        wait (s_axis_data_tready == 1);
        repeat(SAMPLES*2) begin
            s_axis_data_tvalid = 1;
            channel_0 = ifir_in[index][15:0];
            channel_1 = ifir_in[index][31:16];
            index = index + 1;
            if (index == SAMPLES) begin
                index = 0;
            end
            @(posedge aclk);
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

    // Timeout watchdog
    initial begin
        #100000;  // 100us timeout
        $display("Simulation timeout!");
        $finish;
    end

endmodule