#include <fstream>
#include <math.h>
#include <ctime>
#include <string>
#include <stdlib.h>

#include "Gen_Sim_top.h"

using namespace std;

int Gen_Sim_Top(int num_cell_x, int num_cell_y, int num_cell_z, std::string* common_path){

	// Setup Generating file
	char filename[100];
	sprintf(filename,"RL_LJ_Intergrated_Top.v");

	std::string path = *common_path + "/" + std::string(filename);
	std::ofstream fout;
	fout.open(path.c_str());
	if (fout.fail()){
		printf("open %s failed, exiting\n", path.c_str());
		exit(-1);
	}

	// Global Parameters
	int TOTAL_CELL_NUM = num_cell_x * num_cell_y * num_cell_z;
	
	// Start Generating
	fout << "/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////\n";
	fout << "// Module: RL_LJ_Intergrated_Top.v\n";
	fout << "//\n";
	fout << "//	Function:\n";
	fout << "//\t\t\t\tIntegrated top module holding all the cells in the simulation space\n";
	fout << "//\n";
	fout << "//	Purpose:\n";
	fout << "//\t\t\t\tFor real simulation with all the dataset\n";
	fout << "//\t\t\t\tTiming testing with the integrated system\n";
	fout << "//\n";
	fout << "// Data Organization:\n";
	fout << "//\t\t\t\tAddress 0 for each cell module: # of particles in the cell.\n";
	fout << "//\t\t\t\tMSB-LSB: {posz, posy, posx}\n";
	fout << "//\n";
	fout << "// Used by:\n";
	fout << "//\t\t\t\tN\A\n";
	fout << "//\n";
	fout << "// Dependency:\n";
	fout << "//\t\t\t\tRL_LJ_Evaluation_Unit.v\n";
	fout << "//\t\t\t\tParticle_Pair_Gen_HalfShell.v\n";
	fout << "//\t\t\t\tMotion_Update.v\n";
	fout << "//\t\t\t\tcell_x_y_z.v\n";
	fout << "//\t\t\t\tForce_Cache_x_y_z.v\n";
	fout << "//\t\t\t\tVelocity_Cache_x_y_z.v\n";
	fout << "//\n";
	fout << "// Testbench:\n";
	fout << "//\t\t\t\tTBD\n";
	fout << "//\n";
	fout << "// Timing:\n";
	fout << "//\t\t\t\tTBD\n";
	fout << "//\n";
	fout << "// Created by:\n";
	fout << "//\t\t\t\tChen Yang's Script (Gen_Sim_Top.cpp)\n";
	fout << "/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////\n\n";

	fout << "module RL_LJ_Intergrated_Top\n";
	fout << "#(\n";
	fout << "\tparameter DATA_WIDTH 					= 32,\n";
	fout << "\t// Simulation parameters\n";
	fout << "\tparameter TIME_STEP 					= 32'h27101D7D,							// 2fs time step\n";
	fout << "\t// The home cell this unit is working on\n";
	fout << "\tparameter CELL_X						= 4'd2,\n";
	fout << "\tparameter CELL_Y						= 4'd2,\n";
	fout << "\tparameter CELL_Z						= 4'd2,\n";
	fout << "\t// High level parameters\n";
	fout << "\tparameter NUM_EVAL_UNIT					= 1,									// # of evaluation units in the design\n";
	fout << "\t// Dataset defined parameters\n";
	fout << "\tparameter MAX_CELL_COUNT_PER_DIM 		= 5,									// Maximum cell count among the 3 dimensions\n";
	fout << "\tparameter NUM_NEIGHBOR_CELLS			= 13,									// # of neighbor cells per home cell, for Half-shell method, is 13\n";
	fout << "\tparameter CELL_ID_WIDTH					= 3,									// log(NUM_NEIGHBOR_CELLS)\n";
	fout << "\tparameter MAX_CELL_PARTICLE_NUM			= 290,									// The maximum # of particles can be in a cell\n";
	fout << "\tparameter CELL_ADDR_WIDTH				= 9,									// log(MAX_CELL_PARTICLE_NUM)\n";
	fout << "\tparameter PARTICLE_ID_WIDTH				= CELL_ID_WIDTH*3+CELL_ADDR_WIDTH,		// # of bit used to represent particle ID, 9*9*7 cells, each 4-bit, each cell have max of 220 particles, 8-bit\n";
	fout << "\t// Filter parameters\n";
	fout << "\tparameter NUM_FILTER					= 8,	//4\n";
	fout << "\tparameter ARBITER_MSB 					= 128,	//8								// 2^(NUM_FILTER-1)\n";
	fout << "\tparameter FILTER_BUFFER_DEPTH 			= 32,\n";
	fout << "\tparameter FILTER_BUFFER_ADDR_WIDTH		= 5,\n";
	fout << "\tparameter CUTOFF_2 						= 32'h43100000,							// (12^2=144 in IEEE floating point)\n";
	fout << "\t// Force Evaluation parameters\n";
	fout << "\tparameter SEGMENT_NUM					= 14,\n";
	fout << "\tparameter SEGMENT_WIDTH					= 4,\n";
	fout << "\tparameter BIN_NUM						= 256,\n";
	fout << "\tparameter BIN_WIDTH						= 8,\n";
	fout << "\tparameter LOOKUP_NUM					= SEGMENT_NUM * BIN_NUM,				// SEGMENT_NUM * BIN_NUM\n";
	fout << "\tparameter LOOKUP_ADDR_WIDTH				= SEGMENT_WIDTH + BIN_WIDTH,			// log LOOKUP_NUM / log 2\n";
	fout << "\t// Force (accmulation) cache parameters\n";
	fout << "\tparameter FORCE_CACHE_BUFFER_DEPTH		= 16,									// Force cache input buffer depth, for partial force accumulation\n";
	fout << "\tparameter FORCE_CACHE_BUFFER_ADDR_WIDTH	= 4										// log(FORCE_CACHE_BUFFER_DEPTH) / log 2\n";
	fout << ")\n";
	fout << "(\n";
	fout << "\tinput clk,\n";
	fout << "\tinput rst,\n";
	fout << "\tinput start,\n";
	fout << "\t// These are all temp output ports";
	fout << "\toutput [NUM_EVAL_UNIT*PARTICLE_ID_WIDTH-1:0] ref_particle_id,\n";
	fout << "\toutput [NUM_EVAL_UNIT*DATA_WIDTH-1:0] ref_LJ_Force_X,\n";
	fout << "\toutput [NUM_EVAL_UNIT*DATA_WIDTH-1:0] ref_LJ_Force_Y,\n";
	fout << "\toutput [NUM_EVAL_UNIT*DATA_WIDTH-1:0] ref_LJ_Force_Z,\n";
	fout << "\toutput [NUM_EVAL_UNIT-1:0] ref_forceoutput_valid,\n";
	fout << "\toutput [NUM_EVAL_UNIT*PARTICLE_ID_WIDTH-1:0] neighbor_particle_id,\n";
	fout << "\toutput [NUM_EVAL_UNIT*DATA_WIDTH-1:0] neighbor_LJ_Force_X,\n";
	fout << "\toutput [NUM_EVAL_UNIT*DATA_WIDTH-1:0] neighbor_LJ_Force_Y,\n";
	fout << "\toutput [NUM_EVAL_UNIT*DATA_WIDTH-1:0] neighbor_LJ_Force_Z,\n";
	fout << "\toutput [NUM_EVAL_UNIT-1:0] neighbor_forceoutput_valid,\n";
	fout << "\t// Done signals\n";
	fout << "\t// When entire home cell is done processing, this will keep high until the next time 'start' signal turn high\n";
	fout << "\toutput out_home_cell_evaluation_done,\n";
	fout << "\t// When motion update is done processing, remain high until the next motion update starts\n";
	fout << "\toutput out_motion_update_done,\n";
	fout << "\t// Dummy signal selecting which cell is the home cell\n";
	fout << "\t// Need a logic to replace this, generate by out_Motion_Update_cur_cell\n";
	fout << "\tinput [7:0] in_sel,\n";
	fout << "\t// Dummy output for motion update\n";
	fout << "\toutput [3*CELL_ID_WIDTH-1:0] out_Motion_Update_cur_cell\n";
	fout << ");\n\n";

	// Implement signals between Position Cache and Particle Pair gen
	fout << "\t///////////////////////////////////////////////////////////////////////////////////////////////\n";
	fout << "\t// Signals between Cell Module and FSM\n";
	fout << "\t///////////////////////////////////////////////////////////////////////////////////////////////\n";
	fout << "\t//// Signals connect from cell module to FSM\n";
	fout << "\t// Position Data\n";
	fout << "\t// Order: MSB->LSB {333,332,331,323,322,321,313,312,311,233,232,231,223,222} Homecell is on LSB side\n";
	fout << "\twire ["<< TOTAL_CELL_NUM << "*3*DATA_WIDTH-1:0] Position_Cache_readout_position;\n";
	fout << "\t//// Signals connect from FSM to cell modules\n";
	fout << "\twire FSM_to_Cell_rden;\n";
	fout << "\t// Read Address to cells\n";
	fout << "\twire [CELL_ADDR_WIDTH-1:0] FSM_to_Cell_read_addr;\n";
	fout << "\n\n";

	// Implement signals between Force Evaluation and Particle Pair gen
	fout << "\t///////////////////////////////////////////////////////////////////////////////////////////////\n";
	fout << "\t// Signals between Force Evaluation Unit and Particle Pairs Generation\n";
	fout << "\t///////////////////////////////////////////////////////////////////////////////////////////////\n";
	fout << "\t//// Signals connect from FSM to Force Evaluation module\n";
	fout << "\twire [NUM_FILTER*3*DATA_WIDTH-1:0] FSM_to_ForceEval_ref_particle_position;\n";
	fout << "\twire [NUM_FILTER*3*DATA_WIDTH-1:0] FSM_to_ForceEval_neighbor_particle_position;\n";
	fout << "\twire [NUM_FILTER*PARTICLE_ID_WIDTH-1:0] FSM_to_ForceEval_ref_particle_id;			// {cell_x, cell_y, cell_z, ref_particle_rd_addr}\n";
	fout << "\twire [NUM_FILTER*PARTICLE_ID_WIDTH-1:0] FSM_to_ForceEval_neighbor_particle_id;		// {cell_x, cell_y, cell_z, neighbor_particle_rd_addr}\n";
	fout << "\twire [NUM_FILTER-1:0] FSM_to_ForceEval_input_pair_valid;			// Signify the valid of input particle data, this signal should have 1 cycle delay of the rden signal, thus wait for the data read out from BRAM\n";
	fout << "\t//// Signals connect from Force Evaluation module to FSM\n";
	fout << "\twire [NUM_FILTER-1:0] ForceEval_to_FSM_backpressure;\n";
	fout << "\twire ForceEval_to_FSM_all_buffer_empty;\n";
	fout << "\t//// Signals handles the reference output valid\n";
	fout << "\t// Special signal to handle the output valid for the last reference particle\n";
	fout << "\twire FSM_almost_done_generation;\n";
	fout << "\t// Signal connect to the output of Force evaluation valid\n";
	fout << "\twire ForceEval_ref_output_valid;\n";
	fout << "\t// Generate the 'ref_forceoutput_valid' signal\n";
	fout << "\tassign ref_forceoutput_valid = ForceEval_ref_output_valid || FSM_almost_done_generation;\n";
	fout << "\t\n\n";

	// Implement signals Connect to Motion Update
	fout << "\t///////////////////////////////////////////////////////////////////////////////////////////////\n";
	fout << "\t// Motion Update Signals\n";
	fout << "\t///////////////////////////////////////////////////////////////////////////////////////////////\n";
	fout << "\t// Use this signal to locate the rising edge of out_home_cell_evaluation_done signal\n";
	fout << "\t// only start motion update when rising edge is detected\n";
	fout << "\treg prev_out_home_cell_evaluation_done;\n";
	fout << "\talways@(posedge clk)\n";
	fout << "\t\tbegin\n";
	fout << "\t\tprev_out_home_cell_evaluation_done <= out_home_cell_evaluation_done;\n";
	fout << "\tend\n";
	fout << "\twire Motion_Update_start;\n";
	fout << "\tassign Motion_Update_start = (out_home_cell_evaluation_done && prev_out_home_cell_evaluation_done == 0);\n";
	fout << "\t// The enable singal from Motion Update module, this signal will remain high during the entire motion update process\n";
	fout << "\twire Motion_Update_enable;\n";
	fout << "\twire [3*CELL_ID_WIDTH-1:0] Motion_Update_cur_cell;\n";
	fout << "\t// Motion Update read in data from caches\n";
	fout << "\twire [CELL_ADDR_WIDTH-1:0] Motion_Update_position_read_addr;\n";
	fout << "\twire Motion_Update_position_read_en;\n";
	fout << "\treg [3*DATA_WIDTH-1:0] Motion_Update_position_data;\n";
	fout << "\twire [CELL_ADDR_WIDTH-1:0] Motion_Update_force_read_addr;\n";
	fout << "\twire Motion_Update_force_read_en;\n";
	fout << "\treg [3*DATA_WIDTH-1:0] Motion_Update_force_data;\n";
	fout << "\twire [CELL_ADDR_WIDTH-1:0] Motion_Update_velocity_read_addr;\n";
	fout << "\twire Motion_Update_velocity_read_en;\n";
	fout << "\treg [3*DATA_WIDTH-1:0] Motion_Update_velocity_data;\n";
	fout << "\t// Motion Update write back data\n";
	fout << "\twire [3*CELL_ID_WIDTH-1:0] Motion_Update_dst_cell;\n";
	fout << "\twire [3*DATA_WIDTH-1:0] Motion_Update_out_velocity_data;\n";
	fout << "\twire Motion_Update_out_velocity_data_valid;\n";
	fout << "\twire [3*DATA_WIDTH-1:0] Motion_Update_out_position_data;\n";
	fout << "\twire Motion_Update_out_position_data_valid;\n";
	fout << "\t// Motion Update select input from force caches\n";
	fout << "\treg ["<< TOTAL_CELL_NUM-1 << ":0] wire_motion_update_to_cache_read_force_request;\n";
	fout << "\twire ["<< TOTAL_CELL_NUM-1 << ":0] wire_cache_to_motion_update_partial_force_valid;\n";
	fout << "\twire ["<< TOTAL_CELL_NUM << "*3*DATA_WIDTH-1:0] wire_cache_to_motion_update_partial_force;\n";
	fout << "\twire ["<< TOTAL_CELL_NUM << "*PARTICLE_ID_WIDTH-1:0] wire_cache_to_motion_update_particle_id;\n";
	fout << "\twire ["<< TOTAL_CELL_NUM << "*3*DATA_WIDTH-1:0] wire_cache_to_motion_update_velocity_data;\n";
	fout << "\talways@(*)\n";
	fout << "\t\tbegin\n";
	fout << "\t\twire_motion_update_to_cache_read_force_request <= Motion_Update_enable << in_sel;\n";
	fout << "\t\tcase(in_sel)\n";
	for(int cell_ptr = 0; cell_ptr < TOTAL_CELL_NUM; cell_ptr++){
		fout << "\t\t\t" << cell_ptr << ":\n";
		fout << "\t\t\t\tbegin\n";
		fout << "\t\t\t\tMotion_Update_position_data <= Position_Cache_readout_position["<<cell_ptr+1<<"*3*DATA_WIDTH-1:"<<cell_ptr<<"*3*DATA_WIDTH];\n";
		fout << "\t\t\t\tMotion_Update_force_data <= wire_cache_to_motion_update_partial_force["<<cell_ptr+1<<"*3*DATA_WIDTH-1:"<<cell_ptr<<"*3*DATA_WIDTH];\n";
		fout << "\t\t\t\tMotion_Update_velocity_data <= wire_cache_to_motion_update_velocity_data["<<cell_ptr+1<<"*3*DATA_WIDTH-1:"<<cell_ptr<<"*3*DATA_WIDTH];\n";
		fout << "\t\t\t\tend\n";
	}
	fout << "\t\t\tdefault:\n";
	fout << "\t\t\t\tbegin\n";
	fout << "\t\t\t\tMotion_Update_position_data <= Position_Cache_readout_position[1*3*DATA_WIDTH-1:0*3*DATA_WIDTH];\n";
	fout << "\t\t\t\tMotion_Update_force_data <= wire_cache_to_motion_update_partial_force[1*3*DATA_WIDTH-1:0*3*DATA_WIDTH];\n";
	fout << "\t\t\t\tMotion_Update_velocity_data <= wire_cache_to_motion_update_velocity_data[1*3*DATA_WIDTH-1:0*3*DATA_WIDTH];\n";
	fout << "\t\t\t\tend\n";
	fout << "\t\tendcase\n";
	fout << "\t\tend\n";
	fout << "\n\n";

	// Instantiate Particle Pair Gen Unit
	fout << "\t///////////////////////////////////////////////////////////////////////////////////////////////\n";
	fout << "\t// FSM for generating particle pairs\n";
	fout << "\t///////////////////////////////////////////////////////////////////////////////////////////////\n";
	fout << "\tParticle_Pair_Gen_Dummy\n";
	fout << "\t#(\n";
	fout << "\t\t.DATA_WIDTH(DATA_WIDTH),\n";
	fout << "\t\t// The # of cells in each dimension\n";
	fout << "\t\t.CELL_X_NUM("<<num_cell_x<<"),\n";
	fout << "\t\t.CELL_Y_NUM("<<num_cell_x<<"),\n";
	fout << "\t\t.CELL_Z_NUM("<<num_cell_x<<"),\n";
	fout << "\t\t.TOTAL_CELL_NUM("<<TOTAL_CELL_NUM<<"),\n";
	fout << "\t\t// High level parameters\n";
	fout << "\t\t.NUM_EVAL_UNIT(NUM_EVAL_UNIT),							// # of evaluation units in the design\n";
	fout << "\t\t// Dataset defined parameters\n";
	fout << "\t\t.NUM_NEIGHBOR_CELLS(NUM_NEIGHBOR_CELLS),				// # of neighbor cells per home cell, for Half-shell method, is 13\n";
	fout << "\t\t.CELL_ID_WIDTH(CELL_ID_WIDTH),							// log(NUM_NEIGHBOR_CELLS)\n";
	fout << "\t\t.MAX_CELL_PARTICLE_NUM(MAX_CELL_PARTICLE_NUM),\n";
	fout << "\t\t.CELL_ADDR_WIDTH(CELL_ADDR_WIDTH),						// log(MAX_CELL_PARTICLE_NUM)\n";
	fout << "\t\t.PARTICLE_ID_WIDTH(PARTICLE_ID_WIDTH),					// # of bit used to represent particle ID, 9*9*7 cells, each 4-bit, each cell have max of 220 particles, 8-bit\n";
	fout << "\t\t// Filter parameters\n";
	fout << "\t\t.NUM_FILTER(NUM_FILTER),\n";
	fout << "\t\t.ARBITER_MSB(ARBITER_MSB),									// 2^(NUM_FILTER-1)\n";
	fout << "\t\t.FILTER_BUFFER_DEPTH(FILTER_BUFFER_DEPTH),\n";
	fout << "\t\t.FILTER_BUFFER_ADDR_WIDTH(FILTER_BUFFER_ADDR_WIDTH)\n";
	fout << "\t)\n";
	fout << "\tParticle_Pair_Gen\n";
	fout << "\t(\n";
	fout << "\t\t.clk(clk),\n";
	fout << "\t\t.rst(rst),\n";
	fout << "\t\t.start(start),\n";
	fout << "\t\t// Ports connect to Cell Memory Module\n";
	fout << "\t\t// Order: MSB->LSB {333,332,331,323,322,321,313,312,311,233,232,231,223,222} Homecell is on LSB side\n";
	fout << "\t\t.Cell_to_FSM_readout_particle_position(Position_Cache_readout_position),					// input  [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] \n";
	fout << "\t\t.FSM_to_Cell_read_addr(FSM_to_Cell_read_addr),																// output [(NUM_NEIGHBOR_CELLS+1)*CELL_ADDR_WIDTH-1:0] \n";
	fout << "\t\t.FSM_to_Cell_rden(FSM_to_Cell_rden),\n";
	fout << "\t\t// Ports connect to Force Evaluation Unit\n";
	fout << "\t\t.ForceEval_to_FSM_backpressure(ForceEval_to_FSM_backpressure),											// input  [NUM_FILTER-1:0]  								// Backpressure signal from Force Evaluation Unit\n";
	fout << "\t\t.ForceEval_to_FSM_all_buffer_empty(ForceEval_to_FSM_all_buffer_empty),								// input															// Only when all the filter buffers are empty, then the FSM will move on to the next reference particle\n";
	fout << "\t\t.FSM_to_ForceEval_ref_particle_position(FSM_to_ForceEval_ref_particle_position),  				// output [NUM_FILTER*3*DATA_WIDTH-1:0] \n";
	fout << "\t\t.FSM_to_ForceEval_neighbor_particle_position(FSM_to_ForceEval_neighbor_particle_position),	// output [NUM_FILTER*3*DATA_WIDTH-1:0] \n";
	fout << "\t\t.FSM_to_ForceEval_ref_particle_id(FSM_to_ForceEval_ref_particle_id),									// output [NUM_FILTER*PARTICLE_ID_WIDTH-1:0] 		// {cell_z, cell_y, cell_x, ref_particle_rd_addr}\n";
	fout << "\t\t.FSM_to_ForceEval_neighbor_particle_id(FSM_to_ForceEval_neighbor_particle_id),					// output [NUM_FILTER*PARTICLE_ID_WIDTH-1:0] 		// {cell_z, cell_y, cell_x, neighbor_particle_rd_addr}\n";
	fout << "\t\t.FSM_to_ForceEval_input_pair_valid(FSM_to_ForceEval_input_pair_valid),								// output reg [NUM_FILTER-1:0]   						// Signify the valid of input particle data, this signal should have 1 cycle delay of the rden signal, thus wait for the data read out from BRAM\n";
	fout << "\t\t// Special signal to handle the output valid for the last reference particle\n";
	fout << "\t\t.FSM_almost_done_generation(FSM_almost_done_generation),\n";
	fout << "\t\t// Ports to top level modules\n";
	fout << "\t\t.done(out_home_cell_evaluation_done)\n";
	fout << "\t);\n";
	

	fout << "\n\n";

	// Instantiate Force Evaluation Unit
	fout << "\t///////////////////////////////////////////////////////////////////////////////////////////////\n";
	fout << "\t// Force evaluation and accumulation unit\n";
	fout << "\t///////////////////////////////////////////////////////////////////////////////////////////////\n";
	fout << "\tRL_LJ_Evaluation_Unit\n";
	fout << "\t#(\n";
	fout << "\t\t.DATA_WIDTH(DATA_WIDTH),\n";
	fout << "\t\t// The home cell this unit is working on (Not been used so far)\n";
	fout << "\t\t.CELL_X(CELL_X),\n";
	fout << "\t\t.CELL_Y(CELL_Y),\n";
	fout << "\t\t.CELL_Z(CELL_Z),\n";
	fout << "\t\t// Dataset defined parameters\n";
	fout << "\t\t.PARTICLE_ID_WIDTH(PARTICLE_ID_WIDTH),\n";
	fout << "\t\t// Filter parameters\n";
	fout << "\t\t.NUM_FILTER(NUM_FILTER),\n";
	fout << "\t\t.ARBITER_MSB(ARBITER_MSB),\n";
	fout << "\t\t.FILTER_BUFFER_DEPTH(FILTER_BUFFER_DEPTH),\n";
	fout << "\t\t.FILTER_BUFFER_ADDR_WIDTH(FILTER_BUFFER_ADDR_WIDTH),\n";
	fout << "\t\t.CUTOFF_2(CUTOFF_2),\n";
	fout << "\t\t// Force Evaluation parameters\n";
	fout << "\t\t.SEGMENT_NUM(SEGMENT_NUM),\n";
	fout << "\t\t.SEGMENT_WIDTH(SEGMENT_WIDTH),\n";
	fout << "\t\t.BIN_NUM(BIN_NUM),\n";
	fout << "\t\t.BIN_WIDTH(BIN_WIDTH),\n";
	fout << "\t\t.LOOKUP_NUM(LOOKUP_NUM),\n";
	fout << "\t\t.LOOKUP_ADDR_WIDTH(LOOKUP_ADDR_WIDTH)\n";
	fout << "\t)\n";
	fout << "\tRL_LJ_Evaluation_Unit\n";
	fout << "\t(\n";
	fout << "\t\t.clk(clk),\n";
	fout << "\t\t.rst(rst),\n";
	fout << "\t\t.in_input_pair_valid(FSM_to_ForceEval_input_pair_valid),						//input  [NUM_FILTER-1:0]\n";
	fout << "\t\t.in_ref_particle_id(FSM_to_ForceEval_ref_particle_id),							//input  [NUM_FILTER*PARTICLE_ID_WIDTH-1:0]\n";
	fout << "\t\t.in_neighbor_particle_id(FSM_to_ForceEval_neighbor_particle_id),				//input  [NUM_FILTER*PARTICLE_ID_WIDTH-1:0]\n";
	fout << "\t\t.in_ref_particle_position(FSM_to_ForceEval_ref_particle_position),				//input  [NUM_FILTER*3*DATA_WIDTH-1:0]			// {refz, refy, refx}\n";
	fout << "\t\t.in_neighbor_particle_position(FSM_to_ForceEval_neighbor_particle_position),	//input  [NUM_FILTER*3*DATA_WIDTH-1:0]			// {neighborz, neighbory, neighborx}\n";
	fout << "\t\t.out_back_pressure_to_input(ForceEval_to_FSM_backpressure),					//output [NUM_FILTER-1:0] 						// backpressure signal to stop new data arrival from particle memory\n";
	fout << "\t\t.out_all_buffer_empty_to_input(ForceEval_to_FSM_all_buffer_empty),				//output										// Only when all the filter buffers are empty, then the FSM will move on to the next reference particle\n";
	fout << "\t\t// Output accumulated force for reference particles\n";
	fout << "\t\t// The output value is the accumulated value\n";
	fout << "\t\t// Connected to home cell\n";
	fout << "\t\t.out_ref_particle_id(ref_particle_id),						//output [PARTICLE_ID_WIDTH-1:0]\n";
	fout << "\t\t.out_ref_LJ_Force_X(ref_LJ_Force_X),						//output [DATA_WIDTH-1:0]\n";
	fout << "\t\t.out_ref_LJ_Force_Y(ref_LJ_Force_Y),						//output [DATA_WIDTH-1:0]\n";
	fout << "\t\t.out_ref_LJ_Force_Z(ref_LJ_Force_Z),						//output [DATA_WIDTH-1:0]\n";
	fout << "\t\t.out_ref_force_valid(ForceEval_ref_output_valid),			//output\n";
	fout << "\t\t// Output partial force for neighbor particles\n";
	fout << "\t\t// The output value should be the minus value of the calculated force data\n";
	fout << "\t\t// Connected to neighbor cells, if the neighbor paritle comes from the home cell, then discard, since the value will be recalculated when evaluating this particle as reference one\n";
	fout << "\t\t.out_neighbor_particle_id(neighbor_particle_id),			//output [PARTICLE_ID_WIDTH-1:0]\n";
	fout << "\t\t.out_neighbor_LJ_Force_X(neighbor_LJ_Force_X),				//output [DATA_WIDTH-1:0]\n";
	fout << "\t\t.out_neighbor_LJ_Force_Y(neighbor_LJ_Force_Y),				//output [DATA_WIDTH-1:0]\n";
	fout << "\t\t.out_neighbor_LJ_Force_Z(neighbor_LJ_Force_Z),				//output [DATA_WIDTH-1:0]\n";
	fout << "\t\t.out_neighbor_force_valid(neighbor_forceoutput_valid)		//output\n";
	fout << "\t);\n\n";

	// Instantiate Motion Update Unit
	fout << "\t///////////////////////////////////////////////////////////////////////////////////////////////\n";
	fout << "\t// Motion Update Unit\n";
	fout << "\t// This Unit can work on multiple cells, or a single cell\n";
	fout << "\t///////////////////////////////////////////////////////////////////////////////////////////////\n";
	fout << "\t// Assign output signal\n";
	fout << "\tassign out_Motion_Update_cur_cell = Motion_Update_cur_cell;\n";
	fout << "\tMotion_Update\n";
	fout << "\t#(\n";
	fout << "\t\t.DATA_WIDTH(DATA_WIDTH),									// Data width of a single force value, 32-bit\n";
	fout << "\t\t.TIME_STEP(TIME_STEP),										// 2fs time step\n";
	fout << "\t\t// Cell id this unit related to\n";
	fout << "\t\t.CELL_X(CELL_X),\n";
	fout << "\t\t.CELL_Y(CELL_Y),\n";
	fout << "\t\t.CELL_Z(CELL_Z),\n";
	fout << "\t\t// Dataset defined parameters\n";
	fout << "\t\t.MAX_CELL_COUNT_PER_DIM(MAX_CELL_COUNT_PER_DIM),			// Maximum cell count among the 3 dimensions\n";
	fout << "\t\t.CELL_ID_WIDTH(CELL_ID_WIDTH),								// log(NUM_NEIGHBOR_CELLS)\n";
	fout << "\t\t.MAX_CELL_PARTICLE_NUM(MAX_CELL_PARTICLE_NUM),				// The maximum # of particles can be in a cell\n";
	fout << "\t\t.CELL_ADDR_WIDTH(CELL_ADDR_WIDTH),							// log(MAX_CELL_PARTICLE_NUM)\n";
	fout << "\t\t.PARTICLE_ID_WIDTH(PARTICLE_ID_WIDTH)						// # of bit used to represent particle ID, 9*9*7 cells, each 4-bit, each cell have max of 220 particles, 8-bit\n";
	fout << "\t)\n";
	fout << "\tMotion_Update\n";
	fout << "\t(\n";
	fout << "\t\t.clk(clk),\n";
	fout << "\t\t.rst(rst),\n";
	fout << "\t\t.motion_update_start(Motion_Update_start),					// Start Motion update after the home cell is done evaluating\n";
	fout << "\t\t.motion_update_done(out_motion_update_done),					// Remain high until the next motion update starts\n";
	fout << "\t\t// Output the targeting home cell\n";
	fout << "\t\t// When this module is responsible for multiple cells, then the control signal is broadcast to multiple cells, while a mux need to implement on the input side to select from those cells\n";
	fout << "\t\t.out_cur_working_cell_x(Motion_Update_cur_cell[3*CELL_ID_WIDTH-1:2*CELL_ID_WIDTH]),\n";
	fout << "\t\t.out_cur_working_cell_y(Motion_Update_cur_cell[2*CELL_ID_WIDTH-1:1*CELL_ID_WIDTH]),\n";
	fout << "\t\t.out_cur_working_cell_z(Motion_Update_cur_cell[1*CELL_ID_WIDTH-1:0*CELL_ID_WIDTH]),\n";
	fout << "\t\t// Read from Position Cache\n";
	fout << "\t\t.in_position_data(Motion_Update_position_data),\n";
	fout << "\t\t.out_position_cache_rd_en(Motion_Update_position_read_en),\n";
	fout << "\t\t.out_position_cache_rd_addr(Motion_Update_position_read_addr),\n";
	fout << "\t\t// Read from Force Cache\n";
	fout << "\t\t.in_force_data(Motion_Update_force_data),\n";
	fout << "\t\t.out_force_cache_rd_en(Motion_Update_force_read_en),\n";
	fout << "\t\t.out_force_cache_rd_addr(Motion_Update_force_read_addr),\n";
	fout << "\t\t// Read from Velocity Cache\n";
	fout << "\t\t.in_velocity_data(Motion_Update_velocity_data),\n";
	fout << "\t\t.out_velocity_cache_rd_en(Motion_Update_velocity_read_en),\n";
	fout << "\t\t.out_velocity_cache_rd_addr(Motion_Update_velocity_read_addr),\n";
	fout << "\t\t// Motion update enable signal\n";
	fout << "\t\t.out_motion_update_enable(Motion_Update_enable),		// Remine high during the entire motion update process\n";
	fout << "\t\t// Write back to Velocity Cache\n";
	fout << "\t\t.out_velocity_data(Motion_Update_out_velocity_data),	// The updated velocity value\n";
	fout << "\t\t.out_velocity_data_valid(Motion_Update_out_velocity_data_valid),\n";
	fout << "\t\t.out_velocity_destination_cell(Motion_Update_dst_cell),\n";
	fout << "\t\t// Write back to Position Cache\n";
	fout << "\t\t.out_position_data(Motion_Update_out_position_data),\n";
	fout << "\t\t.out_position_data_valid(Motion_Update_out_position_data_valid),\n";
	fout << "\t\t.out_position_destination_cell()						// Leave this one idle, the value is the same as out_velocity_destination_cell\n";
	fout << "\t);\n\n";
	

	// Instantiate the position cache
	fout << "\t///////////////////////////////////////////////////////////////////////////////////////////////\n";
	fout << "\t// Cell particle memory\n";
	fout << "\t// In this impelementation, take cell(2,2,2) as home cell for example (cell cooridinate starts from (1,1,1))\n";
	fout << "\t// The neighbor cells including:\n";
	fout << "\t// Side: (3,1,1),(3,1,2),(3,1,3),(3,2,1),(3,2,2),(3,2,3),(3,3,1),(3,3,2),(3,3,3)\n";
	fout << "\t// Column: (2,3,1),(2,3,2),(2,3,3)\n";
	fout << "\t// Top: (2,2,3)\n";
	fout << "\t// Data orgainization in cell memory: (pos_z, pos_y, pos_x)\n";
	fout << "\t///////////////////////////////////////////////////////////////////////////////////////////////\n";
	int cell_id = 0;
	for(int cell_x = 1; cell_x <= num_cell_x; cell_x++){
		for(int cell_y = 1; cell_y <= num_cell_y; cell_y++){
			for(int cell_z = 1; cell_z <= num_cell_z; cell_z++){
				cell_id = (cell_x-1)*num_cell_y*num_cell_z + (cell_y-1)*num_cell_z + cell_z;
//				fout << "\tPos_Cache_"<< cell_x << "_" << cell_y << "_" << cell_z << "\n";
				fout << "\tPos_Cache_2_2_2\n";									// Temperal Place holder
				fout << "\t#(\n";
				fout << "\t\t.DATA_WIDTH(DATA_WIDTH),\n";
				fout << "\t\t.PARTICLE_NUM(MAX_CELL_PARTICLE_NUM),\n";
				fout << "\t\t.ADDR_WIDTH(CELL_ADDR_WIDTH),\n";
				fout << "\t\t.CELL_ID_WIDTH(CELL_ID_WIDTH),\n";
				fout << "\t\t.CELL_X("<<cell_x<<"),\n";
				fout << "\t\t.CELL_Y("<<cell_y<<"),\n";
				fout << "\t\t.CELL_Z("<<cell_z<<")\n";
				fout << "\t)\n";
				fout << "\tPos_Cache_"<< cell_x << "_" << cell_y << "_" << cell_z << "\n";
				fout << "\t(\n";
				fout << "\t\t.clk(clk),\n";
				fout << "\t\t.rst(rst),\n";
				fout << "\t\t.motion_update_enable(Motion_Update_enable),								// Keep this signal as high during the motion update process\n";
				fout << "\t\t.in_read_address(Motion_Update_enable ? Motion_Update_position_read_addr : FSM_to_Cell_read_addr),\n";
				fout << "\t\t.in_data(Motion_Update_out_position_data),\n";
				fout << "\t\t.in_data_dst_cell(Motion_Update_dst_cell),									// The destination cell for the incoming data\n";
				fout << "\t\t.in_data_valid(Motion_Update_out_position_data_valid),						// Signify if the new incoming data is valid\n";
				fout << "\t\t.in_rden(Motion_Update_enable ? Motion_Update_position_read_en : FSM_to_Cell_rden),\n";
				fout << "\t\t.out_particle_info(Position_Cache_readout_position["<<cell_id<<"*3*DATA_WIDTH-1:"<<cell_id-1<<"*3*DATA_WIDTH])\n";
				fout << "\t);\n\n";
			}
		}
	}

	// Instantiate Force Cache
	fout << "\t///////////////////////////////////////////////////////////////////////////////////////////////\n";
	fout << "\t// Force cache\n";
	fout << "\t// Each cell has an independent cache, MSB -> LSB:{Force_Z, Force_Y, Force_X}\n";
	fout << "\t// The force Serve as the buffer to hold evaluated force values during evaluation\n";
	fout << "\t// The initial force value is 0\n";
	fout << "\t// When new force value arrives, it will accumulate to the current stored value\n";
	fout << "\t///////////////////////////////////////////////////////////////////////////////////////////////\n";
	cell_id = 0;
	for(int cell_x = 1; cell_x <= num_cell_x; cell_x++){
		for(int cell_y = 1; cell_y <= num_cell_y; cell_y++){
			for(int cell_z = 1; cell_z <= num_cell_z; cell_z++){
				cell_id = (cell_x-1)*num_cell_y*num_cell_z + (cell_y-1)*num_cell_z + cell_z;
				fout << "\tForce_Write_Back_Controller\n";
				fout << "\t#(\n";
				fout << "\t\t.DATA_WIDTH(DATA_WIDTH),							// Data width of a single force value, 32-bit\n";
				fout << "\t\t// Cell id this unit related to\n";
				fout << "\t\t.CELL_X("<<cell_x<<"),\n";
				fout << "\t\t.CELL_Y("<<cell_y<<"),\n";
				fout << "\t\t.CELL_Z("<<cell_z<<"),\n";
				fout << "\t\t// Force cache input buffer\n";
				fout << "\t\t.FORCE_CACHE_BUFFER_DEPTH(FORCE_CACHE_BUFFER_DEPTH),\n";
				fout << "\t\t.FORCE_CACHE_BUFFER_ADDR_WIDTH(FORCE_CACHE_BUFFER_ADDR_WIDTH),	// log(FORCE_CACHE_BUFFER_DEPTH) / log 2\n";
				fout << "\t\t// Dataset defined parameters\n";
				fout << "\t\t.CELL_ID_WIDTH(CELL_ID_WIDTH),\n";
				fout << "\t\t.MAX_CELL_PARTICLE_NUM(MAX_CELL_PARTICLE_NUM),		// The maximum # of particles can be in a cell\n";
				fout << "\t\t.CELL_ADDR_WIDTH(CELL_ADDR_WIDTH),					// log(MAX_CELL_PARTICLE_NUM)\n";
				fout << "\t\t.PARTICLE_ID_WIDTH(PARTICLE_ID_WIDTH)				// # of bit used to represent particle ID, 9*9*7 cells, each 4-bit, each cell have max of 220 particles, 8-bit\n";
				fout << "\t\t\n";
				fout << "\t)\n";
				fout << "\tForce_Cache_"<< cell_x << "_" << cell_y << "_" << cell_z << "\n";
				fout << "\t(\n";
				fout << "\t\t.clk(clk),\n";
				fout << "\t\t.rst(rst),\n";
				fout << "\t\t// Cache input force\n";
				fout << "\t\t.in_partial_force_valid(ref_forceoutput_valid),\n";
				fout << "\t\t.in_particle_id(ref_particle_id),\n";
				fout << "\t\t.in_partial_force({ref_LJ_Force_Z, ref_LJ_Force_Y, ref_LJ_Force_X}),\n";
				fout << "\t\t// Cache output force\n";
				fout << "\t\t.in_read_data_request(wire_motion_update_to_cache_read_force_request[" << cell_id-1 << "]),\n";
				fout << "\t\t.in_cache_read_address(Motion_Update_force_read_addr),\n";
				fout << "\t\t.out_partial_force(wire_cache_to_motion_update_partial_force[" << cell_id << "*3*DATA_WIDTH-1:" << cell_id-1 << "*3*DATA_WIDTH]),\n";
				fout << "\t\t.out_particle_id(wire_cache_to_motion_update_particle_id[" << cell_id << "*PARTICLE_ID_WIDTH-1:" << cell_id-1 << "*PARTICLE_ID_WIDTH]),\n";
				fout << "\t\t.out_cache_readout_valid(wire_cache_to_motion_update_partial_force_valid[" << cell_id-1 << "])\n";
				fout << "\t);\n\n";
			}
		}
	}

	// Instantiate Velocity Cache
	fout << "\t///////////////////////////////////////////////////////////////////////////////////////////////\n";
	fout << "\t// Velocity cache\n";
	fout << "\t// Each cell has an independent cache, MSB -> LSB:{vz, vy, vx}\n";
	fout << "\t// The velocity cache provide the spped information for motion update units\n";
	fout << "\t// The inital velocity information is initialized by a initilization file generated from scripts\n";
	fout << "\t// Double buffer mechanism is implemented\n";
	fout << "\t// During motion update process, the new evaluated speed information will write into the alternative cache\n";
	fout << "\t// The read and write address and particle number information should be the same as the Position Cache\n";
	fout << "\t///////////////////////////////////////////////////////////////////////////////////////////////\n";
	cell_id = 0;
	for(int cell_x = 1; cell_x <= num_cell_x; cell_x++){
		for(int cell_y = 1; cell_y <= num_cell_y; cell_y++){
			for(int cell_z = 1; cell_z <= num_cell_z; cell_z++){
				cell_id = (cell_x-1)*num_cell_y*num_cell_z + (cell_y-1)*num_cell_z + cell_z;
//				fout << "\tVelocity_Cache_"<< cell_x << "_" << cell_y << "_" << cell_z << "\n";
				fout << "\tVelocity_Cache_2_2_2\n";								// Temperal place holder
				fout << "\t#(\n";
				fout << "\t\t.DATA_WIDTH(DATA_WIDTH),									// Data width of a single force value, 32-bit\n";
				fout << "\t\t.PARTICLE_NUM(MAX_CELL_PARTICLE_NUM),\n";
				fout << "\t\t.ADDR_WIDTH(CELL_ADDR_WIDTH),\n";
				fout << "\t\t.CELL_ID_WIDTH(CELL_ID_WIDTH),\n";
				fout << "\t\t.CELL_X("<<cell_x<<"),\n";
				fout << "\t\t.CELL_Y("<<cell_y<<"),\n";
				fout << "\t\t.CELL_Z("<<cell_z<<")\n";
				fout << "\t)\n";
				fout << "\tVelocity_Cache_"<< cell_x << "_" << cell_y << "_" << cell_z << "\n";
				fout << "\t(\n";
				fout << "\t\t.clk(clk),\n";
				fout << "\t\t.rst(rst),\n";
				fout << "\t\t.motion_update_enable(Motion_Update_enable),				// Keep this signal as high during the motion update process\n";
				fout << "\t\t.in_read_address(Motion_Update_velocity_read_addr),\n";
				fout << "\t\t.in_data(Motion_Update_out_velocity_data),\n";
				fout << "\t\t.in_data_dst_cell(Motion_Update_dst_cell),					// The destination cell for the incoming data\n";
				fout << "\t\t.in_data_valid(Motion_Update_out_velocity_data_valid),		// Signify if the new incoming data is valid\n";
				fout << "\t\t.in_rden(Motion_Update_velocity_read_en),\n";
				fout << "\t\t.out_particle_info(wire_cache_to_motion_update_velocity_data[" << cell_id << "*3*DATA_WIDTH-1:" << cell_id-1 << "*3*DATA_WIDTH])\n";
				fout << "\t);\n\n";
			}
		}
	}

	fout << "endmodule\n";
	/*
	// Generate some dummy logic
	for(int i=3; i<126;i++){
		fout << "\t\t\t"<<i<<":\n";
		fout << "\t\t\t\tbegin\n";
		fout << "\t\t\t\tFSM_Neighbor_Particle_Position <= Cell_to_FSM_readout_particle_position[(NUM_FILTER+"<<i-1<<")*3*DATA_WIDTH-1:"<<i-1<<"*3*DATA_WIDTH];\n";
		fout << "\t\t\t\tend\n";
	}
	*/
	fout.close();

	return 1;
}
