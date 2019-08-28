/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: RL_LJ_Evaluation_OpenCL_Top.v
//
//	Function: 
//				Top module for OpenCL evaluation.
//				Contains a single filter_logic unit (with buffer) and a single LJ Evaluation Pipeline.
//
// OpenCL HDL Lib setup:
//				Stall-Free: No. Since there is a filter logic, there's no guarantee a valid output appear on the output port after a fixed amount of cycles from input.
//				Interacting with OpenCL control ports: Input and Output buffer
//
// OpenCL Ports clarification:
//				Connect to upstream: ivalid(input), oready(output)
//				Connect to downstream: iready(input), ovalid(output)
//				When ivalid = 1 and oready = 0, the upstream module is expected to hold the values of ivalid, A, and B in the next clock cycle.
//				When ovalid = 1 and iready = 0, the myMod RLT module is expected to hold the valid of the ovalid and C signals in the next clock cycle.
//				myMod module will assert oready for a single clock cycle to indicate it is ready for an active cycle. Cycles during which myMod module is ready for data are called ready cycles. During ready cycles, the module above myMod module can assert ivalid to send data to myMod.
//
//	Purpose:
//				OpenCL HDL library testing
//
// Data Organization:
//				Filter buffer: MSB-LSB: {ref_particle_id, neighbor_particle_id, r2, dz, dy, dx}
//				Input buffer: MSB-LSB: {ref_particle_id, neighbor_particle_id, refx, refy, refz, neighborx, neighbory, neighborz}
//				Output buffer: MSB-LSB: {ref_particle_id, neighbor_particle_id, LJ_Force_X, LJ_Force_Y, LJ_Force_Z}
//
// Used by:
//				N/A
//
// Dependency:
//				Filter_Logic.v
//				RL_LJ_Evaluate_Pairs_1st_Order.v
//
// Testbench:
//				TBD
//
// Timing:
//				RL_LJ_Evaluate_Pairs_1st_Order: 14 cycles
//				r2_compute inside Filter_Logic: 17 cycles				
//
// Created by: 
//				Chen Yang 12/09/18
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module RL_LJ_Evaluation_OpenCL_Top
#(
	parameter DATA_WIDTH 					= 32,
	// Dataset defined parameters
	parameter CELL_ID_WIDTH					= 4,											// log(NUM_NEIGHBOR_CELLS)
	parameter MAX_CELL_PARTICLE_NUM		= 290,										// The maximum # of particles can be in a cell
	parameter CELL_ADDR_WIDTH				= 9,											// log(MAX_CELL_PARTICLE_NUM)
	parameter PARTICLE_ID_WIDTH			= CELL_ID_WIDTH*3+CELL_ADDR_WIDTH,	// # of bit used to represent particle ID, 9*9*7 cells, each 4-bit, each cell have max of 200 particles, 8-bit
	// In & Out buffer parameters
	parameter INPUT_BUFFER_DEPTH			= 4,
	parameter INPUT_BUFFER_ADDR_WIDTH	= 2,											// log INPUT_BUFFER_DEPTH / log 2
	parameter OUTPUT_BUFFER_DEPTH			= 64,											// This one should be large enough to hold all the values in the pipeline 
	parameter OUTPUT_BUFFER_ADDR_WIDTH	= 6,											// log OUTPUT_BUFFER_DEPTH / log 2
	// Filter parameters
	parameter FILTER_BUFFER_DEPTH 		= 32,
	parameter FILTER_BUFFER_ADDR_WIDTH	= 5,
	parameter CUTOFF_2 						= 32'h43100000,							// (12^2=144 in IEEE floating point)
	// Force Evaluation parameters
	parameter SEGMENT_NUM					= 14,
	parameter SEGMENT_WIDTH					= 4,
	parameter BIN_NUM							= 256,
	parameter BIN_WIDTH						= 8,
	parameter LOOKUP_NUM						= SEGMENT_NUM * BIN_NUM,				// SEGMENT_NUM * BIN_NUM
	parameter LOOKUP_ADDR_WIDTH			= SEGMENT_WIDTH + BIN_WIDTH			// log LOOKUP_NUM / log 2
)
(
	input clock,
	input resetn,
	// OpenCL ports
	input ivalid,						// Connect to upstream
	input iready,						// Connect to downstream
	output ovalid,						// Connect to downstream
	output oready,						//	Connect to upstream
	// Data ports
/*	
	input [PARTICLE_ID_WIDTH-1:0] in_ref_particle_id,
	input [PARTICLE_ID_WIDTH-1:0] in_neighbor_particle_id,
	input [DATA_WIDTH-1:0] in_refx,
	input [DATA_WIDTH-1:0] in_refy,
	input [DATA_WIDTH-1:0] in_refz,
	input [DATA_WIDTH-1:0] in_neighborx,
	input [DATA_WIDTH-1:0] in_neighbory,
	input [DATA_WIDTH-1:0] in_neighborz,
	output [PARTICLE_ID_WIDTH-1:0] out_ref_particle_id,
	output [PARTICLE_ID_WIDTH-1:0] out_neighbor_particle_id,
	output [DATA_WIDTH-1:0] out_LJ_Force_X,
	output [DATA_WIDTH-1:0] out_LJ_Force_Y,
	output [DATA_WIDTH-1:0] out_LJ_Force_Z
*/	
	input [2*DATA_WIDTH-1:0] in_particle_id,
	input [4*DATA_WIDTH-1:0] in_reference_pos,
	input [4*DATA_WIDTH-1:0] in_neighbor_pos,
//	output [2*DATA_WIDTH-1:0] out_particle_id,
	output [4*DATA_WIDTH-1:0] out_forceoutput
);
	
	assign out_forceoutput = in_reference_pos + in_neighbor_pos;


endmodule