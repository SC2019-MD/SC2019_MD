/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: RL_Top_tb.v
//
//	Function:
//				Testbench for RL_LJ_Top
//
// Dependency:
// 			RL_Top.v
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ns

module RL_Top_tb;

	parameter DATA_WIDTH 					= 32;
	// High level parameters
	parameter NUM_EVAL_UNIT					= 1;											// # of evaluation units in the design
	// Dataset defined parameters
	parameter NUM_NEIGHBOR_CELLS			= 13;											// # of neighbor cells per home cell, for Half-shell method, is 13
	parameter CELL_ID_WIDTH					= 3;//4;											// log(NUM_NEIGHBOR_CELLS)
	parameter MAX_CELL_PARTICLE_NUM		= 100;//290;										// The maximum # of particles can be in a cell
	parameter CELL_ADDR_WIDTH				= 7;//8;											// log(MAX_CELL_PARTICLE_NUM)
	parameter PARTICLE_ID_WIDTH			= CELL_ID_WIDTH*3+CELL_ADDR_WIDTH;	// # of bit used to represent particle ID, 9*9*7 cells, each 4-bit, each cell have max of 220 particles, 8-bit
	// Filter parameters
	parameter NUM_FILTER						= 8;		//4
	parameter ARBITER_MSB 					= 128;	//8								// 2^(NUM_FILTER-1)
	parameter FILTER_BUFFER_DEPTH 		= 32;
	parameter FILTER_BUFFER_ADDR_WIDTH	= 5;
	parameter CUTOFF_2 						= 32'h42908000;//32'h43100000;							// (12^2=144 in IEEE floating point)
	// Force Evaluation parameters
	parameter SEGMENT_NUM					= 9;//14;
	parameter SEGMENT_WIDTH					= 4;
	parameter BIN_NUM							= 256;
	parameter BIN_WIDTH						= 8;
	parameter LOOKUP_NUM						= SEGMENT_NUM * BIN_NUM;				// SEGMENT_NUM * BIN_NUM
	parameter LOOKUP_ADDR_WIDTH			= SEGMENT_WIDTH + BIN_WIDTH;			// log LOOKUP_NUM / log 2

	
	reg clk, rst, start;
	wire [NUM_EVAL_UNIT*PARTICLE_ID_WIDTH-1:0] ref_particle_id, neighbor_particle_id;
	wire [NUM_EVAL_UNIT*DATA_WIDTH-1:0] ref_RL_Force_X, ref_RL_Force_Y, ref_RL_Force_Z;
	wire [NUM_EVAL_UNIT*DATA_WIDTH-1:0] neighbor_RL_Force_X, neighbor_RL_Force_Y, neighbor_RL_Force_Z;
	wire [NUM_EVAL_UNIT-1:0] ref_forceoutput_valid, neighbor_forceoutput_valid;
	wire done;
	wire [3*CELL_ID_WIDTH-1:0] out_Motion_Update_cur_cell;
	
	always #1 clk <= ~clk;
	
	initial begin
		clk <= 1;
		rst <= 1;
		start <= 0;
		
		#10
		rst <= 0;
		
		#8
		start <= 1;
		
		#100
		start <= 0;
	end

	// UUT
	RL_Top
	#(
		.DATA_WIDTH(DATA_WIDTH),
		// High level parameters
		.NUM_EVAL_UNIT(NUM_EVAL_UNIT),
		// Dataset defined parameters
		.NUM_NEIGHBOR_CELLS(NUM_NEIGHBOR_CELLS),
		.CELL_ID_WIDTH(CELL_ID_WIDTH),
		.MAX_CELL_PARTICLE_NUM(MAX_CELL_PARTICLE_NUM),
		.CELL_ADDR_WIDTH(CELL_ADDR_WIDTH),
		.PARTICLE_ID_WIDTH(PARTICLE_ID_WIDTH),				// # of bit used to represent particle ID, 9*9*7 cells, each 4-bit, each cell have max of 200 particles, 8-bit
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
	RL_Top
	(
		.clk(clk),
		.rst(rst),
		.start(start),
		.ref_particle_id(ref_particle_id),
		.ref_RL_Force_X(ref_RL_Force_X),
		.ref_RL_Force_Y(ref_RL_Force_Y),
		.ref_RL_Force_Z(ref_RL_Force_Z),
		.ref_forceoutput_valid(ref_forceoutput_valid),
		.neighbor_particle_id(neighbor_particle_id),
		.neighbor_RL_Force_X(neighbor_RL_Force_X),
		.neighbor_RL_Force_Y(neighbor_RL_Force_Y),
		.neighbor_RL_Force_Z(neighbor_RL_Force_Z),
		.neighbor_forceoutput_valid(neighbor_forceoutput_valid),
		// Done signal, when entire home cell is done processing, this will keep high until the next time 'start' signal turn high
		.out_home_cell_evaluation_done(done),
		.out_Motion_Update_cur_cell(out_Motion_Update_cur_cell),
		.in_sel(4'b0)
	);
	
endmodule