/**************************************
**************************************/

module dot
(
input clk,
input rst,
input [95:0] a,
input [95:0] b,
output [31:0] r

);

wire [31:0] i1;
wire [31:0] j1;
wire [31:0] k1;
wire [31:0] add;
fp_mult mult1(clk, a[95:64], b[95:64], i1);

fp_mult mult2(clk, a[63:32], b[63:32], j1);

fp_mult mult3(clk, a[31:0], b[31:0], k1);


fp_add add1(clk,rst, i1, j1, add);

wire [31:0] k1_r;
syn_fifo #(32, 6) f3(clk, rst, k1, k1_r);

fp_add add2(clk,rst, add, k1_r, r);


endmodule