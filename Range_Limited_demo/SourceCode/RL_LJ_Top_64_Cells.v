/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: RL_LJ_Top.v
//
//	Function: 
//				Evaluate the dataset using 1st order interpolation (interpolation index is generated in Matlab (under MatlabScripts/LJ_no_smooth_poly_interpolation_function.m))
// 			The input data is pre-processed ApoA1/LJArgon data with partiation into cells
//				Mapping a single reference pariticle cell and multiple neighbor particle cells onto one RL_LJ_Evaluation_Unit (memory content in ref and neighbor are realistic to actual distibution)
//				Including force accumulation & Motion Update
//				Cell coordinates start from (1,1,1) instead of (0,0,0)
//
//	Purpose:
//				Filter version, used for final system
//
// Mapping Scheme:
//				Half-shell method: each home cell interact with 13 nearest neighbors
//				For 8 Filters configurations, the mapping is follows:
//					Filter 0: 222 (home)
//					Filter 1: 223 (face) 
//					Filter 2: 231 (edge) 232 (face) 
//					Filter 3: 233 (edge) 311 (corner) 
//					Filter 4: 312 (edge) 313 (corner) 
//					Filter 5: 321 (edge) 322 (face) 
//					Filter 6: 323 (edge) 331 (corner) 
//					Filter 7: 332 (edge) 333 (corner) 
//
// Data Organization:
//				particle_id [PARTICLE_ID_WIDTH-1:0]:  {cell_x, cell_y, cell_z, particle_in_cell_rd_addr}
//				ref_particle_position [3*DATA_WIDTH-1:0]: {refz, refy, refx}
//				neighbor_particle_position [3*DATA_WIDTH-1:0]: {neighborz, neighbory, neighborx}
//				LJ_Force [3*DATA_WIDTH-1:0]: {LJ_Force_Z, LJ_Force_Y, LJ_Force_X}
//				cell_id [3*CELL_ID_WIDTH-1:0]: {cell_x, cell_y, cell_z}
//
// Used by:
//				Board_Test_RL_LJ_Top.v
//
// Dependency:
//				RL_LJ_Evaluation_Unit.v
//				Particle_Pair_Gen_HalfShell_64_Cells.v
//				Motion_Update_64_Cells.v
//				cell_x_y_z.v
//				Force_Cache_x_y_z.v
//				Velocity_Cache_x_y_z.v
//
// Testbench:
//				RL_LJ_Top_64_Cells_tb.v
//
// Latency:
//				TBD
//
// Attention:
//				If the homecell is on the border, then need to apply boundary conditions when assigning the cell id for Force Caches
//
// Todo:
//				This is a work in progress module that will be used in the final system
//				0, Accumulation logic for neighbor particle partial forces
//				1, Implement a general numbering mechanism for all the cell in the simulation space, currently using fixed cells id for each input to filters
//				2, parameterize # of force evaluation units in it
//
// Created by:
//				Chen Yang 10/30/2018
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module RL_LJ_Top_64_Cells
#(
	parameter DATA_WIDTH 					= 32,
	// Simulation parameters
	parameter TIME_STEP 						= 32'h27101D7D,							// 2fs time step
	// The home cell this unit is working on
	parameter CELL_X							= 4'd2,
	parameter CELL_Y							= 4'd2,
	parameter CELL_Z							= 4'd2,
	parameter GLOBAL_CELL_X					= 4'd1,
	parameter GLOBAL_CELL_Y					= 4'd1,
	// High level parameters
	parameter NUM_EVAL_UNIT					= 1,											// # of evaluation units in the design
	// Dataset defined parameters
	parameter X_DIM							= 4,
	parameter Y_DIM							= 4,
	parameter Z_DIM							= 4,
	parameter TOTAL_CELL_NUM				= 64,
	parameter MAX_CELL_COUNT_PER_DIM 	= 4,//9,										// Maximum cell count among the 3 dimensions
	parameter NUM_NEIGHBOR_CELLS			= 13,											// # of neighbor cells per home cell, for Half-shell method, is 13
	parameter CELL_ID_WIDTH					= 3,//4,										// log(MAX_CELL_COUNT_PER_DIM)
	parameter MAX_CELL_PARTICLE_NUM		= 100,//200,								// The maximum # of particles can be in a cell
	parameter CELL_ADDR_WIDTH				= 7,//8,										// log(MAX_CELL_PARTICLE_NUM)
	parameter PARTICLE_ID_WIDTH			= CELL_ID_WIDTH*3+CELL_ADDR_WIDTH,	// # of bit used to represent particle ID, 9*9*7 cells, each 4-bit, each cell have max of 220 particles, 8-bit
	// Filter parameters
	parameter NUM_FILTER						= 8,		//4
	parameter ARBITER_MSB 					= 128,	//8								// 2^(NUM_FILTER-1)
	parameter FILTER_BUFFER_DEPTH 		= 32,
	parameter FILTER_BUFFER_ADDR_WIDTH	= 5,
	parameter CUTOFF_2 						= 32'h42908000,							// 8.5^2=72.25 in IEEE Floating Point//32'h43100000,			// (12^2=144 in IEEE floating point)
	parameter CUTOFF_TIMES_SQRT_3			= 32'h416b8f15,//32'h41A646DC,		// sqrt(3) * CUTOFF
	parameter FIXED_POINT_WIDTH 			= 24,//32,
	parameter FILTER_IN_PATCH_0_BITS		= 0,//8'b0,									// Width = FIXED_POINT_WIDTH - 1 - 23
	// Bounding box parameters, used when applying PBC inside r2 evaluation
	parameter BOUNDING_BOX_X				= 32'h426E0000,							// 8.5*7 = 59.5 in IEEE floating point		//32'h42D80000,							// 12*9 = 108 in IEEE floating point
	parameter BOUNDING_BOX_Y				= 32'h424C0000,							// 8.5*6 = 51 in IEEE floating point		//32'h42D80000,							// 12*9 = 108 in IEEE floating point
	parameter BOUNDING_BOX_Z				= 32'h424C0000,							// 8.5*6 = 51 in IEEE floating point		//32'h42A80000,							// 12*7 = 84 in IEEE floating point
	parameter HALF_BOUNDING_BOX_X_POS 	= 32'h41EE0000,							// 59.5/2 = 29.75 in IEEE floating point
	parameter HALF_BOUNDING_BOX_Y_POS 	= 32'h41CC0000,							// 51/2 = 25.5 in IEEE floating point
	parameter HALF_BOUNDING_BOX_Z_POS 	= 32'h41CC0000,							// 51/2 = 25.5 in IEEE floating point
	parameter HALF_BOUNDING_BOX_X_NEG 	= 32'hC1EE0000,							// -59.5/2 = -29.75 in IEEE floating point
	parameter HALF_BOUNDING_BOX_Y_NEG 	= 32'hC1CC0000,							// -51/2 = -25.5 in IEEE floating point
	parameter HALF_BOUNDING_BOX_Z_NEG 	= 32'hC1CC0000,							// -51/2 = -25.5 in IEEE floating point
	// Force Evaluation parameters
	parameter SEGMENT_NUM					= 9,//14,
	parameter SEGMENT_WIDTH					= 4,
	parameter BIN_NUM							= 256,
	parameter BIN_WIDTH						= 8,
	parameter LOOKUP_NUM						= SEGMENT_NUM * BIN_NUM,				// SEGMENT_NUM * BIN_NUM
	parameter LOOKUP_ADDR_WIDTH			= SEGMENT_WIDTH + BIN_WIDTH,			// log LOOKUP_NUM / log 2
	// Force (accmulation) cache parameters
	parameter FORCE_CACHE_BUFFER_DEPTH	= 16,											// Force cache input buffer depth, for partial force accumulation
	parameter FORCE_CACHE_BUFFER_ADDR_WIDTH = 4,										// log(FORCE_CACHE_BUFFER_DEPTH) / log 2
	// Force Evaluation output to FIFO
	parameter FORCE_EVAL_FIFO_DATA_WIDTH = 113,
	parameter FORCE_EVAL_FIFO_DEPTH = 128,
	parameter FORCE_EVAL_FIFO_ADDR_WIDTH = 7
)
(
	input  clk,
	input  rst,
	input  start,
	// Import the cells and the success flags from the topest module
	input [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] from_cells_particle_info,
	input [NUM_NEIGHBOR_CELLS:0] Cell_to_FSM_read_success_bit,
	// From motion update
	input motion_update_done,
	
	// From other pipelines
	input all_pipelines_done_reading,
	
	// From force cache arbiter
	input ref_force_write_success,
	input neighbor_force_write_success_1,
	input neighbor_force_write_success_2,
	
	// Output from the force FIFOs
	output [FORCE_EVAL_FIFO_DATA_WIDTH-1:0] ref_force_data_from_FIFO,
	output [FORCE_EVAL_FIFO_DATA_WIDTH-1:0] neighbor_force_data_from_FIFO_1,
	output [FORCE_EVAL_FIFO_DATA_WIDTH-1:0] neighbor_force_data_from_FIFO_2,
	output ref_force_buffer_full,
	output neighbor_force_buffer_full_1,
	output neighbor_force_buffer_full_2,
	output reg ref_force_valid,
	output reg neighbor_force_valid_1,
	output reg neighbor_force_valid_2,
	
	// Done signals
	// When entire home cell is done processing, this will keep high until the next time 'start' signal turn high
	output out_home_cell_evaluation_done,
	
	// To top cell position cache signals
	output [CELL_ID_WIDTH-1:0] cellz,
	output [(NUM_NEIGHBOR_CELLS+1)*CELL_ADDR_WIDTH-1:0] out_FSM_to_cell_read_addr,
	output [NUM_NEIGHBOR_CELLS:0] enable_reading,
	
	// To top cell motion update signals
	output out_Motion_Update_start
);

	///////////////////////////////////////////////////////////////////////////////////////////////
	// Signals between Cell Module and FSM
	///////////////////////////////////////////////////////////////////////////////////////////////
	//// Signals connect from cell module to FSM
	// Position Data
	// Order: MSB->LSB {333,332,331,323,322,321,313,312,311,233,232,231,223,222} Homecell is on LSB side
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] Position_Cache_readout_position;
	assign Position_Cache_readout_position = from_cells_particle_info;
	
	// Read Address to cells
	wire [(NUM_NEIGHBOR_CELLS+1)*CELL_ADDR_WIDTH-1:0] FSM_to_Cell_read_addr;
	assign out_FSM_to_cell_read_addr = FSM_to_Cell_read_addr;
	
	///////////////////////////////////////////////////////////////////////////////////////////////
	// Signals between Force Evaluation Unit and FSM
	///////////////////////////////////////////////////////////////////////////////////////////////
	//// Signals connect from FSM to Force Evaluation module
	wire [NUM_FILTER*3*DATA_WIDTH-1:0] FSM_to_ForceEval_ref_particle_position;
	wire [NUM_FILTER*3*DATA_WIDTH-1:0] FSM_to_ForceEval_neighbor_particle_position;
	wire [NUM_FILTER*PARTICLE_ID_WIDTH-1:0] FSM_to_ForceEval_ref_particle_id;				// {cell_x, cell_y, cell_z, ref_particle_rd_addr}
	wire [NUM_FILTER*PARTICLE_ID_WIDTH-1:0] FSM_to_ForceEval_neighbor_particle_id;		// {cell_x, cell_y, cell_z, neighbor_particle_rd_addr}
	wire [NUM_FILTER-1:0] FSM_to_ForceEval_input_pair_valid;			// Signify the valid of input particle data, this signal should have 1 cycle delay of the rden signal, thus wait for the data read out from BRAM
	//// Signals connect from Force Evaluation module to FSM
	wire [NUM_FILTER-1:0] ForceEval_to_FSM_backpressure;
	wire ForceEval_to_FSM_all_buffer_empty;
	//// Signals handles the reference output valid
	// Special signal to handle the output valid for the last reference particle
	wire FSM_almost_done_generation;
	
	wire [FORCE_EVAL_FIFO_DATA_WIDTH-1:0] ref_force_data_to_FIFO;
	wire [FORCE_EVAL_FIFO_DATA_WIDTH-1:0] neighbor_force_data_to_FIFO_1;
	wire [FORCE_EVAL_FIFO_DATA_WIDTH-1:0] neighbor_force_data_to_FIFO_2;
	wire ref_force_read_req;
	wire neighbor_force_read_req_1;
	wire neighbor_force_read_req_2;
	
	// Empty output as the valid bit in the arbiters
	wire ref_force_buffer_empty;
	wire neighbor_force_buffer_empty_1;
	wire neighbor_force_buffer_empty_2;
	
	reg ref_queuing;
	reg neighbor_queuing_1;
	reg neighbor_queuing_2;
	
	reg prev_ref_force_buffer_empty;
	reg prev_neighbor_force_buffer_empty_1;
	reg prev_neighbor_force_buffer_empty_2;
	
	// Queuing logic ref
	always@(*)
		begin
		if (rst)
			begin
			ref_queuing = 1'b0;
			end
		else
			begin
			if (~ref_force_buffer_empty && ref_force_write_success)
				begin
				ref_queuing = 1'b0;
				end
			else if (~ref_force_buffer_empty && ~ref_force_write_success)
				begin
				if (~prev_ref_force_buffer_empty)
					begin
					ref_queuing = 1'b1;
					end
				else
					begin
					if (ref_force_valid)
						begin
						ref_queuing = 1'b1;
						end
					else
						begin
						ref_queuing = 1'b0;
						end
					end
				end
			else if (ref_force_buffer_empty && ~ref_force_write_success)
				begin
				if (~prev_ref_force_buffer_empty)
					begin
					ref_queuing = 1'b1;
					end
				else
					begin
					if (ref_force_valid)
						begin
						ref_queuing = 1'b1;
						end
					else
						begin
						ref_queuing = 1'b0;
						end
					end
				end
			else
				begin
				ref_queuing = 1'b0;
				end
			end
		end
		
	// Queuing logic neighbor 1
	always@(*)
		begin
		if (rst)
			begin
			neighbor_queuing_1 = 1'b0;
			end
		else
			begin
			if (~neighbor_force_buffer_empty_1 && neighbor_force_write_success_1)
				begin
				neighbor_queuing_1 = 1'b0;
				end
			else if (~neighbor_force_buffer_empty_1 && ~neighbor_force_write_success_1)
				begin
				if (~prev_neighbor_force_buffer_empty_1)
					begin
					neighbor_queuing_1 = 1'b1;
					end
				else
					begin
					if (neighbor_force_valid_1)
						begin
						neighbor_queuing_1 = 1'b1;
						end
					else
						begin
						neighbor_queuing_1 = 1'b0;
						end
					end
				end
			else if (neighbor_force_buffer_empty_1 && ~neighbor_force_write_success_1)
				begin
				if (~prev_neighbor_force_buffer_empty_1)
					begin
					neighbor_queuing_1 = 1'b1;
					end
				else
					begin
					if (neighbor_force_valid_1)
						begin
						neighbor_queuing_1 = 1'b1;
						end
					else
						begin
						neighbor_queuing_1 = 1'b0;
						end
					end
				end
			else
				begin
				neighbor_queuing_1 = 1'b0;
				end
			end
		end
		
	// Queuing logic neighbor 2
	always@(*)
		begin
		if (rst)
			begin
			neighbor_queuing_2 = 1'b0;
			end
		else
			begin
			if (~neighbor_force_buffer_empty_2 && neighbor_force_write_success_2)
				begin
				neighbor_queuing_2 = 1'b0;
				end
			else if (~neighbor_force_buffer_empty_2 && ~neighbor_force_write_success_2)
				begin
				if (~prev_neighbor_force_buffer_empty_2)
					begin
					neighbor_queuing_2 = 1'b1;
					end
				else
					begin
					if (neighbor_force_valid_2)
						begin
						neighbor_queuing_2 = 1'b1;
						end
					else
						begin
						neighbor_queuing_2 = 1'b0;
						end
					end
				end
			else if (neighbor_force_buffer_empty_2 && ~neighbor_force_write_success_2)
				begin
				if (~prev_neighbor_force_buffer_empty_2)
					begin
					neighbor_queuing_2 = 1'b1;
					end
				else
					begin
					if (neighbor_force_valid_2)
						begin
						neighbor_queuing_2 = 1'b1;
						end
					else
						begin
						neighbor_queuing_2 = 1'b0;
						end
					end
				end
			else
				begin
				neighbor_queuing_2 = 1'b0;
				end
			end
		end
	
	// If arbiter says success and the FIFO is not empty, continue reading, otherwise stop reading, so the data in FIFO will not be lost. 
	// If not queuing, the next force can be read. 
	assign ref_force_read_req = ~(ref_queuing | ref_force_buffer_empty);
	assign neighbor_force_read_req_1 = ~(neighbor_queuing_1 | neighbor_force_buffer_empty_1);
	assign neighbor_force_read_req_2 = ~(neighbor_queuing_2 | neighbor_force_buffer_empty_2);
	
	
	// Force valid check: If write success and buffer empty, meaning the next force output is the same as the current used force.
	// If not success and buffer empty, the force output is valid if not used before, and not valid if used, thus keep the state. 
	// If success and buffer not empty, the next force is valid. 
	// If not success and buffer not empty, current force is unused, thus valid. 
	always@(posedge clk)
		begin
		if (rst)
			begin
			prev_ref_force_buffer_empty <= 1'b1;
			ref_force_valid <= 1'b0;
			end
		else
			begin
			prev_ref_force_buffer_empty <= ref_force_buffer_empty;
			if (ref_force_write_success && ref_force_buffer_empty)
				begin
				ref_force_valid <= 1'b0;
				end
			else if (~ref_force_write_success && ref_force_buffer_empty)
				begin
				ref_force_valid <= ref_force_valid;
				end
			else
				begin
				ref_force_valid <= 1'b1;
				end
			end
		end
		
		
	always@(posedge clk)
		begin
		if (rst)
			begin
			prev_neighbor_force_buffer_empty_1 <= 1'b1;
			neighbor_force_valid_1 <= 1'b0;
			end
		else
			begin
			prev_neighbor_force_buffer_empty_1 <= neighbor_force_buffer_empty_1;
			if (neighbor_force_write_success_1 && neighbor_force_buffer_empty_1)
				begin
				neighbor_force_valid_1 <= 1'b0;
				end
			else if (~neighbor_force_write_success_1 && neighbor_force_buffer_empty_1)
				begin
				neighbor_force_valid_1 <= neighbor_force_valid_1;
				end
			else
				begin
				neighbor_force_valid_1 <= 1'b1;
				end
			end
		end
		
		
	always@(posedge clk)
		begin
		if (rst)
			begin
			prev_neighbor_force_buffer_empty_2 <= 1'b1;
			neighbor_force_valid_2 <= 1'b0;
			end
		else
			begin
			prev_neighbor_force_buffer_empty_2 <= neighbor_force_buffer_empty_2;
			if (neighbor_force_write_success_2 && neighbor_force_buffer_empty_2)
				begin
				neighbor_force_valid_2 <= 1'b0;
				end
			else if (~neighbor_force_write_success_2 && neighbor_force_buffer_empty_2)
				begin
				neighbor_force_valid_2 <= neighbor_force_valid_2;
				end
			else
				begin
				neighbor_force_valid_2 <= 1'b1;
				end
			end
		end
	
	///////////////////////////////////////////////////////////////////////////////////////////////
	// Motion Update Signals
	///////////////////////////////////////////////////////////////////////////////////////////////
	// Use this signal to locate the rising edge of out_home_cell_evaluation_done signal
	// only start motion update when rising edge is detected
	wire all_cells_evaluation_done;
	reg prev_all_cells_evaluation_done;
	always@(posedge clk)
		begin
		prev_all_cells_evaluation_done <= all_cells_evaluation_done;
		end
	assign out_Motion_Update_start = (all_cells_evaluation_done && prev_all_cells_evaluation_done == 0);
	
	///////////////////////////////////////////////////////////////////////////////////////////////
	// FSM for generating particle pairs
	///////////////////////////////////////////////////////////////////////////////////////////////
	Particle_Pair_Gen_HalfShell_64_Cells
	#(
		.DATA_WIDTH(DATA_WIDTH),
		// The home cell this unit is working on
		.CELL_X(4'd2),
		.CELL_Y(4'd2),
		.CELL_Z(4'd2),
		// High level parameters
		.NUM_EVAL_UNIT(NUM_EVAL_UNIT),							// # of evaluation units in the design
		// Dataset defined parameters
		.Z_DIM(Z_DIM),
		.NUM_NEIGHBOR_CELLS(NUM_NEIGHBOR_CELLS),				// # of neighbor cells per home cell, for Half-shell method, is 13
		.MAX_CELL_COUNT_PER_DIM(MAX_CELL_COUNT_PER_DIM),
		.CELL_ID_WIDTH(CELL_ID_WIDTH),							// log(NUM_NEIGHBOR_CELLS)
		.MAX_CELL_PARTICLE_NUM(MAX_CELL_PARTICLE_NUM),
		.CELL_ADDR_WIDTH(CELL_ADDR_WIDTH),						// log(MAX_CELL_PARTICLE_NUM)
		.PARTICLE_ID_WIDTH(PARTICLE_ID_WIDTH),					// # of bit used to represent particle ID, 9*9*7 cells, each 4-bit, each cell have max of 220 particles, 8-bit
		// Filter parameters
		.NUM_FILTER(NUM_FILTER),
		.ARBITER_MSB(ARBITER_MSB),									// 2^(NUM_FILTER-1)
		.FILTER_BUFFER_DEPTH(FILTER_BUFFER_DEPTH),
		.FILTER_BUFFER_ADDR_WIDTH(FILTER_BUFFER_ADDR_WIDTH)
	)
	Particle_Pair_Gen
	(
		.clk(clk),
		.rst(rst),
		.start(start),
		.motion_update_done(motion_update_done),
		// Ports connect to Cell Memory Module
		// Order: MSB->LSB {333,332,331,323,322,321,313,312,311,233,232,231,223,222} Homecell is on LSB side
		.Cell_to_FSM_readout_particle_position(Position_Cache_readout_position),					// input  [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] 
		.ForceEval_to_FSM_backpressure(ForceEval_to_FSM_backpressure),											// input  [NUM_FILTER-1:0]  								// Backpressure signal from Force Evaluation Unit
		.ForceEval_to_FSM_all_buffer_empty(ForceEval_to_FSM_all_buffer_empty),								// input									
		.Cell_to_FSM_read_success_bit(Cell_to_FSM_read_success_bit),
		.all_pipelines_done_reading(all_pipelines_done_reading),
		
		.FSM_to_Cell_read_addr(FSM_to_Cell_read_addr),																// output [(NUM_NEIGHBOR_CELLS+1)*CELL_ADDR_WIDTH-1:0] 
		// Ports connect to Force Evaluation Unit						// Only when all the filter buffers are empty, then the FSM will move on to the next reference particle
		.FSM_to_ForceEval_ref_particle_position(FSM_to_ForceEval_ref_particle_position),  				// output [NUM_FILTER*3*DATA_WIDTH-1:0] 
		.FSM_to_ForceEval_neighbor_particle_position(FSM_to_ForceEval_neighbor_particle_position),	// output [NUM_FILTER*3*DATA_WIDTH-1:0] 
		.FSM_to_ForceEval_ref_particle_id(FSM_to_ForceEval_ref_particle_id),									// output [NUM_FILTER*PARTICLE_ID_WIDTH-1:0] 		// {cell_z, cell_y, cell_x, ref_particle_rd_addr}
		.FSM_to_ForceEval_neighbor_particle_id(FSM_to_ForceEval_neighbor_particle_id),					// output [NUM_FILTER*PARTICLE_ID_WIDTH-1:0] 		// {cell_z, cell_y, cell_x, neighbor_particle_rd_addr}
		.FSM_to_ForceEval_input_pair_valid(FSM_to_ForceEval_input_pair_valid),								// output reg [NUM_FILTER-1:0]   						// Signify the valid of input particle data, this signal should have 1 cycle delay of the rden signal, thus wait for the data read out from BRAM
		// Special signal to handle the output valid for the last reference particle
		.FSM_almost_done_generation(FSM_almost_done_generation),
		// Ports to top level modules
		.done(out_home_cell_evaluation_done),
		.all_done(all_cells_evaluation_done),
		.enable_reading(enable_reading),
		.cellz(cellz)
	);
	///////////////////////////////////////////////////////////////////////////////////////////////
	// Force evaluation and accumulation unit
	///////////////////////////////////////////////////////////////////////////////////////////////
	RL_LJ_Evaluation_Unit_64_Cells
	#(
		.DATA_WIDTH(DATA_WIDTH),
		// The home cell this unit is working on
		.CELL_X(CELL_X),
		.CELL_Y(CELL_Y),
		.CELL_Z(CELL_Z),
		// Dataset defined parameters
		.PARTICLE_ID_WIDTH(PARTICLE_ID_WIDTH),
		.CELL_ADDR_WIDTH(CELL_ADDR_WIDTH),
		// Filter parameters
		.NUM_FILTER(NUM_FILTER),
		.ARBITER_MSB(ARBITER_MSB),
		.FILTER_BUFFER_DEPTH(FILTER_BUFFER_DEPTH),
		.FILTER_BUFFER_ADDR_WIDTH(FILTER_BUFFER_ADDR_WIDTH),
		.CUTOFF_2(CUTOFF_2),
		.CUTOFF_TIMES_SQRT_3(CUTOFF_TIMES_SQRT_3),					// sqrt(3) * CUTOFF
		.FIXED_POINT_WIDTH(FIXED_POINT_WIDTH),
		.FILTER_IN_PATCH_0_BITS(FILTER_IN_PATCH_0_BITS),			// Width = FIXED_POINT_WIDTH - 1 - 23
		// Force Evaluation parameters
		.SEGMENT_NUM(SEGMENT_NUM),
		.SEGMENT_WIDTH(SEGMENT_WIDTH),
		.BIN_NUM(BIN_NUM),
		.BIN_WIDTH(BIN_WIDTH),
		.LOOKUP_NUM(LOOKUP_NUM),
		.LOOKUP_ADDR_WIDTH(LOOKUP_ADDR_WIDTH),
		// Bounding box size, used when applying PBC
		.BOUNDING_BOX_X(BOUNDING_BOX_X),
		.BOUNDING_BOX_Y(BOUNDING_BOX_Y),
		.BOUNDING_BOX_Z(BOUNDING_BOX_Z),
		.HALF_BOUNDING_BOX_X_POS(HALF_BOUNDING_BOX_X_POS),
		.HALF_BOUNDING_BOX_Y_POS(HALF_BOUNDING_BOX_Y_POS),
		.HALF_BOUNDING_BOX_Z_POS(HALF_BOUNDING_BOX_Z_POS),
		.HALF_BOUNDING_BOX_X_NEG(HALF_BOUNDING_BOX_X_NEG),
		.HALF_BOUNDING_BOX_Y_NEG(HALF_BOUNDING_BOX_Y_NEG),
		.HALF_BOUNDING_BOX_Z_NEG(HALF_BOUNDING_BOX_Z_NEG),
		// Force eval to FIFO
		.FORCE_EVAL_FIFO_DATA_WIDTH(FORCE_EVAL_FIFO_DATA_WIDTH)
	)
	RL_LJ_Evaluation_Unit
	(
		.clk(clk),
		.rst(rst),
		.in_input_pair_valid(FSM_to_ForceEval_input_pair_valid),								//input  [NUM_FILTER-1:0]
		.in_ref_particle_id(FSM_to_ForceEval_ref_particle_id),								//input  [NUM_FILTER*PARTICLE_ID_WIDTH-1:0]
		.in_neighbor_particle_id(FSM_to_ForceEval_neighbor_particle_id),					//input  [NUM_FILTER*PARTICLE_ID_WIDTH-1:0]
		.in_ref_particle_position(FSM_to_ForceEval_ref_particle_position),				//input  [NUM_FILTER*3*DATA_WIDTH-1:0]			// {refz, refy, refx}
		.in_neighbor_particle_position(FSM_to_ForceEval_neighbor_particle_position),	//input  [NUM_FILTER*3*DATA_WIDTH-1:0]			// {neighborz, neighbory, neighborx}
		.in_from_FSM_almost_done_generation(FSM_almost_done_generation),
		
		.out_back_pressure_to_input(ForceEval_to_FSM_backpressure),							//output [NUM_FILTER-1:0] 							// backpressure signal to stop new data arrival from particle memory
		.out_all_buffer_empty_to_input(ForceEval_to_FSM_all_buffer_empty),				//output													// Only when all the filter buffers are empty, then the FSM will move on to the next reference particle
		.out_ref_particle_data(ref_force_data_to_FIFO),
		.out_neighbor_particle_data_1(neighbor_force_data_to_FIFO_1),
		.out_neighbor_particle_data_2(neighbor_force_data_to_FIFO_2)
	);
	
	Filter_Buffer
	#(
		.DATA_WIDTH(FORCE_EVAL_FIFO_DATA_WIDTH),
		.FILTER_BUFFER_DEPTH(FORCE_EVAL_FIFO_DEPTH),
		.FILTER_BUFFER_ADDR_WIDTH(FORCE_EVAL_FIFO_ADDR_WIDTH)
	)
	Home_cell_force_buffer
	(
		 .clock(clk),
		 .data(ref_force_data_to_FIFO),
		 .rdreq(ref_force_read_req),
		 .wrreq(ref_force_data_to_FIFO[0]),							// If valid, write. 
		 .empty(ref_force_buffer_empty),
		 .full(ref_force_buffer_full),
		 .q(ref_force_data_from_FIFO),
		 .usedw()
	);
	
	Filter_Buffer
	#(
		.DATA_WIDTH(FORCE_EVAL_FIFO_DATA_WIDTH),
		.FILTER_BUFFER_DEPTH(FORCE_EVAL_FIFO_DEPTH),
		.FILTER_BUFFER_ADDR_WIDTH(FORCE_EVAL_FIFO_ADDR_WIDTH)
	)
	Neighbor_cell_force_buffer_1
	(
		 .clock(clk),
		 .data(neighbor_force_data_to_FIFO_1),
		 .rdreq(neighbor_force_read_req_1),
		 .wrreq(neighbor_force_data_to_FIFO_1[0]),							// If valid, write. 
		 .empty(neighbor_force_buffer_empty_1),
		 .full(neighbor_force_buffer_full_1),
		 .q(neighbor_force_data_from_FIFO_1),
		 .usedw()
	);
	
	Filter_Buffer
	#(
		.DATA_WIDTH(FORCE_EVAL_FIFO_DATA_WIDTH),
		.FILTER_BUFFER_DEPTH(FORCE_EVAL_FIFO_DEPTH),
		.FILTER_BUFFER_ADDR_WIDTH(FORCE_EVAL_FIFO_ADDR_WIDTH)
	)
	Neighbor_cell_force_buffer_2
	(
		 .clock(clk),
		 .data(neighbor_force_data_to_FIFO_2),
		 .rdreq(neighbor_force_read_req_2),
		 .wrreq(neighbor_force_data_to_FIFO_2[0]),							// If valid, write. 
		 .empty(neighbor_force_buffer_empty_2),
		 .full(neighbor_force_buffer_full_2),
		 .q(neighbor_force_data_from_FIFO_2),
		 .usedw()
	);
	
endmodule


