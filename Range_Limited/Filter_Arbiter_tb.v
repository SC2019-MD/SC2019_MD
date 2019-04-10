/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: Filter_Arbiter_tb.v
//
//	Function: Testbench for Filter_Arbiter.v
//
// Dependency:
// 			Filter_Arbiter.v
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ns

module Filter_Arbiter_tb;
	
	parameter NUM_FILTER = 4;
	parameter ARBITER_MSB = 8;					// 2^(NUM_FILTER-1)

	reg clk, rst;
	reg [NUM_FILTER-1:0] Filter_Available_Flag;
	wire [NUM_FILTER-1:0] Arbitration_Result;
	
	reg [8:0] counter;
	
	always #1 clk <= ~clk;
	
	always@(posedge clk)
		if(rst)
			begin
			Filter_Available_Flag <= 4'b0000;
			counter <= 0;
			end
		else if(counter < 10)
			begin
			Filter_Available_Flag <= 4'b1111;
			counter <= counter + 1'b1;
			end
		else if(counter < 30)
			begin
			Filter_Available_Flag <= Filter_Available_Flag + 1'b1; 
			counter <= counter + 1'b1;
			end
		else
			begin
			Filter_Available_Flag <= 4'b1000;
			counter <= counter + 1'b1;
			end
	
	initial begin
		clk <= 1'b1;
		rst <= 1'b1;
		
		#10
		rst <= 1'b0;
	end
	
	// UUT
	Filter_Arbiter
	#(
		.NUM_FILTER(NUM_FILTER),
		.ARBITER_MSB(ARBITER_MSB)
	)
	Filter_Arbiter
	(
		.clk(clk),
		.rst(rst),
		.Filter_Available_Flag(Filter_Available_Flag),
		.Arbitration_Result(Arbitration_Result)
	);

endmodule