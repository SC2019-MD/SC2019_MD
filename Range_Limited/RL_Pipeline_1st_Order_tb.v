`timescale 1ns/1ns
module RL_Pipeline_1st_Order_tb;
	
	parameter DATA_WIDTH 				= 32;
	parameter INTERPOLATION_ORDER		= 1;
	parameter SEGMENT_NUM				= 12;
	parameter SEGMENT_WIDTH				= 4;
	parameter BIN_WIDTH					= 9;
	parameter BIN_NUM						= 256;
	parameter LOOKUP_NUM					= SEGMENT_NUM * BIN_NUM;			// SEGMENT_NUM * BIN_NUM
	parameter LOOKUP_ADDR_WIDTH		= 12;										// log LOOKUP_NUM / log 2
	
	reg  clk;
	reg  rst;
	reg  start;
	wire [DATA_WIDTH-1:0] forceoutput;
	wire forceoutput_valid;
	wire done;

	RL_Pipeline_1st_Order
	#(
		DATA_WIDTH,
		INTERPOLATION_ORDER,
		SEGMENT_NUM,
		SEGMENT_WIDTH,
		BIN_WIDTH,
		BIN_NUM,
		LOOKUP_NUM,			// SEGMENT_NUM * BIN_NUM
		LOOKUP_ADDR_WIDTH
	)
	UUT(
		.clk(clk),
		.rst(rst),
		.start(start),
		.forceoutput(forceoutput),
		.forceoutput_valid(forceoutput_valid),
		.done(done)
	);

	always begin
		#1 clk <= ~clk;
	end 
	



	initial 
	begin     
		clk <= 1'b0;
		rst <= 1'b1;
		start <= 1'b0;    
		
		#10
		rst <= 1'b0;
		
		#10
		start <= 1'b1;
		
		#2000;
		$stop;
			
	end 

endmodule 