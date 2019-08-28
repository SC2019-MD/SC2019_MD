#include <fstream>
#include <math.h>
#include <ctime>
#include <string>
#include <stdlib.h>

#include "Gen_Velocity_Cache.h"

using namespace std;

std::string common_path = "/home/chunshu/Documents/Legacy";
std::string sim_script_out_path = "/mentor";
std::string common_src_path = common_path + "/SourceCode";
std::string sub_folder_path = "/LJArgon_v_File_64_Cells";
#define CELL_NUM_X 4
#define CELL_NUM_Y 4
#define CELL_NUM_Z 4

int Gen_Velocity_Cache(int cellx, int celly, int cellz, std::string* common_path){

	// Setup Generating file
	char filename[100];
	sprintf(filename,"Velocity_Cache_%d_%d_%d.v", cellx, celly, cellz);

	std::string path = *common_path + "/CellMemoryModules" + sub_folder_path + "/" + std::string(filename);
	std::string cell_mem_path = *common_path + "/CellMemoryModules" + sub_folder_path;
	std::ofstream fout;
	fout.open(path.c_str());
	if (fout.fail()){
		printf("open %s failed, exiting\n", path.c_str());
		exit(-1);
	}
	
	fout << "/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////\n";
	fout << "// Module: Velocity_Cache_"<< cellx <<"_"<< celly <<"_"<< cellz <<".v (This module is almost identical to Pos_Cache_2_2_2.v, share the same testbench)\n";
	fout << "//\n";
	fout << "//	Function:\n";
	fout << "//				Velocity cache with double buffering for motion update\n";
	fout << "//				Holds the velocity value from previous motion update\n";
	fout << "//				Update the value after each motion update process\n";
	fout << "//\n";
	fout << "//	Purpose:\n";
	fout << "//				Providing particle velocity information for motion update\n";
	fout << "//				Have a secondary buffer to hold the new data after motion update process\n";
	fout << "//				During motion update process, the motion update module will broadcast the valid data and destination cell to all cells\n";
	fout << "//				Upon receiving valid particle data, first determine if this is the target destination cell\n";
	fout << "//\n";
	fout << "// Data Organization:\n";
	fout << "//				Address 0 for each cell module: # of particles in the cell\n";
	fout << "//				Velocity data: MSB-LSB: {vz, vy, vx}\n";
	fout << "//				Cell address: MSB-LSB: {cell_x, cell_y, cell_z}\n";
	fout << "//\n";
	fout << "// Used by:\n";
	fout << "//				RL_LJ_Top.v\n";
	fout << "//\n";
	fout << "// Dependency:\n";
	fout << "//				velocity_x_y_z.v\n";
	fout << "//				cell_empty.v\n";
	fout << "//\n";
	fout << "// Testbench:\n";
	fout << "//				Refere to Pos_Cache_2_2_2_tb.v			(testing the swap function during motion update)\n";
	fout << "//				RL_LJ_Top_tb.v					(testing the correctness of read & write)\n";
	fout << "//\n";
	fout << "// Timing:\n";
	fout << "//				2 cycles reading delay from input address and output data.\n";
	fout << "//\n";
	fout << "// Created by:\n";
	fout << "//				Chunshu's Script (Gen_Velocity_Cache.cpp).\n";
	fout << "/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////\n";
fout << "\n";
	fout << "module Velocity_Cache_"<< cellx <<"_"<< celly <<"_"<< cellz <<"\n";
	fout << "#(\n";
	fout << "\tparameter DATA_WIDTH = 32,\n";
	fout << "\tparameter PARTICLE_NUM = 220,\n";
	fout << "\tparameter ADDR_WIDTH = 8,\n";
	fout << "\tparameter CELL_ID_WIDTH = 4,\n";
	fout << "\tparameter CELL_X = " << cellx << ",\n";
	fout << "\tparameter CELL_Y = " << celly << ",\n";
	fout << "\tparameter CELL_Z = " << cellz << "\n";
	fout << ")\n";
	fout << "(\n";
	fout << "\tinput clk,\n";
	fout << "\tinput rst,\n";
	fout << "\tinput motion_update_enable,										// Keep this signal as high during the motion update process\n";
	fout << "\tinput [ADDR_WIDTH-1:0] in_read_address,\n";
	fout << "\tinput [3*DATA_WIDTH-1:0] in_data,\n";
	fout << "\tinput [3*CELL_ID_WIDTH-1:0] in_data_dst_cell,				// The destination cell for the incoming data\n";
	fout << "\tinput in_data_valid,													// Signify if the new incoming data is valid\n";
	fout << "\tinput in_rden,\n";
	fout << "\t//input in_wren,\n";
	fout << "\toutput [3*DATA_WIDTH-1:0] out_particle_info\n";
	fout << ");\n";
fout << "\n";
	fout << "\t//////////////////////////////////////////////////////////////////////////////////////////////\n";
	fout << "\t// Control FSM to switch between the 2 memory modules\n";
	fout << "\t//////////////////////////////////////////////////////////////////////////////////////////////\n";
	fout << "\tparameter WAIT_FOR_MOTION_UPDATE_START = 2'b00;\n";
	fout << "\tparameter MOTION_UPDATE_PROCESS = 2'b01;\n";
	fout << "\tparameter WRITE_PARTICLE_NUM = 2'b10;\n";
	fout << "\tparameter MOTION_UPDATE_DONE = 2'b11;\n";
	fout << "\treg [1:0] state;\n";
	fout << "\t// Flag slecting which cell is the active one for processing\n";
	fout << "\treg active_cell;\n";
	fout << "\t// Counter for recording the # of new particles\n";
	fout << "\treg [ADDR_WIDTH-1:0] new_particle_counter;\n";
	fout << "\t// Memory module control signal\n";
	fout << "\treg cell_wr_en;\n";
	fout << "\treg [ADDR_WIDTH-1:0] cell_wr_address;\n";
	fout << "\treg [3*DATA_WIDTH-1:0] cell_wr_data;\n";
	fout << "\t// Assign the current cell ID\n";
	fout << "\twire [CELL_ID_WIDTH-1:0] cur_cell_x, cur_cell_y, cur_cell_z;\n";
	fout << "\tassign cur_cell_x = CELL_X;\n";
	fout << "\tassign cur_cell_y = CELL_Y;\n";
	fout << "\tassign cur_cell_z = CELL_Z;\n";
	fout << "\t// Check if the incoming particle is targeting the current cell\n";
	fout << "\twire data_valid;\n";
	fout << "\tassign data_valid = in_data_valid && (in_data_dst_cell == {cur_cell_x, cur_cell_y, cur_cell_z});\n";
	fout << "\talways@(posedge clk)\n";
	fout << "\t\tbegin\n";
	fout << "\t\tif(rst)\n";
	fout << "\t\t\tbegin\n";
	fout << "\t\t\tactive_cell <= 1'b0;\n";
	fout << "\t\t\tnew_particle_counter <= 1;								// Counter starts from 1, to avoid write to Address 0\n";
	fout << "\t\t\tcell_wr_en <= 1'b0;\n";
	fout << "\t\t\tcell_wr_address <= {(ADDR_WIDTH){1'b0}};\n";
	fout << "\t\t\tcell_wr_data <= {(3*DATA_WIDTH){1'b0}};\n";
fout << "\n";			
	fout << "\t\t\tstate <= WAIT_FOR_MOTION_UPDATE_START;\n";
	fout << "\t\t\tend\n";
	fout << "\t\telse\n";
	fout << "\t\t\tbegin\n";
	fout << "\t\t\tcase(state)\n";
	fout << "\t\t\t\t// Wait for the start signal\n";
	fout << "\t\t\t\tWAIT_FOR_MOTION_UPDATE_START:\n";
	fout << "\t\t\t\t\tbegin\n";
	fout << "\t\t\t\t\tif(motion_update_enable)\n";
	fout << "\t\t\t\t\t\tbegin\n";
	fout << "\t\t\t\t\t\tactive_cell <= active_cell;\n";
	fout << "\t\t\t\t\t\t// Check if the first data is valid\n";
	fout << "\t\t\t\t\t\tif(data_valid)\n";
	fout << "\t\t\t\t\t\t\tbegin\n";
	fout << "\t\t\t\t\t\t\tnew_particle_counter <= new_particle_counter + 1'b1;\n";
	fout << "\t\t\t\t\t\t\tcell_wr_en <= 1'b1;\n";
	fout << "\t\t\t\t\t\t\tcell_wr_address <= new_particle_counter;\n";
	fout << "\t\t\t\t\t\t\tcell_wr_data <= in_data;\n";
	fout << "\t\t\t\t\t\t\tend\n";
	fout << "\t\t\t\t\t\telse\n";
	fout << "\t\t\t\t\t\t\tbegin\n";
	fout << "\t\t\t\t\t\t\tnew_particle_counter <= new_particle_counter;\n";
	fout << "\t\t\t\t\t\t\tcell_wr_en <= 1'b0;\n";
	fout << "\t\t\t\t\t\t\tcell_wr_address <= 0;\n";
	fout << "\t\t\t\t\t\t\tcell_wr_data <= 0;\n";
	fout << "\t\t\t\t\t\t\tend\n";
	fout << "\t\t\t\t\t\tstate <= MOTION_UPDATE_PROCESS;\n";
	fout << "\t\t\t\t\t\tend\n";
	fout << "\t\t\t\t\telse\n";
	fout << "\t\t\t\t\t\tbegin\n";
	fout << "\t\t\t\t\t\tactive_cell <= active_cell;\n";
	fout << "\t\t\t\t\t\tnew_particle_counter <= 1;\n";
	fout << "\t\t\t\t\t\tcell_wr_en <= 1'b0;\n";
	fout << "\t\t\t\t\t\tcell_wr_address <= {(ADDR_WIDTH){1'b0}};\n";
	fout << "\t\t\t\t\t\tcell_wr_data <= {(3*DATA_WIDTH){1'b0}};\n";
	fout << "\t\t\t\t\t\tstate <= WAIT_FOR_MOTION_UPDATE_START;\n";
	fout << "\t\t\t\t\t\tend\n";
	fout << "\t\t\t\t\tend\n";
	fout << "\t\t\t\t// Record the new particle data\n";
	fout << "\t\t\t\tMOTION_UPDATE_PROCESS:\n";
	fout << "\t\t\t\t\tbegin\n";
	fout << "\t\t\t\t\tactive_cell <= active_cell;\n";
	fout << "\t\t\t\t\t// Check if the first data is valid\n";
	fout << "\t\t\t\t\tif(data_valid)\n";
	fout << "\t\t\t\t\t\tbegin\n";
	fout << "\t\t\t\t\t\tnew_particle_counter <= new_particle_counter + 1'b1;\n";
	fout << "\t\t\t\t\t\tcell_wr_en <= 1'b1;\n";
	fout << "\t\t\t\t\t\tcell_wr_address <= new_particle_counter;\n";
	fout << "\t\t\t\t\t\tcell_wr_data <= in_data;\n";
	fout << "\t\t\t\t\t\tend\n";
	fout << "\t\t\t\t\telse\n";
	fout << "\t\t\t\t\t\tbegin\n";
	fout << "\t\t\t\t\t\tnew_particle_counter <= new_particle_counter;\n";
	fout << "\t\t\t\t\t\tcell_wr_en <= 1'b0;\n";
	fout << "\t\t\t\t\t\tcell_wr_address <= 0;\n";
	fout << "\t\t\t\t\t\tcell_wr_data <= 0;\n";
	fout << "\t\t\t\t\t\tend\n";
	fout << "\t\t\t\t\t// Update the next state\n";
	fout << "\t\t\t\t\t// The motion_update_enable is suppose to keep high during the process\n";
	fout << "\t\t\t\t\tif(motion_update_enable)\n";
	fout << "\t\t\t\t\t\tbegin\n";
	fout << "\t\t\t\t\t\tstate <= MOTION_UPDATE_PROCESS;\n";
	fout << "\t\t\t\t\t\tend\n";
	fout << "\t\t\t\t\telse\n";
	fout << "\t\t\t\t\t\tbegin\n";
	fout << "\t\t\t\t\t\tstate <= WRITE_PARTICLE_NUM;\n";
	fout << "\t\t\t\t\t\tend\n";
	fout << "\t\t\t\t\tend\n";
	fout << "\t\t\t\t// Write the paticle # to address 0\n";
	fout << "\t\t\t\tWRITE_PARTICLE_NUM:\n";
	fout << "\t\t\t\t\tbegin\n";
	fout << "\t\t\t\t\tactive_cell <= active_cell;\n";
	fout << "\t\t\t\t\t// Write the new particle # to address 0\n";
	fout << "\t\t\t\t\tnew_particle_counter <= new_particle_counter;\n";
	fout << "\t\t\t\t\tcell_wr_en <= 1'b1;\n";
	fout << "\t\t\t\t\tcell_wr_address <= 0;\n";
	fout << "\t\t\t\t\tcell_wr_data <= new_particle_counter - 1'b1;					// new_particle_counter = actual_current_# + 1'b1\n";
	fout << "\t\t\t\t\t// Move to the DONE state\n";
	fout << "\t\t\t\t\tstate <= MOTION_UPDATE_DONE;\n";
	fout << "\t\t\t\t\tend\n";
	fout << "\t\t\t\t// Flip the active_cell bit\n";
	fout << "\t\t\t\tMOTION_UPDATE_DONE:\n";
	fout << "\t\t\t\t\tbegin\n";
	fout << "\t\t\t\t\t// Inverse the sel bit\n";
	fout << "\t\t\t\t\tactive_cell <= ~active_cell;\n";
	fout << "\t\t\t\t\t// Reset the counter to 1\n";
	fout << "\t\t\t\t\tnew_particle_counter <= 1;\n";
	fout << "\t\t\t\t\tcell_wr_en <= 1'b0;\n";
	fout << "\t\t\t\t\tcell_wr_address <= 0;\n";
	fout << "\t\t\t\t\tcell_wr_data <= 0;\n";
	fout << "\t\t\t\t\t// Move to the initial state\n";
	fout << "\t\t\t\t\tstate <= WAIT_FOR_MOTION_UPDATE_START;\n";
	fout << "\t\t\t\t\tend\n";
	fout << "\t\t\tendcase\n";
	fout << "\t\t\tend\n";
	fout << "\t\tend\n";
fout << "\n";		
	fout << "\t//////////////////////////////////////////////////////////////////////////////////////////////\n";
	fout << "\t// Signals connect to 2 cell memories\n";
	fout << "\t//////////////////////////////////////////////////////////////////////////////////////////////\n";
	fout << "\t// Assign the read address\n";
	fout << "\twire [ADDR_WIDTH-1:0] input_to_cell_addr_0, input_to_cell_addr_1;\n";
	fout << "\tassign input_to_cell_addr_0 = (active_cell) ? cell_wr_address : in_read_address;\n";
	fout << "\tassign input_to_cell_addr_1 = (active_cell) ? in_read_address : cell_wr_address;\n";
	fout << "\t// Assign the write data\n";
	fout << "\twire [3*DATA_WIDTH-1:0] input_to_cell_new_position_data_0, input_to_cell_new_position_data_1;\n";
	fout << "\tassign input_to_cell_new_position_data_0 = (active_cell) ? cell_wr_data : 0;\n";
	fout << "\tassign input_to_cell_new_position_data_1 = (active_cell) ? 0 : cell_wr_data;\n";
	fout << "\t// Assign the read enable\n";
	fout << "\twire input_to_cell_rden_0, input_to_cell_rden_1;\n";
	fout << "\tassign input_to_cell_rden_0 = (active_cell) ? 1'b0 : in_rden;\n";
	fout << "\tassign input_to_cell_rden_1 = (active_cell) ? in_rden : 1'b0;\n";
	fout << "\t// Assign the write enable\n";
	fout << "\twire input_to_cell_wren_0, input_to_cell_wren_1;\n";
	fout << "\tassign input_to_cell_wren_0 = (active_cell) ? cell_wr_en : 1'b0;\n";
	fout << "\tassign input_to_cell_wren_1 = (active_cell) ? 1'b0 : cell_wr_en;\n";
	fout << "\t// Assign the read out data to output\n";
	fout << "\twire [3*DATA_WIDTH-1:0] cell_to_output_position_readout_0, cell_to_output_position_readout_1;\n";
	fout << "\tassign out_particle_info = (active_cell) ? cell_to_output_position_readout_1 : cell_to_output_position_readout_0;\n";
fout << "\n";	
	fout << "\t//////////////////////////////////////////////////////////////////////////////////////////////\n";
	fout << "\t// Memory Modules\n";
	fout << "\t//////////////////////////////////////////////////////////////////////////////////////////////\n";
	fout << "\t// Original Cell with initial value\n";
	fout << "\tvelocity_"<< cellx <<"_"<< celly <<"_"<< cellz <<"\n";
	fout << "\t#(\n";
	fout << "\t\t.DATA_WIDTH(3*DATA_WIDTH),\n";
	fout << "\t\t.PARTICLE_NUM(PARTICLE_NUM),\n";
	fout << "\t\t.ADDR_WIDTH(ADDR_WIDTH)\n";
	fout << "\t)\n";
	fout << "\tvelocity_cell_0\n";
	fout << "\t(\n";
	fout << "\t\t.address(input_to_cell_addr_0),\n";
	fout << "\t\t.clock(clk),\n";
	fout << "\t\t.data(input_to_cell_new_position_data_0),\n";
	fout << "\t\t.rden(input_to_cell_rden_0),\n";
	fout << "\t\t.wren(input_to_cell_wren_0),\n";
	fout << "\t\t.q(cell_to_output_position_readout_0)\n";
	fout << "\t);\n";
fout << "\n";	
	fout << "\t// Alternative cell\n";
	fout << "\tcell_empty\n";
	fout << "\t#(\n";
	fout << "\t\t.DATA_WIDTH(3*DATA_WIDTH),\n";
	fout << "\t\t.PARTICLE_NUM(PARTICLE_NUM),\n";
	fout << "\t\t.ADDR_WIDTH(ADDR_WIDTH)\n";
	fout << "\t)\n";
	fout << "\tvelocity_cell_1\n";
	fout << "\t(\n";
	fout << "\t\t.address(input_to_cell_addr_1),\n";
	fout << "\t\t.clock(clk),\n";
	fout << "\t\t.data(input_to_cell_new_position_data_1),\n";
	fout << "\t\t.rden(input_to_cell_rden_1),\n";
	fout << "\t\t.wren(input_to_cell_wren_1),\n";
	fout << "\t\t.q(cell_to_output_position_readout_1)\n";
	fout << "\t);\n";
fout << "\n";
	fout << "endmodule	\n";

	fout.close();

	return 1;
}

int main() {
	int i, j, k;
	for (i = 0; i < CELL_NUM_X; i++) {
		for (j = 0; j < CELL_NUM_Y; j++) {
			for (k = 0; k < CELL_NUM_Z; k++) {
				Gen_Velocity_Cache(i+1, j+1, k+1, &common_src_path);
			}
		}
	}
	return 0;
}
