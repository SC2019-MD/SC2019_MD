/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: RL_LJ_Top_Raw_Data_Testing_tb.v
//
//	Function:
//				Testbench for RL_LJ_Top_Raw_Data_Testing
//				Evaluate the dataset using 1st order interpolation (interpolation index is generated in Matlab (under Ethan_GoldenModel/Matlab_Interpolation))
// 			The input data is raw ApoA1 data without sorting into cells
//				Mapping a single reference pariticle memory and a single neighbor particle memory onto one RL_LJ_Evaluation_Unit (memory content in ref and neighbor are the same)
//				Each unit handles a single home cell
//
// Dependency:
// 			RL_LJ_Top_Raw_Data_Testing.v
//
// Created by:
//				Chen Yang 10/18/18
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ns

module RL_LJ_Top_Raw_Data_Testing_tb;

	parameter DATA_WIDTH 					= 32;
	// High level parameters
	parameter NUM_FORCE_EVAL_UNIT			= 1;
	// Dataset defined parameters
	parameter PARTICLE_ID_WIDTH			= 20;										// # of bit used to represent particle ID, 9*9*7 cells, each 4-bit, each cell have max of 200 particles, 8-bit
	parameter REF_PARTICLE_NUM				= 100;
	parameter REF_RAM_ADDR_WIDTH			= 7;										// log(REF_PARTICLE_NUM)
	parameter NEIGHBOR_PARTICLE_NUM		= 100;
	parameter NEIGHBOR_RAM_ADDR_WIDTH	= 7;										// log(NEIGHBOR_RAM_ADDR_WIDTH)
	// Filter parameters
	parameter NUM_FILTER						= 4;	// 8
	parameter ARBITER_MSB 					= 8;	//128								// 2^(NUM_FILTER-1)
	parameter FILTER_BUFFER_DEPTH 		= 32;
	parameter FILTER_BUFFER_ADDR_WIDTH	= 5;
	parameter CUTOFF_2 						= 32'h43100000;						// (12^2=144 in IEEE floating point)
	// Force Evaluation parameters
	parameter SEGMENT_NUM					= 14;
	parameter SEGMENT_WIDTH					= 4;
	parameter BIN_NUM							= 256;
	parameter BIN_WIDTH						= 8;
	parameter LOOKUP_NUM						= SEGMENT_NUM * BIN_NUM;			// SEGMENT_NUM * BIN_NUM
	parameter LOOKUP_ADDR_WIDTH			= SEGMENT_WIDTH + BIN_WIDTH;		// log LOOKUP_NUM / log 2

	
	reg clk, rst, start;
	wire [NUM_FORCE_EVAL_UNIT*PARTICLE_ID_WIDTH-1:0] ref_particle_id, neighbor_particle_id;
	wire [NUM_FORCE_EVAL_UNIT*DATA_WIDTH-1:0] LJ_Force_X, LJ_Force_Y, LJ_Force_Z;
	wire [NUM_FORCE_EVAL_UNIT-1:0] forceoutput_valid;
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

	// UUT
	RL_LJ_Top_Raw_Data_Testing
	#(
		.DATA_WIDTH(DATA_WIDTH),
		// High level parameters
		.NUM_FORCE_EVAL_UNIT(NUM_FORCE_EVAL_UNIT),
		// Dataset defined parameters
		.PARTICLE_ID_WIDTH(PARTICLE_ID_WIDTH),				// # of bit used to represent particle ID, 9*9*7 cells, each 4-bit, each cell have max of 200 particles, 8-bit
		.REF_PARTICLE_NUM(REF_PARTICLE_NUM),
		.REF_RAM_ADDR_WIDTH(REF_RAM_ADDR_WIDTH),			// log(REF_PARTICLE_NUM)
		.NEIGHBOR_PARTICLE_NUM(NEIGHBOR_PARTICLE_NUM),
		.NEIGHBOR_RAM_ADDR_WIDTH(NEIGHBOR_RAM_ADDR_WIDTH),	// log(NEIGHBOR_RAM_ADDR_WIDTH)
		// Filter parameters
		.NUM_FILTER(NUM_FILTER),
		.ARBITER_MSB(ARBITER_MSB),								// 2^(NUM_FILTER-1)
		.FILTER_BUFFER_DEPTH(FILTER_BUFFER_DEPTH),
		.FILTER_BUFFER_ADDR_WIDTH(FILTER_BUFFER_ADDR_WIDTH),
		.CUTOFF_2(CUTOFF_2),										// (12^2=144 in IEEE floating point)
		// Force Evaluation parameters
		.SEGMENT_NUM(SEGMENT_NUM),
		.SEGMENT_WIDTH(SEGMENT_WIDTH),
		.BIN_NUM(BIN_NUM),
		.BIN_WIDTH(BIN_WIDTH),
		.LOOKUP_NUM(LOOKUP_NUM),								// SEGMENT_NUM * BIN_NUM
		.LOOKUP_ADDR_WIDTH(LOOKUP_ADDR_WIDTH)				// log LOOKUP_NUM / log 2
	)
	RL_LJ_Top_Raw_Data_Testing
	(
		.clk(clk),
		.rst(rst),
		.start(start),
		.ref_particle_id(ref_particle_id),
		.neighbor_particle_id(neighbor_particle_id),
		.LJ_Force_X(LJ_Force_X),
		.LJ_Force_Y(LJ_Force_Y),
		.LJ_Force_Z(LJ_Force_Z),
		.forceoutput_valid(forceoutput_valid),
		.done(done)
	);
	
endmodule