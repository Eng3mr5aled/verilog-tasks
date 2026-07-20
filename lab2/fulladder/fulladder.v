
// AND Gate
module andGate (a, b, c);
    input a, b;         // Changed 'inout' to 'input'
    output c;
    
    assign c = a & b;
endmodule

// NOT Gate
module notGate (h, g);
    input h;
    output g;
    
    assign g = ~h;
endmodule

// OR Gate
module orGate (j, n, m);
    input j, n;         // Changed 'inout' to 'input'
    output m;
    
    assign m = j | n;
endmodule           // Removed trailing semicolon
//xor Gate
module xorGate (k,l,v);
input k,l;
output v;
assign v=(k&~l)|(l&~k);
endmodule
//full adder
module fulladder (A,B,Cin,S,Cout);
input A,B,Cin;
output S,Cout;
wire out_G1,out_G3,out_G4;
xorGate G1 (A,B,out_G1);
xorGate G2 (out_G1,Cin,S);
andGate G3 (Cin,out_G1,out_G3);
andGate G4 (B,A,out_G4);
orGate G5 (out_G3,out_G4,Cout);
endmodule  
