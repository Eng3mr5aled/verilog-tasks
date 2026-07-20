module decimal_to_bcd (i,A);
input [9:0] i;
output [3:0] A;
assign A[0] = i[1] | i[3] | i[5] | i[7] | i[9];
    assign A[1] = i[2] | i[3] | i[6] | i[7];
    assign A[2] = i[4] | i[5] | i[6] | i[7];
    assign A[3] = i[8] | i[9];

endmodule