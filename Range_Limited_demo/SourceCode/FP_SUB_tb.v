/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: FP_SUB_tb.v
//
//	Function:
//				Testbench for FP_SUB.v
//				Checking accuracy of subtraction
//				Checking latency
//				Checking if ay-ax of ax-ay
// 
// Dependency:
// 			FP_SUB.v
//
// Created by:
//				Chen Yang 11/16/2018
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ns

module FP_SUB_tb;
	
	reg clk,ena,clr;
	reg [31:0] in1, in2;
	wire [31:0] result;
	
	always #1 clk <= ~clk;
	
	
	// in1 - in2
	initial begin
		clk <= 1'b1;
		ena <= 1'b0;
		clr <= 1'b1;
		in1 <= 0;
		in2 <= 0;
		
		#10
		// suppose result 0 since clear is 1
		ena <= 1'b1;
		clr <= 1'b1;
		in1 <= 32'h41668F5C;			// 14.410
		in2 <= 32'h41591270;			// 13.567
		
		#10
		// suppose result: 3F57CEC0, 0.842999
		ena <= 1'b1;
		clr <= 1'b0;
		in1 <= 32'h41668F5C;			// 14.410
		in2 <= 32'h41591270;			// 13.567
		
		#2
		// suppose result: BE126F00, -0.143002
		ena <= 1'b1;
		clr <= 1'b0;
		in1 <= 32'h414153F8;			// 12.083
		in2 <= 32'h41439DB4;			// 12.226
		
		#2
		// suppose result: 3EF43940, 0.476999
		ena <= 1'b1;
		clr <= 1'b0;
		in1 <= 32'h416974BC;			// 14.591
		in2 <= 32'h4161D2F2;			// 14.114
		
		#2
		// suppose result: BF9E1480, -1.235001
		ena <= 1'b1;
		clr <= 1'b0;
		in1 <= 32'h41668F5C;			// 14.410
		in2 <= 32'h417A51EC;			// 15.645
		
		#2
		// suppose result: BFD85200, -1.690002
		ena <= 1'b1;
		clr <= 1'b0;
		in1 <= 32'h414153F8;			// 12.083
		in2 <= 32'h415C5E38;			// 13.773
		
		#2
		// suppose result: 3FE374C0, 1.777000
		ena <= 1'b1;
		clr <= 1'b0;
		in1 <= 32'h416974BC;			// 14.591
		in2 <= 32'h414D0624;			// 12.814
		
		#2
		// check the latency on clr
		ena <= 1'b1;
		clr <= 1'b1;
		in1 <= 32'h416974BC;			// 14.591
		in2 <= 32'h414D0624;			// 12.814
		
		#2
		// resume evaluation: 3FE374C0, 1.777000
		ena <= 1'b1;
		clr <= 1'b0;
		in1 <= 32'h416974BC;			// 14.591
		in2 <= 32'h414D0624;			// 12.814
		
		#10
		// check ena
		ena <= 1'b0;
		clr <= 1'b0;
		in1 <= 32'h416974BC;			// 14.591
		in2 <= 32'h414D0624;			// 12.814
		
	
	end
	
	FP_SUB FP_SUB (
		.clk(clk),
		.ena(ena),
		.clr(clr),
		.ax(in2),
		.ay(in1),
		.result(result)
	);


endmodule