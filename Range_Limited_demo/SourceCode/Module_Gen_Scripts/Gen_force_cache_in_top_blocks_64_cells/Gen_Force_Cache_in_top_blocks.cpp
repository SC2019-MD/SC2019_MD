#include <fstream>
#include <math.h>
#include <ctime>
#include <string>
#include <stdlib.h>

#include "Gen_Force_Cache_in_top_blocks.h"

using namespace std;

std::string common_path = "/home/chunshu/Documents/Legacy";
std::string sim_script_out_path = "/mentor";
std::string common_src_path = common_path + "/SourceCode";
std::string sub_folder_path = "/LJArgon_v_File_64_Cells";
#define CELL_NUM_X 4
#define CELL_NUM_Y 4
#define CELL_NUM_Z 4

int Gen_Velocity_Cache_Blocks(std::string* common_path){

	// Setup Generating file
	int cellx, celly, cellz;
	char filename[100];
	sprintf(filename,"Force_Cache_Blocks_in_Top_64_Cells.txt");

	std::string path = *common_path + "/CellMemoryModules" + sub_folder_path + "/" + std::string(filename);
	std::string cell_mem_path = *common_path + "/CellMemoryModules" + sub_folder_path;
	std::ofstream fout;
	fout.open(path.c_str());
	if (fout.fail()){
		printf("open %s failed, exiting\n", path.c_str());
		exit(-1);
	}
	for(cellx = 0; cellx < CELL_NUM_X; cellx++) {
	for(celly = 0; celly < CELL_NUM_Y; celly++) {
	for(cellz = 0; cellz < CELL_NUM_Z; cellz++) {
fout << "	// Force_Cache_"<< cellx + 1 <<"_"<< celly + 1 <<"_"<< cellz + 1 << "\n";
fout << "	Force_Write_Back_Controller\n";
fout << "	#(\n";
fout << "		.DATA_WIDTH(DATA_WIDTH),									// Data width of a single force value, 32-bit\n";
fout << "		// Cell id this unit related to\n";
fout << "		.CELL_X("<< cellx + 1 <<"),\n";
fout << "		.CELL_Y("<< celly + 1 <<"),\n";
fout << "		.CELL_Z("<< cellz + 1 <<"),\n";
fout << "		// Force cache input buffer\n";
fout << "		.FORCE_CACHE_BUFFER_DEPTH(FORCE_CACHE_BUFFER_DEPTH),\n";
fout << "		.FORCE_CACHE_BUFFER_ADDR_WIDTH(FORCE_CACHE_BUFFER_ADDR_WIDTH),	// log(FORCE_CACHE_BUFFER_DEPTH) / log 2\n";
fout << "		// Dataset defined parameters\n";
fout << "		.CELL_ID_WIDTH(CELL_ID_WIDTH),\n";
fout << "		.MAX_CELL_PARTICLE_NUM(MAX_CELL_PARTICLE_NUM),		// The maximum # of particles can be in a cell\n";
fout << "		.CELL_ADDR_WIDTH(CELL_ADDR_WIDTH),						// log(MAX_CELL_PARTICLE_NUM)\n";
fout << "		.PARTICLE_ID_WIDTH(PARTICLE_ID_WIDTH)					// # of bit used to represent particle ID, 9*9*7 cells, each 4-bit, each cell have max of 220 particles, 8-bit\n";
fout << "	)\n";
fout << "	Force_"<< cellx + 1 <<"_"<< celly + 1 <<"_"<< cellz + 1 << "\n";
fout << "	(\n";
fout << "		.clk(clk),\n";
fout << "		.rst(rst),\n";
fout << "		// Cache input force\n";
fout << "		.in_partial_force_valid(to_force_cache_partial_force_valid[" << cellx*CELL_NUM_Y*CELL_NUM_Z+celly*CELL_NUM_Z+cellz << "]),\n";
fout << "		.in_particle_id(to_force_cache_particle_id[" << cellx*CELL_NUM_Y*CELL_NUM_Z+celly*CELL_NUM_Z+cellz+1 << "*PARTICLE_ID_WIDTH-1:" << cellx*CELL_NUM_Y*CELL_NUM_Z+celly*CELL_NUM_Z+cellz << "*PARTICLE_ID_WIDTH]),\n";
fout << "		.in_partial_force({to_force_cache_LJ_Force_Z[" << cellx*CELL_NUM_Y*CELL_NUM_Z+celly*CELL_NUM_Z+cellz+1 << "*DATA_WIDTH-1:" << cellx*CELL_NUM_Y*CELL_NUM_Z+celly*CELL_NUM_Z+cellz << "*DATA_WIDTH], to_force_cache_LJ_Force_Y[" << cellx*CELL_NUM_Y*CELL_NUM_Z+celly*CELL_NUM_Z+cellz+1 << "*DATA_WIDTH-1:" << cellx*CELL_NUM_Y*CELL_NUM_Z+celly*CELL_NUM_Z+cellz << "*DATA_WIDTH], to_force_cache_LJ_Force_X[" << cellx*CELL_NUM_Y*CELL_NUM_Z+celly*CELL_NUM_Z+cellz+1 << "*DATA_WIDTH-1:" << cellx*CELL_NUM_Y*CELL_NUM_Z+celly*CELL_NUM_Z+cellz << "*DATA_WIDTH]}),\n";
fout << "		// Cache output force\n";
fout << "		.in_read_data_request(wire_motion_update_to_cache_read_force_request[" << cellx*CELL_NUM_Y*CELL_NUM_Z+celly*CELL_NUM_Z+cellz << "]),									// Enables read data from the force cache, if this signal is high, then no write operation is permitted\n";
fout << "		.in_cache_read_address(Motion_Update_force_read_addr),\n";
fout << "		.out_partial_force(wire_cache_to_motion_update_partial_force[" << cellx*CELL_NUM_Y*CELL_NUM_Z+celly*CELL_NUM_Z+cellz+1 << "*3*DATA_WIDTH-1:" << cellx*CELL_NUM_Y*CELL_NUM_Z+celly*CELL_NUM_Z+cellz << "*3*DATA_WIDTH]),\n";
fout << "		.out_particle_id(wire_cache_to_motion_update_particle_id[" << cellx*CELL_NUM_Y*CELL_NUM_Z+celly*CELL_NUM_Z+cellz+1 << "*PARTICLE_ID_WIDTH-1:" << cellx*CELL_NUM_Y*CELL_NUM_Z+celly*CELL_NUM_Z+cellz << "*PARTICLE_ID_WIDTH]),\n";
fout << "		.out_cache_readout_valid(wire_cache_to_motion_update_partial_force_valid[" << cellx*CELL_NUM_Y*CELL_NUM_Z+celly*CELL_NUM_Z+cellz << "])\n";
fout << "	);\n";
	}
	}
	}

	fout.close();

	return 1;
}

int main() {
	Gen_Velocity_Cache_Blocks(&common_src_path);
	return 0;
}
