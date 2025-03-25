`timescale 1ns/100ps

module axi_adc_decimate_tb;

    // Testbench signals
    reg adc_clk;
    reg adc_rst;
    reg [15:0] adc_data_a;
    reg [15:0] adc_data_b;
    reg adc_valid_a;
    reg adc_valid_b;

    wire [15:0] adc_dec_data_a;
    wire [15:0] adc_dec_data_b;
    wire adc_dec_valid_a;
    wire adc_dec_valid_b;
    wire [2:0] adc_data_rate;
    wire adc_oversampling_en;

    reg s_axi_aclk;
    reg s_axi_aresetn;
    reg s_axi_awvalid;
    reg [6:0] s_axi_awaddr;
    reg [2:0] s_axi_awprot;
    wire s_axi_awready;
    reg s_axi_wvalid;
    reg [31:0] s_axi_wdata;
    reg [3:0] s_axi_wstrb;
    wire s_axi_wready;
    wire s_axi_bvalid;
    wire [1:0] s_axi_bresp;
    reg s_axi_bready;
    reg s_axi_arvalid;
    reg [6:0] s_axi_araddr;
    reg [2:0] s_axi_arprot;
    wire s_axi_arready;
    wire s_axi_rvalid;
    wire [31:0] s_axi_rdata;
    wire [1:0] s_axi_rresp;
    reg s_axi_rready;

    // Parameters: Clk Periods, Samples, Addresses
    parameter ADC_CLK_PERIOD = 10;
    parameter AXI_CLK_PERIOD = 5;
    parameter SAMPLES = 1000;
    parameter DEC_RATIO = 10;

    // Internal registers addresses
    parameter ADDR_VERSION = 7'h00;
    parameter ADDR_SCRATCH = 7'h04;
    parameter ADDR_DEC_RATIO_ARB = 7'h40;
    parameter ADDR_DEC_RATIO_FILT = 7'h44;
    parameter ADDR_CONFIG = 7'h48;
    parameter ADDR_CORR_COEF_A = 7'h4C;
    parameter ADDR_CORR_COEF_B = 7'h50;

    // Internal signals
    reg [31:0] wdata;
    reg [31:0] rdata;
    reg init_done = 0;
    reg sim_done = 0;

    // waveform file
    integer file, status, i, j;
    reg [31:0] decfir_in[0:SAMPLES-1];
    reg [31:0] decfir_out[0:SAMPLES/10-1];

    // Instantiate the DUT
    axi_adc_decimate #(
    .CORRECTION_DISABLE(0)
    ) uut (
        .adc_clk(adc_clk),
        .adc_rst(adc_rst),
        .adc_data_a(adc_data_a),
        .adc_data_b(adc_data_b),
        .adc_valid_a(adc_valid_a),
        .adc_valid_b(adc_valid_b),
        .adc_dec_data_a(adc_dec_data_a),
        .adc_dec_data_b(adc_dec_data_b),
        .adc_dec_valid_a(adc_dec_valid_a),
        .adc_dec_valid_b(adc_dec_valid_b),
        .adc_data_rate(adc_data_rate),
        .adc_oversampling_en(adc_oversampling_en),
        .s_axi_aclk(s_axi_aclk),
        .s_axi_aresetn(s_axi_aresetn),
        .s_axi_awvalid(s_axi_awvalid),
        .s_axi_awaddr(s_axi_awaddr),
        .s_axi_awprot(s_axi_awprot),
        .s_axi_awready(s_axi_awready),
        .s_axi_wvalid(s_axi_wvalid),
        .s_axi_wdata(s_axi_wdata),
        .s_axi_wstrb(s_axi_wstrb),
        .s_axi_wready(s_axi_wready),
        .s_axi_bvalid(s_axi_bvalid),
        .s_axi_bresp(s_axi_bresp),
        .s_axi_bready(s_axi_bready),
        .s_axi_arvalid(s_axi_arvalid),
        .s_axi_araddr(s_axi_araddr),
        .s_axi_arprot(s_axi_arprot),
        .s_axi_arready(s_axi_arready),
        .s_axi_rvalid(s_axi_rvalid),
        .s_axi_rdata(s_axi_rdata),
        .s_axi_rresp(s_axi_rresp),
        .s_axi_rready(s_axi_rready)
    );

    // Clock generation
    always #(ADC_CLK_PERIOD/2) adc_clk = ~adc_clk;
    always #(AXI_CLK_PERIOD/2) s_axi_aclk = ~s_axi_aclk;

    // AXI write function
    task axi_write(input [6:0] addr, input [31:0] data);
    begin
        @(posedge s_axi_aclk);
        s_axi_awvalid <= 1;
        s_axi_awaddr <= addr;
        s_axi_wvalid <= 1;
        s_axi_wdata <= data;
        s_axi_wstrb <= 4'b1111;
        @(posedge s_axi_aclk);
        while (!s_axi_awready || !s_axi_wready) @(posedge s_axi_aclk);
        s_axi_awvalid <= 0;
        s_axi_wvalid <= 0;
        @(posedge s_axi_aclk);
        while (!s_axi_bvalid) @(posedge s_axi_aclk);
        s_axi_bready <= 1;
        @(posedge s_axi_aclk);
        s_axi_bready <= 0;
    end
    endtask

    // AXI read function
    task axi_read(input [6:0] addr, output [31:0] data);
    begin
        @(posedge s_axi_aclk);
        s_axi_arvalid <= 1;
        s_axi_araddr <= addr;
        @(posedge s_axi_aclk);
        while (!s_axi_arready) @(posedge s_axi_aclk);
        s_axi_arvalid <= 0;
        @(posedge s_axi_aclk);
        while (!s_axi_rvalid) @(posedge s_axi_aclk);
        data <= s_axi_rdata;
        s_axi_rready <= 1;
        @(posedge s_axi_aclk);
        s_axi_rready <= 0;
    end
    endtask

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
            status = $fscanf(file, "%h\n", decfir_in[i]);
            if (status == 0) begin
                $display("Error: End of file reached");
                $finish;
            end
        end

        // Close waveform file
        $fclose(file);
    end

    // Test sequence
    initial begin
        // Initialize signals
        adc_clk = 0;
        adc_rst = 1;
        adc_data_a = 0;
        adc_data_b = 0;
        adc_valid_a = 0;
        adc_valid_b = 0;
        s_axi_aclk = 0;
        s_axi_aresetn = 0;
        s_axi_awvalid = 0;
        s_axi_wvalid = 0;
        s_axi_bready = 0;
        s_axi_arvalid = 0;
        s_axi_rready = 0;
        s_axi_awaddr = 0;
        s_axi_awprot = 0;
        s_axi_araddr = 0;
        s_axi_arprot = 0;
        init_done = 0;

        // Reset
        #(AXI_CLK_PERIOD*10);
        adc_rst = 0;
        s_axi_aresetn = 1;
        #(AXI_CLK_PERIOD*10);

        // Write to scratch register
        wdata = 32'h12345678;
        axi_write(ADDR_SCRATCH, wdata);
        $display("Write SCRATCH: 0x%08X", wdata);

        // Write to arbitrary decimation ratio register
        wdata = 32'h0;
        axi_write(ADDR_DEC_RATIO_ARB, wdata);
        $display("Write DEC_RATIO_ARB: 0x%08X", wdata);

        // Write to filtered decimation ratio register
        wdata = 32'h1;
        axi_write(ADDR_DEC_RATIO_FILT, wdata);
        $display("Write DEC_RATIO_FILT: 0x%08X", wdata);

        // Write to configuration register
        wdata = 32'h3;
        axi_write(ADDR_CONFIG, wdata);
        $display("Write CONFIG: 0x%08X", wdata);

        // Write to correction coefficient A register
        wdata = 32'h4333; //1.05
        axi_write(ADDR_CORR_COEF_A, wdata);
        $display("Write CORR_COEF_A: 0x%08X", wdata);

        // Write to correction coefficient B register
        wdata = 32'h4333; //1.05
        axi_write(ADDR_CORR_COEF_B, wdata);
        $display("Write CORR_COEF_B: 0x%08X", wdata);

        // Read from version register
        axi_read(ADDR_VERSION, rdata);
        $display("Read VERSION: 0x%08X", rdata);

        // Read from scratch register
        axi_read(ADDR_SCRATCH, rdata);
        $display("Read SCRATCH: 0x%08X", rdata);

        // Read from arbitrary decimation ratio register
        axi_read(ADDR_DEC_RATIO_ARB, rdata);
        $display("Read DEC_RATIO_ARB: 0x%08X", rdata);

        // Read from filtered decimation ratio register
        axi_read(ADDR_DEC_RATIO_FILT, rdata);
        $display("Read DEC_RATIO_FILT: 0x%08X", rdata);

        // Read from configuration register
        axi_read(ADDR_CONFIG, rdata);
        $display("Read CONFIG: 0x%08X", rdata);

        // Read from correction coefficient A register
        axi_read(ADDR_CORR_COEF_A, rdata);
        $display("Read CORR_COEF_A: 0x%08X", rdata);

        // Read from correction coefficient B register
        axi_read(ADDR_CORR_COEF_B, rdata);
        $display("Read CORR_COEF_B: 0x%08X", rdata);

        init_done = 1;
    end

// Simulate filter input
initial begin
    adc_rst = 1;
    adc_data_a = 0;
    adc_data_b = 0;
    adc_valid_a = 0;
    adc_valid_b = 0;
    #(ADC_CLK_PERIOD*10);
    adc_rst = 0;
    wait (init_done == 1);

    j = 0;
    repeat(SAMPLES*2) begin
        {adc_data_a, adc_data_b} = decfir_in[j];
        adc_valid_a = 1;
        adc_valid_b = 1;
        //@(posedge adc_clk);
        #ADC_CLK_PERIOD;
        j = j + 1;
        if (j == SAMPLES) begin
            j = 0;
        end
    end

    sim_done = 1;
    // Wait for some time
    #(ADC_CLK_PERIOD*10);

    // End simulation
    $finish;
end

// Save filter output to file
integer ii = 0;
initial begin
    ii = 0;
    // compensate for the delay
    repeat(10) begin
        wait (adc_dec_valid_a == 1);
        @(posedge adc_clk);
    end

    // save the first SAMPLES/DEC_RATIO samples to decfir_out
    repeat(SAMPLES/DEC_RATIO) begin
        wait (adc_dec_valid_a == 1);
        decfir_out[ii] = {4'h0, adc_dec_data_a[11:0], 4'h0, adc_dec_data_b[11:0]};
        ii = ii + 1;
        if (ii == SAMPLES/DEC_RATIO) begin
            ii = 0;
        end
        @(posedge adc_clk);
        #(1); // wait for 1 ns
    end

    wait (sim_done == 1);
    // Open waveform file
    file = $fopen("../../../../waveform_out.txt", "w");
    if (file == 0) begin
        $display("Error: Could not open file");
        $finish;
    end

    // Write filter output to file
    for (ii = 0; ii < SAMPLES/DEC_RATIO; ii = ii + 1) begin
        $fwrite(file, "%8X\n", decfir_out[ii]);
    end

    // Close waveform file
    $fclose(file);
end

endmodule