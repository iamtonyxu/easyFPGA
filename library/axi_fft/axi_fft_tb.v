`timescale 1ns/100ps

module tb_axi_fft;

    // Parameters
    parameter CLK_PERIOD = 10;  // 100MHz clock
    parameter FFT_SIZE = 1024;  // FFT size
    
    // Signals
    reg                     aclk;
    
    // Configuration Interface
    reg     [15:0]         s_axis_config_tdata;
    reg                     s_axis_config_tvalid;
    wire                    s_axis_config_tready;
    
    // Input Data Interface
    reg     [31:0]         s_axis_data_tdata;
    reg                     s_axis_data_tvalid;
    wire                    s_axis_data_tready;
    reg                     s_axis_data_tlast;
    
    // Output Data Interface
    wire    [31:0]         m_axis_data_tdata;
    wire    [15:0]         m_axis_data_tuser;
    wire                    m_axis_data_tvalid;
    reg                     m_axis_data_tready;
    wire                    m_axis_data_tlast;
    
    // Event Signals
    wire                    event_frame_started;
    wire                    event_tlast_unexpected;
    wire                    event_tlast_missing;
    wire                    event_status_channel_halt;
    wire                    event_data_in_channel_halt;
    wire                    event_data_out_channel_halt;

    reg signed [15:0]       s_axis_data_tdata_i;
    reg signed [15:0]       s_axis_data_tdata_q;

    // Clock generation
    initial begin
        aclk = 0;
        forever #(CLK_PERIOD/2) aclk = ~aclk;
    end

    // DUT instantiation
    axi_fft dut (
        .aclk(aclk),
        .s_axis_config_tdata(s_axis_config_tdata),
        .s_axis_config_tvalid(s_axis_config_tvalid),
        .s_axis_config_tready(s_axis_config_tready),
        .s_axis_data_tdata(s_axis_data_tdata),
        .s_axis_data_tvalid(s_axis_data_tvalid),
        .s_axis_data_tready(s_axis_data_tready),
        .s_axis_data_tlast(s_axis_data_tlast),
        .m_axis_data_tdata(m_axis_data_tdata),
        .m_axis_data_tuser(m_axis_data_tuser),
        .m_axis_data_tvalid(m_axis_data_tvalid),
        .m_axis_data_tready(m_axis_data_tready),
        .m_axis_data_tlast(m_axis_data_tlast),
        .event_frame_started(event_frame_started),
        .event_tlast_unexpected(event_tlast_unexpected),
        .event_tlast_missing(event_tlast_missing),
        .event_status_channel_halt(event_status_channel_halt),
        .event_data_in_channel_halt(event_data_in_channel_halt),
        .event_data_out_channel_halt(event_data_out_channel_halt)
    );

    // Test stimulus
    integer i;
    initial begin
        // Initialize waveform dumping
        //$dumpfile("tb_axi_fft.vcd");
        //$dumpvars(0, tb_axi_fft);

        // Initialize signals
        s_axis_config_tdata = 0;
        s_axis_config_tvalid = 0;
        s_axis_data_tdata = 0;
        s_axis_data_tvalid = 0;
        s_axis_data_tlast = 0;
        m_axis_data_tready = 1;

        // Wait 100ns for global reset
        #100;

        // NOTE: DON'T Configure FFT if this feature is NOT enabled
        /*
        @(posedge aclk);
        //|15|14||13|12|11|10|09|08|07|06|05|04|03|02|01|00|
        //|PAD|SCALE|FWD|PAD|CP_LEN|--PAD---|-----NFFT-----|
        s_axis_config_tdata = 16'h0; // Forward FFT, scale schedule
        s_axis_config_tvalid = 1;
        @(posedge aclk);
        while (!s_axis_config_tready) @(posedge aclk);
        s_axis_config_tvalid = 0;

        // Wait a few cycles
        repeat(10) @(posedge aclk);
        */

        // Send test data (sine wave)
        for (i = 0; i < FFT_SIZE; i = i + 1) begin
            @(posedge aclk);
            while (!s_axis_data_tready) @(posedge aclk);
            
            // Generate sine wave input
            s_axis_data_tvalid = 1;
            s_axis_data_tdata_i = $signed($rtoi($sin(2.0 * 3.14159 * i / 64.0) * 32767)); // Real
            s_axis_data_tdata_q = $signed($rtoi($cos(2.0 * 3.14159 * i / 64.0) * 32767)); // Imag
            s_axis_data_tdata = {s_axis_data_tdata_q, s_axis_data_tdata_i};
            s_axis_data_tlast = (i == FFT_SIZE-1);
        end
        
        @(posedge aclk);
        s_axis_data_tvalid = 0;
        s_axis_data_tlast = 0;

        // Wait for all data to be processed
        wait(m_axis_data_tlast);
        repeat(20) @(posedge aclk);

        // End simulation
        $display("Simulation completed successfully");
        $finish;
    end

    // Monitor FFT outputs
    real y_real;
    real y_imag;
    always @(posedge aclk) begin
        if (m_axis_data_tvalid && m_axis_data_tready) begin
            y_real = $signed(m_axis_data_tdata[15:0])/32767.0;
            y_imag = $signed(m_axis_data_tdata[31:16])/32767.0;
            $display("Time=%0t: FFT Output: Data=%.2f, XK_Index=%h", 
                    $time, y_real*y_real+y_imag*y_imag, m_axis_data_tuser);
        end
    end

    // Monitor events
    always @(posedge aclk) begin
        if (event_frame_started)
            $display("Time=%0t: Frame started", $time);
        if (event_tlast_unexpected)
            $display("Time=%0t: Unexpected TLAST", $time);
        if (event_tlast_missing)
            $display("Time=%0t: Missing TLAST", $time);
        if (event_status_channel_halt)
            $display("Time=%0t: Status channel halt", $time);
        if (event_data_in_channel_halt)
            $display("Time=%0t: Data input channel halt", $time);
        if (event_data_out_channel_halt)
            $display("Time=%0t: Data output channel halt", $time);
    end

    // Timeout watchdog
    initial begin
        #1000000; // 1ms timeout
        $display("Simulation timeout!");
        $finish;
    end

endmodule