#include <fstream>
#include <math.h>
#include <ctime>
#include <string>
#include <stdlib.h>

#include "Gen_Pos_Cell.h"

using namespace std;

int Gen_Pos_Cell(int cellx, int celly, int cellz, std::string* common_path){

	// Setup Generating file
	char filename[100];
	sprintf(filename,"cell_%d_%d_%d.v", cellx, celly, cellz);

	std::string path = *common_path + "/CellMemoryModules/" + std::string(filename);
	std::string cell_mem_path = *common_path + "/CellMemoryModules";
	std::ofstream fout;
	fout.open(path.c_str());
	if (fout.fail()){
		printf("open %s failed, exiting\n", path.c_str());
		exit(-1);
	}
	
	fout << "/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////\n";
	fout << "// Module: cell_"<< cellx <<"_"<< celly <<"_"<< cellz <<".v\n";
	fout << "//\n";
	fout << "//	Function:\n";
	fout << "//\t\t\t\tMemory modules holding the position value of each cells\n";
	fout << "//\n";
	fout << "//	Purpose:\n";
	fout << "//\t\t\t\tProviding particle position data for force evaluation and motion update\n";
	fout << "//\n";
	fout << "// Data Organization:\n";
	fout << "//\t\t\t\tAddress 0 for each cell module: # of particles in the cell.\n";
	fout << "//\t\t\t\tMSB-LSB: {posz, posy, posx}\n";
	fout << "//\n";
	fout << "// Used by:\n";
	fout << "//\t\t\t\tPos_Cache_" << cellx <<  "_" << celly << "_" << cellz << ".v\n";
	fout << "//\n";
	fout << "// Dependency:\n";
	fout << "//\t\t\t\tcell_ini_file_"<< cellx <<"_"<< celly <<"_"<< cellz <<".hex / cell_ini_file_"<< cellx <<"_"<< celly <<"_"<< cellz <<".mif\n";
	fout << "//\n";
	fout << "// Testbench:\n";
	fout << "//\t\t\t\tRL_LJ_Top_tb.v\n";
	fout << "//\n";
	fout << "// Timing:\n";
	fout << "//\t\t\t\t2 cycles reading delay from input address and output data.\n";
	fout << "//\n";
	fout << "// Created by:\n";
	fout << "//\t\t\t\tChen Yang's Script (Gen_Pos_Cell.cpp), based on Single Port RAM IP core\n";
	fout << "/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////\n\n";

	fout << "`include \"../define.v\"\n\n";

	fout << "`timescale 1 ps / 1 ps\n\n";
	
	fout << "module cell_"<< cellx <<"_"<< celly <<"_"<< cellz <<"\n";
	fout << "#(\n";
	fout << "\tparameter DATA_WIDTH = 32*3,\n";
	fout << "\tparameter PARTICLE_NUM = 220,\n";
	fout << "\tparameter ADDR_WIDTH = 8\n";
	fout << ")\n";
	fout << "(\n";
	fout << "\taddress,\n";
	fout << "\tclock,\n";
	fout << "\tdata,\n";
	fout << "\trden,\n";
	fout << "\twren,\n";
	fout << "\tq\n";
	fout << ");\n\n";

	fout << "\tinput  [ADDR_WIDTH-1:0]  address;\n";
	fout << "\tinput    clock;\n";
	fout << "\tinput  [DATA_WIDTH-1:0]  data;\n";
	fout << "\tinput    rden;\n";
	fout << "\tinput    wren;\n";
	fout << "\toutput [DATA_WIDTH-1:0]  q;\n\n";

	fout << "\ttri1     clock;\n";
	fout << "\ttri1     rden;\n\n";

	fout << "\twire [DATA_WIDTH-1:0] sub_wire0;\n";
	fout << "\twire [DATA_WIDTH-1:0] q = sub_wire0[DATA_WIDTH-1:0];\n\n";

	fout << "\taltera_syncram  altera_syncram_component (\n";
	fout << "\t\t.address_a (address),\n";
	fout << "\t\t.clock0 (clock),\n";
	fout << "\t\t.data_a (data),\n";
	fout << "\t\t.rden_a (rden),\n";
	fout << "\t\t.wren_a (wren),\n";
	fout << "\t\t.q_a (sub_wire0),\n";
	fout << "\t\t.aclr0 (1'b0),\n";
	fout << "\t\t.aclr1 (1'b0),\n";
	fout << "\t\t.address2_a (1'b1),\n";
	fout << "\t\t.address2_b (1'b1),\n";
	fout << "\t\t.address_b (1'b1),\n";
	fout << "\t\t.addressstall_a (1'b0),\n";
	fout << "\t\t.addressstall_b (1'b0),\n";
	fout << "\t\t.byteena_a (1'b1),\n";
	fout << "\t\t.byteena_b (1'b1),\n";
	fout << "\t\t.clock1 (1'b1),\n";
	fout << "\t\t.clocken0 (1'b1),\n";
	fout << "\t\t.clocken1 (1'b1),\n";
	fout << "\t\t.clocken2 (1'b1),\n";
	fout << "\t\t.clocken3 (1'b1),\n";
	fout << "\t\t.data_b (1'b1),\n";
	fout << "\t\t.eccencbypass (1'b0),\n";
	fout << "\t\t.eccencparity (8'b0),\n";
	fout << "\t\t.eccstatus ( ),\n";
	fout << "\t\t.q_b ( ),\n";
	fout << "\t\t.rden_b (1'b1),\n";
	fout << "\t\t.sclr (1'b0),\n";
	fout << "\t\t.wren_b (1'b0));\n";
	fout << "\tdefparam\n";
	fout << "\t\taltera_syncram_component.width_byteena_a  = 1,\n";
	fout << "\t\taltera_syncram_component.clock_enable_input_a  = \"BYPASS\",\n";
	fout << "\t\taltera_syncram_component.clock_enable_output_a  = \"BYPASS\",\n\n";

	fout << "`ifdef WINDOWS_PATH\n";
	fout << "\t\taltera_syncram_component.init_file = \"" << cell_mem_path << "/cell_ini_file_" << cellx <<"_"<< celly <<"_"<< cellz <<".hex\"\n";
	fout << "`elsif STX_PATH\n";
	fout << "\t\taltera_syncram_component.init_file = \"/home/vsachde/Dropbox/CAAD_Server/MD_RL_Pipeline/Ethan_RL_Pipeline_1st_Order_SingleFloat_18.0/SourceCode/cell_ini_file_"<< cellx <<"_"<< celly <<"_"<< cellz <<".hex\"\n";
	fout << "`elsif STX_2ND_PATH\n";
	fout << "\t\taltera_syncram_component.init_file = \"/home/vsachde/Dropbox/CAAD_Server/MD_RL_Pipeline/MD_HDL_STX/SourceCode/cell_ini_file_"<< cellx <<"_"<< celly <<"_"<< cellz <<".hex\"\n";
	fout << "`else\n";
	fout << "\t\taltera_syncram_component.init_file = \"" << cell_mem_path << "/cell_ini_file_" << cellx <<"_"<< celly <<"_"<< cellz <<".hex\"\n";
	fout << "`endif\n";
	fout << ",\n";
	fout << "\t\taltera_syncram_component.intended_device_family  = \"Stratix 10\",\n";
	fout << "\t\taltera_syncram_component.lpm_hint  = \"ENABLE_RUNTIME_MOD=NO\",\n";
	fout << "\t\taltera_syncram_component.lpm_type  = \"altera_syncram\",\n";
	fout << "\t\taltera_syncram_component.numwords_a  = PARTICLE_NUM,\n";
	fout << "\t\taltera_syncram_component.operation_mode  = \"SINGLE_PORT\",\n";
	fout << "\t\taltera_syncram_component.outdata_aclr_a  = \"NONE\",\n";
	fout << "\t\taltera_syncram_component.outdata_sclr_a  = \"NONE\",\n";
	fout << "\t\taltera_syncram_component.outdata_reg_a  = \"CLOCK0\",\n";
	fout << "\t\taltera_syncram_component.enable_force_to_zero  = \"TRUE\",\n";
	fout << "\t\taltera_syncram_component.power_up_uninitialized  = \"FALSE\",\n";
	fout << "\t\taltera_syncram_component.ram_block_type  = \"M20K\",\n";
	fout << "\t\taltera_syncram_component.read_during_write_mode_port_a  = \"DONT_CARE\",\n";
	fout << "\t\taltera_syncram_component.widthad_a  = ADDR_WIDTH,\n";
	fout << "\t\taltera_syncram_component.width_a  = DATA_WIDTH;\n\n\n";

	fout << "endmodule\n";

	fout.close();

	return 1;
}
