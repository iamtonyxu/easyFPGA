module PB_Debouncer_tb;

reg clk;
reg PB;
wire PB_state;
wire PB_down;
wire PB_up;

parameter PERIOD = 10; // 100 MHz clock
parameter HALF_PERIOD = PERIOD / 2;
parameter PB_DURATION = 2**16; // Duration of push-button press/release in clock cycles
parameter ACTIVE_LOW = 1; // Active low push-button

// Instantiate the PushButton_Debouncer module
PushButton_Debouncer #(
    .ACTIVE_LOW(ACTIVE_LOW)
)uut(
    .clk(clk),
    .PB(PB),
    .PB_state(PB_state),
    .PB_down(PB_down),
    .PB_up(PB_up)
);


// Clock generation
always #HALF_PERIOD clk = ~clk;

// Test sequence
initial begin
    // Initialize signals
    clk = 0; // Clock starts low
    PB = 1; // Push-button not pressed (active low)

    // Wait for a few clock cycles
    #(PERIOD*10);

    // Simulate push-button press
    PB = 0; // Push-button pressed
    #(PERIOD*PB_DURATION); // Hold for PB_DURATION clock cycles

    // Simulate push-button release
    PB = 1; // Push-button released
    #(PERIOD*PB_DURATION); // Hold for PB_DURATION clock cycles

    // Simulate another push-button press
    PB = 0; // Push-button pressed
    #(PERIOD*PB_DURATION); // Hold for PB_DURATION clock cycles

    // Simulate push-button release
    PB = 1; // Push-button released
    #(PERIOD*PB_DURATION); // Hold for PB_DURATION clock cycles

    // Simulate another push-button press
    PB = 0; // Push-button pressed
    #(PERIOD*(PB_DURATION-1)); // Hold for PB_DURATION clock cycles

    // Simulate push-button release
    PB = 1; // Push-button released
    #(PERIOD*PB_DURATION); // Hold for PB_DURATION clock cycles

    // Simulate another push-button press
    PB = 0; // Push-button pressed
    #(PERIOD*PB_DURATION); // Hold for PB_DURATION clock cycles

    // Simulate push-button release
    PB = 1; // Push-button released
    #(PERIOD*(PB_DURATION)); // Hold for PB_DURATION clock cycles
    #(PERIOD*PB_DURATION/2); // a few clock cycles to see the final output

    // End simulation
    $finish;
end

// Monitor output
initial begin
    $monitor("At time %t, PB = %b, PB_state = %b, PB_down = %b, PB_up = %b", $time, PB, PB_state, PB_down, PB_up);
end

endmodule