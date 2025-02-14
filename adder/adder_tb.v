`timescale 1ns / 1ps  

module adder_tb;  

    // Inputs  
    reg [3:0] a;  
    reg [3:0] b;  
    reg cin;  

    // Outputs  
    wire [3:0] s;  
    wire cout;  

    // Instantiate the adder module  
    adder uut (  
        .a(a),  
        .b(b),  
        .cin(cin),  
        .s(s),  
        .cout(cout)  
    );  

    // Test cases  
    initial begin  
        // Initialize all inputs  
        a = 4'b0000;  
        b = 4'b0000;  
        cin = 1'b0;  
        
        // Test case 1: Adding zeros  
        $display("Test Case 1: Adding zeros");  
        #10;  
        
        // Test case 2: Adding with carry  
        a = 4'b1111;  
        b = 4'b0001;  
        cin = 1'b0;  
        $display("Test Case 2: Adding with carry");  
        #10;  
        
        // Test case 3: Adding different values  
        a = 4'b1010;  
        b = 4'b1100;  
        cin = 1'b0;  
        $display("Test Case 3: Adding different values");  
        #10;  
        
        // Test case 4: Adding maximum values  
        a = 4'b1111;  
        b = 4'b1111;  
        cin = 1'b1;  
        $display("Test Case 4: Adding maximum values");  
        #10;  
        
        // Test case 5: Single bit addition with carry  
        a = 4'b0001;  
        b = 4'b0001;  
        cin = 1'b0;  
        $display("Test Case 5: Single bit addition");  
        #10;  
        
        // Test case 6: All bits set  
        a = 4'b1111;  
        b = 4'b1111;  
        cin = 1'b0;  
        $display("Test Case 6: All bits set");  
        #10;  
    end  

endmodule