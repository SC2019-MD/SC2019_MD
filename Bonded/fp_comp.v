/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: fp_comp.v
//
//	Function:
//				Wrapper on top of FP_GREAT_THAN, FP_LESS_THAN, to meet the port configuration in the old design
//				Return 3 comparision results:
//					a equal to b
//					a greater than b
//					a less than b
//
// Dependency:
//				FP_GREAT_THAN.v
//				FP_LESS_THAN.v
//
// Latency:  4 cycles
//				FP_GREATER_THAN				4 cycles
//				FP_LESS_THAN					4 cycles

//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module fp_comp
#(
	parameter DATA_WIDTH = 32
)
(
	input clk,
	input [DATA_WIDTH-1:0] dataa,
	input [DATA_WIDTH-1:0] datab,
	output reg aeb,
	output agb,
	output alb
);
	
	wire aeb_wire;
	assign aeb_wire = (dataa == datab);
	reg aeb_reg0, aeb_reg1, aeb_reg2;

	// Delay the equal signal by 4 cycles to meet the other comparision results
	always@(posedge clk)
		begin
		aeb_reg0 <= aeb_wire;
		aeb_reg1 <= aeb_reg0;
		aeb_reg2 <= aeb_reg1;
		aeb <= aeb_reg2;
		end

	FP_GREAT_THAN FP_GREAT_THAN
	(
		.clk(clk),
		.areset(1'b0),
		.a(dataa),
		.b(datab),
		.q(agb)
	);
	
	FP_LESS_THAN FP_LESS_THAN
	(
		.clk(clk),
		.areset(1'b0),
		.a(dataa),
		.b(datab),
		.q(alb)
	);

endmodule
