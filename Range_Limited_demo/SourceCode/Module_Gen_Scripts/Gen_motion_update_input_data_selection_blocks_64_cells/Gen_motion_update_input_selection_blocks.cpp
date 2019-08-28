#include <fstream>
#include <math.h>
#include <ctime>
#include <string>
#include <stdlib.h>

#include "Gen_motion_update_input_selection_blocks.h"

using namespace std;

std::string common_path = "/home/chunshu/Documents/Legacy";
std::string sim_script_out_path = "/mentor";
std::string common_src_path = common_path + "/SourceCode";
std::string sub_folder_path = "/LJArgon_v_File_64_Cells";
#define CELL_NUM 64

int Gen_motion_update_input_selection_blocks(std::string* common_path){

	// Setup Generating file
	int cell;
	char filename[100];
	sprintf(filename,"Motion_update_input_selection_blocks.txt");

	std::string path = *common_path + "/CellMemoryModules" + sub_folder_path + "/" + std::string(filename);
	std::string cell_mem_path = *common_path + "/CellMemoryModules" + sub_folder_path;
	std::ofstream fout;
	fout.open(path.c_str());
	if (fout.fail()){
		printf("open %s failed, exiting\n", path.c_str());
		exit(-1);
	}
	fout << "always@(*)\n";
	fout << "	begin\n";
	fout << "	case(Motion_Update_cell_num)\n";
	for(cell = 0; cell < CELL_NUM; cell++) {
		fout << "		" << cell+1 << ":\n";
		fout << "			begin\n";
		fout << "			Motion_Update_position_data <= Position_Cache_readout_position[" << cell+1 << "*3*DATA_WIDTH-1:" << cell << "*3*DATA_WIDTH];\n";
		fout << "			Motion_Update_force_data <= wire_cache_to_motion_update_partial_force[" << cell+1 << "*3*DATA_WIDTH-1:" << cell << "*3*DATA_WIDTH];\n";
		fout << "			end\n";
	}
	fout << "		default:\n";
	fout << "			begin\n";
	fout << "			Motion_Update_position_data <= Position_Cache_readout_position[1*3*DATA_WIDTH-1:0*3*DATA_WIDTH];\n";
	fout << "			Motion_Update_force_data <= wire_cache_to_motion_update_partial_force[1*3*DATA_WIDTH-1:0*3*DATA_WIDTH];\n";
	fout << "			end\n";
	fout << "	endcase\n";
	fout << "	end\n";

	fout.close();

	return 1;
}

int main() {
	Gen_motion_update_input_selection_blocks(&common_src_path);
	return 0;
}
