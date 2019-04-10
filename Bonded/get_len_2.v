/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: get_gen_2.v
//
//	Function:
//				Wrapper on top of FP_3D_HYPO_ROOT, to meet the port configuration in the old design
//				result = sqrt(in1^2 + in2^2 + in3^2)
//
// Dependency:
//				FP_3D_HYPO_ROOT.v
//
// Latency: 45 cycles

//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module get_len_2
#(
	parameter DATA_WIDTH = 32
)
(
	input clk,
	input rst,
	input [DATA_WIDTH-1:0] in1,
	input [DATA_WIDTH-1:0] in2,
	input [DATA_WIDTH-1:0] in3,
	output [DATA_WIDTH-1:0] result
);

	FP_3D_HYPO_ROOT FP_3D_HYPO_ROOT
	(
		.clk(clk),
		.areset(rst),
		.a(in1),
		.b(in2),
		.c(in3),
		.q(result)
	);

endmodule
