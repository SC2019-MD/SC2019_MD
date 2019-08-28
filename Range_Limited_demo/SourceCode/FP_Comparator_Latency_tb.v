/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: FP_Comparator_Latency_tb.v
//
//	Function: 
//				Evaluate the latency of FP Comparators
//
// Used by:
//				N/A
//
// Dependency:
//				FP_GreaterThan_or_Equal.v
//				FP_LessThan.v
//
// Timing:
//				4 cycles delay from input to output
//
// Created by: 
//				Chen Yang 01/01/19
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ns

module FP_Comparator_Latency_tb;

	reg [31:0] input1, input2;
	reg clk;
	reg rst;
	wire greaterthan_or_equal;
	wire lessthan;
	
	always #1 clk <= ~clk;
	
	initial begin
		clk <= 1'b1;
		rst <= 1'b1;
		input1 <= 0;
		input2 <= 0;
		
		#10
		rst <= 1'b0;
		
		#10
		input1 <= 32'h3F800000;			// 1.0
		input2 <= 32'h40000000;			// 2.0
		
		#2
		input1 <= 32'h4163BF48;			// 14.2342
		input2 <= 32'h41400000;			// 12.0
		
		#2
		input1 <= 32'h43800000;			// 256
		input2 <= 32'h43800000;			// 256
		
		#2
		input1 <= 32'h41400000;			// 12.0
		input2 <= 32'h4163BF48;			// 14.2342
		
		#2
		input1 <= 32'h3F800000;			// 1.0
		input2 <= 32'h40000000;			// 2.0
		
		#2
		input1 <= 32'hBF800000;			// -1.0
		input2 <= 32'h3F800000;			// 1.0
		
		#2
		input1 <= 32'h3F800000;			// 1.0
		input2 <= 32'hBF800000;			// -1.0
		
		#2
		input1 <= 32'hBF800000;			// -1.0
		input2 <= 32'hBF800000;			// -1.0
		
	end
	
	
	FP_GreaterThan_or_Equal GreaterThan_Or_Equal(
		.a(input1),
		.areset(rst),
		.b(input2),
		.clk(clk),
		.q(greaterthan_or_equal)
	);
	
	FP_LessThan LessThan(
		.a(input1),
		.areset(rst),
		.b(input2),
		.clk(clk),
		.q(lessthan)
	);


endmodule