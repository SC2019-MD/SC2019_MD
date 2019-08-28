#include <fstream>
#include <math.h>
#include <ctime>
#include <string>
#include <stdlib.h>

#include "Gen_motion_update_input_selector.h"

using namespace std;

std::string common_path = "/home/chunshu/Documents/Legacy";
std::string sim_script_out_path = "/mentor";
std::string common_src_path = common_path + "/SourceCode";
std::string sub_folder_path = "/LJArgon_v_File_64_Cells";
#define CELL_NUM 64

int Gen_motion_update_input_selector(std::string* common_path){

	// Setup Generating file
	int id;
	char filename[100];
	sprintf(filename,"Motion_Update_selector_blocks.txt");

	std::string path = *common_path + "/CellMemoryModules" + sub_folder_path + "/" + std::string(filename);
	std::string cell_mem_path = *common_path + "/CellMemoryModules" + sub_folder_path;
	std::ofstream fout;
	fout.open(path.c_str());
	if (fout.fail()){
		printf("open %s failed, exiting\n", path.c_str());
		exit(-1);
	}
	for(id = 0; id < CELL_NUM; id++) {
	fout << "	\n";
fout << "always@(*)\n";
fout << "	begin\n";
fout << "	case(cell_being_updated_id)\n";
	for (id = 0; id < CELL_NUM; id++) {
fout << "		" << id+1 << ":\n";
fout << "			begin\n";
fout << "			reg_Motion_Update_velocity_data[3*DATA_WIDTH-1:0] <= all_Motion_Update_velocity_data[" << id+1 << "*3*DATA_WIDTH-1:" << id << "*3*DATA_WIDTH];\n";
fout << "			reg_Motion_Update_position_data[3*DATA_WIDTH-1:0] <= all_Motion_Update_position_data[" << id+1 << "*3*DATA_WIDTH-1:" << id << "*3*DATA_WIDTH];\n";
fout << "			reg_Motion_Update_force_data[3*DATA_WIDTH-1:0] <= all_Motion_Update_force_data[" << id+1 << "*3*DATA_WIDTH-1:" << id << "*3*DATA_WIDTH];\n";
fout << "			end\n";
	}
fout << "		default:\n";
fout << "			begin\n";
fout << "			reg_Motion_Update_velocity_data[3*DATA_WIDTH-1:0] <= 0;\n";
fout << "			reg_Motion_Update_position_data[3*DATA_WIDTH-1:0] <= 0;\n";
fout << "			reg_Motion_Update_force_data[3*DATA_WIDTH-1:0] <= 0;\n";
fout << "			end\n";
fout << "	endcase\n";
fout << "end\n";
	}

	fout.close();

	return 1;
}

int main() {
	Gen_motion_update_input_selector(&common_src_path);
	return 0;
}
