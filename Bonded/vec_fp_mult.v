/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: vec_fp_mult.v
//
//	Function: 
//				Perform FP Multiply on vector of size 3 and a single float input
//				Result is a size 3 vector in single float
//
// Data Organization:
//
//
// Dependency:
//				FP_MUL.v
//
// Testbench:
//				_tb.v
//
// Timing:
//				FP_MUL:				4 cycles			
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


module vec_fp_mult
#(
	parameter DATA_WIDTH = 32
)
(
	input clk,
	input rst,
	input [3*DATA_WIDTH-1:0] a,
	input [DATA_WIDTH-1:0] b,
	output [3*DATA_WIDTH-1:0] r
);
	
	FP_MUL FP_MUL_x
	(
		.clk(clk),
		.ena(1'b1),
		.clr(rst),
		.ay(a[1*DATA_WIDTH-1:0*DATA_WIDTH]),
		.az(b),
		.result(r[1*DATA_WIDTH-1:0*DATA_WIDTH])
	);
	
	FP_MUL FP_MUL_y
	(
		.clk(clk),
		.ena(1'b1),
		.clr(rst),
		.ay(a[2*DATA_WIDTH-1:1*DATA_WIDTH]),
		.az(b),
		.result(r[2*DATA_WIDTH-1:1*DATA_WIDTH])
	);
	
	FP_MUL FP_MUL_z
	(
		.clk(clk),
		.ena(1'b1),
		.clr(rst),
		.ay(a[3*DATA_WIDTH-1:2*DATA_WIDTH]),
		.az(b),
		.result(r[3*DATA_WIDTH-1:2*DATA_WIDTH])
	);


endmodule 