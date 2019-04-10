/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: RL_LJ_Pipeline_1st_Order_no_filter_tb.v
//
//	Function:
//				Testbench for RL_LJ_Pipeline_1st_Order_no_filter
//				Evaluate the LJ force of given datasets using 1st order interpolation (interpolation index is generated in Matlab (under Ethan_GoldenModel/Matlab_Interpolation))
// 			1 tile of force pipeline, without filter
//				for each force pipeline, there are 2 banks of brams to feed position data of particle pairs which are already filtered.
//
// Dependency:
// 			RL_LJ_Pipeline_1st_Order_no_filter.v
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ns

module RL_LJ_Pipeline_1st_Order_no_filter_tb;

	parameter DATA_WIDTH 				= 32;
	parameter REF_PARTICLE_NUM			= 100;
	parameter REF_RAM_ADDR_WIDTH		= 7;										// log(REF_PARTICLE_NUM)
	parameter NEIGHBOR_PARTICLE_NUM	= 100;
	parameter NEIGHBOR_RAM_ADDR_WIDTH= 7;										// log(NEIGHBOR_RAM_ADDR_WIDTH)
	parameter INTERPOLATION_ORDER		= 1;
	parameter SEGMENT_NUM				= 14;
	parameter SEGMENT_WIDTH				= 4;
	parameter BIN_WIDTH					= 8;
	parameter BIN_NUM						= 256;
	parameter CUTOFF_2					= 32'h43100000;						// (12^2=144 in IEEE floating point)
	parameter LOOKUP_NUM					= SEGMENT_NUM * BIN_NUM;			// SEGMENT_NUM * BIN_NUM
	parameter LOOKUP_ADDR_WIDTH		= SEGMENT_WIDTH + BIN_WIDTH;		// log LOOKUP_NUM / log 2

	reg clk, rst, start;
	wire [DATA_WIDTH-1:0] LJ_Force_X, LJ_Force_Y, LJ_Force_Z;
	wire forceoutput_valid;
	wire done;
	
	always #1 clk <= ~clk;
	
	initial begin
		clk <= 1;
		rst <= 1;
		start <= 0;
		
		#10
		rst <= 0;
		
		#2
		start <= 1;
		
		#100
		start <= 0;
	
	end
	
	RL_LJ_Pipeline_1st_Order_no_filter
	#(
		.DATA_WIDTH(DATA_WIDTH),
		.REF_PARTICLE_NUM(REF_PARTICLE_NUM),
		.REF_RAM_ADDR_WIDTH(REF_RAM_ADDR_WIDTH),							// log(REF_PARTICLE_NUM)
		.NEIGHBOR_PARTICLE_NUM(NEIGHBOR_PARTICLE_NUM),
		.NEIGHBOR_RAM_ADDR_WIDTH(NEIGHBOR_RAM_ADDR_WIDTH),				// log(NEIGHBOR_RAM_ADDR_WIDTH)
		.INTERPOLATION_ORDER(INTERPOLATION_ORDER),
		.SEGMENT_NUM(SEGMENT_NUM),
		.SEGMENT_WIDTH(SEGMENT_WIDTH),
		.BIN_WIDTH(BIN_WIDTH),
		.BIN_NUM(BIN_NUM),
		.CUTOFF_2(CUTOFF_2),
		.LOOKUP_NUM(LOOKUP_NUM),
		.LOOKUP_ADDR_WIDTH(LOOKUP_ADDR_WIDTH)
	)
	RL_LJ_Pipeline_1st_Order_no_filter
	(
		.clk(clk),
		.rst(rst),
		.start(start),
		.LJ_Force_X(LJ_Force_X),
		.LJ_Force_Y(LJ_Force_Y),
		.LJ_Force_Z(LJ_Force_Z),
		.forceoutput_valid(forceoutput_valid),
		.done(done)
	);


endmodule