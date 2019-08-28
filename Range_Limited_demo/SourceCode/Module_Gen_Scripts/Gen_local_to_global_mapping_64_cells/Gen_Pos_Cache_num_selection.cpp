#include <fstream>
#include <math.h>
#include <ctime>
#include <string>
#include <stdlib.h>
#include <iostream>

#include "Gen_Pos_Cache_num_selection.h"

using namespace std;

std::string common_path = "/home/chunshu/Documents/Legacy";
std::string sim_script_out_path = "/mentor";
std::string common_src_path = common_path + "/SourceCode";
std::string sub_folder_path = "/LJArgon_v_File_64_Cells";
#define CELL_NUM_X 4
#define CELL_NUM_Y 4
#define CELL_NUM_Z 4

int Gen_Pos_Cache_Num_Selection(std::string* common_path){

	// Setup Generating file
	int cellx, celly, cellz;
	int iter;
	char filename[100];
	sprintf(filename,"local_to_global_mapping.txt");

	std::string path = *common_path + "/CellMemoryModules" + sub_folder_path + "/" + std::string(filename);
	std::string cell_mem_path = *common_path + "/CellMemoryModules" + sub_folder_path;
	std::ofstream fout;
	fout.open(path.c_str());
	if (fout.fail()){
		printf("open %s failed, exiting\n", path.c_str());
		exit(-1);
	}
	// for testing
	for(cellz = 0; cellz < 4; cellz++) {
		int z0 = cellz;
		int x0 = 0;
		int y0 = 0;
		int i, j;
		int n[14];
		// (222)
		n[0] = pbc_find_band_num(x0, y0, z0);
		// (223)
		n[1] = pbc_find_band_num(x0, y0, pbc_add_one(z0, CELL_NUM_Z));
		// (231)
		n[2] = pbc_find_band_num(x0, pbc_add_one(y0, CELL_NUM_Y), pbc_sub_one(z0, CELL_NUM_Z));
		// (232)
		n[3] = pbc_find_band_num(x0, pbc_add_one(y0, CELL_NUM_Y), z0);
		// (233)
		n[4] = pbc_find_band_num(x0, pbc_add_one(y0, CELL_NUM_Y), pbc_add_one(z0, CELL_NUM_Z));
		// (311)
		n[5] = pbc_find_band_num(pbc_add_one(x0, CELL_NUM_X), pbc_sub_one(y0, CELL_NUM_Y), pbc_sub_one(z0, CELL_NUM_Z));
		// (312)
		n[6] = pbc_find_band_num(pbc_add_one(x0, CELL_NUM_X), pbc_sub_one(y0, CELL_NUM_Y), z0);
		// (313)
		n[7] = pbc_find_band_num(pbc_add_one(x0, CELL_NUM_X), pbc_sub_one(y0, CELL_NUM_Y), pbc_add_one(z0, CELL_NUM_Z));
		// (321)
		n[8] = pbc_find_band_num(pbc_add_one(x0, CELL_NUM_X), y0, pbc_sub_one(z0, CELL_NUM_Z));
		// (322)
		n[9] = pbc_find_band_num(pbc_add_one(x0, CELL_NUM_X), y0, z0);
		// (323)
		n[10] = pbc_find_band_num(pbc_add_one(x0, CELL_NUM_X), y0, pbc_add_one(z0, CELL_NUM_Z));
		// (331)
		n[11] = pbc_find_band_num(pbc_add_one(x0, CELL_NUM_X), pbc_add_one(y0, CELL_NUM_Y), pbc_sub_one(z0, CELL_NUM_Z));
		// (332)
		n[12] = pbc_find_band_num(pbc_add_one(x0, CELL_NUM_X), pbc_add_one(y0, CELL_NUM_Y), z0);
		// (333)
		n[13] = pbc_find_band_num(pbc_add_one(x0, CELL_NUM_X), pbc_add_one(y0, CELL_NUM_Y), pbc_add_one(z0, CELL_NUM_Z));
		fout << "\n";
		int count = 0;
		/*
		for (i = 0; i < 64; i++) {
			int flag = 0;
			for (j = 0; j < 14; j++) {
				if (i == n[j]) {
					fout << "reg_FSM_to_Cell_rden[" << i << "] <= 1'b1;\n";
					flag = 1;
					break;
				}
			}
			if (flag == 0)
				fout << "reg_FSM_to_Cell_rden[" << i << "] <= 1'b0;\n";
		}
		for (i = 0; i < 64; i++) {
			int flag = 0;
			for (j = 0; j < 14; j++) {
				if (i == n[j]) {
					fout << "reg_FSM_to_Cell_read_addr[" << i+1 << "*CELL_ADDR_WIDTH-1:" << i << "*CELL_ADDR_WIDTH] <= FSM_to_Cell_read_addr_1_1[" << j+1 << "*CELL_ADDR_WIDTH-1:" << j << "*CELL_ADDR_WIDTH];\n";
					flag = 1;
					break;
				}
			}
			if (flag == 0)
				fout << "reg_FSM_to_Cell_read_addr[" << i+1 << "*CELL_ADDR_WIDTH-1:" << i << "*CELL_ADDR_WIDTH] <= 0;\n";
		}
		for (i = 0; i < 64; i++) {
			int flag = 0;
			for (j = 0; j < 14; j++) {
				if (i == n[j] && j == 0) {
					fout << "reg_to_force_cache_partial_force_valid[" << i << "] <= ref_forceoutput_valid_1_1;\n";
					flag = 1;
					break;
				}
				else if (i == n[j] && j != 0){
					fout << "reg_to_force_cache_partial_force_valid[" << i << "] <= neighbor_forceoutput_valid_1_1;\n";
					flag = 1;
					break;
				}
			}
			if (flag == 0)
				fout << "reg_to_force_cache_partial_force_valid[" << i << "] <= 1'b0;\n";
		}
		for (i = 0; i < 64; i++) {
			int flag = 0;
			for (j = 0; j < 14; j++) {
				if (i == n[j] && j == 0) {
					fout << "reg_to_force_cache_particle_id[" << i+1 << "*PARTICLE_ID_WIDTH-1:" << i << "*PARTICLE_ID_WIDTH] <= ref_particle_id_1_1;\n";
					flag = 1;
					break;
				}
				else if (i == n[j] && j != 0){
					fout << "reg_to_force_cache_particle_id[" << i+1 << "*PARTICLE_ID_WIDTH-1:" << i << "*PARTICLE_ID_WIDTH] <= neighbor_particle_id_1_1;\n";
					flag = 1;
					break;
				}
			}
			if (flag == 0)
				fout << "reg_to_force_cache_particle_id[" << i+1 << "*PARTICLE_ID_WIDTH-1:" << i << "*PARTICLE_ID_WIDTH] <= 0;\n";
		}
		*/
		for (i = 0; i < 64; i++) {
			int flag = 0;
			for (j = 0; j < 14; j++) {
				if (i == n[j] && j == 0) {
					fout << "reg_to_force_cache_LJ_Force_Z[" << i+1 << "*DATA_WIDTH-1:" << i << "*DATA_WIDTH] <= ref_LJ_Force_Z_1_1;\n";
					flag = 1;
					break;
				}
				else if (i == n[j] && j != 0){
					fout << "reg_to_force_cache_LJ_Force_Z[" << i+1 << "*DATA_WIDTH-1:" << i << "*DATA_WIDTH] <= neighbor_LJ_Force_Z_1_1;\n";
					flag = 1;
					break;
				}
			}
			if (flag == 0)
				fout << "reg_to_force_cache_LJ_Force_Z[" << i+1 << "*DATA_WIDTH-1:" << i << "*DATA_WIDTH] <= 0;\n";
		}
		for (i = 0; i < 64; i++) {
			int flag = 0;
			for (j = 0; j < 14; j++) {
				if (i == n[j] && j == 0) {
					fout << "reg_to_force_cache_LJ_Force_Y[" << i+1 << "*DATA_WIDTH-1:" << i << "*DATA_WIDTH] <= ref_LJ_Force_Y_1_1;\n";
					flag = 1;
					break;
				}
				else if (i == n[j] && j != 0){
					fout << "reg_to_force_cache_LJ_Force_Y[" << i+1 << "*DATA_WIDTH-1:" << i << "*DATA_WIDTH] <= neighbor_LJ_Force_Y_1_1;\n";
					flag = 1;
					break;
				}
			}
			if (flag == 0)
				fout << "reg_to_force_cache_LJ_Force_Y[" << i+1 << "*DATA_WIDTH-1:" << i << "*DATA_WIDTH] <= 0;\n";
		}
		for (i = 0; i < 64; i++) {
			int flag = 0;
			for (j = 0; j < 14; j++) {
				if (i == n[j] && j == 0) {
					fout << "reg_to_force_cache_LJ_Force_X[" << i+1 << "*DATA_WIDTH-1:" << i << "*DATA_WIDTH] <= ref_LJ_Force_X_1_1;\n";
					flag = 1;
					break;
				}
				else if (i == n[j] && j != 0){
					fout << "reg_to_force_cache_LJ_Force_X[" << i+1 << "*DATA_WIDTH-1:" << i << "*DATA_WIDTH] <= neighbor_LJ_Force_X_1_1;\n";
					flag = 1;
					break;
				}
			}
			if (flag == 0)
				fout << "reg_to_force_cache_LJ_Force_X[" << i+1 << "*DATA_WIDTH-1:" << i << "*DATA_WIDTH] <= 0;\n";
		}
	}
	fout << "\n";
	fout << "reg_FSM_to_Cell_read_addr <= {\n";
	for (iter = 0; iter < 63; iter++) {
		fout << "														dummy_zeros,\n";
	}
	fout << "														dummy_zeros\n";
	fout << "														};\n";
	
	for(cellx = 0; cellx < CELL_NUM_X; cellx++) {
	for(celly = 0; celly < CELL_NUM_Y; celly++) {
	fout << "	\n";
	fout << "	// Cell selection for pipeline " << cellx + 1 << "-" << celly + 1 << "\n";
	fout << "	wire [CELL_ID_WIDTH-1:0] cell_set_select_" << cellx + 1 << "_" << celly + 1 << ";\n";
	fout << "	reg [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_" << cellx + 1 << "_" << celly + 1 << ";\n";
	for(cellz = 0; cellz < CELL_NUM_Z; cellz++) {
	fout << "	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_" << cellx + 1 << "_" << celly + 1 << "_" << cellz + 1 << ";\n";
	fout << "	assign cells_to_pipeline_" << cellx + 1 << "_" << celly + 1 << "_" << cellz + 1 << " = {\n";
	gen_14_cell_num(cellx, celly, cellz, fout);
	fout << "												};\n";
	}
	fout << "	always@(*)\n";
	fout << "		begin\n";
	fout << "		case(cell_set_select_" << cellx + 1 << "_" << celly + 1 << ")\n";
	for(cellz = 0; cellz < CELL_NUM_Z; cellz++) {
	fout << "			" << cellz + 1 << ":\n"; 
	fout << "				begin\n";
	fout << "				cells_to_pipeline_" << cellx + 1 << "_" << celly + 1 << " <= cells_to_pipeline_" << cellx + 1 << "_" << celly + 1 << "_" << cellz + 1 << ";\n";
	fout << "				end\n";
	}
	fout << "			default:\n";
	fout << "				begin\n";
	fout << "				cells_to_pipeline_" << cellx + 1 << "_" << celly + 1 << " <= cells_to_pipeline_" << cellx + 1 << "_" << celly + 1 << "_1;\n";
	fout << "				end\n";
	fout << "		endcase\n";
	fout << "		end\n";
}
}

	fout.close();

	return 1;
}
int pbc_add_one(int a, int boundary) {
	return (a + 1 == boundary) ? 0 : a + 1;
}
int pbc_sub_one(int a, int boundary) {
	return (a - 1 < 0) ? boundary-1 : a - 1;
}
int pbc_find_band_num(int x, int y, int z) {
	// x, y, z start from 0
	int num;
	num = x*CELL_NUM_Y*CELL_NUM_Z + y*CELL_NUM_Z + z;
	return num;
}
void gen_14_cell_num(int x0, int y0, int z0, std::ofstream &fout) {
	// (222)
	int n222 = pbc_find_band_num(x0, y0, z0);
	// (223)
	int n223 = pbc_find_band_num(x0, y0, pbc_add_one(z0, CELL_NUM_Z));
	// (231)
	int n231 = pbc_find_band_num(x0, pbc_add_one(y0, CELL_NUM_Y), pbc_sub_one(z0, CELL_NUM_Z));
	// (232)
	int n232 = pbc_find_band_num(x0, pbc_add_one(y0, CELL_NUM_Y), z0);
	// (233)
	int n233 = pbc_find_band_num(x0, pbc_add_one(y0, CELL_NUM_Y), pbc_add_one(z0, CELL_NUM_Z));
	// (311)
	int n311 = pbc_find_band_num(pbc_add_one(x0, CELL_NUM_X), pbc_sub_one(y0, CELL_NUM_Y), pbc_sub_one(z0, CELL_NUM_Z));
	// (312)
	int n312 = pbc_find_band_num(pbc_add_one(x0, CELL_NUM_X), pbc_sub_one(y0, CELL_NUM_Y), z0);
	// (313)
	int n313 = pbc_find_band_num(pbc_add_one(x0, CELL_NUM_X), pbc_sub_one(y0, CELL_NUM_Y), pbc_add_one(z0, CELL_NUM_Z));
	// (321)
	int n321 = pbc_find_band_num(pbc_add_one(x0, CELL_NUM_X), y0, pbc_sub_one(z0, CELL_NUM_Z));
	// (322)
	int n322 = pbc_find_band_num(pbc_add_one(x0, CELL_NUM_X), y0, z0);
	// (323)
	int n323 = pbc_find_band_num(pbc_add_one(x0, CELL_NUM_X), y0, pbc_add_one(z0, CELL_NUM_Z));
	// (331)
	int n331 = pbc_find_band_num(pbc_add_one(x0, CELL_NUM_X), pbc_add_one(y0, CELL_NUM_Y), pbc_sub_one(z0, CELL_NUM_Z));
	// (332)
	int n332 = pbc_find_band_num(pbc_add_one(x0, CELL_NUM_X), pbc_add_one(y0, CELL_NUM_Y), z0);
	// (333)
	int n333 = pbc_find_band_num(pbc_add_one(x0, CELL_NUM_X), pbc_add_one(y0, CELL_NUM_Y), pbc_add_one(z0, CELL_NUM_Z));
	fout << "												Position_Cache_readout_position[" << n333+1 << "*3*DATA_WIDTH-1:" << n333 << "*3*DATA_WIDTH],\n";
	fout << "												Position_Cache_readout_position[" << n332+1 << "*3*DATA_WIDTH-1:" << n332 << "*3*DATA_WIDTH],\n";
	fout << "												Position_Cache_readout_position[" << n331+1 << "*3*DATA_WIDTH-1:" << n331 << "*3*DATA_WIDTH],\n";
	fout << "												Position_Cache_readout_position[" << n323+1 << "*3*DATA_WIDTH-1:" << n323 << "*3*DATA_WIDTH],\n";
	fout << "												Position_Cache_readout_position[" << n322+1 << "*3*DATA_WIDTH-1:" << n322 << "*3*DATA_WIDTH],\n";
	fout << "												Position_Cache_readout_position[" << n321+1 << "*3*DATA_WIDTH-1:" << n321 << "*3*DATA_WIDTH],\n";
	fout << "												Position_Cache_readout_position[" << n313+1 << "*3*DATA_WIDTH-1:" << n313 << "*3*DATA_WIDTH],\n";
	fout << "												Position_Cache_readout_position[" << n312+1 << "*3*DATA_WIDTH-1:" << n312 << "*3*DATA_WIDTH],\n";
	fout << "												Position_Cache_readout_position[" << n311+1 << "*3*DATA_WIDTH-1:" << n311 << "*3*DATA_WIDTH],\n";
	fout << "												Position_Cache_readout_position[" << n233+1 << "*3*DATA_WIDTH-1:" << n233 << "*3*DATA_WIDTH],\n";
	fout << "												Position_Cache_readout_position[" << n232+1 << "*3*DATA_WIDTH-1:" << n232 << "*3*DATA_WIDTH],\n";
	fout << "												Position_Cache_readout_position[" << n231+1 << "*3*DATA_WIDTH-1:" << n231 << "*3*DATA_WIDTH],\n";
	fout << "												Position_Cache_readout_position[" << n223+1 << "*3*DATA_WIDTH-1:" << n223 << "*3*DATA_WIDTH],\n";
	fout << "												Position_Cache_readout_position[" << n222+1 << "*3*DATA_WIDTH-1:" << n222 << "*3*DATA_WIDTH]\n";
}
void gen_14_cell_readout_addr(int x0, int y0, int z0, std::ofstream &fout) {
	// (222)
	int n222 = pbc_find_band_num(x0, y0, z0);
	// (223)
	int n223 = pbc_find_band_num(x0, y0, pbc_add_one(z0, CELL_NUM_Z));
	// (231)
	int n231 = pbc_find_band_num(x0, pbc_add_one(y0, CELL_NUM_Y), pbc_sub_one(z0, CELL_NUM_Z));
	// (232)
	int n232 = pbc_find_band_num(x0, pbc_add_one(y0, CELL_NUM_Y), z0);
	// (233)
	int n233 = pbc_find_band_num(x0, pbc_add_one(y0, CELL_NUM_Y), pbc_add_one(z0, CELL_NUM_Z));
	// (311)
	int n311 = pbc_find_band_num(pbc_add_one(x0, CELL_NUM_X), pbc_sub_one(y0, CELL_NUM_Y), pbc_sub_one(z0, CELL_NUM_Z));
	// (312)
	int n312 = pbc_find_band_num(pbc_add_one(x0, CELL_NUM_X), pbc_sub_one(y0, CELL_NUM_Y), z0);
	// (313)
	int n313 = pbc_find_band_num(pbc_add_one(x0, CELL_NUM_X), pbc_sub_one(y0, CELL_NUM_Y), pbc_add_one(z0, CELL_NUM_Z));
	// (321)
	int n321 = pbc_find_band_num(pbc_add_one(x0, CELL_NUM_X), y0, pbc_sub_one(z0, CELL_NUM_Z));
	// (322)
	int n322 = pbc_find_band_num(pbc_add_one(x0, CELL_NUM_X), y0, z0);
	// (323)
	int n323 = pbc_find_band_num(pbc_add_one(x0, CELL_NUM_X), y0, pbc_add_one(z0, CELL_NUM_Z));
	// (331)
	int n331 = pbc_find_band_num(pbc_add_one(x0, CELL_NUM_X), pbc_add_one(y0, CELL_NUM_Y), pbc_sub_one(z0, CELL_NUM_Z));
	// (332)
	int n332 = pbc_find_band_num(pbc_add_one(x0, CELL_NUM_X), pbc_add_one(y0, CELL_NUM_Y), z0);
	// (333)
	int n333 = pbc_find_band_num(pbc_add_one(x0, CELL_NUM_X), pbc_add_one(y0, CELL_NUM_Y), pbc_add_one(z0, CELL_NUM_Z));
	fout << "												FSM_to_Cell_read_addr[" << n333+1 << "*CELL_ADDR_WIDTH-1:" << n333 << "*CELL_ADDR_WIDTH],\n";
	fout << "												FSM_to_Cell_read_addr[" << n332+1 << "*CELL_ADDR_WIDTH-1:" << n332 << "*CELL_ADDR_WIDTH],\n";
	fout << "												FSM_to_Cell_read_addr[" << n331+1 << "*CELL_ADDR_WIDTH-1:" << n331 << "*CELL_ADDR_WIDTH],\n";
	fout << "												FSM_to_Cell_read_addr[" << n323+1 << "*CELL_ADDR_WIDTH-1:" << n323 << "*CELL_ADDR_WIDTH],\n";
	fout << "												FSM_to_Cell_read_addr[" << n322+1 << "*CELL_ADDR_WIDTH-1:" << n322 << "*CELL_ADDR_WIDTH],\n";
	fout << "												FSM_to_Cell_read_addr[" << n321+1 << "*CELL_ADDR_WIDTH-1:" << n321 << "*CELL_ADDR_WIDTH],\n";
	fout << "												FSM_to_Cell_read_addr[" << n313+1 << "*CELL_ADDR_WIDTH-1:" << n313 << "*CELL_ADDR_WIDTH],\n";
	fout << "												FSM_to_Cell_read_addr[" << n312+1 << "*CELL_ADDR_WIDTH-1:" << n312 << "*CELL_ADDR_WIDTH],\n";
	fout << "												FSM_to_Cell_read_addr[" << n311+1 << "*CELL_ADDR_WIDTH-1:" << n311 << "*CELL_ADDR_WIDTH],\n";
	fout << "												FSM_to_Cell_read_addr[" << n233+1 << "*CELL_ADDR_WIDTH-1:" << n233 << "*CELL_ADDR_WIDTH],\n";
	fout << "												FSM_to_Cell_read_addr[" << n232+1 << "*CELL_ADDR_WIDTH-1:" << n232 << "*CELL_ADDR_WIDTH],\n";
	fout << "												FSM_to_Cell_read_addr[" << n231+1 << "*CELL_ADDR_WIDTH-1:" << n231 << "*CELL_ADDR_WIDTH],\n";
	fout << "												FSM_to_Cell_read_addr[" << n223+1 << "*CELL_ADDR_WIDTH-1:" << n223 << "*CELL_ADDR_WIDTH],\n";
	fout << "												FSM_to_Cell_read_addr[" << n222+1 << "*CELL_ADDR_WIDTH-1:" << n222 << "*CELL_ADDR_WIDTH],\n";
}
int main() {
	Gen_Pos_Cache_Num_Selection(&common_src_path);
	return 0;
}
