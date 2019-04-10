/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: fp_cos.v
//
//	Function:
//				Wrapper on top of FP_COS, to meet the port configuration in the old design
//				The FP_SIN IP core can have pure LUT version, or consume DSP cores at an alterntaive
//				In the current design, we choose to use DSP to realize this IP
//
// Dependency:
//				FP_COS.v
//
// Latency: 34 cycles

//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module fp_cos
#(
	parameter DATA_WIDTH = 32
)
(
	input clk,
	input rst,
	input [DATA_WIDTH-1:0] in1,
	output [DATA_WIDTH-1:0] result
);

	FP_COS FP_COS
	(
		.clk(clk),
		.areset(rst),
		.a(in1),
		.q(result)
	);

endmodule
