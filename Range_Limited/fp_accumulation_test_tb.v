/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: fp_accumulation_test_tb.v
//
//	Function: 
//				Testbench for fp_accumulation_test.v
//
// Used by:
//				fp_accumulation_test.v
//
// Timing:
//				TBD
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ns

module fp_accumulation_test_tb;

	reg clk, rst;
	reg [31:0] in0, in1;
	wire [31:0] out;
	
	fp_accumulation_test fp_accumulation_test(
		.clk(clk),
		.rst(rst),
		.in0(in0),
		.in1(in1),
		.out(out)
	);
	
	always #1 clk <= ~clk;
	
	initial begin
		rst <= 1'b1;
		clk <= 1'b1;
		in0 <= 0;
		in1 <= 0;
		
		#10
		rst <= 1'b0;
		
		#2
		in0 <= 32'h40000000;				// 2.0
		in1 <= 32'h40C00000;				// 6.0
		
		#2
		in0 <= 32'h40C00000;				// 6.0
		in1 <= 32'h41000000;				// 8.0
		
		#2
		in0 <= 32'h400CCCCD;				// 2.2
		in1 <= 32'h40866666;				// 4.2
		
		#2
		in0 <= 32'h4048F5C3;				// 3.14
		in1 <= 32'h4050624E;				// 3.256
		
		#2
		in0 <= 32'h40800000;				// 4.0
		
		#2
		in0 <= 32'h3F800000;				// 1.0
		
	end

endmodule
