#include <fstream>
#include <math.h>
#include <ctime>
#include <string>
#include <stdlib.h>

#include "Gen_pair_filter_logic.h"

using namespace std;

std::string common_path = "./";
std::string sim_script_out_path = "";
std::string common_src_path = common_path + "";
std::string sub_folder_path = "";
#define FILTER_NUM 8

int Gen_Velocity_Cache_Blocks(std::string* common_path){

	// Setup Generating file
	int filter;
	char filename[100];
	sprintf(filename,"Gen_pair_filter_logic.txt");

	std::string path = *common_path + "" + sub_folder_path + "/" + std::string(filename);
	std::string cell_mem_path = *common_path + "" + sub_folder_path;
	std::ofstream fout;
	fout.open(path.c_str());
	if (fout.fail()){
		printf("open %s failed, exiting\n", path.c_str());
		exit(-1);
	}
	for(filter = 2; filter < FILTER_NUM; filter++) {
fout << "						if(FSM_Filter_Sel_Cell[" << filter << "] == 1'b0)			// Processing the 1st neighbor cell\n";
fout << "							begin\n";
fout << "							FSM_Filter_Done_Processing[" << filter << "] <= 1'b0;		// Processing not finished\n";
fout << "							if (Cell_to_FSM_read_success_bit[" << filter << "])\n";
fout << "								FSM_Filter_Pause_Processing[" << filter << "] <= 1'b0;\n";
fout << "								begin\n";
fout << "								if(FSM_Filter_Read_Addr[" << filter+1 << "*CELL_ADDR_WIDTH-1:" << filter << "*CELL_ADDR_WIDTH] < FSM_Cell_Particle_Num[" << (filter-2)*2+3 << "*CELL_ADDR_WIDTH-1:" << (filter-2)*2+2 << "*CELL_ADDR_WIDTH])\n";
fout << "									begin\n";
fout << "									FSM_Filter_Sel_Cell[" << filter << "] <= 1'b0;\n";
fout << "									FSM_Filter_Read_Addr[" << filter+1 << "*CELL_ADDR_WIDTH-1:" << filter << "*CELL_ADDR_WIDTH] <= FSM_Filter_Read_Addr[" << filter+1 << "*CELL_ADDR_WIDTH-1:" << filter << "*CELL_ADDR_WIDTH] + 1'b1;\n";
fout << "									end\n";
fout << "								else\n";
fout << "									begin\n";
fout << "									FSM_Filter_Sel_Cell[" << filter << "] <= 1'b1;\n";
fout << "									FSM_Filter_Read_Addr[" << filter+1 << "*CELL_ADDR_WIDTH-1:" << filter << "*CELL_ADDR_WIDTH] <= 1;			// Start from address 1 for the next cell\n";
fout << "									end\n";
fout << "								end\n";
fout << "							else\n";
fout << "								begin\n";
fout << "								FSM_Filter_Pause_Processing[" << filter << "] <= 1'b1;\n";
fout << "								FSM_Filter_Sel_Cell[" << filter << "] <= 1'b0;\n";
fout << "								FSM_Filter_Read_Addr[" << filter+1 << "*CELL_ADDR_WIDTH-1:" << filter << "*CELL_ADDR_WIDTH] <= FSM_Filter_Read_Addr[" << filter+1 << "*CELL_ADDR_WIDTH-1:" << filter << "*CELL_ADDR_WIDTH];\n";
fout << "								end\n";
fout << "							end\n";
fout << "						else					// Processing the 2nd neighbor cell\n";
fout << "							begin\n";
fout << "							FSM_Filter_Sel_Cell[" << filter << "] <= FSM_Filter_Sel_Cell[" << filter << "];					// Sel bit remains\n";
fout << "							if (Cell_to_FSM_read_success_bit[" << filter << "])\n";
fout << "								begin\n";
fout << "								FSM_Filter_Pause_Processing[" << filter << "] <= 1'b0;\n";
fout << "								if(FSM_Filter_Read_Addr[" << filter+1 << "*CELL_ADDR_WIDTH-1:" << filter << "*CELL_ADDR_WIDTH] < FSM_Cell_Particle_Num[" << (filter-2)*2+4 << "*CELL_ADDR_WIDTH-1:" << (filter-2)*2+3 << "*CELL_ADDR_WIDTH])\n";
fout << "									begin\n";
fout << "									FSM_Filter_Read_Addr[" << filter+1 << "*CELL_ADDR_WIDTH-1:" << filter << "*CELL_ADDR_WIDTH] <= FSM_Filter_Read_Addr[" << filter+1 << "*CELL_ADDR_WIDTH-1:" << filter << "*CELL_ADDR_WIDTH] + 1'b1;\n";
fout << "									FSM_Filter_Done_Processing[" << filter << "] <= 1'b0;\n";
fout << "									end\n";
fout << "								else\n";
fout << "									begin\n";
fout << "									FSM_Filter_Read_Addr[" << filter+1 << "*CELL_ADDR_WIDTH-1:" << filter << "*CELL_ADDR_WIDTH] <= FSM_Filter_Read_Addr[" << filter+1 << "*CELL_ADDR_WIDTH-1:" << filter << "*CELL_ADDR_WIDTH];\n";
fout << "									FSM_Filter_Done_Processing[" << filter << "] <= 1'b1;								// Processing done\n";
fout << "									end\n";
fout << "								end\n";
fout << "							else\n";
fout << "								begin\n";
fout << "								FSM_Filter_Pause_Processing[" << filter << "] <= 1'b1;\n";
fout << "								FSM_Filter_Read_Addr[" << filter+1 << "*CELL_ADDR_WIDTH-1:" << filter << "*CELL_ADDR_WIDTH] <= FSM_Filter_Read_Addr[" << filter+1 << "*CELL_ADDR_WIDTH-1:" << filter << "*CELL_ADDR_WIDTH];\n";
fout << "								FSM_Filter_Done_Processing[" << filter << "] <= 1'b0;\n";
fout << "								end\n";
fout << "							end\n";
fout << "\n";
	}
	fout.close();

	return 1;
}

int main() {
	Gen_Velocity_Cache_Blocks(&common_src_path);
	return 0;
}
