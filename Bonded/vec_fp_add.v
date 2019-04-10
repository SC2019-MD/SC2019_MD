/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: vec_fp_add.v
//
//	Function: 
//				Perform FP addition on two vectors of size 3
//				Result is a size 3 vector in single float
//
// Data Organization:
//
//
// Dependency:
//				FP_ADD.v
//
// Testbench:
//				_tb.v
//
// Timing:
//				FP_ADD:				3 cycles			
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


module vec_fp_add
#(
	parameter DATA_WIDTH = 32
)
(
	input clk,
	input rst,
	input [3*DATA_WIDTH-1:0] a,
	input [3*DATA_WIDTH-1:0] b,
	output [3*DATA_WIDTH-1:0] r
);

	FP_ADD 
	#(
		.DATA_WIDTH(DATA_WIDTH)
	)
	FP_ADD_x
	(
		.clk(clk),
		.ena(1'b1),
		.clr(rst),
		.ax(a[1*DATA_WIDTH-1:0*DATA_WIDTH]),
		.ay(b[1*DATA_WIDTH-1:0*DATA_WIDTH]),
		.result(r[1*DATA_WIDTH-1:0*DATA_WIDTH])
	);
	
	FP_ADD 
	#(
		.DATA_WIDTH(DATA_WIDTH)
	)
	FP_ADD_y
	(
		.clk(clk),
		.ena(1'b1),
		.clr(rst),
		.ax(a[2*DATA_WIDTH-1:1*DATA_WIDTH]),
		.ay(b[2*DATA_WIDTH-1:1*DATA_WIDTH]),
		.result(r[2*DATA_WIDTH-1:1*DATA_WIDTH])
	);
	
	FP_ADD 
	#(
		.DATA_WIDTH(DATA_WIDTH)
	)
	FP_ADD_z
	(
		.clk(clk),
		.ena(1'b1),
		.clr(rst),
		.ax(a[3*DATA_WIDTH-1:2*DATA_WIDTH]),
		.ay(b[3*DATA_WIDTH-1:2*DATA_WIDTH]),
		.result(r[3*DATA_WIDTH-1:2*DATA_WIDTH])
	);

endmodule 