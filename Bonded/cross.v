/**************************************
**************************************/

module cross
(
input clk,
input rst,
input [95:0] a,
input [95:0] b,
output [95:0] r
);

wire [31:0] i1,i2;
wire [31:0] j1,j2;
wire [31:0] k1,k2;

fp_mult mult1(clk, a[63:32], b[31:0], i1);
fp_mult mult2(clk, a[31:0], b[63:32], i2);

fp_mult mult3(clk, a[31:0], b[95:64], j1);
fp_mult mult4(clk, a[95:64], b[31:0], j2);

fp_mult mult5(clk, a[63:32], b[95:64], k1);
fp_mult mult6(clk, a[95:64], b[63:32], k2);

FP_SUB sub1(clk,1'b1,rst,i1, i2, r[95:64]);
FP_SUB sub2(clk,1'b1,rst,j1, j2, r[63:32]);
FP_SUB sub3(clk,1'b1,rst,k1, k2, r[31:0]);

endmodule