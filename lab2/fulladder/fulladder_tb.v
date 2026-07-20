module Fulladder_tb;
  reg A, B, Cin;
  wire S, Cout;
  
  // Instantiate the full adder
 fulladder Fulladder_dut (A, B, Cin, S, Cout);
  
  initial begin
    
    // Initialize inputs (removed S and Cout assignments)
    A = 0; B = 0; Cin = 0;
    
    // Stimulus covering the full truth table
    #10 Cin = 0; A = 0; B = 1;
    #10 Cin = 0; A = 1; B = 0;
    #10 Cin = 0; A = 1; B = 1;
    #10 Cin = 1; A = 0; B = 0;
    #10 Cin = 1; A = 0; B = 1;
    #10 Cin = 1; A = 1; B = 0;
    #10 Cin = 1; A = 1; B = 1;
    
   
  end
endmodule