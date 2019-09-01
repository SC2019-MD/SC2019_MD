`timescale 1ns/1ns
module RL_LJ_Topest_Top_64_Cells_tb;

	parameter DATA_WIDTH 					= 32;
	parameter NUM_PIPELINES					= 16;
	// Simulation parameters
	parameter TIME_STEP 						= 32'h27101D7D;							// 2fs time step
	// High level parameters
	parameter NUM_EVAL_UNIT					= 1;											// # of evaluation units in the design
	parameter RDADDR_ARBITER_SIZE			= 5;
	parameter RDADDR_ARBITER_MSB			= 16;
	parameter FORCE_WTADDR_ARBITER_SIZE	= 6;
	parameter FORCE_WTADDR_ARBITER_MSB	= 32;
	// Dataset defined parameters
	parameter X_DIM							= 4;
	parameter Y_DIM							= 4;
	parameter Z_DIM							= 4;
	parameter TOTAL_CELL_NUM				= X_DIM*Y_DIM*Z_DIM;
	parameter GLOBAL_CELL_ADDR_LEN		= 7;
	parameter MAX_CELL_COUNT_PER_DIM 	= 4;//9,										// Maximum cell count among the 3 dimensions
	parameter NUM_NEIGHBOR_CELLS			= 13;										// # of neighbor cells per home cell, for Half-shell method, is 13
	parameter CELL_ID_WIDTH					= 3;//4,										// log(MAX_CELL_COUNT_PER_DIM)
	parameter MAX_CELL_PARTICLE_NUM		= 100;//200,								// The maximum # of particles can be in a cell
	parameter CELL_ADDR_WIDTH				= 7;//8,										// log(MAX_CELL_PARTICLE_NUM)
	parameter PARTICLE_ID_WIDTH			= CELL_ID_WIDTH*3+CELL_ADDR_WIDTH;	// # of bit used to represent particle ID, 9*9*7 cells, each 4-bit, each cell have max of 220 particles, 8-bit
	// Filter parameters
	parameter NUM_FILTER						= 8;		//4
	parameter ARBITER_MSB 					= 128;   //8								// 2^(NUM_FILTER-1)
	parameter FILTER_BUFFER_DEPTH 		= 32;
	parameter FILTER_BUFFER_ADDR_WIDTH	= 5;
	parameter CUTOFF_2 						= 32'h42908000;							// 8.5^2=72.25 in IEEE Floating Point//32'h43100000,			// (12^2=144 in IEEE floating point)
	parameter CUTOFF_TIMES_SQRT_3			= 32'h416b8f15;//32'h41A646DC,		// sqrt(3) * CUTOFF
	parameter FIXED_POINT_WIDTH 			= 24;//32,
	parameter FILTER_IN_PATCH_0_BITS		= 0;//8'b0,									// Width = FIXED_POINT_WIDTH - 1 - 23
	// Bounding box parameters, used when applying PBC inside r2 evaluation
	parameter BOUNDING_BOX_X 				= 32'h42080000;							// 8.5*4 = 34 in IEEE floating point
	parameter BOUNDING_BOX_Y				= 32'h42080000;
	parameter BOUNDING_BOX_Z				= 32'h42080000;
	parameter HALF_BOUNDING_BOX_X_POS	= 32'h41880000;							// 34/2 = 17 in IEEE floating point
	parameter HALF_BOUNDING_BOX_Y_POS	= 32'h41880000;
	parameter HALF_BOUNDING_BOX_Z_POS	= 32'h41880000;
	parameter HALF_BOUNDING_BOX_X_NEG	= 32'hC1880000;							// -34/2 = -17 in IEEE floating point
	parameter HALF_BOUNDING_BOX_Y_NEG	= 32'hC1880000;
	parameter HALF_BOUNDING_BOX_Z_NEG	= 32'hC1880000;
	// Force Evaluation parameters
	parameter SEGMENT_NUM					= 9;//14,
	parameter SEGMENT_WIDTH					= 4;
	parameter BIN_NUM							= 256;
	parameter BIN_WIDTH						= 8;
	parameter LOOKUP_NUM						= SEGMENT_NUM * BIN_NUM;				// SEGMENT_NUM * BIN_NUM
	parameter LOOKUP_ADDR_WIDTH			= SEGMENT_WIDTH + BIN_WIDTH;			// log LOOKUP_NUM / log 2
	// Force (accmulation) cache parameters
	parameter FORCE_CACHE_BUFFER_DEPTH	= 32;											// Force cache input buffer depth, for partial force accumulation
	parameter FORCE_CACHE_BUFFER_ADDR_WIDTH = 5;										// log(FORCE_CACHE_BUFFER_DEPTH) / log 2
	// Used in cell matching
	parameter BINARY_222							= 9'b010010010;
	parameter BINARY_223							= 9'b010010011;
	parameter BINARY_231							= 9'b010011001;
	parameter BINARY_232							= 9'b010011010;
	parameter BINARY_233							= 9'b010011011;
	parameter BINARY_311							= 9'b011001001;
	parameter BINARY_312							= 9'b011001010;
	parameter BINARY_313							= 9'b011001011;
	parameter BINARY_321							= 9'b011010001;
	parameter BINARY_322							= 9'b011010010;
	parameter BINARY_323							= 9'b011010011;
	parameter BINARY_331							= 9'b011011001;
	parameter BINARY_332							= 9'b011011010;
	parameter BINARY_333							= 9'b011011011;
	// Force Evaluation output to FIFO
	parameter FORCE_EVAL_FIFO_DATA_WIDTH = 113;
	parameter FORCE_EVAL_FIFO_DEPTH = 128;
	parameter FORCE_EVAL_FIFO_ADDR_WIDTH = 7;

	
	reg clk, rst, start;
/*
	wire [NUM_EVAL_UNIT*PARTICLE_ID_WIDTH-1:0] ref_particle_id_1_1, neighbor_particle_id_1_1;
	wire [NUM_EVAL_UNIT*DATA_WIDTH-1:0] ref_LJ_Force_X_1_1, ref_LJ_Force_Y_1_1, ref_LJ_Force_Z_1_1;
	wire [NUM_EVAL_UNIT*DATA_WIDTH-1:0] neighbor_LJ_Force_X_1_1, neighbor_LJ_Force_Y_1_1, neighbor_LJ_Force_Z_1_1;
	wire [NUM_EVAL_UNIT-1:0] ref_forceoutput_valid_1_1, neighbor_forceoutput_valid_1_1;
	wire done;
	wire [3*CELL_ID_WIDTH-1:0] out_Motion_Update_cur_cell;
*/
	
	wire out_home_cell_evaluation_done_1_1;
	wire out_motion_update_done;
	wire [3*CELL_ID_WIDTH-1:0] out_Motion_Update_cur_cell;
	wire [NUM_PIPELINES-1:0] ref_force_buffer_full;
	wire [NUM_PIPELINES-1:0] neighbor_force_buffer_full_1;
	wire [NUM_PIPELINES-1:0] neighbor_force_buffer_full_2;
	
	
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
	RL_LJ_Topest_Top_64_Cells
	#(
		.DATA_WIDTH(DATA_WIDTH),
		.NUM_PIPELINES(NUM_PIPELINES),
		.TIME_STEP(TIME_STEP),
		.NUM_EVAL_UNIT(NUM_EVAL_UNIT),
		.RDADDR_ARBITER_SIZE(RDADDR_ARBITER_SIZE),
		.RDADDR_ARBITER_MSB(RDADDR_ARBITER_MSB),
		.FORCE_WTADDR_ARBITER_SIZE(FORCE_WTADDR_ARBITER_SIZE),
		.FORCE_WTADDR_ARBITER_MSB(FORCE_WTADDR_ARBITER_MSB),
		.X_DIM(X_DIM),
		.Y_DIM(Y_DIM),
		.Z_DIM(Z_DIM),
		.TOTAL_CELL_NUM(TOTAL_CELL_NUM),
		.GLOBAL_CELL_ADDR_LEN(GLOBAL_CELL_ADDR_LEN),
		.MAX_CELL_COUNT_PER_DIM(MAX_CELL_COUNT_PER_DIM),
		.NUM_NEIGHBOR_CELLS(NUM_NEIGHBOR_CELLS),
		.CELL_ID_WIDTH(CELL_ID_WIDTH),
		.MAX_CELL_PARTICLE_NUM(MAX_CELL_PARTICLE_NUM),
		.CELL_ADDR_WIDTH(CELL_ADDR_WIDTH),
		.PARTICLE_ID_WIDTH(PARTICLE_ID_WIDTH),
		.NUM_FILTER(NUM_FILTER),
		.ARBITER_MSB(ARBITER_MSB),
		.FILTER_BUFFER_DEPTH(FILTER_BUFFER_DEPTH),
		.FILTER_BUFFER_ADDR_WIDTH(FILTER_BUFFER_ADDR_WIDTH),
		.CUTOFF_TIMES_SQRT_3(CUTOFF_TIMES_SQRT_3),
		.CUTOFF_2(CUTOFF_2),
		.FIXED_POINT_WIDTH(FIXED_POINT_WIDTH),
		.FILTER_IN_PATCH_0_BITS(FILTER_IN_PATCH_0_BITS),
		.BOUNDING_BOX_X(BOUNDING_BOX_X),
		.BOUNDING_BOX_Y(BOUNDING_BOX_Y),
		.BOUNDING_BOX_Z(BOUNDING_BOX_Z),
		.HALF_BOUNDING_BOX_X_POS(HALF_BOUNDING_BOX_X_POS),
		.HALF_BOUNDING_BOX_Y_POS(HALF_BOUNDING_BOX_Y_POS),
		.HALF_BOUNDING_BOX_Z_POS(HALF_BOUNDING_BOX_Z_POS),
		.HALF_BOUNDING_BOX_X_NEG(HALF_BOUNDING_BOX_X_NEG),
		.HALF_BOUNDING_BOX_Y_NEG(HALF_BOUNDING_BOX_Y_NEG),
		.HALF_BOUNDING_BOX_Z_NEG(HALF_BOUNDING_BOX_Z_NEG),
		.SEGMENT_NUM(SEGMENT_NUM),
		.SEGMENT_WIDTH(SEGMENT_WIDTH),
		.BIN_NUM(BIN_NUM),
		.BIN_WIDTH(BIN_WIDTH),
		.LOOKUP_NUM(LOOKUP_NUM),
		.LOOKUP_ADDR_WIDTH(LOOKUP_ADDR_WIDTH),
		.FORCE_CACHE_BUFFER_DEPTH(FORCE_CACHE_BUFFER_DEPTH),
		.FORCE_CACHE_BUFFER_ADDR_WIDTH(FORCE_CACHE_BUFFER_ADDR_WIDTH),
		.BINARY_222(BINARY_222),
		.BINARY_223(BINARY_223),
		.BINARY_231(BINARY_231),
		.BINARY_232(BINARY_232),
		.BINARY_233(BINARY_233),
		.BINARY_311(BINARY_311),
		.BINARY_312(BINARY_312),
		.BINARY_313(BINARY_313),
		.BINARY_321(BINARY_321),
		.BINARY_322(BINARY_322),
		.BINARY_323(BINARY_323),
		.BINARY_331(BINARY_331),
		.BINARY_332(BINARY_332),
		.BINARY_333(BINARY_333),
		.FORCE_EVAL_FIFO_DATA_WIDTH(FORCE_EVAL_FIFO_DATA_WIDTH),
		.FORCE_EVAL_FIFO_DEPTH(FORCE_EVAL_FIFO_DEPTH),
		.FORCE_EVAL_FIFO_ADDR_WIDTH(FORCE_EVAL_FIFO_ADDR_WIDTH)
	)
	RL_LJ_Topest_64_Cells
	(
		.clk(clk),
		.rst(rst),
		.start(start),
		
		.out_home_cell_evaluation_done_1_1(out_home_cell_evaluation_done_1_1),
		.out_motion_update_done(out_motion_update_done),
		.out_Motion_Update_cur_cell(out_Motion_Update_cur_cell),
		.ref_force_buffer_full(ref_force_buffer_full),
		.neighbor_force_buffer_full_1(neighbor_force_buffer_full_1),
		.neighbor_force_buffer_full_2(neighbor_force_buffer_full_2)
	);
	
endmodule