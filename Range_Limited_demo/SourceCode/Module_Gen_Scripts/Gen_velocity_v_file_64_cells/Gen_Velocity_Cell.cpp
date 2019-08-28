#include <fstream>
#include <math.h>
#include <ctime>
#include <string>
#include <stdlib.h>

#include "Gen_Velocity_Cell.h"

using namespace std;

std::string common_path = "/home/chunshu/Documents/Legacy";
std::string sim_script_out_path = "/mentor";
std::string common_src_path = common_path + "/SourceCode";
std::string sub_folder_path = "/LJArgon_v_File_64_Cells";
#define CELL_NUM_X 4
#define CELL_NUM_Y 4
#define CELL_NUM_Z 4

int Gen_Pos_Cell(int cellx, int celly, int cellz, std::string* common_path){

	// Setup Generating file
	char filename[100];
	sprintf(filename,"velocity_%d_%d_%d.v", cellx, celly, cellz);

	std::string path = *common_path + "/CellMemoryModules" + sub_folder_path + "/" + std::string(filename);
	std::string cell_mem_path = *common_path + "/CellMemoryModules" + sub_folder_path;
	std::ofstream fout;
	fout.open(path.c_str());
	if (fout.fail()){
		printf("open %s failed, exiting\n", path.c_str());
		exit(-1);
	}
	
fout << "/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////\n";
fout << "// Module: velocity_2_2_2.v\n";
fout << "//\n";
fout << "//	Function:\n";
fout << "//				Memory modules holding the initial velocity information of each cells\n";
fout << "//\n";
fout << "//	Purpose:\n";
fout << "//				Providing particle position data for force evaluation and motion update\n";
fout << "//\n";
fout << "// Data Organization:\n";
fout << "//				Address 0 for each cell module: # of particles in the cell.\n";
fout << "//				MSB-LSB: {vz, vy, vx}\n";
fout << "//\n";
fout << "// Used by:\n";
fout << "//				Velocity_Cache_2_2_2.v\n";
fout << "//\n";
fout << "// Dependency:\n";
fout << "//				velocity_ini_file_2_2_2.hex / velocity_ini_file_2_2_2.mif\n";
fout << "//\n";
fout << "// Testbench:\n";
fout << "//				RL_LJ_Top_tb.v\n";
fout << "//\n";
fout << "// Timing:\n";
fout << "//				1 cycle reading delay from input address and output data.\n";
fout << "//\n";
fout << "// Created by:\n";
fout << "//				Chen Yang's Script (Gen_Velocity_Cell.cpp), based on Single Port RAM IP core\n";
fout << "/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////\n";
fout << "\n";
fout << "`include \"../define.v\"\n";
fout << "\n";
fout << "`timescale 1 ps / 1 ps\n";
fout << "\n";
fout << "module velocity_" << cellx << "_" << celly << "_" << cellz << "\n";
fout << "#(\n";
fout << "	parameter DATA_WIDTH = 32*3,\n";
fout << "	parameter PARTICLE_NUM = 220,\n";
fout << "	parameter ADDR_WIDTH = 8\n";
fout << ")\n";
fout << "(\n";
fout << "	address,\n";
fout << "	clock,\n";
fout << "	data,\n";
fout << "	rden,\n";
fout << "	wren,\n";
fout << "	q\n";
fout << ");\n";
fout << "\n";
fout << "	input  [ADDR_WIDTH-1:0]  address;\n";
fout << "	input    clock;\n";
fout << "	input  [DATA_WIDTH-1:0]  data;\n";
fout << "	input    rden;\n";
fout << "	input    wren;\n";
fout << "	output [DATA_WIDTH-1:0]  q;\n";
fout << "\n";
fout << "	tri1     clock;\n";
fout << "	tri1     rden;\n";
fout << "\n";
fout << "	wire [DATA_WIDTH-1:0] sub_wire0;\n";
fout << "	wire [DATA_WIDTH-1:0] q = sub_wire0[DATA_WIDTH-1:0];\n";
fout << "\n";
fout << "	altera_syncram  altera_syncram_component (\n";
fout << "		.address_a (address),\n";
fout << "		.clock0 (clock),\n";
fout << "		.data_a (data),\n";
fout << "		.rden_a (rden),\n";
fout << "		.wren_a (wren),\n";
fout << "		.q_a (sub_wire0),\n";
fout << "		.aclr0 (1'b0),\n";
fout << "		.aclr1 (1'b0),\n";
fout << "		.address2_a (1'b1),\n";
fout << "		.address2_b (1'b1),\n";
fout << "		.address_b (1'b1),\n";
fout << "		.addressstall_a (1'b0),\n";
fout << "		.addressstall_b (1'b0),\n";
fout << "		.byteena_a (1'b1),\n";
fout << "		.byteena_b (1'b1),\n";
fout << "		.clock1 (1'b1),\n";
fout << "		.clocken0 (1'b1),\n";
fout << "		.clocken1 (1'b1),\n";
fout << "		.clocken2 (1'b1),\n";
fout << "		.clocken3 (1'b1),\n";
fout << "		.data_b (1'b1),\n";
fout << "		.eccencbypass (1'b0),\n";
fout << "		.eccencparity (8'b0),\n";
fout << "		.eccstatus ( ),\n";
fout << "		.q_b ( ),\n";
fout << "		.rden_b (1'b1),\n";
fout << "		.sclr (1'b0),\n";
fout << "		.wren_b (1'b0));\n";
fout << "	defparam\n";
fout << "		altera_syncram_component.width_byteena_a  = 1,\n";
fout << "		altera_syncram_component.clock_enable_input_a  = \"BYPASS\",\n";
fout << "		altera_syncram_component.clock_enable_output_a  = \"BYPASS\",\n";
fout << "/*\n";
fout << "`ifdef WINDOWS_PATH\n";
fout << "		altera_syncram_component.init_file = \"F:/Dropbox/CAAD_Server/MD_RL_Pipeline/Ethan_RL_Pipeline_1st_Order_SingleFloat_18.0/SourceCode/cell_ini_file_2_2_2.hex\"\n";
fout << "`elsif STX_PATH\n";
fout << "		altera_syncram_component.init_file = \"/home/vsachde/Dropbox/CAAD_Server/MD_RL_Pipeline/Ethan_RL_Pipeline_1st_Order_SingleFloat_18.0/SourceCode/cell_ini_file_2_2_2.hex\"\n";
fout << "`elsif STX_2ND_PATH\n";
fout << "		altera_syncram_component.init_file = \"/home/vsachde/Dropbox/CAAD_Server/MD_RL_Pipeline/MD_HDL_STX/SourceCode/cell_ini_file_2_2_2.hex\"\n";
fout << "`else\n";
fout << "		altera_syncram_component.init_file = \"/home/chunshu/Documents/Legacy/SourceCode/cell_ini_file_2_2_2.hex\"\n";
fout << "`endif\n";
fout << ",\n";
fout << "*/\n";
fout << "		altera_syncram_component.intended_device_family  = \"Stratix 10\",\n";
fout << "		altera_syncram_component.lpm_hint  = \"ENABLE_RUNTIME_MOD=NO\",\n";
fout << "		altera_syncram_component.lpm_type  = \"altera_syncram\",\n";
fout << "		altera_syncram_component.numwords_a  = PARTICLE_NUM,\n";
fout << "		altera_syncram_component.operation_mode  = \"SINGLE_PORT\",\n";
fout << "		altera_syncram_component.outdata_aclr_a  = \"NONE\",\n";
fout << "		altera_syncram_component.outdata_sclr_a  = \"NONE\",\n";
fout << "		altera_syncram_component.outdata_reg_a  = \"CLOCK0\",\n";
fout << "		altera_syncram_component.enable_force_to_zero  = \"TRUE\",\n";
fout << "		altera_syncram_component.power_up_uninitialized  = \"FALSE\",\n";
fout << "		altera_syncram_component.ram_block_type  = \"M20K\",\n";
fout << "		altera_syncram_component.read_during_write_mode_port_a  = \"DONT_CARE\",\n";
fout << "		altera_syncram_component.widthad_a  = ADDR_WIDTH,\n";
fout << "		altera_syncram_component.width_a  = DATA_WIDTH;\n";
fout << "\n";
fout << "\n";
fout << "endmodule\n";
fout << "\n";

	fout.close();

	return 1;
}

int main() {
	int i, j, k;
	for (i = 0; i < CELL_NUM_X; i++) {
		for (j = 0; j < CELL_NUM_Y; j++) {
			for (k = 0; k < CELL_NUM_Z; k++) {
				Gen_Pos_Cell(i+1, j+1, k+1, &common_src_path);
			}
		}
	}
	return 0;
}
