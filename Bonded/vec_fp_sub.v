/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: vec_fp_add.v
//
//	Function: 
//				Perform FP subtraction on two vectors of size 3
//				Result is a size 3 vector in single float
//
// Data Organization:
//
//
// Dependency:
//				FP_SUB.v
//
// Testbench:
//				_tb.v
//
// Timing:
//				FP_SUB:				3 cycles			
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module vec_fp_sub
#(
	parameter DATA_WIDTH = 32
)
(
	input clk,
	input rst,
	input [95:0] a,
	input [95:0] b,
	output [95:0] r
	
);

	FP_SUB FP_SUB_x
	(
		.clk(clk),
		.ena(1'b1),
		.clr(rst),
		.ax(a[1*DATA_WIDTH-1:0*DATA_WIDTH]),
		.ay(b[1*DATA_WIDTH-1:0*DATA_WIDTH]),
		.result(r[1*DATA_WIDTH-1:0*DATA_WIDTH])
	);
	
	FP_SUB FP_SUB_y
	(
		.clk(clk),
		.ena(1'b1),
		.clr(rst),
		.ax(a[2*DATA_WIDTH-1:1*DATA_WIDTH]),
		.ay(b[2*DATA_WIDTH-1:1*DATA_WIDTH]),
		.result(r[2*DATA_WIDTH-1:1*DATA_WIDTH])
	);
	
	FP_SUB FP_SUB_z
	(
		.clk(clk),
		.ena(1'b1),
		.clr(rst),
		.ax(a[3*DATA_WIDTH-1:2*DATA_WIDTH]),
		.ay(b[3*DATA_WIDTH-1:2*DATA_WIDTH]),
		.result(r[3*DATA_WIDTH-1:2*DATA_WIDTH])
	);



endmodule 