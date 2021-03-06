#include <fstream>
#include <math.h>
#include <ctime>
#include <string>
#include <stdlib.h>

#include "Gen_Velocity_Cache_in_top_blocks.h"

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
	sprintf(filename,"Velocity_Cache_Blocks_in_Top_64_Cells.txt");

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
	fout << "	Velocity_Cache_"<< cellx + 1 <<"_"<< celly + 1 <<"_"<< cellz + 1 << "\n";
	fout << "	#(\n";
	fout << "		.DATA_WIDTH(DATA_WIDTH),\n";
	fout << "		.PARTICLE_NUM(MAX_CELL_PARTICLE_NUM),\n";
	fout << "		.ADDR_WIDTH(CELL_ADDR_WIDTH),\n";
	fout << "		.CELL_ID_WIDTH(CELL_ID_WIDTH),\n";
	fout << "		.CELL_X(4'd" << cellx + 1 << "),\n";
	fout << "		.CELL_Y(4'd" << celly + 1 << "),\n";
	fout << "		.CELL_Z(4'd" << cellz + 1 << ")\n";
	fout << "	)\n";
	fout << "	Velocity_Cache_"<< cellx + 1 <<"_"<< celly + 1 <<"_"<< cellz + 1 << "\n";
	fout << "	(\n";
	fout << "		.clk(clk),\n";
	fout << "		.rst(rst),\n";
	fout << "		.motion_update_enable(Motion_Update_enable),				// Keep this signal as high during the motion update process\n";
	fout << "		.in_read_address(Motion_Update_velocity_read_addr),\n";
	fout << "		.in_data(Motion_Update_out_velocity_data),\n";
	fout << "		.in_data_dst_cell(Motion_Update_dst_cell),				// The destination cell for the incoming data\n";
	fout << "		.in_data_valid(Motion_Update_out_velocity_data_valid),// Signify if the new incoming data is valid\n";
	fout << "		.in_rden(Motion_Update_velocity_read_en),\n";
	fout << "		.out_particle_info(Motion_Update_velocity_data[" << cellx*CELL_NUM_Y*CELL_NUM_Z+celly*CELL_NUM_Z+cellz+1 << "*3*DATA_WIDTH-1:" << cellx*CELL_NUM_Y*CELL_NUM_Z+celly*CELL_NUM_Z+cellz << "*3*DATA_WIDTH])\n";
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
