/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: fp_accumulation_test.v
//
//	Function: 
//				Evaluate the FP_ADD IP that finish evaluation in a single cycle 
//
//	Purpose:
//				For simulation purpose only
//
// Used by:
//				N/A
//
// Dependency:
//				FP_ACC.v
//
// Testbench:
//				fp_accumulation_test_tb.v
//
// Timing:
//				1 cycle from input to output
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module fp_accumulation_test(
	input clk,
	input rst,
	input [31:0] in0,
	input [31:0] in1,
	output [31:0] out
);

	wire [31:0] out_wire;
	assign out = out_wire;

	FP_ACC FP_ACC (
		.ax     (in0),     //   input,  width = 32,     ax.ax
		.ay     (out_wire),     //   input,  width = 32,     ay.ay
		.clk    (clk),    //   input,   width = 1,    clk.clk
		.clr    (rst),    //   input,   width = 1,    clr.clr
		.ena    (1'b1),    //   input,   width = 1,    ena.ena
		.result (out_wire)  //  output,  width = 32, result.result
	);


endmodule
