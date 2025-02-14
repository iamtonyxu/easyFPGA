module adder(  
    input   [3:0] a,  // First 4-bit input  
    input   [3:0] b,  // Second 4-bit input  
    input         cin, // Carry-in  
    output  [3:0] s,  // 4-bit sum  
    output        cout  // Carry-out  
);  

assign {cout, s} = a + b + cin;

endmodule