/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: RL_LJ_Evaluation_Unit.v
//
//	Function: 
//				Evaluate the accumulated LJ force of given datasets using 1st order interpolation (interpolation index is generated in Matlab (under Ethan_GoldenModel/Matlab_Interpolation))
// 			Force_Evaluation_Unit with Accumulation_Unit and send out neighbor particle force (with negation)
//				Single set of force evaluation unit, including:
//							* Single force evaluation pipeline
//							* Multiple (8) filters
//							* Accumulation unit for reference particles
//				Output:
//							* Each iteration, output neighbor particle's partial force
//							(** if the neighbor particle belongs to the home cell, then don't write that particle value back. It will be recalculated when treat the neighbor particle as reference particle)
//							* When the reference particle is done, output the accumulated force on this reference particle
//
// Mapping Model:
//				Half-shell mapping
//				Each force pipeline working on a single reference particle until all the neighboring particles are evaluated, then move to the next reference particle
//				Depending the # of cells, each unit will be responsible for part of a home cell, or a single home cell, or multiple home cells
//
// Format:
//				particle_id [PARTICLE_ID_WIDTH-1:0]:  {cell_x, cell_y, cell_z, particle_in_cell_rd_addr}
//				in_ref_particle_position [3*DATA_WIDTH-1:0]: {refz, refy, refx}
//				in_neighbor_particle_position [3*DATA_WIDTH-1:0]: {neighborz, neighbory, neighborx}
//
//	Purpose:
//				Filter version, used for final system (half-shell mapping scheme)
//
// Used by:
//				RL_LJ_Top.v
//
// Dependency:
//				RL_LJ_Force_Evaluation_Unit.v / RL_LJ_Force_Evaluation_Unit_simple_filter.v
//				Partial_Force_Acc.v
//
// Testbench:
//				RL_LJ_Top_tb.v
//
// Timing:
//				Total Latency:									32 cycles
//				RL_LJ_Force_Evaluation_Unit:				31 cycles
//				Partial_Force_Acc:							currently 1 cycle
//
// Created by:
//				Chen Yang 10/23/2018
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module RL_LJ_Evaluation_Unit
#(
	parameter DATA_WIDTH 					= 32,
	// The home cell this unit is working on
	parameter CELL_X							= 2,
	parameter CELL_Y							= 2,
	parameter CELL_Z							= 2,
	// Dataset defined parameters
	parameter PARTICLE_ID_WIDTH			= 20,										// # of bit used to represent particle ID, 9*9*7 cells, each 4-bit, each cell have max of 200 particles, 8-bit
	// Filter parameters
	parameter NUM_FILTER						= 8,		// 4
	parameter ARBITER_MSB 					= 128,	// 8							// 2^(NUM_FILTER-1)
	parameter FILTER_BUFFER_DEPTH 		= 32,
	parameter FILTER_BUFFER_ADDR_WIDTH	= 5,
	parameter CUTOFF_2 						= 32'h43100000,						// (12^2=144 in IEEE floating point)
	parameter CUTOFF_TIMES_SQRT_3			= 32'h41A646DC,						// sqrt(3) * CUTOFF
	parameter FIXED_POINT_WIDTH 			= 32,
	parameter FILTER_IN_PATCH_0_BITS		= 8'b0,									// Width = FIXED_POINT_WIDTH - 1 - 23
	parameter BOUNDING_BOX_X				= 32'h42D80000,						// 12*9 = 108 in IEEE floating point
	parameter BOUNDING_BOX_Y				= 32'h42D80000,						// 12*9 = 108 in IEEE floating point
	parameter BOUNDING_BOX_Z				= 32'h42A80000,						// 12*7 = 84 in IEEE floating point
	parameter HALF_BOUNDING_BOX_X_POS 	= 32'h41EE0000,					// 59.5/2 = 29.75 in IEEE floating point
	parameter HALF_BOUNDING_BOX_Y_POS 	= 32'h41CC0000,					// 51/2 = 25.5 in IEEE floating point
	parameter HALF_BOUNDING_BOX_Z_POS 	= 32'h41CC0000,					// 51/2 = 25.5 in IEEE floating point
	parameter HALF_BOUNDING_BOX_X_NEG 	= 32'hC1EE0000,					// -59.5/2 = -29.75 in IEEE floating point
	parameter HALF_BOUNDING_BOX_Y_NEG 	= 32'hC1CC0000,					// -51/2 = -25.5 in IEEE floating point
	parameter HALF_BOUNDING_BOX_Z_NEG 	= 32'hC1CC0000,					// -51/2 = -25.5 in IEEE floating point
	// Force Evaluation parameters
	parameter SEGMENT_NUM					= 14,
	parameter SEGMENT_WIDTH					= 4,
	parameter BIN_NUM							= 256,
	parameter BIN_WIDTH						= 8,
	parameter LOOKUP_NUM						= SEGMENT_NUM * BIN_NUM,			// SEGMENT_NUM * BIN_NUM
	parameter LOOKUP_ADDR_WIDTH			= SEGMENT_WIDTH + BIN_WIDTH		// log LOOKUP_NUM / log 2
)
(
	input  clk,
	input  rst,
	input  [NUM_FILTER-1:0] in_input_pair_valid,
	input  [NUM_FILTER*PARTICLE_ID_WIDTH-1:0] in_ref_particle_id,
	input  [NUM_FILTER*PARTICLE_ID_WIDTH-1:0] in_neighbor_particle_id,
	input  [NUM_FILTER*3*DATA_WIDTH-1:0] in_ref_particle_position,			// {refz, refy, refx}
	input  [NUM_FILTER*3*DATA_WIDTH-1:0] in_neighbor_particle_position,	// {neighborz, neighbory, neighborx}
	output [NUM_FILTER-1:0] out_back_pressure_to_input,						// backpressure signal to stop new data arrival from particle memory
	output out_all_buffer_empty_to_input,											// Output to FSM that generate particle pairs. Only when all the filter buffers are empty, then the FSM will move on to the next reference particle
	// Output accumulated force for reference particles
	// The output value is the accumulated value
	// Connected to home cell
	output [PARTICLE_ID_WIDTH-1:0] out_ref_particle_id,
	output [DATA_WIDTH-1:0] out_ref_LJ_Force_X,
	output [DATA_WIDTH-1:0] out_ref_LJ_Force_Y,
	output [DATA_WIDTH-1:0] out_ref_LJ_Force_Z,
	output out_ref_force_valid,
	// Output partial force for neighbor particles
	// The output value should be the minus value of the calculated force data
	// Connected to neighbor cells, if the neighbor paritle comes from the home cell, then discard, since the value will be recalculated when evaluating this particle as reference one
	output [PARTICLE_ID_WIDTH-1:0] out_neighbor_particle_id,
	output [DATA_WIDTH-1:0] out_neighbor_LJ_Force_X,
	output [DATA_WIDTH-1:0] out_neighbor_LJ_Force_Y,
	output [DATA_WIDTH-1:0] out_neighbor_LJ_Force_Z,
	output out_neighbor_force_valid
);
	
	wire [PARTICLE_ID_WIDTH-1:0] ref_particle_id_wire;				// Wires sending from RL_LJ_Force_Evaluation_Unit to Partial_Force_Acc
	
	/////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Wires for assigning the output neighbor particle partial force value
	/////////////////////////////////////////////////////////////////////////////////////////////////////////
	// assign the neighbor particle partial force valid, connected directly to force evaluation unit
	wire evaluated_force_valid;
	// assign the output port for neighbor partial force valid
	assign out_neighbor_force_valid = evaluated_force_valid;
	// assign the neighbor particle partial force, should negate the sign bit to signify the mutual force
	wire [DATA_WIDTH-1:0] LJ_Force_X_wire;
	wire [DATA_WIDTH-1:0] LJ_Force_Y_wire;
	wire [DATA_WIDTH-1:0] LJ_Force_Z_wire;
	/*
	generate
		begin: neighbor_particle_partial_force_assignment
		assign out_neighbor_LJ_Force_X[DATA_WIDTH-2:0] = LJ_Force_X_wire[DATA_WIDTH-2:0];	
		assign out_neighbor_LJ_Force_X[DATA_WIDTH-1] = ~LJ_Force_X_wire[DATA_WIDTH-1];		// Negate the sign bit
		assign out_neighbor_LJ_Force_Y[DATA_WIDTH-2:0] = LJ_Force_Y_wire[DATA_WIDTH-2:0];
		assign out_neighbor_LJ_Force_Y[DATA_WIDTH-1] = ~LJ_Force_Y_wire[DATA_WIDTH-1];		// Negate the sign bit
		assign out_neighbor_LJ_Force_Z[DATA_WIDTH-2:0] = LJ_Force_Z_wire[DATA_WIDTH-2:0];
		assign out_neighbor_LJ_Force_Z[DATA_WIDTH-1] = ~LJ_Force_Z_wire[DATA_WIDTH-1];		// Negate the sign bit
		end
	endgenerate
	*/
	// Assign the output neighbor force, flip the sign bit
	assign out_neighbor_LJ_Force_X = LJ_Force_X_wire ^ 32'h80000000;
	assign out_neighbor_LJ_Force_Y = LJ_Force_Y_wire ^ 32'h80000000;
	assign out_neighbor_LJ_Force_Z = LJ_Force_Z_wire ^ 32'h80000000;
	
	/////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Wires for assigning input particle data to Force Evaluation Unit
	// Data alignment: {refz, refy, refx}, {neighborz, neighbory, neighborx}
	/////////////////////////////////////////////////////////////////////////////////////////////////////////
	wire [NUM_FILTER*DATA_WIDTH-1:0] refx_in_wire, refy_in_wire, refz_in_wire;
	wire [NUM_FILTER*DATA_WIDTH-1:0] neighborx_in_wire, neighbory_in_wire, neighborz_in_wire;
	genvar i;
	generate 
		for(i = 0; i < NUM_FILTER; i = i + 1)
			begin: input_wire_assignment
			assign refx_in_wire[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH] = in_ref_particle_position[i*3*DATA_WIDTH+DATA_WIDTH-1:i*3*DATA_WIDTH];
			assign refy_in_wire[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH] = in_ref_particle_position[i*3*DATA_WIDTH+2*DATA_WIDTH-1:i*3*DATA_WIDTH+DATA_WIDTH];
			assign refz_in_wire[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH] = in_ref_particle_position[i*3*DATA_WIDTH+3*DATA_WIDTH-1:i*3*DATA_WIDTH+2*DATA_WIDTH];
			assign neighborx_in_wire[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH] = in_neighbor_particle_position[i*3*DATA_WIDTH+DATA_WIDTH-1:i*3*DATA_WIDTH];
			assign neighbory_in_wire[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH] = in_neighbor_particle_position[i*3*DATA_WIDTH+2*DATA_WIDTH-1:i*3*DATA_WIDTH+DATA_WIDTH];
			assign neighborz_in_wire[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH] = in_neighbor_particle_position[i*3*DATA_WIDTH+3*DATA_WIDTH-1:i*3*DATA_WIDTH+2*DATA_WIDTH];
			end
	endgenerate
	
	// Force evaluation unit
	// Including filters and force evaluation pipeline
	RL_LJ_Force_Evaluation_Unit
	#(
		.DATA_WIDTH(DATA_WIDTH),
		// Dataset defined parameters
		.PARTICLE_ID_WIDTH(PARTICLE_ID_WIDTH),							// # of bit used to represent particle ID, 9*9*7 cells, each 4-bit, each cell have max of 200 particles, 8-bit
		// Filter parameters
		.NUM_FILTER(NUM_FILTER),
		.ARBITER_MSB(ARBITER_MSB),											// 2^(NUM_FILTER-1)
		.FILTER_BUFFER_DEPTH(FILTER_BUFFER_DEPTH),
		.FILTER_BUFFER_ADDR_WIDTH(FILTER_BUFFER_ADDR_WIDTH),
		.CUTOFF_2(CUTOFF_2),													// in IEEE floating point format
		// Force Evaluation parameters
		.SEGMENT_NUM(SEGMENT_NUM),
		.SEGMENT_WIDTH(SEGMENT_WIDTH),
		.BIN_NUM(BIN_NUM),
		.BIN_WIDTH(BIN_WIDTH),
		.LOOKUP_NUM(LOOKUP_NUM),											// SEGMENT_NUM * BIN_NUM
		.LOOKUP_ADDR_WIDTH(LOOKUP_ADDR_WIDTH),							// log(LOOKUP_NUM) / log 2
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
	RL_LJ_Force_Evaluation_Unit
	(
		.clk(clk),
		.rst(rst),
		.in_input_valid(in_input_pair_valid),										// INPUT [NUM_FILTER-1:0]
		.in_ref_particle_id(in_ref_particle_id),									// INPUT [NUM_FILTER*PARTICLE_ID_WIDTH-1:0]
		.in_neighbor_particle_id(in_neighbor_particle_id),						// INPUT [NUM_FILTER*PARTICLE_ID_WIDTH-1:0]
		.in_refx(refx_in_wire),															// INPUT [NUM_FILTER*DATA_WIDTH-1:0]
		.in_refy(refy_in_wire),															// INPUT [NUM_FILTER*DATA_WIDTH-1:0]
		.in_refz(refz_in_wire),															// INPUT [NUM_FILTER*DATA_WIDTH-1:0]
		.in_neighborx(neighborx_in_wire),											// INPUT [NUM_FILTER*DATA_WIDTH-1:0]
		.in_neighbory(neighbory_in_wire),											// INPUT [NUM_FILTER*DATA_WIDTH-1:0]
		.in_neighborz(neighborz_in_wire),											// INPUT [NUM_FILTER*DATA_WIDTH-1:0]
		.out_ref_particle_id(ref_particle_id_wire),							// OUTPUT [PARTICLE_ID_WIDTH-1:0]
		.out_neighbor_particle_id(out_neighbor_particle_id),				// OUTPUT [PARTICLE_ID_WIDTH-1:0]
		.out_LJ_Force_X(LJ_Force_X_wire),												// OUTPUT [DATA_WIDTH-1:0]
		.out_LJ_Force_Y(LJ_Force_Y_wire),												// OUTPUT [DATA_WIDTH-1:0]
		.out_LJ_Force_Z(LJ_Force_Z_wire),												// OUTPUT [DATA_WIDTH-1:0]
		.out_forceoutput_valid(evaluated_force_valid),							// OUTPUT
		.out_back_pressure_to_input(out_back_pressure_to_input),			// OUTPUT [NUM_FILTER-1:0]
		.out_all_buffer_empty_to_input(out_all_buffer_empty_to_input)	// OUTPUT
	);
	
/*	RL_LJ_Force_Evaluation_Unit_simple_filter
	#(
		.DATA_WIDTH(DATA_WIDTH),
		// Dataset defined parameters
		.PARTICLE_ID_WIDTH(PARTICLE_ID_WIDTH),							// # of bit used to represent particle ID, 9*9*7 cells, each 4-bit, each cell have max of 200 particles, 8-bit
		// Filter parameters
		.NUM_FILTER(NUM_FILTER),
		.ARBITER_MSB(ARBITER_MSB),											// 2^(NUM_FILTER-1)
		.FILTER_BUFFER_DEPTH(FILTER_BUFFER_DEPTH),
		.FILTER_BUFFER_ADDR_WIDTH(FILTER_BUFFER_ADDR_WIDTH),
		.CUTOFF_2(CUTOFF_2),													// in IEEE floating point format
		.CUTOFF_TIMES_SQRT_3(CUTOFF_TIMES_SQRT_3),					// sqrt(3) * CUTOFF
		.FIXED_POINT_WIDTH(FIXED_POINT_WIDTH),
		.FILTER_IN_PATCH_0_BITS(FILTER_IN_PATCH_0_BITS),			// Width = FIXED_POINT_WIDTH - 1 - 23
		.BOUNDING_BOX_X(BOUNDING_BOX_X),									// 12*9 = 108 in IEEE floating point
		.BOUNDING_BOX_Y(BOUNDING_BOX_Y),									// 12*9 = 108 in IEEE floating point
		.BOUNDING_BOX_Z(BOUNDING_BOX_Z),									// 12*7 = 84 in IEEE floating point
		// Force Evaluation parameters
		.SEGMENT_NUM(SEGMENT_NUM),
		.SEGMENT_WIDTH(SEGMENT_WIDTH),
		.BIN_NUM(BIN_NUM),
		.BIN_WIDTH(BIN_WIDTH),
		.LOOKUP_NUM(LOOKUP_NUM),											// SEGMENT_NUM * BIN_NUM
		.LOOKUP_ADDR_WIDTH(LOOKUP_ADDR_WIDTH)							// log(LOOKUP_NUM) / log 2
	)
	RL_LJ_Force_Evaluation_Unit
	(
		.clk(clk),
		.rst(rst),
		.input_valid(in_input_pair_valid),										// INPUT [NUM_FILTER-1:0]
		.ref_particle_id(in_ref_particle_id),									// INPUT [NUM_FILTER*PARTICLE_ID_WIDTH-1:0]
		.neighbor_particle_id(in_neighbor_particle_id),						// INPUT [NUM_FILTER*PARTICLE_ID_WIDTH-1:0]
		.refx(refx_in_wire),															// INPUT [NUM_FILTER*DATA_WIDTH-1:0]
		.refy(refy_in_wire),															// INPUT [NUM_FILTER*DATA_WIDTH-1:0]
		.refz(refz_in_wire),															// INPUT [NUM_FILTER*DATA_WIDTH-1:0]
		.neighborx(neighborx_in_wire),											// INPUT [NUM_FILTER*DATA_WIDTH-1:0]
		.neighbory(neighbory_in_wire),											// INPUT [NUM_FILTER*DATA_WIDTH-1:0]
		.neighborz(neighborz_in_wire),											// INPUT [NUM_FILTER*DATA_WIDTH-1:0]
		.ref_particle_id_out(ref_particle_id_wire),							// OUTPUT [PARTICLE_ID_WIDTH-1:0]
		.neighbor_particle_id_out(out_neighbor_particle_id),				// OUTPUT [PARTICLE_ID_WIDTH-1:0]
		.LJ_Force_X(LJ_Force_X_wire),												// OUTPUT [DATA_WIDTH-1:0]
		.LJ_Force_Y(LJ_Force_Y_wire),												// OUTPUT [DATA_WIDTH-1:0]
		.LJ_Force_Z(LJ_Force_Z_wire),												// OUTPUT [DATA_WIDTH-1:0]
		.forceoutput_valid(evaluated_force_valid),							// OUTPUT
		.out_back_pressure_to_input(out_back_pressure_to_input),			// OUTPUT [NUM_FILTER-1:0]
		.out_all_buffer_empty_to_input(out_all_buffer_empty_to_input)	// OUTPUT
	);
*/	
	// Partial force accumulator
	// Working on reference particle
	Partial_Force_Acc
	#(
		.DATA_WIDTH(DATA_WIDTH),
		.PARTICLE_ID_WIDTH(PARTICLE_ID_WIDTH)							// # of bit used to represent particle ID, 9*9*7 cells, each 4-bit, each cell have max of 200 particles, 8-bit
	)
	Partial_Force_Acc
	(
		.clk(clk),
		.rst(rst),
		.in_input_valid(evaluated_force_valid),
		.in_particle_id(ref_particle_id_wire),
		.in_partial_force_x(LJ_Force_X_wire),
		.in_partial_force_y(LJ_Force_Y_wire),
		.in_partial_force_z(LJ_Force_Z_wire),
		.out_particle_id(out_ref_particle_id),
		.out_particle_acc_force_x(out_ref_LJ_Force_X),
		.out_particle_acc_force_y(out_ref_LJ_Force_Y),
		.out_particle_acc_force_z(out_ref_LJ_Force_Z),
		.out_acc_force_valid(out_ref_force_valid)						// only set as valid when the particle_id changes, which means the accumulation for the current particle is done
	);

endmodule


