/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: RL_Top.v
//
//	Function: 
//				Evaluate the dataset using 1st order interpolation (interpolation index is generated in Matlab (under MatlabScripts/LJ_Coulomb_no_smooth_poly_interpolation_function.m))
// 			The input data is pre-processed with LJArgon/ApoA1 data with partiation into cells
//				Mapping a single reference pariticle cell and multiple neighbor particle cells onto one RL_Evaluation_Unit (memory content in ref and neighbor are realistic to actual distibution)
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
//				RL_Force [3*DATA_WIDTH-1:0]: {RL_Force_Z, RL_Force_Y, RL_Force_X}
//				cell_id [3*CELL_ID_WIDTH-1:0]: {cell_x, cell_y, cell_z}
//
// Used by:
//				Board_Test_RL_Top.v
//
// Dependency:
//				RL_Evaluation_Unit.v
//				Particle_Pair_Gen_HalfShell.v
//				Motion_Update.v
//				cell_x_y_z.v
//				Force_Cache_x_y_z.v
//				Velocity_Cache_x_y_z.v
//
// Testbench:
//				RL_Top_tb.v
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
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module RL_Top
#(
	parameter DATA_WIDTH 					= 32,
	// Simulation parameters
	parameter TIME_STEP 						= 32'h27101D7D,							// 2fs time step
	// The home cell this unit is working on
	parameter CELL_X							= 4'd2,
	parameter CELL_Y							= 4'd2,
	parameter CELL_Z							= 4'd2,
	// High level parameters
	parameter NUM_EVAL_UNIT					= 1,											// # of evaluation units in the design
	// Dataset defined parameters
	parameter TOTAL_PARTICLE_NUM 			= 20000,
	parameter PARTICLE_GLOBAL_ID_WIDTH 	= 15,											// log(TOTAL_PARTICLE_NUM)/log(2)
	parameter NUM_CELL_X 					= 5,
	parameter NUM_CELL_Y 					= 5,
	parameter NUM_CELL_Z 					= 5,
	parameter NUM_TOTAL_CELL 				= NUM_CELL_X * NUM_CELL_Y * NUM_CELL_Z,
	parameter MAX_CELL_COUNT_PER_DIM 	= 7,//9,										// Maximum cell count among the 3 dimensions
	parameter NUM_NEIGHBOR_CELLS			= 13,											// # of neighbor cells per home cell, for Half-shell method, is 13
	parameter CELL_ID_WIDTH					= 3,//4,										// log(NUM_NEIGHBOR_CELLS)
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
	parameter FORCE_CACHE_BUFFER_ADDR_WIDTH = 4										// log(FORCE_CACHE_BUFFER_DEPTH) / log 2
)
(
	input  clk,
	input  rst,
	input  start,
	// These are all temp output ports
	output [NUM_EVAL_UNIT*PARTICLE_ID_WIDTH-1:0] ref_particle_id,
	output [NUM_EVAL_UNIT*DATA_WIDTH-1:0] ref_RL_Force_X,
	output [NUM_EVAL_UNIT*DATA_WIDTH-1:0] ref_RL_Force_Y,
	output [NUM_EVAL_UNIT*DATA_WIDTH-1:0] ref_RL_Force_Z,
	output [NUM_EVAL_UNIT-1:0] ref_forceoutput_valid,
	output [NUM_EVAL_UNIT*PARTICLE_ID_WIDTH-1:0] neighbor_particle_id,
	output [NUM_EVAL_UNIT*DATA_WIDTH-1:0] neighbor_RL_Force_X,
	output [NUM_EVAL_UNIT*DATA_WIDTH-1:0] neighbor_RL_Force_Y,
	output [NUM_EVAL_UNIT*DATA_WIDTH-1:0] neighbor_RL_Force_Z,
	output [NUM_EVAL_UNIT-1:0] neighbor_forceoutput_valid,
	// Done signals
	// When entire home cell is done processing, this will keep high until the next time 'start' signal turn high
	output out_home_cell_evaluation_done,
	// When motion update is done processing, remain high until the next motion update starts
	output out_motion_update_done,
	
	// Dummy signal selecting which cell is the home cell
	// Need a logic to replace this, generate by out_Motion_Update_cur_cell
	input [3:0] in_sel,
	
	// Dummy output for motion update
	output [3*CELL_ID_WIDTH-1:0] out_Motion_Update_cur_cell
);

	
	
	///////////////////////////////////////////////////////////////////////////////////////////////
	// Signals between Cell Module and FSM
	///////////////////////////////////////////////////////////////////////////////////////////////
	//// Signals connect from cell module to FSM
	// Position Data
	// Order: MSB->LSB {333,332,331,323,322,321,313,312,311,233,232,231,223,222} Homecell is on LSB side
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] Position_Cache_readout_position;
	//// Signals connect from FSM to cell modules
	wire FSM_to_Cell_rden;
	// Read Address to cells
	wire [(NUM_NEIGHBOR_CELLS+1)*CELL_ADDR_WIDTH-1:0] FSM_to_Cell_read_addr;

	
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
	// Signal connect to the output of Force evaluation valid
	wire ForceEval_ref_output_valid;
	// Generate the 'ref_forceoutput_valid' signal
	assign ref_forceoutput_valid = ForceEval_ref_output_valid || FSM_almost_done_generation;

	///////////////////////////////////////////////////////////////////////////////////////////////
	// Motion Update Signals
	///////////////////////////////////////////////////////////////////////////////////////////////
	// Use this signal to locate the rising edge of out_home_cell_evaluation_done signal
	// only start motion update when rising edge is detected
	reg prev_out_home_cell_evaluation_done;
	always@(posedge clk)
		begin
		prev_out_home_cell_evaluation_done <= out_home_cell_evaluation_done;
		end
	wire Motion_Update_start;
	assign Motion_Update_start = (out_home_cell_evaluation_done && prev_out_home_cell_evaluation_done == 0);
	// The enable singal from Motion Update module, this signal will remain high during the entire motion update process
	wire Motion_Update_enable;
	wire [3*CELL_ID_WIDTH-1:0] Motion_Update_cur_cell;
	// Motion Update read in data from caches
	wire [CELL_ADDR_WIDTH-1:0] Motion_Update_position_read_addr;
	wire Motion_Update_position_read_en;
	reg [3*DATA_WIDTH-1:0] Motion_Update_position_data;
	wire [CELL_ADDR_WIDTH-1:0] Motion_Update_force_read_addr;
	wire Motion_Update_force_read_en;
	reg [3*DATA_WIDTH-1:0] Motion_Update_force_data;
	wire [CELL_ADDR_WIDTH-1:0] Motion_Update_velocity_read_addr;
	wire Motion_Update_velocity_read_en;
	wire [3*DATA_WIDTH-1:0] Motion_Update_velocity_data;
	// Motion Update write back data
	wire [3*CELL_ID_WIDTH-1:0] Motion_Update_dst_cell;
	wire [3*DATA_WIDTH-1:0] Motion_Update_out_velocity_data;
	wire Motion_Update_out_velocity_data_valid;
	wire [3*DATA_WIDTH-1:0] Motion_Update_out_position_data;
	wire Motion_Update_out_position_data_valid;
	// Motion Update select input from force caches
	reg [NUM_NEIGHBOR_CELLS:0] wire_motion_update_to_cache_read_force_request;
	wire [NUM_NEIGHBOR_CELLS:0] wire_cache_to_motion_update_partial_force_valid;
	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] wire_cache_to_motion_update_partial_force;
	wire [(NUM_NEIGHBOR_CELLS+1)*PARTICLE_ID_WIDTH-1:0] wire_cache_to_motion_update_particle_id;
	always@(*)
		begin
		wire_motion_update_to_cache_read_force_request <= Motion_Update_enable << in_sel;
		case(in_sel)
			0:
				begin
//				wire_motion_update_to_cache_read_force_request <= 14'b00000000000001;
				Motion_Update_position_data <= Position_Cache_readout_position[1*3*DATA_WIDTH-1:0*3*DATA_WIDTH];
				Motion_Update_force_data <= wire_cache_to_motion_update_partial_force[1*3*DATA_WIDTH-1:0*3*DATA_WIDTH];
				end
			1:
				begin
//				wire_motion_update_to_cache_read_force_request <= 14'b00000000000010;
				Motion_Update_position_data <= Position_Cache_readout_position[2*3*DATA_WIDTH-1:1*3*DATA_WIDTH];
				Motion_Update_force_data <= wire_cache_to_motion_update_partial_force[2*3*DATA_WIDTH-1:1*3*DATA_WIDTH];
				end
			2:
				begin
//				wire_motion_update_to_cache_read_force_request <= 14'b00000000000100;
				Motion_Update_position_data <= Position_Cache_readout_position[3*3*DATA_WIDTH-1:2*3*DATA_WIDTH];
				Motion_Update_force_data <= wire_cache_to_motion_update_partial_force[3*3*DATA_WIDTH-1:2*3*DATA_WIDTH];
				end
			3:
				begin
//				wire_motion_update_to_cache_read_force_request <= 14'b00000000001000;
				Motion_Update_position_data <= Position_Cache_readout_position[4*3*DATA_WIDTH-1:3*3*DATA_WIDTH];
				Motion_Update_force_data <= wire_cache_to_motion_update_partial_force[4*3*DATA_WIDTH-1:3*3*DATA_WIDTH];
				end
			4:
				begin
//				wire_motion_update_to_cache_read_force_request <= 14'b00000000010000;
				Motion_Update_position_data <= Position_Cache_readout_position[5*3*DATA_WIDTH-1:4*3*DATA_WIDTH];
				Motion_Update_force_data <= wire_cache_to_motion_update_partial_force[5*3*DATA_WIDTH-1:4*3*DATA_WIDTH];
				end
			5:
				begin
//				wire_motion_update_to_cache_read_force_request <= 14'b00000000100000;
				Motion_Update_position_data <= Position_Cache_readout_position[6*3*DATA_WIDTH-1:5*3*DATA_WIDTH];
				Motion_Update_force_data <= wire_cache_to_motion_update_partial_force[6*3*DATA_WIDTH-1:5*3*DATA_WIDTH];
				end
			6:
				begin
//				wire_motion_update_to_cache_read_force_request <= 14'b00000001000000;
				Motion_Update_position_data <= Position_Cache_readout_position[7*3*DATA_WIDTH-1:6*3*DATA_WIDTH];
				Motion_Update_force_data <= wire_cache_to_motion_update_partial_force[7*3*DATA_WIDTH-1:6*3*DATA_WIDTH];
				end
			7:
				begin
//				wire_motion_update_to_cache_read_force_request <= 14'b00000010000000;
				Motion_Update_position_data <= Position_Cache_readout_position[8*3*DATA_WIDTH-1:7*3*DATA_WIDTH];
				Motion_Update_force_data <= wire_cache_to_motion_update_partial_force[8*3*DATA_WIDTH-1:7*3*DATA_WIDTH];
				end
			8:
				begin
//				wire_motion_update_to_cache_read_force_request <= 14'b00000100000000;
				Motion_Update_position_data <= Position_Cache_readout_position[9*3*DATA_WIDTH-1:8*3*DATA_WIDTH];
				Motion_Update_force_data <= wire_cache_to_motion_update_partial_force[9*3*DATA_WIDTH-1:8*3*DATA_WIDTH];
				end
			9:
				begin
//				wire_motion_update_to_cache_read_force_request <= 14'b00001000000000;
				Motion_Update_position_data <= Position_Cache_readout_position[10*3*DATA_WIDTH-1:9*3*DATA_WIDTH];
				Motion_Update_force_data <= wire_cache_to_motion_update_partial_force[10*3*DATA_WIDTH-1:9*3*DATA_WIDTH];
				end
			10:
				begin
//				wire_motion_update_to_cache_read_force_request <= 14'b00010000000000;
				Motion_Update_position_data <= Position_Cache_readout_position[11*3*DATA_WIDTH-1:10*3*DATA_WIDTH];
				Motion_Update_force_data <= wire_cache_to_motion_update_partial_force[11*3*DATA_WIDTH-1:10*3*DATA_WIDTH];
				end
			11:
				begin
//				wire_motion_update_to_cache_read_force_request <= 14'b00100000000000;
				Motion_Update_position_data <= Position_Cache_readout_position[12*3*DATA_WIDTH-1:11*3*DATA_WIDTH];
				Motion_Update_force_data <= wire_cache_to_motion_update_partial_force[12*3*DATA_WIDTH-1:11*3*DATA_WIDTH];
				end
			12:
				begin
//				wire_motion_update_to_cache_read_force_request <= 14'b01000000000000;
				Motion_Update_position_data <= Position_Cache_readout_position[13*3*DATA_WIDTH-1:12*3*DATA_WIDTH];
				Motion_Update_force_data <= wire_cache_to_motion_update_partial_force[13*3*DATA_WIDTH-1:12*3*DATA_WIDTH];
				end
			13:
				begin
//				wire_motion_update_to_cache_read_force_request <= 14'b10000000000000;
				Motion_Update_position_data <= Position_Cache_readout_position[14*3*DATA_WIDTH-1:13*3*DATA_WIDTH];
				Motion_Update_force_data <= wire_cache_to_motion_update_partial_force[14*3*DATA_WIDTH-1:13*3*DATA_WIDTH];
				end
			default:
				begin
//				wire_motion_update_to_cache_read_force_request <= 14'b00000000000001;
				Motion_Update_position_data <= Position_Cache_readout_position[1*3*DATA_WIDTH-1:0*3*DATA_WIDTH];
				Motion_Update_force_data <= wire_cache_to_motion_update_partial_force[1*3*DATA_WIDTH-1:0*3*DATA_WIDTH];
				end
		endcase
		end
	
	///////////////////////////////////////////////////////////////////////////////////////////////
	// FSM for generating particle pairs
	///////////////////////////////////////////////////////////////////////////////////////////////
	Particle_Pair_Gen_HalfShell
	#(
		.DATA_WIDTH(DATA_WIDTH),
		// The home cell this unit is working on
		.CELL_X(4'd2),
		.CELL_Y(4'd2),
		.CELL_Z(4'd2),
		// High level parameters
		.NUM_EVAL_UNIT(NUM_EVAL_UNIT),							// # of evaluation units in the design
		// Dataset defined parameters
		.NUM_NEIGHBOR_CELLS(NUM_NEIGHBOR_CELLS),				// # of neighbor cells per home cell, for Half-shell method, is 13
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
		// Ports connect to Cell Memory Module
		// Order: MSB->LSB {333,332,331,323,322,321,313,312,311,233,232,231,223,222} Homecell is on LSB side
		.Cell_to_FSM_readout_particle_position(Position_Cache_readout_position),					// input  [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] 
		.FSM_to_Cell_read_addr(FSM_to_Cell_read_addr),																// output [(NUM_NEIGHBOR_CELLS+1)*CELL_ADDR_WIDTH-1:0] 
		.FSM_to_Cell_rden(FSM_to_Cell_rden),
		// Ports connect to Force Evaluation Unit
		.ForceEval_to_FSM_backpressure(ForceEval_to_FSM_backpressure),											// input  [NUM_FILTER-1:0]  								// Backpressure signal from Force Evaluation Unit
		.ForceEval_to_FSM_all_buffer_empty(ForceEval_to_FSM_all_buffer_empty),								// input															// Only when all the filter buffers are empty, then the FSM will move on to the next reference particle
		.FSM_to_ForceEval_ref_particle_position(FSM_to_ForceEval_ref_particle_position),  				// output [NUM_FILTER*3*DATA_WIDTH-1:0] 
		.FSM_to_ForceEval_neighbor_particle_position(FSM_to_ForceEval_neighbor_particle_position),	// output [NUM_FILTER*3*DATA_WIDTH-1:0] 
		.FSM_to_ForceEval_ref_particle_id(FSM_to_ForceEval_ref_particle_id),									// output [NUM_FILTER*PARTICLE_ID_WIDTH-1:0] 		// {cell_z, cell_y, cell_x, ref_particle_rd_addr}
		.FSM_to_ForceEval_neighbor_particle_id(FSM_to_ForceEval_neighbor_particle_id),					// output [NUM_FILTER*PARTICLE_ID_WIDTH-1:0] 		// {cell_z, cell_y, cell_x, neighbor_particle_rd_addr}
		.FSM_to_ForceEval_input_pair_valid(FSM_to_ForceEval_input_pair_valid),								// output reg [NUM_FILTER-1:0]   						// Signify the valid of input particle data, this signal should have 1 cycle delay of the rden signal, thus wait for the data read out from BRAM
		// Special signal to handle the output valid for the last reference particle
		.FSM_almost_done_generation(FSM_almost_done_generation),
		// Ports to top level modules
		.done(out_home_cell_evaluation_done)
	);
	
	
	///////////////////////////////////////////////////////////////////////////////////////////////
	// Force evaluation and accumulation unit
	///////////////////////////////////////////////////////////////////////////////////////////////
	RL_Evaluation_Unit
	#(
		.DATA_WIDTH(DATA_WIDTH),
		// The home cell this unit is working on
		.CELL_X(CELL_X),
		.CELL_Y(CELL_Y),
		.CELL_Z(CELL_Z),
		// Dataset defined parameters
		.PARTICLE_ID_WIDTH(PARTICLE_ID_WIDTH),
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
		.HALF_BOUNDING_BOX_Z_NEG(HALF_BOUNDING_BOX_Z_NEG)
	)
	RL_Evaluation_Unit
	(
		.clk(clk),
		.rst(rst),
		.in_input_pair_valid(FSM_to_ForceEval_input_pair_valid),								//input  [NUM_FILTER-1:0]
		.in_ref_particle_id(FSM_to_ForceEval_ref_particle_id),								//input  [NUM_FILTER*PARTICLE_ID_WIDTH-1:0]
		.in_neighbor_particle_id(FSM_to_ForceEval_neighbor_particle_id),					//input  [NUM_FILTER*PARTICLE_ID_WIDTH-1:0]
		.in_ref_particle_position(FSM_to_ForceEval_ref_particle_position),				//input  [NUM_FILTER*3*DATA_WIDTH-1:0]			// {refz, refy, refx}
		.in_neighbor_particle_position(FSM_to_ForceEval_neighbor_particle_position),	//input  [NUM_FILTER*3*DATA_WIDTH-1:0]			// {neighborz, neighbory, neighborx}
		.out_back_pressure_to_input(ForceEval_to_FSM_backpressure),							//output [NUM_FILTER-1:0] 							// backpressure signal to stop new data arrival from particle memory
		.out_all_buffer_empty_to_input(ForceEval_to_FSM_all_buffer_empty),				//output													// Only when all the filter buffers are empty, then the FSM will move on to the next reference particle
		// Output accumulated force for reference particles
		// The output value is the accumulated value
		// Connected to home cell
		.out_ref_particle_id(ref_particle_id),						//output [PARTICLE_ID_WIDTH-1:0]
		.out_ref_RL_Force_X(ref_RL_Force_X),						//output [DATA_WIDTH-1:0]
		.out_ref_RL_Force_Y(ref_RL_Force_Y),						//output [DATA_WIDTH-1:0]
		.out_ref_RL_Force_Z(ref_RL_Force_Z),						//output [DATA_WIDTH-1:0]
		.out_ref_force_valid(ForceEval_ref_output_valid),		//output
		// Output partial force for neighbor particles
		// The output value should be the minus value of the calculated force data
		// Connected to neighbor cells, if the neighbor paritle comes from the home cell, then discard, since the value will be recalculated when evaluating this particle as reference one
		.out_neighbor_particle_id(neighbor_particle_id),		//output [PARTICLE_ID_WIDTH-1:0]
		.out_neighbor_RL_Force_X(neighbor_RL_Force_X),			//output [DATA_WIDTH-1:0]
		.out_neighbor_RL_Force_Y(neighbor_RL_Force_Y),			//output [DATA_WIDTH-1:0]
		.out_neighbor_RL_Force_Z(neighbor_RL_Force_Z),			//output [DATA_WIDTH-1:0]
		.out_neighbor_force_valid(neighbor_forceoutput_valid)	//output
	);
	
	///////////////////////////////////////////////////////////////////////////////////////////////
	// Motion Update Unit
	// This Unit can work on multiple cells, or a single cell
	///////////////////////////////////////////////////////////////////////////////////////////////
	// Assign output signal
	assign out_Motion_Update_cur_cell = Motion_Update_cur_cell;
	Motion_Update
	#(
		.DATA_WIDTH(DATA_WIDTH),											// Data width of a single force value, 32-bit
		.TIME_STEP(TIME_STEP),												// 2fs time step
		// Cell id this unit related to
		.CELL_X(CELL_X),
		.CELL_Y(CELL_Y),
		.CELL_Z(CELL_Z),
		// Dataset defined parameters
		.MAX_CELL_COUNT_PER_DIM(MAX_CELL_COUNT_PER_DIM),			// Maximum cell count among the 3 dimensions
		.CELL_ID_WIDTH(CELL_ID_WIDTH),									// log(NUM_NEIGHBOR_CELLS)
		.MAX_CELL_PARTICLE_NUM(MAX_CELL_PARTICLE_NUM),				// The maximum # of particles can be in a cell
		.CELL_ADDR_WIDTH(CELL_ADDR_WIDTH),								// log(MAX_CELL_PARTICLE_NUM)
		.PARTICLE_ID_WIDTH(PARTICLE_ID_WIDTH)							// # of bit used to represent particle ID, 9*9*7 cells, each 4-bit, each cell have max of 220 particles, 8-bit
	)
	Motion_Update
	(
		.clk(clk),
		.rst(rst),
		.motion_update_start(Motion_Update_start),					// Start Motion update after the home cell is done evaluating
		.motion_update_done(out_motion_update_done),					// Remain high until the next motion update starts
		// Output the targeting home cell
		// When this module is responsible for multiple cells, then the control signal is broadcast to multiple cells, while a mux need to implement on the input side to select from those cells
		.out_cur_working_cell_x(Motion_Update_cur_cell[3*CELL_ID_WIDTH-1:2*CELL_ID_WIDTH]),
		.out_cur_working_cell_y(Motion_Update_cur_cell[2*CELL_ID_WIDTH-1:1*CELL_ID_WIDTH]),
		.out_cur_working_cell_z(Motion_Update_cur_cell[1*CELL_ID_WIDTH-1:0*CELL_ID_WIDTH]),
		// Read from Position Cache
		.in_position_data(Motion_Update_position_data),
		.out_position_cache_rd_en(Motion_Update_position_read_en),
		.out_position_cache_rd_addr(Motion_Update_position_read_addr),
		// Read from Force Cache
		.in_force_data(Motion_Update_force_data),
		.out_force_cache_rd_en(Motion_Update_force_read_en),
		.out_force_cache_rd_addr(Motion_Update_force_read_addr),
		// Read from Velocity Cache
		.in_velocity_data(Motion_Update_velocity_data),
		.out_velocity_cache_rd_en(Motion_Update_velocity_read_en),
		.out_velocity_cache_rd_addr(Motion_Update_velocity_read_addr),
		// Motion update enable signal
		.out_motion_update_enable(Motion_Update_enable),		// Remine high during the entire motion update process
		// Write back to Velocity Cache
		.out_velocity_data(Motion_Update_out_velocity_data),	// The updated velocity value
		.out_velocity_data_valid(Motion_Update_out_velocity_data_valid),
		.out_velocity_destination_cell(Motion_Update_dst_cell),
		// Write back to Position Cache
		.out_position_data(Motion_Update_out_position_data),
		.out_position_data_valid(Motion_Update_out_position_data_valid),
		.out_position_destination_cell()								// Leave this one idle, the value is the same as out_velocity_destination_cell
	);
	
	///////////////////////////////////////////////////////////////////////////////////////////////
	// Cell particle memory
	// In this impelementation, take cell(2,2,2) as home cell (cell cooridinate starts from (1,1,1))
	// The neighbor cells including:
	// Side: (3,1,1),(3,1,2),(3,1,3),(3,2,1),(3,2,2),(3,2,3),(3,3,1),(3,3,2),(3,3,3)
	// Column: (2,3,1),(2,3,2),(2,3,3)
	// Top: (2,2,3)
	// Data orgainization in cell memory: (pos_z, pos_y, pos_x)
	///////////////////////////////////////////////////////////////////////////////////////////////
	// Home cell (2,2,2)
	Pos_Cache_2_2_2
	#(
		.DATA_WIDTH(DATA_WIDTH),
		.PARTICLE_NUM(MAX_CELL_PARTICLE_NUM),
		.ADDR_WIDTH(CELL_ADDR_WIDTH),
		.CELL_ID_WIDTH(CELL_ID_WIDTH),
		.CELL_X(2),
		.CELL_Y(2),
		.CELL_Z(2)
	)
	cell_2_2_2
	(
		.clk(clk),
		.rst(rst),
		.motion_update_enable(Motion_Update_enable),				// Keep this signal as high during the motion update process
		.in_read_address(Motion_Update_enable ? Motion_Update_position_read_addr : FSM_to_Cell_read_addr[1*CELL_ADDR_WIDTH-1:0*CELL_ADDR_WIDTH]),
		.in_data(Motion_Update_out_position_data),
		.in_data_dst_cell(Motion_Update_dst_cell),				// The destination cell for the incoming data
		.in_data_valid(Motion_Update_out_position_data_valid),						// Signify if the new incoming data is valid
		.in_rden(Motion_Update_enable ? Motion_Update_position_read_en : FSM_to_Cell_rden),
		.out_particle_info(Position_Cache_readout_position[1*3*DATA_WIDTH-1:0*3*DATA_WIDTH])
	);
	
	// Neighbor cell #1 (2,2,3)
	Pos_Cache_2_2_3
	#(
		.DATA_WIDTH(DATA_WIDTH),
		.PARTICLE_NUM(MAX_CELL_PARTICLE_NUM),
		.ADDR_WIDTH(CELL_ADDR_WIDTH),
		.CELL_ID_WIDTH(CELL_ID_WIDTH),
		.CELL_X(2),
		.CELL_Y(2),
		.CELL_Z(3)
	)
	cell_2_2_3
	(
		.clk(clk),
		.rst(rst),
		.motion_update_enable(Motion_Update_enable),				// Keep this signal as high during the motion update process
		.in_read_address(Motion_Update_enable ? Motion_Update_position_read_addr : FSM_to_Cell_read_addr[2*CELL_ADDR_WIDTH-1:1*CELL_ADDR_WIDTH]),
		.in_data(Motion_Update_out_position_data),
		.in_data_dst_cell(Motion_Update_dst_cell),				// The destination cell for the incoming data
		.in_data_valid(Motion_Update_out_position_data_valid),						// Signify if the new incoming data is valid
		.in_rden(Motion_Update_enable ? Motion_Update_position_read_en : FSM_to_Cell_rden),
		.out_particle_info(Position_Cache_readout_position[2*3*DATA_WIDTH-1:1*3*DATA_WIDTH])
	);
	
	// Neighbor cell #2 (2,3,1)
	Pos_Cache_2_3_1
	#(
		.DATA_WIDTH(DATA_WIDTH),
		.PARTICLE_NUM(MAX_CELL_PARTICLE_NUM),
		.ADDR_WIDTH(CELL_ADDR_WIDTH),
		.CELL_ID_WIDTH(CELL_ID_WIDTH),
		.CELL_X(2),
		.CELL_Y(3),
		.CELL_Z(1)
	)
	cell_2_3_1
	(
		.clk(clk),
		.rst(rst),
		.motion_update_enable(Motion_Update_enable),				// Keep this signal as high during the motion update process
		.in_read_address(Motion_Update_enable ? Motion_Update_position_read_addr : FSM_to_Cell_read_addr[3*CELL_ADDR_WIDTH-1:2*CELL_ADDR_WIDTH]),
		.in_data(Motion_Update_out_position_data),
		.in_data_dst_cell(Motion_Update_dst_cell),				// The destination cell for the incoming data
		.in_data_valid(Motion_Update_out_position_data_valid),						// Signify if the new incoming data is valid
		.in_rden(Motion_Update_enable ? Motion_Update_position_read_en : FSM_to_Cell_rden),
		.out_particle_info(Position_Cache_readout_position[3*3*DATA_WIDTH-1:2*3*DATA_WIDTH])
	);
	
	// Neighbor cell #3 (2,3,2)
	Pos_Cache_2_3_2
	#(
		.DATA_WIDTH(DATA_WIDTH),
		.PARTICLE_NUM(MAX_CELL_PARTICLE_NUM),
		.ADDR_WIDTH(CELL_ADDR_WIDTH),
		.CELL_ID_WIDTH(CELL_ID_WIDTH),
		.CELL_X(2),
		.CELL_Y(3),
		.CELL_Z(2)
	)
	cell_2_3_2
	(
		.clk(clk),
		.rst(rst),
		.motion_update_enable(Motion_Update_enable),				// Keep this signal as high during the motion update process
		.in_read_address(Motion_Update_enable ? Motion_Update_position_read_addr : FSM_to_Cell_read_addr[4*CELL_ADDR_WIDTH-1:3*CELL_ADDR_WIDTH]),
		.in_data(Motion_Update_out_position_data),
		.in_data_dst_cell(Motion_Update_dst_cell),				// The destination cell for the incoming data
		.in_data_valid(Motion_Update_out_position_data_valid),						// Signify if the new incoming data is valid
		.in_rden(Motion_Update_enable ? Motion_Update_position_read_en : FSM_to_Cell_rden),
		.out_particle_info(Position_Cache_readout_position[4*3*DATA_WIDTH-1:3*3*DATA_WIDTH])
	);
	
	// Neighbor cell #4 (2,3,3)
	Pos_Cache_2_3_3
	#(
		.DATA_WIDTH(DATA_WIDTH),
		.PARTICLE_NUM(MAX_CELL_PARTICLE_NUM),
		.ADDR_WIDTH(CELL_ADDR_WIDTH),
		.CELL_ID_WIDTH(CELL_ID_WIDTH),
		.CELL_X(2),
		.CELL_Y(3),
		.CELL_Z(3)
	)
	cell_2_3_3
	(
		.clk(clk),
		.rst(rst),
		.motion_update_enable(Motion_Update_enable),				// Keep this signal as high during the motion update process
		.in_read_address(Motion_Update_enable ? Motion_Update_position_read_addr : FSM_to_Cell_read_addr[5*CELL_ADDR_WIDTH-1:4*CELL_ADDR_WIDTH]),
		.in_data(Motion_Update_out_position_data),
		.in_data_dst_cell(Motion_Update_dst_cell),				// The destination cell for the incoming data
		.in_data_valid(Motion_Update_out_position_data_valid),						// Signify if the new incoming data is valid
		.in_rden(Motion_Update_enable ? Motion_Update_position_read_en : FSM_to_Cell_rden),
		.out_particle_info(Position_Cache_readout_position[5*3*DATA_WIDTH-1:4*3*DATA_WIDTH])
	);
	
	// Neighbor cell #5 (3,1,1)
	Pos_Cache_3_1_1
	#(
		.DATA_WIDTH(DATA_WIDTH),
		.PARTICLE_NUM(MAX_CELL_PARTICLE_NUM),
		.ADDR_WIDTH(CELL_ADDR_WIDTH),
		.CELL_ID_WIDTH(CELL_ID_WIDTH),
		.CELL_X(3),
		.CELL_Y(1),
		.CELL_Z(1)
	)
	cell_3_1_1
	(
		.clk(clk),
		.rst(rst),
		.motion_update_enable(Motion_Update_enable),				// Keep this signal as high during the motion update process
		.in_read_address(Motion_Update_enable ? Motion_Update_position_read_addr : FSM_to_Cell_read_addr[6*CELL_ADDR_WIDTH-1:5*CELL_ADDR_WIDTH]),
		.in_data(Motion_Update_out_position_data),
		.in_data_dst_cell(Motion_Update_dst_cell),				// The destination cell for the incoming data
		.in_data_valid(Motion_Update_out_position_data_valid),						// Signify if the new incoming data is valid
		.in_rden(Motion_Update_enable ? Motion_Update_position_read_en : FSM_to_Cell_rden),
		.out_particle_info(Position_Cache_readout_position[6*3*DATA_WIDTH-1:5*3*DATA_WIDTH])
	);
	
	// Neighbor cell #6 (3,1,2)
	Pos_Cache_3_1_2
	#(
		.DATA_WIDTH(DATA_WIDTH),
		.PARTICLE_NUM(MAX_CELL_PARTICLE_NUM),
		.ADDR_WIDTH(CELL_ADDR_WIDTH),
		.CELL_ID_WIDTH(CELL_ID_WIDTH),
		.CELL_X(3),
		.CELL_Y(1),
		.CELL_Z(2)
	)
	cell_3_1_2
	(
		.clk(clk),
		.rst(rst),
		.motion_update_enable(Motion_Update_enable),				// Keep this signal as high during the motion update process
		.in_read_address(Motion_Update_enable ? Motion_Update_position_read_addr : FSM_to_Cell_read_addr[7*CELL_ADDR_WIDTH-1:6*CELL_ADDR_WIDTH]),
		.in_data(Motion_Update_out_position_data),
		.in_data_dst_cell(Motion_Update_dst_cell),				// The destination cell for the incoming data
		.in_data_valid(Motion_Update_out_position_data_valid),						// Signify if the new incoming data is valid
		.in_rden(Motion_Update_enable ? Motion_Update_position_read_en : FSM_to_Cell_rden),
		.out_particle_info(Position_Cache_readout_position[7*3*DATA_WIDTH-1:6*3*DATA_WIDTH])
	);
	
	// Neighbor cell #7 (3,1,3)
	Pos_Cache_3_1_3
	#(
		.DATA_WIDTH(DATA_WIDTH),
		.PARTICLE_NUM(MAX_CELL_PARTICLE_NUM),
		.ADDR_WIDTH(CELL_ADDR_WIDTH),
		.CELL_ID_WIDTH(CELL_ID_WIDTH),
		.CELL_X(3),
		.CELL_Y(1),
		.CELL_Z(3)
	)
	cell_3_1_3
	(
		.clk(clk),
		.rst(rst),
		.motion_update_enable(Motion_Update_enable),				// Keep this signal as high during the motion update process
		.in_read_address(Motion_Update_enable ? Motion_Update_position_read_addr : FSM_to_Cell_read_addr[8*CELL_ADDR_WIDTH-1:7*CELL_ADDR_WIDTH]),
		.in_data(Motion_Update_out_position_data),
		.in_data_dst_cell(Motion_Update_dst_cell),				// The destination cell for the incoming data
		.in_data_valid(Motion_Update_out_position_data_valid),						// Signify if the new incoming data is valid
		.in_rden(Motion_Update_enable ? Motion_Update_position_read_en : FSM_to_Cell_rden),
		.out_particle_info(Position_Cache_readout_position[8*3*DATA_WIDTH-1:7*3*DATA_WIDTH])
	);
	
	// Neighbor cell #8 (3,2,1)
	Pos_Cache_3_2_1
	#(
		.DATA_WIDTH(DATA_WIDTH),
		.PARTICLE_NUM(MAX_CELL_PARTICLE_NUM),
		.ADDR_WIDTH(CELL_ADDR_WIDTH),
		.CELL_ID_WIDTH(CELL_ID_WIDTH),
		.CELL_X(3),
		.CELL_Y(2),
		.CELL_Z(1)
	)
	cell_3_2_1
	(
		.clk(clk),
		.rst(rst),
		.motion_update_enable(Motion_Update_enable),				// Keep this signal as high during the motion update process
		.in_read_address(Motion_Update_enable ? Motion_Update_position_read_addr : FSM_to_Cell_read_addr[9*CELL_ADDR_WIDTH-1:8*CELL_ADDR_WIDTH]),
		.in_data(Motion_Update_out_position_data),
		.in_data_dst_cell(Motion_Update_dst_cell),				// The destination cell for the incoming data
		.in_data_valid(Motion_Update_out_position_data_valid),						// Signify if the new incoming data is valid
		.in_rden(Motion_Update_enable ? Motion_Update_position_read_en : FSM_to_Cell_rden),
		.out_particle_info(Position_Cache_readout_position[9*3*DATA_WIDTH-1:8*3*DATA_WIDTH])
	);
	
	// Neighbor cell #9 (3,2,2)
	Pos_Cache_3_2_2
	#(
		.DATA_WIDTH(DATA_WIDTH),
		.PARTICLE_NUM(MAX_CELL_PARTICLE_NUM),
		.ADDR_WIDTH(CELL_ADDR_WIDTH),
		.CELL_ID_WIDTH(CELL_ID_WIDTH),
		.CELL_X(3),
		.CELL_Y(2),
		.CELL_Z(2)
	)
	cell_3_2_2
	(
		.clk(clk),
		.rst(rst),
		.motion_update_enable(Motion_Update_enable),				// Keep this signal as high during the motion update process
		.in_read_address(Motion_Update_enable ? Motion_Update_position_read_addr : FSM_to_Cell_read_addr[10*CELL_ADDR_WIDTH-1:9*CELL_ADDR_WIDTH]),
		.in_data(Motion_Update_out_position_data),
		.in_data_dst_cell(Motion_Update_dst_cell),				// The destination cell for the incoming data
		.in_data_valid(Motion_Update_out_position_data_valid),						// Signify if the new incoming data is valid
		.in_rden(Motion_Update_enable ? Motion_Update_position_read_en : FSM_to_Cell_rden),
		.out_particle_info(Position_Cache_readout_position[10*3*DATA_WIDTH-1:9*3*DATA_WIDTH])
	);
	
	// Neighbor cell #10 (3,2,3)
	Pos_Cache_3_2_3
	#(
		.DATA_WIDTH(DATA_WIDTH),
		.PARTICLE_NUM(MAX_CELL_PARTICLE_NUM),
		.ADDR_WIDTH(CELL_ADDR_WIDTH),
		.CELL_ID_WIDTH(CELL_ID_WIDTH),
		.CELL_X(3),
		.CELL_Y(2),
		.CELL_Z(3)
	)
	cell_3_2_3
	(
		.clk(clk),
		.rst(rst),
		.motion_update_enable(Motion_Update_enable),				// Keep this signal as high during the motion update process
		.in_read_address(Motion_Update_enable ? Motion_Update_position_read_addr : FSM_to_Cell_read_addr[11*CELL_ADDR_WIDTH-1:10*CELL_ADDR_WIDTH]),
		.in_data(Motion_Update_out_position_data),
		.in_data_dst_cell(Motion_Update_dst_cell),				// The destination cell for the incoming data
		.in_data_valid(Motion_Update_out_position_data_valid),						// Signify if the new incoming data is valid
		.in_rden(Motion_Update_enable ? Motion_Update_position_read_en : FSM_to_Cell_rden),
		.out_particle_info(Position_Cache_readout_position[11*3*DATA_WIDTH-1:10*3*DATA_WIDTH])
	);
	
	// Neighbor cell #11 (3,3,1)
	Pos_Cache_3_3_1
	#(
		.DATA_WIDTH(DATA_WIDTH),
		.PARTICLE_NUM(MAX_CELL_PARTICLE_NUM),
		.ADDR_WIDTH(CELL_ADDR_WIDTH),
		.CELL_ID_WIDTH(CELL_ID_WIDTH),
		.CELL_X(3),
		.CELL_Y(3),
		.CELL_Z(1)
	)
	cell_3_3_1
	(
		.clk(clk),
		.rst(rst),
		.motion_update_enable(Motion_Update_enable),				// Keep this signal as high during the motion update process
		.in_read_address(Motion_Update_enable ? Motion_Update_position_read_addr : FSM_to_Cell_read_addr[12*CELL_ADDR_WIDTH-1:11*CELL_ADDR_WIDTH]),
		.in_data(Motion_Update_out_position_data),
		.in_data_dst_cell(Motion_Update_dst_cell),				// The destination cell for the incoming data
		.in_data_valid(Motion_Update_out_position_data_valid),						// Signify if the new incoming data is valid
		.in_rden(Motion_Update_enable ? Motion_Update_position_read_en : FSM_to_Cell_rden),
		.out_particle_info(Position_Cache_readout_position[12*3*DATA_WIDTH-1:11*3*DATA_WIDTH])
	);
	
	// Neighbor cell #12 (3,3,2)
	Pos_Cache_3_3_2
	#(
		.DATA_WIDTH(DATA_WIDTH),
		.PARTICLE_NUM(MAX_CELL_PARTICLE_NUM),
		.ADDR_WIDTH(CELL_ADDR_WIDTH),
		.CELL_ID_WIDTH(CELL_ID_WIDTH),
		.CELL_X(3),
		.CELL_Y(3),
		.CELL_Z(2)
	)
	cell_3_3_2
	(
		.clk(clk),
		.rst(rst),
		.motion_update_enable(Motion_Update_enable),				// Keep this signal as high during the motion update process
		.in_read_address(Motion_Update_enable ? Motion_Update_position_read_addr : FSM_to_Cell_read_addr[13*CELL_ADDR_WIDTH-1:12*CELL_ADDR_WIDTH]),
		.in_data(Motion_Update_out_position_data),
		.in_data_dst_cell(Motion_Update_dst_cell),				// The destination cell for the incoming data
		.in_data_valid(Motion_Update_out_position_data_valid),						// Signify if the new incoming data is valid
		.in_rden(Motion_Update_enable ? Motion_Update_position_read_en : FSM_to_Cell_rden),
		.out_particle_info(Position_Cache_readout_position[13*3*DATA_WIDTH-1:12*3*DATA_WIDTH])
	);
	
	// Neighbor cell #13 (3,3,3)
	Pos_Cache_3_3_3
	#(
		.DATA_WIDTH(DATA_WIDTH),
		.PARTICLE_NUM(MAX_CELL_PARTICLE_NUM),
		.ADDR_WIDTH(CELL_ADDR_WIDTH),
		.CELL_ID_WIDTH(CELL_ID_WIDTH),
		.CELL_X(3),
		.CELL_Y(3),
		.CELL_Z(2)
	)
	cell_3_3_3
	(
		.clk(clk),
		.rst(rst),
		.motion_update_enable(Motion_Update_enable),				// Keep this signal as high during the motion update process
		.in_read_address(Motion_Update_enable ? Motion_Update_position_read_addr : FSM_to_Cell_read_addr[14*CELL_ADDR_WIDTH-1:13*CELL_ADDR_WIDTH]),
		.in_data(Motion_Update_out_position_data),
		.in_data_dst_cell(Motion_Update_dst_cell),				// The destination cell for the incoming data
		.in_data_valid(Motion_Update_out_position_data_valid),						// Signify if the new incoming data is valid
		.in_rden(Motion_Update_enable ? Motion_Update_position_read_en : FSM_to_Cell_rden),
		.out_particle_info(Position_Cache_readout_position[14*3*DATA_WIDTH-1:13*3*DATA_WIDTH])
	);

	
	///////////////////////////////////////////////////////////////////////////////////////////////
	// Force cache
	// Each cell has an independent cache, MSB -> LSB:{Force_Z, Force_Y, Force_X}
	// The force Serve as the buffer to hold evaluated force values during evaluation
	// The initial force value is 0
	// When new force value arrives, it will accumulate to the current stored value
	///////////////////////////////////////////////////////////////////////////////////////////////
	// Home cell 222
	Force_Write_Back_Controller
	#(
		.DATA_WIDTH(DATA_WIDTH),									// Data width of a single force value, 32-bit
		// Cell id this unit related to
		.CELL_X(CELL_X),
		.CELL_Y(CELL_Y),
		.CELL_Z(CELL_Z),
		// Force cache input buffer
		.FORCE_CACHE_BUFFER_DEPTH(FORCE_CACHE_BUFFER_DEPTH),
		.FORCE_CACHE_BUFFER_ADDR_WIDTH(FORCE_CACHE_BUFFER_ADDR_WIDTH),	// log(FORCE_CACHE_BUFFER_DEPTH) / log 2
		// Dataset defined parameters
		.CELL_ID_WIDTH(CELL_ID_WIDTH),
		.MAX_CELL_PARTICLE_NUM(MAX_CELL_PARTICLE_NUM),		// The maximum # of particles can be in a cell
		.CELL_ADDR_WIDTH(CELL_ADDR_WIDTH),						// log(MAX_CELL_PARTICLE_NUM)
		.PARTICLE_ID_WIDTH(PARTICLE_ID_WIDTH)					// # of bit used to represent particle ID, 9*9*7 cells, each 4-bit, each cell have max of 220 particles, 8-bit
	)
	Force_Cache_Home_Cell
	(
		.clk(clk),
		.rst(rst),
		// Cache input force
		.in_partial_force_valid(ref_forceoutput_valid),
		.in_particle_id(ref_particle_id),
		.in_partial_force({ref_RL_Force_Z, ref_RL_Force_Y, ref_RL_Force_X}),
		// Cache output force
		.in_read_data_request(wire_motion_update_to_cache_read_force_request[0]),									// Enables read data from the force cache, if this signal is high, then no write operation is permitted
		.in_cache_read_address(Motion_Update_force_read_addr),
		.out_partial_force(wire_cache_to_motion_update_partial_force[1*3*DATA_WIDTH-1:0*3*DATA_WIDTH]),
		.out_particle_id(wire_cache_to_motion_update_particle_id[1*PARTICLE_ID_WIDTH-1:0*PARTICLE_ID_WIDTH]),
		.out_cache_readout_valid(wire_cache_to_motion_update_partial_force_valid[0])
	);
	
	// Neighbor cell #1 (223)
	Force_Write_Back_Controller
	#(
		.DATA_WIDTH(DATA_WIDTH),									// Data width of a single force value, 32-bit
		// Cell id this unit related to
		.CELL_X(CELL_X),
		.CELL_Y(CELL_Y),
		.CELL_Z(CELL_Z+1'b1),
		// Force cache input buffer
		.FORCE_CACHE_BUFFER_DEPTH(FORCE_CACHE_BUFFER_DEPTH),
		.FORCE_CACHE_BUFFER_ADDR_WIDTH(FORCE_CACHE_BUFFER_ADDR_WIDTH),	// log(FORCE_CACHE_BUFFER_DEPTH) / log 2
		// Dataset defined parameters
		.CELL_ID_WIDTH(CELL_ID_WIDTH),
		.MAX_CELL_PARTICLE_NUM(MAX_CELL_PARTICLE_NUM),		// The maximum # of particles can be in a cell
		.CELL_ADDR_WIDTH(CELL_ADDR_WIDTH),						// log(MAX_CELL_PARTICLE_NUM)
		.PARTICLE_ID_WIDTH(PARTICLE_ID_WIDTH)					// # of bit used to represent particle ID, 9*9*7 cells, each 4-bit, each cell have max of 220 particles, 8-bit
	)
	Force_Cache_2_2_3
	(
		.clk(clk),
		.rst(rst),
		// Cache input force
		.in_partial_force_valid(neighbor_forceoutput_valid),
		.in_particle_id(neighbor_particle_id),
		.in_partial_force({neighbor_RL_Force_Z, neighbor_RL_Force_Y, neighbor_RL_Force_X}),
		// Cache output force
		.in_read_data_request(wire_motion_update_to_cache_read_force_request[1]),									// Enables read data from the force cache, if this signal is high, then no write operation is permitted
		.in_cache_read_address(Motion_Update_force_read_addr),
		.out_partial_force(wire_cache_to_motion_update_partial_force[2*3*DATA_WIDTH-1:1*3*DATA_WIDTH]),
		.out_particle_id(wire_cache_to_motion_update_particle_id[2*PARTICLE_ID_WIDTH-1:1*PARTICLE_ID_WIDTH]),
		.out_cache_readout_valid(wire_cache_to_motion_update_partial_force_valid[1])
	);
	
	// Neighbor cell #2 (231)
	Force_Write_Back_Controller
	#(
		.DATA_WIDTH(DATA_WIDTH),									// Data width of a single force value, 32-bit
		// Cell id this unit related to
		.CELL_X(CELL_X),
		.CELL_Y(CELL_Y+1'b1),
		.CELL_Z(CELL_Z-1'b1),
		// Force cache input buffer
		.FORCE_CACHE_BUFFER_DEPTH(FORCE_CACHE_BUFFER_DEPTH),
		.FORCE_CACHE_BUFFER_ADDR_WIDTH(FORCE_CACHE_BUFFER_ADDR_WIDTH),	// log(FORCE_CACHE_BUFFER_DEPTH) / log 2
		// Dataset defined parameters
		.CELL_ID_WIDTH(CELL_ID_WIDTH),
		.MAX_CELL_PARTICLE_NUM(MAX_CELL_PARTICLE_NUM),		// The maximum # of particles can be in a cell
		.CELL_ADDR_WIDTH(CELL_ADDR_WIDTH),						// log(MAX_CELL_PARTICLE_NUM)
		.PARTICLE_ID_WIDTH(PARTICLE_ID_WIDTH)					// # of bit used to represent particle ID, 9*9*7 cells, each 4-bit, each cell have max of 220 particles, 8-bit
	)
	Force_Cache_2_3_1
	(
		.clk(clk),
		.rst(rst),
		// Cache input force
		.in_partial_force_valid(neighbor_forceoutput_valid),
		.in_particle_id(neighbor_particle_id),
		.in_partial_force({neighbor_RL_Force_Z, neighbor_RL_Force_Y, neighbor_RL_Force_X}),
		// Cache output force
		.in_read_data_request(wire_motion_update_to_cache_read_force_request[2]),									// Enables read data from the force cache, if this signal is high, then no write operation is permitted
		.in_cache_read_address(Motion_Update_force_read_addr),
		.out_partial_force(wire_cache_to_motion_update_partial_force[3*3*DATA_WIDTH-1:2*3*DATA_WIDTH]),
		.out_particle_id(wire_cache_to_motion_update_particle_id[3*PARTICLE_ID_WIDTH-1:2*PARTICLE_ID_WIDTH]),
		.out_cache_readout_valid(wire_cache_to_motion_update_partial_force_valid[2])
	);
	
	// Neighbor cell #3 (232)
	Force_Write_Back_Controller
	#(
		.DATA_WIDTH(DATA_WIDTH),									// Data width of a single force value, 32-bit
		// Cell id this unit related to
		.CELL_X(CELL_X),
		.CELL_Y(CELL_Y+1'b1),
		.CELL_Z(CELL_Z),
		// Force cache input buffer
		.FORCE_CACHE_BUFFER_DEPTH(FORCE_CACHE_BUFFER_DEPTH),
		.FORCE_CACHE_BUFFER_ADDR_WIDTH(FORCE_CACHE_BUFFER_ADDR_WIDTH),	// log(FORCE_CACHE_BUFFER_DEPTH) / log 2
		// Dataset defined parameters
		.CELL_ID_WIDTH(CELL_ID_WIDTH),
		.MAX_CELL_PARTICLE_NUM(MAX_CELL_PARTICLE_NUM),		// The maximum # of particles can be in a cell
		.CELL_ADDR_WIDTH(CELL_ADDR_WIDTH),						// log(MAX_CELL_PARTICLE_NUM)
		.PARTICLE_ID_WIDTH(PARTICLE_ID_WIDTH)					// # of bit used to represent particle ID, 9*9*7 cells, each 4-bit, each cell have max of 220 particles, 8-bit
	)
	Force_Cache_2_3_2
	(
		.clk(clk),
		.rst(rst),
		// Cache input force
		.in_partial_force_valid(neighbor_forceoutput_valid),
		.in_particle_id(neighbor_particle_id),
		.in_partial_force({neighbor_RL_Force_Z, neighbor_RL_Force_Y, neighbor_RL_Force_X}),
		// Cache output force
		.in_read_data_request(wire_motion_update_to_cache_read_force_request[3]),									// Enables read data from the force cache, if this signal is high, then no write operation is permitted
		.in_cache_read_address(Motion_Update_force_read_addr),
		.out_partial_force(wire_cache_to_motion_update_partial_force[4*3*DATA_WIDTH-1:3*3*DATA_WIDTH]),
		.out_particle_id(wire_cache_to_motion_update_particle_id[4*PARTICLE_ID_WIDTH-1:3*PARTICLE_ID_WIDTH]),
		.out_cache_readout_valid(wire_cache_to_motion_update_partial_force_valid[3])
	);
	
	// Neighbor cell #4 (233)
	Force_Write_Back_Controller
	#(
		.DATA_WIDTH(DATA_WIDTH),									// Data width of a single force value, 32-bit
		// Cell id this unit related to
		.CELL_X(CELL_X),
		.CELL_Y(CELL_Y+1'b1),
		.CELL_Z(CELL_Z+1'b1),
		// Force cache input buffer
		.FORCE_CACHE_BUFFER_DEPTH(FORCE_CACHE_BUFFER_DEPTH),
		.FORCE_CACHE_BUFFER_ADDR_WIDTH(FORCE_CACHE_BUFFER_ADDR_WIDTH),	// log(FORCE_CACHE_BUFFER_DEPTH) / log 2
		// Dataset defined parameters
		.CELL_ID_WIDTH(CELL_ID_WIDTH),
		.MAX_CELL_PARTICLE_NUM(MAX_CELL_PARTICLE_NUM),		// The maximum # of particles can be in a cell
		.CELL_ADDR_WIDTH(CELL_ADDR_WIDTH),						// log(MAX_CELL_PARTICLE_NUM)
		.PARTICLE_ID_WIDTH(PARTICLE_ID_WIDTH)					// # of bit used to represent particle ID, 9*9*7 cells, each 4-bit, each cell have max of 220 particles, 8-bit
	)
	Force_Cache_2_3_3
	(
		.clk(clk),
		.rst(rst),
		// Cache input force
		.in_partial_force_valid(neighbor_forceoutput_valid),
		.in_particle_id(neighbor_particle_id),
		.in_partial_force({neighbor_RL_Force_Z, neighbor_RL_Force_Y, neighbor_RL_Force_X}),
		// Cache output force
		.in_read_data_request(wire_motion_update_to_cache_read_force_request[4]),									// Enables read data from the force cache, if this signal is high, then no write operation is permitted
		.in_cache_read_address(Motion_Update_force_read_addr),
		.out_partial_force(wire_cache_to_motion_update_partial_force[5*3*DATA_WIDTH-1:4*3*DATA_WIDTH]),
		.out_particle_id(wire_cache_to_motion_update_particle_id[5*PARTICLE_ID_WIDTH-1:4*PARTICLE_ID_WIDTH]),
		.out_cache_readout_valid(wire_cache_to_motion_update_partial_force_valid[4])
	);
	
	// Neighbor cell #5 (311)
	Force_Write_Back_Controller
	#(
		.DATA_WIDTH(DATA_WIDTH),									// Data width of a single force value, 32-bit
		// Cell id this unit related to
		.CELL_X(CELL_X+1'b1),
		.CELL_Y(CELL_Y-1'b1),
		.CELL_Z(CELL_Z-1'b1),
		// Force cache input buffer
		.FORCE_CACHE_BUFFER_DEPTH(FORCE_CACHE_BUFFER_DEPTH),
		.FORCE_CACHE_BUFFER_ADDR_WIDTH(FORCE_CACHE_BUFFER_ADDR_WIDTH),	// log(FORCE_CACHE_BUFFER_DEPTH) / log 2
		// Dataset defined parameters
		.CELL_ID_WIDTH(CELL_ID_WIDTH),
		.MAX_CELL_PARTICLE_NUM(MAX_CELL_PARTICLE_NUM),		// The maximum # of particles can be in a cell
		.CELL_ADDR_WIDTH(CELL_ADDR_WIDTH),						// log(MAX_CELL_PARTICLE_NUM)
		.PARTICLE_ID_WIDTH(PARTICLE_ID_WIDTH)					// # of bit used to represent particle ID, 9*9*7 cells, each 4-bit, each cell have max of 220 particles, 8-bit
	)
	Force_Cache_3_1_1
	(
		.clk(clk),
		.rst(rst),
		// Cache input force
		.in_partial_force_valid(neighbor_forceoutput_valid),
		.in_particle_id(neighbor_particle_id),
		.in_partial_force({neighbor_RL_Force_Z, neighbor_RL_Force_Y, neighbor_RL_Force_X}),
		// Cache output force
		.in_read_data_request(wire_motion_update_to_cache_read_force_request[5]),									// Enables read data from the force cache, if this signal is high, then no write operation is permitted
		.in_cache_read_address(Motion_Update_force_read_addr),
		.out_partial_force(wire_cache_to_motion_update_partial_force[6*3*DATA_WIDTH-1:5*3*DATA_WIDTH]),
		.out_particle_id(wire_cache_to_motion_update_particle_id[6*PARTICLE_ID_WIDTH-1:5*PARTICLE_ID_WIDTH]),
		.out_cache_readout_valid(wire_cache_to_motion_update_partial_force_valid[5])
	);

	// Neighbor cell #6 (312)
	Force_Write_Back_Controller
	#(
		.DATA_WIDTH(DATA_WIDTH),									// Data width of a single force value, 32-bit
		// Cell id this unit related to
		.CELL_X(CELL_X+1'b1),
		.CELL_Y(CELL_Y-1'b1),
		.CELL_Z(CELL_Z),
		// Force cache input buffer
		.FORCE_CACHE_BUFFER_DEPTH(FORCE_CACHE_BUFFER_DEPTH),
		.FORCE_CACHE_BUFFER_ADDR_WIDTH(FORCE_CACHE_BUFFER_ADDR_WIDTH),	// log(FORCE_CACHE_BUFFER_DEPTH) / log 2
		// Dataset defined parameters
		.CELL_ID_WIDTH(CELL_ID_WIDTH),
		.MAX_CELL_PARTICLE_NUM(MAX_CELL_PARTICLE_NUM),		// The maximum # of particles can be in a cell
		.CELL_ADDR_WIDTH(CELL_ADDR_WIDTH),						// log(MAX_CELL_PARTICLE_NUM)
		.PARTICLE_ID_WIDTH(PARTICLE_ID_WIDTH)					// # of bit used to represent particle ID, 9*9*7 cells, each 4-bit, each cell have max of 220 particles, 8-bit
	)
	Force_Cache_3_1_2
	(
		.clk(clk),
		.rst(rst),
		// Cache input force
		.in_partial_force_valid(neighbor_forceoutput_valid),
		.in_particle_id(neighbor_particle_id),
		.in_partial_force({neighbor_RL_Force_Z, neighbor_RL_Force_Y, neighbor_RL_Force_X}),
		// Cache output force
		.in_read_data_request(wire_motion_update_to_cache_read_force_request[6]),									// Enables read data from the force cache, if this signal is high, then no write operation is permitted
		.in_cache_read_address(Motion_Update_force_read_addr),
		.out_partial_force(wire_cache_to_motion_update_partial_force[7*3*DATA_WIDTH-1:6*3*DATA_WIDTH]),
		.out_particle_id(wire_cache_to_motion_update_particle_id[7*PARTICLE_ID_WIDTH-1:6*PARTICLE_ID_WIDTH]),
		.out_cache_readout_valid(wire_cache_to_motion_update_partial_force_valid[6])
	);
	
	// Neighbor cell #7 (313)
	Force_Write_Back_Controller
	#(
		.DATA_WIDTH(DATA_WIDTH),									// Data width of a single force value, 32-bit
		// Cell id this unit related to
		.CELL_X(CELL_X+1'b1),
		.CELL_Y(CELL_Y-1'b1),
		.CELL_Z(CELL_Z+1'b1),
		// Force cache input buffer
		.FORCE_CACHE_BUFFER_DEPTH(FORCE_CACHE_BUFFER_DEPTH),
		.FORCE_CACHE_BUFFER_ADDR_WIDTH(FORCE_CACHE_BUFFER_ADDR_WIDTH),	// log(FORCE_CACHE_BUFFER_DEPTH) / log 2
		// Dataset defined parameters
		.CELL_ID_WIDTH(CELL_ID_WIDTH),
		.MAX_CELL_PARTICLE_NUM(MAX_CELL_PARTICLE_NUM),		// The maximum # of particles can be in a cell
		.CELL_ADDR_WIDTH(CELL_ADDR_WIDTH),						// log(MAX_CELL_PARTICLE_NUM)
		.PARTICLE_ID_WIDTH(PARTICLE_ID_WIDTH)					// # of bit used to represent particle ID, 9*9*7 cells, each 4-bit, each cell have max of 220 particles, 8-bit
	)
	Force_Cache_3_1_3
	(
		.clk(clk),
		.rst(rst),
		// Cache input force
		.in_partial_force_valid(neighbor_forceoutput_valid),
		.in_particle_id(neighbor_particle_id),
		.in_partial_force({neighbor_RL_Force_Z, neighbor_RL_Force_Y, neighbor_RL_Force_X}),
		// Cache output force
		.in_read_data_request(wire_motion_update_to_cache_read_force_request[7]),									// Enables read data from the force cache, if this signal is high, then no write operation is permitted
		.in_cache_read_address(Motion_Update_force_read_addr),
		.out_partial_force(wire_cache_to_motion_update_partial_force[8*3*DATA_WIDTH-1:7*3*DATA_WIDTH]),
		.out_particle_id(wire_cache_to_motion_update_particle_id[8*PARTICLE_ID_WIDTH-1:7*PARTICLE_ID_WIDTH]),
		.out_cache_readout_valid(wire_cache_to_motion_update_partial_force_valid[7])
	);
	
	// Neighbor cell #8 (321)
	Force_Write_Back_Controller
	#(
		.DATA_WIDTH(DATA_WIDTH),									// Data width of a single force value, 32-bit
		// Cell id this unit related to
		.CELL_X(CELL_X+1'b1),
		.CELL_Y(CELL_Y),
		.CELL_Z(CELL_Z-1'b1),
		// Force cache input buffer
		.FORCE_CACHE_BUFFER_DEPTH(FORCE_CACHE_BUFFER_DEPTH),
		.FORCE_CACHE_BUFFER_ADDR_WIDTH(FORCE_CACHE_BUFFER_ADDR_WIDTH),	// log(FORCE_CACHE_BUFFER_DEPTH) / log 2
		// Dataset defined parameters
		.CELL_ID_WIDTH(CELL_ID_WIDTH),
		.MAX_CELL_PARTICLE_NUM(MAX_CELL_PARTICLE_NUM),		// The maximum # of particles can be in a cell
		.CELL_ADDR_WIDTH(CELL_ADDR_WIDTH),						// log(MAX_CELL_PARTICLE_NUM)
		.PARTICLE_ID_WIDTH(PARTICLE_ID_WIDTH)					// # of bit used to represent particle ID, 9*9*7 cells, each 4-bit, each cell have max of 220 particles, 8-bit
	)
	Force_Cache_3_2_1
	(
		.clk(clk),
		.rst(rst),
		// Cache input force
		.in_partial_force_valid(neighbor_forceoutput_valid),
		.in_particle_id(neighbor_particle_id),
		.in_partial_force({neighbor_RL_Force_Z, neighbor_RL_Force_Y, neighbor_RL_Force_X}),
		// Cache output force
		.in_read_data_request(wire_motion_update_to_cache_read_force_request[8]),									// Enables read data from the force cache, if this signal is high, then no write operation is permitted
		.in_cache_read_address(Motion_Update_force_read_addr),
		.out_partial_force(wire_cache_to_motion_update_partial_force[9*3*DATA_WIDTH-1:8*3*DATA_WIDTH]),
		.out_particle_id(wire_cache_to_motion_update_particle_id[9*PARTICLE_ID_WIDTH-1:8*PARTICLE_ID_WIDTH]),
		.out_cache_readout_valid(wire_cache_to_motion_update_partial_force_valid[8])
	);
	
	// Neighbor cell #9 (322)
	Force_Write_Back_Controller
	#(
		.DATA_WIDTH(DATA_WIDTH),									// Data width of a single force value, 32-bit
		// Cell id this unit related to
		.CELL_X(CELL_X+1'b1),
		.CELL_Y(CELL_Y),
		.CELL_Z(CELL_Z),
		// Force cache input buffer
		.FORCE_CACHE_BUFFER_DEPTH(FORCE_CACHE_BUFFER_DEPTH),
		.FORCE_CACHE_BUFFER_ADDR_WIDTH(FORCE_CACHE_BUFFER_ADDR_WIDTH),	// log(FORCE_CACHE_BUFFER_DEPTH) / log 2
		// Dataset defined parameters
		.CELL_ID_WIDTH(CELL_ID_WIDTH),
		.MAX_CELL_PARTICLE_NUM(MAX_CELL_PARTICLE_NUM),		// The maximum # of particles can be in a cell
		.CELL_ADDR_WIDTH(CELL_ADDR_WIDTH),						// log(MAX_CELL_PARTICLE_NUM)
		.PARTICLE_ID_WIDTH(PARTICLE_ID_WIDTH)					// # of bit used to represent particle ID, 9*9*7 cells, each 4-bit, each cell have max of 220 particles, 8-bit
	)
	Force_Cache_3_2_2
	(
		.clk(clk),
		.rst(rst),
		// Cache input force
		.in_partial_force_valid(neighbor_forceoutput_valid),
		.in_particle_id(neighbor_particle_id),
		.in_partial_force({neighbor_RL_Force_Z, neighbor_RL_Force_Y, neighbor_RL_Force_X}),
		// Cache output force
		.in_read_data_request(wire_motion_update_to_cache_read_force_request[9]),									// Enables read data from the force cache, if this signal is high, then no write operation is permitted
		.in_cache_read_address(Motion_Update_force_read_addr),
		.out_partial_force(wire_cache_to_motion_update_partial_force[10*3*DATA_WIDTH-1:9*3*DATA_WIDTH]),
		.out_particle_id(wire_cache_to_motion_update_particle_id[10*PARTICLE_ID_WIDTH-1:9*PARTICLE_ID_WIDTH]),
		.out_cache_readout_valid(wire_cache_to_motion_update_partial_force_valid[9])
	);
	
	// Neighbor cell #10 (323)
	Force_Write_Back_Controller
	#(
		.DATA_WIDTH(DATA_WIDTH),									// Data width of a single force value, 32-bit
		// Cell id this unit related to
		.CELL_X(CELL_X+1'b1),
		.CELL_Y(CELL_Y),
		.CELL_Z(CELL_Z+1'b1),
		// Force cache input buffer
		.FORCE_CACHE_BUFFER_DEPTH(FORCE_CACHE_BUFFER_DEPTH),
		.FORCE_CACHE_BUFFER_ADDR_WIDTH(FORCE_CACHE_BUFFER_ADDR_WIDTH),	// log(FORCE_CACHE_BUFFER_DEPTH) / log 2
		// Dataset defined parameters
		.CELL_ID_WIDTH(CELL_ID_WIDTH),
		.MAX_CELL_PARTICLE_NUM(MAX_CELL_PARTICLE_NUM),		// The maximum # of particles can be in a cell
		.CELL_ADDR_WIDTH(CELL_ADDR_WIDTH),						// log(MAX_CELL_PARTICLE_NUM)
		.PARTICLE_ID_WIDTH(PARTICLE_ID_WIDTH)					// # of bit used to represent particle ID, 9*9*7 cells, each 4-bit, each cell have max of 220 particles, 8-bit
	)
	Force_Cache_3_2_3
	(
		.clk(clk),
		.rst(rst),
		// Cache input force
		.in_partial_force_valid(neighbor_forceoutput_valid),
		.in_particle_id(neighbor_particle_id),
		.in_partial_force({neighbor_RL_Force_Z, neighbor_RL_Force_Y, neighbor_RL_Force_X}),
		// Cache output force
		.in_read_data_request(wire_motion_update_to_cache_read_force_request[10]),									// Enables read data from the force cache, if this signal is high, then no write operation is permitted
		.in_cache_read_address(Motion_Update_force_read_addr),
		.out_partial_force(wire_cache_to_motion_update_partial_force[11*3*DATA_WIDTH-1:10*3*DATA_WIDTH]),
		.out_particle_id(wire_cache_to_motion_update_particle_id[11*PARTICLE_ID_WIDTH-1:10*PARTICLE_ID_WIDTH]),
		.out_cache_readout_valid(wire_cache_to_motion_update_partial_force_valid[10])
	);
	
	// Neighbor cell #11 (331)
	Force_Write_Back_Controller
	#(
		.DATA_WIDTH(DATA_WIDTH),									// Data width of a single force value, 32-bit
		// Cell id this unit related to
		.CELL_X(CELL_X+1'b1),
		.CELL_Y(CELL_Y+1'b1),
		.CELL_Z(CELL_Z-1'b1),
		// Force cache input buffer
		.FORCE_CACHE_BUFFER_DEPTH(FORCE_CACHE_BUFFER_DEPTH),
		.FORCE_CACHE_BUFFER_ADDR_WIDTH(FORCE_CACHE_BUFFER_ADDR_WIDTH),	// log(FORCE_CACHE_BUFFER_DEPTH) / log 2
		// Dataset defined parameters
		.CELL_ID_WIDTH(CELL_ID_WIDTH),
		.MAX_CELL_PARTICLE_NUM(MAX_CELL_PARTICLE_NUM),		// The maximum # of particles can be in a cell
		.CELL_ADDR_WIDTH(CELL_ADDR_WIDTH),						// log(MAX_CELL_PARTICLE_NUM)
		.PARTICLE_ID_WIDTH(PARTICLE_ID_WIDTH)					// # of bit used to represent particle ID, 9*9*7 cells, each 4-bit, each cell have max of 220 particles, 8-bit
	)
	Force_Cache_3_3_1
	(
		.clk(clk),
		.rst(rst),
		// Cache input force
		.in_partial_force_valid(neighbor_forceoutput_valid),
		.in_particle_id(neighbor_particle_id),
		.in_partial_force({neighbor_RL_Force_Z, neighbor_RL_Force_Y, neighbor_RL_Force_X}),
		// Cache output force
		.in_read_data_request(wire_motion_update_to_cache_read_force_request[11]),									// Enables read data from the force cache, if this signal is high, then no write operation is permitted
		.in_cache_read_address(Motion_Update_force_read_addr),
		.out_partial_force(wire_cache_to_motion_update_partial_force[12*3*DATA_WIDTH-1:11*3*DATA_WIDTH]),
		.out_particle_id(wire_cache_to_motion_update_particle_id[12*PARTICLE_ID_WIDTH-1:11*PARTICLE_ID_WIDTH]),
		.out_cache_readout_valid(wire_cache_to_motion_update_partial_force_valid[11])
	);
	
	// Neighbor cell #12 (332)
	Force_Write_Back_Controller
	#(
		.DATA_WIDTH(DATA_WIDTH),									// Data width of a single force value, 32-bit
		// Cell id this unit related to
		.CELL_X(CELL_X+1'b1),
		.CELL_Y(CELL_Y+1'b1),
		.CELL_Z(CELL_Z),
		// Force cache input buffer
		.FORCE_CACHE_BUFFER_DEPTH(FORCE_CACHE_BUFFER_DEPTH),
		.FORCE_CACHE_BUFFER_ADDR_WIDTH(FORCE_CACHE_BUFFER_ADDR_WIDTH),	// log(FORCE_CACHE_BUFFER_DEPTH) / log 2
		// Dataset defined parameters
		.CELL_ID_WIDTH(CELL_ID_WIDTH),
		.MAX_CELL_PARTICLE_NUM(MAX_CELL_PARTICLE_NUM),		// The maximum # of particles can be in a cell
		.CELL_ADDR_WIDTH(CELL_ADDR_WIDTH),						// log(MAX_CELL_PARTICLE_NUM)
		.PARTICLE_ID_WIDTH(PARTICLE_ID_WIDTH)					// # of bit used to represent particle ID, 9*9*7 cells, each 4-bit, each cell have max of 220 particles, 8-bit
	)
	Force_Cache_3_3_2
	(
		.clk(clk),
		.rst(rst),
		// Cache input force
		.in_partial_force_valid(neighbor_forceoutput_valid),
		.in_particle_id(neighbor_particle_id),
		.in_partial_force({neighbor_RL_Force_Z, neighbor_RL_Force_Y, neighbor_RL_Force_X}),
		// Cache output force
		.in_read_data_request(wire_motion_update_to_cache_read_force_request[12]),									// Enables read data from the force cache, if this signal is high, then no write operation is permitted
		.in_cache_read_address(Motion_Update_force_read_addr),
		.out_partial_force(wire_cache_to_motion_update_partial_force[13*3*DATA_WIDTH-1:12*3*DATA_WIDTH]),
		.out_particle_id(wire_cache_to_motion_update_particle_id[13*PARTICLE_ID_WIDTH-1:12*PARTICLE_ID_WIDTH]),
		.out_cache_readout_valid(wire_cache_to_motion_update_partial_force_valid[12])
	);

	// Neighbor cell #13 (333)
	Force_Write_Back_Controller
	#(
		.DATA_WIDTH(DATA_WIDTH),									// Data width of a single force value, 32-bit
		// Cell id this unit related to
		.CELL_X(CELL_X+1'b1),
		.CELL_Y(CELL_Y+1'b1),
		.CELL_Z(CELL_Z+1'b1),
		// Force cache input buffer
		.FORCE_CACHE_BUFFER_DEPTH(FORCE_CACHE_BUFFER_DEPTH),
		.FORCE_CACHE_BUFFER_ADDR_WIDTH(FORCE_CACHE_BUFFER_ADDR_WIDTH),	// log(FORCE_CACHE_BUFFER_DEPTH) / log 2
		// Dataset defined parameters
		.CELL_ID_WIDTH(CELL_ID_WIDTH),
		.MAX_CELL_PARTICLE_NUM(MAX_CELL_PARTICLE_NUM),		// The maximum # of particles can be in a cell
		.CELL_ADDR_WIDTH(CELL_ADDR_WIDTH),						// log(MAX_CELL_PARTICLE_NUM)
		.PARTICLE_ID_WIDTH(PARTICLE_ID_WIDTH)					// # of bit used to represent particle ID, 9*9*7 cells, each 4-bit, each cell have max of 220 particles, 8-bit
	)
	Force_Cache_3_3_3
	(
		.clk(clk),
		.rst(rst),
		// Cache input force
		.in_partial_force_valid(neighbor_forceoutput_valid),
		.in_particle_id(neighbor_particle_id),
		.in_partial_force({neighbor_RL_Force_Z, neighbor_RL_Force_Y, neighbor_RL_Force_X}),
		// Cache output force
		.in_read_data_request(wire_motion_update_to_cache_read_force_request[13]),									// Enables read data from the force cache, if this signal is high, then no write operation is permitted
		.in_cache_read_address(Motion_Update_force_read_addr),
		.out_partial_force(wire_cache_to_motion_update_partial_force[14*3*DATA_WIDTH-1:13*3*DATA_WIDTH]),
		.out_particle_id(wire_cache_to_motion_update_particle_id[14*PARTICLE_ID_WIDTH-1:13*PARTICLE_ID_WIDTH]),
		.out_cache_readout_valid(wire_cache_to_motion_update_partial_force_valid[13])
	);

	
	///////////////////////////////////////////////////////////////////////////////////////////////
	// Velocity cache
	// Each cell has an independent cache, MSB -> LSB:{vz, vy, vx}
	// The velocity cache provide the spped information for motion update units
	// The inital velocity information is initialized by a initilization file generated from scripts
	// Double buffer mechanism is implemented
	// During motion update process, the new evaluated speed information will write into the alternative cache
	// The read and write address and particle number information should be the same as the Position Cache
	///////////////////////////////////////////////////////////////////////////////////////////////
	// Home cell velocity (2,2,2)
	Velocity_Cache_2_2_2
	#(
		.DATA_WIDTH(DATA_WIDTH),
		.PARTICLE_NUM(MAX_CELL_PARTICLE_NUM),
		.ADDR_WIDTH(CELL_ADDR_WIDTH),
		.CELL_ID_WIDTH(CELL_ID_WIDTH),
		.CELL_X(4'd2),
		.CELL_Y(4'd2),
		.CELL_Z(4'd2)
	)
	Velocity_Cache_2_2_2
	(
		.clk(clk),
		.rst(rst),
		.motion_update_enable(Motion_Update_enable),				// Keep this signal as high during the motion update process
		.in_read_address(Motion_Update_velocity_read_addr),
		.in_data(Motion_Update_out_velocity_data),
		.in_data_dst_cell(Motion_Update_dst_cell),				// The destination cell for the incoming data
		.in_data_valid(Motion_Update_out_velocity_data_valid),// Signify if the new incoming data is valid
		.in_rden(Motion_Update_velocity_read_en),
		.out_particle_info(Motion_Update_velocity_data)
	);
	
endmodule


