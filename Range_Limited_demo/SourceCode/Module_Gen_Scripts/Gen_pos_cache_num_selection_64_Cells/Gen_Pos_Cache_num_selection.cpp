#include <fstream>
#include <math.h>
#include <ctime>
#include <string>
#include <stdlib.h>
#include <iostream>

#include "Gen_Pos_Cache_num_selection.h"

using namespace std;

std::string common_path = "./";
std::string sim_script_out_path = "";
std::string common_src_path = common_path + "";
std::string sub_folder_path = "";
#define CELL_NUM_X 4
#define CELL_NUM_Y 4
#define CELL_NUM_Z 4

int Gen_Pos_Cache_Num_Selection(std::string* common_path){

	// Setup Generating file
	int cellx, celly, cellz;
	int i, j, k, l, m;
	int iter;
	char filename[100];
	sprintf(filename,"Pos_Cache_Num_Selection_in_Top_64_Cells.txt");

	std::string path = *common_path + "" + sub_folder_path + "/" + std::string(filename);
	std::string cell_mem_path = *common_path + "" + sub_folder_path;
	std::ofstream fout;
	fout.open(path.c_str());
	if (fout.fail()){
		printf("open %s failed, exiting\n", path.c_str());
		exit(-1);
	}
	for (i = 1; i <= 4; i++) {
	for (j = 1; j <= 4; j++) {
fout << "	// Force writeback signals\n";
fout << "	wire [NUM_EVAL_UNIT*PARTICLE_ID_WIDTH-1:0] ref_particle_id_" << i << "_" << j << ";\n";
fout << "	wire [NUM_EVAL_UNIT*DATA_WIDTH-1:0] ref_LJ_Force_X_" << i << "_" << j << ";\n";
fout << "	wire [NUM_EVAL_UNIT*DATA_WIDTH-1:0] ref_LJ_Force_Y_" << i << "_" << j << ";\n";
fout << "	wire [NUM_EVAL_UNIT*DATA_WIDTH-1:0] ref_LJ_Force_Z_" << i << "_" << j << ";\n";
fout << "	wire [NUM_EVAL_UNIT-1:0] ref_forceoutput_valid_" << i << "_" << j << ";\n";
fout << "	wire [NUM_EVAL_UNIT*PARTICLE_ID_WIDTH-1:0] neighbor_particle_id_" << i << "_" << j << ";\n";
fout << "	wire [NUM_EVAL_UNIT*DATA_WIDTH-1:0] neighbor_LJ_Force_X_" << i << "_" << j << ";\n";
fout << "	wire [NUM_EVAL_UNIT*DATA_WIDTH-1:0] neighbor_LJ_Force_Y_" << i << "_" << j << ";\n";
fout << "	wire [NUM_EVAL_UNIT*DATA_WIDTH-1:0] neighbor_LJ_Force_Z_" << i << "_" << j << ";\n";
fout << "	wire [NUM_EVAL_UNIT-1:0] neighbor_forceoutput_valid_" << i << "_" << j << ";\n";
	}
	}
	for (i = 0; i < 4; i++) {
	for (j = 0; j < 4; j++) {
fout << "	RL_LJ_Top_64_Cells\n";
fout << "	#(\n";
fout << "		.DATA_WIDTH(DATA_WIDTH),\n";
fout << "		.TIME_STEP(TIME_STEP),\n";
fout << "		// The home cell this unit is working on, always (222)\n";
fout << "		.CELL_X(4'd2),\n";
fout << "		.CELL_Y(4'd2),\n";
fout << "		.CELL_Z(4'd2),\n";
fout << "		.GLOBAL_CELL_X(4'd1),\n";
fout << "		.GLOBAL_CELL_Y(4'd1),\n";
fout << "		.X_DIM(X_DIM),\n";
fout << "		.Y_DIM(Y_DIM),\n";
fout << "		.Z_DIM(Z_DIM),\n";
fout << "		.TOTAL_CELL_NUM(TOTAL_CELL_NUM),\n";
fout << "		.NUM_EVAL_UNIT(NUM_EVAL_UNIT),\n";
fout << "		.MAX_CELL_COUNT_PER_DIM(MAX_CELL_COUNT_PER_DIM),\n";
fout << "		.NUM_NEIGHBOR_CELLS(NUM_NEIGHBOR_CELLS),\n";
fout << "		.CELL_ID_WIDTH(CELL_ID_WIDTH),\n";
fout << "		.MAX_CELL_PARTICLE_NUM(MAX_CELL_PARTICLE_NUM),\n";
fout << "		.CELL_ADDR_WIDTH(CELL_ADDR_WIDTH),\n";
fout << "		.PARTICLE_ID_WIDTH(PARTICLE_ID_WIDTH),\n";
fout << "		// Filter parameters\n";
fout << "		.NUM_FILTER(NUM_FILTER),\n";
fout << "		.ARBITER_MSB(ARBITER_MSB),\n";
fout << "		.FILTER_BUFFER_DEPTH(FILTER_BUFFER_DEPTH),\n";
fout << "		.FILTER_BUFFER_ADDR_WIDTH(FILTER_BUFFER_ADDR_WIDTH),\n";
fout << "		.CUTOFF_2(CUTOFF_2),\n";
fout << "		.CUTOFF_TIMES_SQRT_3(CUTOFF_TIMES_SQRT_3),\n";
fout << "		.FIXED_POINT_WIDTH(FIXED_POINT_WIDTH),\n";
fout << "		.FILTER_IN_PATCH_0_BITS(FILTER_IN_PATCH_0_BITS),\n";
fout << "		// Bounding box parameters, used when applying PBC inside r2 evaluation\n";
fout << "		.BOUNDING_BOX_X(BOUNDING_BOX_X),\n";
fout << "		.BOUNDING_BOX_Y(BOUNDING_BOX_Y),\n";
fout << "		.BOUNDING_BOX_Z(BOUNDING_BOX_Z),\n";
fout << "		.HALF_BOUNDING_BOX_X_POS(HALF_BOUNDING_BOX_X_POS),\n";
fout << "		.HALF_BOUNDING_BOX_Y_POS(HALF_BOUNDING_BOX_Y_POS),\n";
fout << "		.HALF_BOUNDING_BOX_Z_POS(HALF_BOUNDING_BOX_Z_POS),\n";
fout << "		.HALF_BOUNDING_BOX_X_NEG(HALF_BOUNDING_BOX_X_NEG),\n";
fout << "		.HALF_BOUNDING_BOX_Y_NEG(HALF_BOUNDING_BOX_Y_NEG),\n";
fout << "		.HALF_BOUNDING_BOX_Z_NEG(HALF_BOUNDING_BOX_Z_NEG),\n";
fout << "		// Force Evaluation parameters\n";
fout << "		.SEGMENT_NUM(SEGMENT_NUM),\n";
fout << "		.SEGMENT_WIDTH(SEGMENT_WIDTH),\n";
fout << "		.BIN_NUM(BIN_NUM),\n";
fout << "		.BIN_WIDTH(BIN_WIDTH),\n";
fout << "		.LOOKUP_NUM(LOOKUP_NUM),\n";
fout << "		.LOOKUP_ADDR_WIDTH(LOOKUP_ADDR_WIDTH),\n";
fout << "		// Force (accmulation) cache parameters\n";
fout << "		.FORCE_CACHE_BUFFER_DEPTH(FORCE_CACHE_BUFFER_DEPTH),\n";
fout << "		.FORCE_CACHE_BUFFER_ADDR_WIDTH(FORCE_CACHE_BUFFER_ADDR_WIDTH)\n";
fout << "	)\n";
fout << "	RL_LJ_Top_64_Cells_" << i << "_" << j << "\n";
fout << "	(\n";
fout << "		.clk(clk),\n";
fout << "		.rst(rst),\n";
fout << "		.start(start),\n";
fout << "		.from_cells_particle_info(cells_to_pipeline_" << i << "_" << j << "),\n";
fout << "		.Cell_to_FSM_read_success_bit(Cell_to_FSM_read_success_bit_" << i << "_" << j << "),\n";
fout << "\n";		
fout << "		// From motion update\n";
fout << "		.motion_update_done(out_motion_update_done),\n";
fout << "\n";		
fout << "		//From other pipelines\n";
fout << "		.all_pipelines_done_reading(all_pipelines_done_reading),\n";
fout << "											\n";
fout << "		// To force caches\n";
fout << "		.ref_particle_id(ref_particle_id[" << 4*i+j+1 << "*PARTICLE_ID_WIDTH-1:" << 4*i+j << "*PARTICLE_ID_WIDTH]),\n";
fout << "		.ref_LJ_Force_X(ref_LJ_Force_X[" << 4*i+j+1 << "*DATA_WIDTH-1:" << 4*i+j << "*DATA_WIDTH]),\n";
fout << "		.ref_LJ_Force_Y(ref_LJ_Force_Y[" << 4*i+j+1 << "*DATA_WIDTH-1:" << 4*i+j << "*DATA_WIDTH]),\n";
fout << "		.ref_LJ_Force_Z(ref_LJ_Force_Z[" << 4*i+j+1 << "*DATA_WIDTH-1:" << 4*i+j << "*DATA_WIDTH]),\n";
fout << "		.ref_forceoutput_valid(ref_forceoutput_valid[" << 4*i+j+1 << "*PARTICLE_ID_WIDTH-1:" << 4*i+j << "*PARTICLE_ID_WIDTH]]),\n";
fout << "		.neighbor_particle_id(neighbor_particle_id[" << 4*i+j << "]),\n";
fout << "		.neighbor_LJ_Force_X(neighbor_LJ_Force_X[" << 4*i+j+1 << "*DATA_WIDTH-1:" << 4*i+j << "*DATA_WIDTH]),\n";
fout << "		.neighbor_LJ_Force_Y(neighbor_LJ_Force_Y[" << 4*i+j+1 << "*DATA_WIDTH-1:" << 4*i+j << "*DATA_WIDTH]),\n";
fout << "		.neighbor_LJ_Force_Z(neighbor_LJ_Force_Z[" << 4*i+j+1 << "*DATA_WIDTH-1:" << 4*i+j << "*DATA_WIDTH]),\n";
fout << "		.neighbor_forceoutput_valid(neighbor_forceoutput_valid[" << 4*i+j << "]),\n";
fout << "\n";		
fout << "		// pair gen done signals\n";
fout << "		.out_home_cell_evaluation_done(out_home_cell_evaluation_done_" << i << "_" << j << "),\n";
fout << "\n";		
fout << "		// To caches\n";
fout << "		.out_FSM_to_cell_read_addr(FSM_to_Cell_read_addr_" << i << "_" << j << "),\n";
fout << "		.FSM_home_cell_id(cellz_" << i << "_" << j << "),\n";
fout << "		.enable_reading(enable_reading_" << i << "_" << j << "),\n";
fout << "\n";		
fout << "		// To motion update\n";
fout << "		.out_Motion_Update_start(Motion_Update_start_" << i << "_" << j << ")\n";
fout << "	);\n";
	
	}
	}
	for (i = 1; i <= 4; i++) {
	for (j = 1; j <= 4; j++) {
	
fout << "	// Input to the pipeline\n";
fout << "	wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline_" << i << "_" << j << ";\n";
fout << "\n";	
fout << "	// Output from the pipeline\n";
fout << "	wire [(NUM_NEIGHBOR_CELLS+1)*CELL_ADDR_WIDTH-1:0] FSM_to_Cell_read_addr_" << i << "_" << j << ";\n";
fout << "	wire Motion_Update_start_" << i << "_" << j << ";\n";
fout << "	wire [CELL_ID_WIDTH-1:0] cellz_" << i << "_" << j << ";\n";
fout << "	wire [NUM_NEIGHBOR_CELLS:0] enable_reading_" << i << "_" << j << ";\n";
fout << "	wire [NUM_NEIGHBOR_CELLS:0] Cell_to_FSM_read_success_bit_" << i << "_" << j << ";\n";

	}
	}
fout << "		case (cellz)\n";
	int n[14][4][4];
	for(cellz = 0; cellz < 4; cellz++) {
fout << "			" << cellz+1 << ":\n";
fout << "				begin\n";
	for(cellx = 0; cellx < 4; cellx++) {
	for(celly = 0; celly < 4; celly++) {
		int x0 = cellx;
		int y0 = celly;
		int z0 = cellz;
		// (222)
		n[0][cellx][celly] = pbc_find_band_num(x0, y0, z0);
		// (223)
		n[1][cellx][celly] = pbc_find_band_num(x0, y0, pbc_add_one(z0, CELL_NUM_Z));
		// (231)
		n[2][cellx][celly] = pbc_find_band_num(x0, pbc_add_one(y0, CELL_NUM_Y), pbc_sub_one(z0, CELL_NUM_Z));
		// (232)
		n[3][cellx][celly] = pbc_find_band_num(x0, pbc_add_one(y0, CELL_NUM_Y), z0);
		// (233)
		n[4][cellx][celly] = pbc_find_band_num(x0, pbc_add_one(y0, CELL_NUM_Y), pbc_add_one(z0, CELL_NUM_Z));
		// (311)
		n[5][cellx][celly] = pbc_find_band_num(pbc_add_one(x0, CELL_NUM_X), pbc_sub_one(y0, CELL_NUM_Y), pbc_sub_one(z0, CELL_NUM_Z));
		// (312)
		n[6][cellx][celly] = pbc_find_band_num(pbc_add_one(x0, CELL_NUM_X), pbc_sub_one(y0, CELL_NUM_Y), z0);
		// (313)
		n[7][cellx][celly] = pbc_find_band_num(pbc_add_one(x0, CELL_NUM_X), pbc_sub_one(y0, CELL_NUM_Y), pbc_add_one(z0, CELL_NUM_Z));
		// (321)
		n[8][cellx][celly] = pbc_find_band_num(pbc_add_one(x0, CELL_NUM_X), y0, pbc_sub_one(z0, CELL_NUM_Z));
		// (322)
		n[9][cellx][celly] = pbc_find_band_num(pbc_add_one(x0, CELL_NUM_X), y0, z0);
		// (323)
		n[10][cellx][celly] = pbc_find_band_num(pbc_add_one(x0, CELL_NUM_X), y0, pbc_add_one(z0, CELL_NUM_Z));
		// (331)
		n[11][cellx][celly] = pbc_find_band_num(pbc_add_one(x0, CELL_NUM_X), pbc_add_one(y0, CELL_NUM_Y), pbc_sub_one(z0, CELL_NUM_Z));
		// (332)
		n[12][cellx][celly] = pbc_find_band_num(pbc_add_one(x0, CELL_NUM_X), pbc_add_one(y0, CELL_NUM_Y), z0);
		// (333)
		n[13][cellx][celly] = pbc_find_band_num(pbc_add_one(x0, CELL_NUM_X), pbc_add_one(y0, CELL_NUM_Y), pbc_add_one(z0, CELL_NUM_Z));
	}
	}
	for (i = 0; i < 64; i++) {
	int flag = 0;
fout << "				reg_enable_reading["<< i <<"] <= ";
	for (j = 0; j < 4; j++) {
	for (k = 0; k < 4; k++) {
	for (l = 0; l < 14; l++) {
		if (n[l][j][k] == i) {
			if (flag == 0) {
			fout << "(Local_enable_reading[" << 4*j+k << "*(NUM_NEIGHBOR_CELLS+1)+" << l << "]";
			}
			else {
			fout << " | Local_enable_reading[" << 4*j+k << "*(NUM_NEIGHBOR_CELLS+1)+" << l << "]";
			}
			flag = 1;
		}
	}
	}
	}
		if (flag == 0) {
			fout << "0;\n";
		}
		else {
			fout << ");\n";	
		}
	}
	for (i = 0; i < 4; i++) {
	for (j = 0; j < 4; j++) {
	for (k = 0; k < 14; k++) {
	for (l = 0; l < 64; l++) {
		if (n[k][i][j] == l) {
fout << "				reg_cells_to_pipeline[" << 4*i+j << "*(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH+" << k+1 << "*3*DATA_WIDTH-1:" << 4*i+j << "*(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH+" << k << "*3*DATA_WIDTH] <= Position_Cache_readout_position[" << l+1 << "*3*DATA_WIDTH-1:" << l << "*3*DATA_WIDTH];\n";
		}
	}
	}
	}
	}
	int map1[4][4][3][5];
	for (i = 0; i < 4; i++) {
	for (j = 0; j < 4; j++) {
	for (k = 0; k < 3; k++) {
	for (l = 0; l < 5; l++) {
		map1[i][j][k][l] = -1;
	}
	}
	}
	}
	int map2[4][4][3][5];
	for (i = 0; i < 4; i++) {
	for (j = 0; j < 4; j++) {
	for (k = 0; k < 3; k++) {
	for (l = 0; l < 5; l++) {
		map2[i][j][k][l] = -1;
	}
	}
	}
	}
	int pile_count[16][3];
	for (i = 0; i < 16; i++) {
		for (j = 0; j < 3; j++) {
			pile_count[i][j] = 1;
		}
	}
	for (i = 0; i < 4; i++) {
	for (j = 0; j < 4; j++) {
fout << "always@(*)\n";
fout << "	begin\n";
fout << "	case(neighbor_force_data_from_FIFO_1[" << (4*i+j) << "*FORCE_EVAL_FIFO_DATA_WIDTH+3*CELL_ID_WIDTH:" << (4*i+j) << "*FORCE_EVAL_FIFO_DATA_WIDTH+1])\n";
	for (k = 0; k < 8; k++) {
		switch(k) {
			case 0: fout << "		BINARY_222:\n";	break;
			case 1: fout << "		BINARY_223:\n";	break;
			case 2: fout << "		BINARY_231:\n";	break;
			case 3: fout << "		BINARY_232:\n";	break;
			case 4: fout << "		BINARY_233:\n";	break;
			case 5: fout << "		BINARY_311:\n";	break;
			case 6: fout << "		BINARY_312:\n";	break;
			default: fout << "		default:\n";	break;
		}
fout << "			begin\n";
		if (k == 0 || k == 3 || k == 6) {
				map1[n[k][i][j]/16][n[k][i][j]/4%4][0][pile_count[4*(n[k][i][j]/16)+n[k][i][j]/4%4][0]-1] = 4*i+j;
fout << "			force_valid_" << n[k][i][j]/16+1 << "_" << n[k][i][j]/4%4+1 << "_mid_" << pile_count[4*(n[k][i][j]/16)+n[k][i][j]/4%4][0] << " = neighbor_force_valid_1[" << 4*i+j << "];\n";
		}
		else if (k == 1 || k == 4) {
				map1[n[k][i][j]/16][n[k][i][j]/4%4][1][pile_count[4*(n[k][i][j]/16)+n[k][i][j]/4%4][1]-1] = 4*i+j;
fout << "			force_valid_" << n[k][i][j]/16+1 << "_" << n[k][i][j]/4%4+1 << "_top_" << pile_count[4*(n[k][i][j]/16)+n[k][i][j]/4%4][1] << " = neighbor_force_valid_1[" << 4*i+j << "];\n";
		}
		else if (k < 7) {
				map1[n[k][i][j]/16][n[k][i][j]/4%4][2][pile_count[4*(n[k][i][j]/16)+n[k][i][j]/4%4][2]-1] = 4*i+j;
fout << "			force_valid_" << n[k][i][j]/16+1 << "_" << n[k][i][j]/4%4+1 << "_bottom_" << pile_count[4*(n[k][i][j]/16)+n[k][i][j]/4%4][2] << " = neighbor_force_valid_1[" << 4*i+j << "];\n";
		}
		for (l = 0; l < 7; l++) {
			if (l != k) {
			if (l == 0 || l == 3 || l == 6) {
fout << "			force_valid_" << n[l][i][j]/16+1 << "_" << n[l][i][j]/4%4+1 << "_mid_" << pile_count[4*(n[l][i][j]/16)+n[l][i][j]/4%4][0] << " = 1'b0;\n";
			}
			else if (l == 1 || l == 4) {
fout << "			force_valid_" << n[l][i][j]/16+1 << "_" << n[l][i][j]/4%4+1 << "_top_" << pile_count[4*(n[l][i][j]/16)+n[l][i][j]/4%4][1] << " = 1'b0;\n";
			}
			else {
fout << "			force_valid_" << n[l][i][j]/16+1 << "_" << n[l][i][j]/4%4+1 << "_bottom_" << pile_count[4*(n[l][i][j]/16)+n[l][i][j]/4%4][2] << " = 1'b0;\n";
			}
			}
		}
fout << "			end\n";
	}
	for (k = 0; k < 7; k++) {
		if (k == 0 || k == 3 || k == 6) {
			pile_count[4*(n[k][i][j]/16)+n[k][i][j]/4%4][0] += 1;
		}
		else if (k == 1 || k == 4) {
			pile_count[4*(n[k][i][j]/16)+n[k][i][j]/4%4][1] += 1;
		}
		else {			
			pile_count[4*(n[k][i][j]/16)+n[k][i][j]/4%4][2] += 1;
		}
	}
fout << "	endcase\n";
fout << "	end\n";
	}
	}

	for (i = 0; i < 4; i++) {
	for (j = 0; j < 4; j++) {
fout << "always@(*)\n";
fout << "	begin\n";
fout << "	case(neighbor_force_data_from_FIFO_2[" << (4*i+j) << "*FORCE_EVAL_FIFO_DATA_WIDTH+3*CELL_ID_WIDTH:" << (4*i+j) << "*FORCE_EVAL_FIFO_DATA_WIDTH+1])\n";
	for (k = 7; k < 15; k++) {
		switch(k) {
			case 7: fout << "		BINARY_313:\n";	break;
			case 8: fout << "		BINARY_321:\n";	break;
			case 9: fout << "		BINARY_322:\n";	break;
			case 10: fout << "		BINARY_323:\n";	break;
			case 11: fout << "		BINARY_331:\n";	break;
			case 12: fout << "		BINARY_332:\n";	break;
			case 13: fout << "		BINARY_333:\n";	break;
			default: fout << "		default:\n";	break;
		}
fout << "			begin\n";
		if (k == 9 || k == 12) {
				map2[n[k][i][j]/16][n[k][i][j]/4%4][0][pile_count[4*(n[k][i][j]/16)+n[k][i][j]/4%4][0]-1] = 4*i+j;
fout << "			force_valid_" << n[k][i][j]/16+1 << "_" << n[k][i][j]/4%4+1 << "_mid_" << pile_count[4*(n[k][i][j]/16)+n[k][i][j]/4%4][0] << " = neighbor_force_valid_2[" << 4*i+j << "];\n";
		}
		else if (k == 7 || k == 10 || k == 13) {
				map2[n[k][i][j]/16][n[k][i][j]/4%4][1][pile_count[4*(n[k][i][j]/16)+n[k][i][j]/4%4][1]-1] = 4*i+j;
fout << "			force_valid_" << n[k][i][j]/16+1 << "_" << n[k][i][j]/4%4+1 << "_top_" << pile_count[4*(n[k][i][j]/16)+n[k][i][j]/4%4][1] << " = neighbor_force_valid_2[" << 4*i+j << "];\n";
		}
		else if (k < 14) {
				map2[n[k][i][j]/16][n[k][i][j]/4%4][2][pile_count[4*(n[k][i][j]/16)+n[k][i][j]/4%4][2]-1] = 4*i+j;
fout << "			force_valid_" << n[k][i][j]/16+1 << "_" << n[k][i][j]/4%4+1 << "_bottom_" << pile_count[4*(n[k][i][j]/16)+n[k][i][j]/4%4][2] << " = neighbor_force_valid_2[" << 4*i+j << "];\n";
		}
		for (l = 7; l < 14; l++) {
			if (l != k) {
			if (l == 9 || l == 12) {
fout << "			force_valid_" << n[l][i][j]/16+1 << "_" << n[l][i][j]/4%4+1 << "_mid_" << pile_count[4*(n[l][i][j]/16)+n[l][i][j]/4%4][0] << " = 1'b0;\n";
			}
			else if (l == 7 || l == 10 || l == 13) {
fout << "			force_valid_" << n[l][i][j]/16+1 << "_" << n[l][i][j]/4%4+1 << "_top_" << pile_count[4*(n[l][i][j]/16)+n[l][i][j]/4%4][1] << " = 1'b0;\n";
			}
			else {
fout << "			force_valid_" << n[l][i][j]/16+1 << "_" << n[l][i][j]/4%4+1 << "_bottom_" << pile_count[4*(n[l][i][j]/16)+n[l][i][j]/4%4][2] << " = 1'b0;\n";
			}
			}
		}
fout << "			end\n";
	}
	for (k = 7; k < 14; k++) {
		if (k == 9 || k == 12) {
			pile_count[4*(n[k][i][j]/16)+n[k][i][j]/4%4][0] += 1;
		}
		else if (k == 7 || k == 10 || k == 13) {
			pile_count[4*(n[k][i][j]/16)+n[k][i][j]/4%4][1] += 1;
		}
		else {			
			pile_count[4*(n[k][i][j]/16)+n[k][i][j]/4%4][2] += 1;
		}
	}
fout << "	endcase\n";
fout << "	end\n";
	}
	}


	int a, b, c, d;

/*
	case(Arbitration_1_1_mid)
		6'b100000:
			begin
			valid_force_values_1_1_mid = ref_force_data_from_FIFO[1*FORCE_EVAL_FIFO_DATA_WIDTH-1:0*FORCE_EVAL_FIFO_DATA_WIDTH]
			end
		6'b010000:
			begin
			valid_force_values_1_1_mid = neighbor_force_data_from_FIFO_1[1*FORCE_EVAL_FIFO_DATA_WIDTH:0*FORCE_EVAL_FIFO_DATA_WIDTH]
			end
		6'b001000:
			begin
			valid_force_values_1_1_mid = neighbor_force_data_from_FIFO_1[4*FORCE_EVAL_FIFO_DATA_WIDTH:3*FORCE_EVAL_FIFO_DATA_WIDTH]
			end
		6'b000100:
			begin
			end
		6'b000010:
			begin
			end
		6'b000001:
			begin
			end
		default:
			begin
			end
	endcase
*/

	for (i = 0; i < 4; i++) {
	for (j = 0; j < 4; j++) {
	for (k = 0; k < 3; k++) {
		if (k == 0) {
fout << "	case(Arbitration_" << i+1 << "_" << j+1 << "_mid)\n";
		}
		if (k == 1) {
fout << "	case(Arbitration_" << i+1 << "_" << j+1 << "_top)\n";
		}
		if (k == 2) {
fout << "	case(Arbitration_" << i+1 << "_" << j+1 << "_bottom)\n";
		}
	for (l = 0; l < 6; l++) {
		switch (l) {
		case 0:
fout << "		6'b100000:\n";
			break;
		case 1:
fout << "		6'b010000:\n";
			break;
		case 2:
fout << "		6'b001000:\n";
			break;
		case 3:
fout << "		6'b000100:\n";
			break;
		case 4:
fout << "		6'b000010:\n";
			break;
		case 5:
fout << "		6'b000001:\n";
			break;
		}
fout << "			begin\n";
		if (l == 0) {
		if (k == 0) {
fout << "			valid_force_values_" << i+1 << "_" << j+1 << "_mid = ref_force_data_from_FIFO[" << 4*i+j+1 << "*FORCE_EVAL_FIFO_DATA_WIDTH-1:" << 4*i+j << "*FORCE_EVAL_FIFO_DATA_WIDTH];\n";
		}
		if (k == 1) {
fout << "			valid_force_values_" << i+1 << "_" << j+1 << "_top = 0;\n";
		}
		if (k == 2) {
fout << "			valid_force_values_" << i+1 << "_" << j+1 << "_bottom = 0;\n";
		}
		}
		else {
		if (k == 0) {
		if (map1[i][j][k][l-1] != -1) {
fout << "			valid_force_values_" << i+1 << "_" << j+1 << "_mid = neighbor_force_data_from_FIFO_1[" << map1[i][j][k][l-1]+1 << "*FORCE_EVAL_FIFO_DATA_WIDTH-1:" << map1[i][j][k][l-1] << "*FORCE_EVAL_FIFO_DATA_WIDTH];\n";
		}
		else if (map2[i][j][k][l-1] != -1) {
fout << "			valid_force_values_" << i+1 << "_" << j+1 << "_mid = neighbor_force_data_from_FIFO_2[" << map2[i][j][k][l-1]+1 << "*FORCE_EVAL_FIFO_DATA_WIDTH-1:" << map2[i][j][k][l-1] << "*FORCE_EVAL_FIFO_DATA_WIDTH];\n";
		}
		else {
fout << "			valid_force_values_" << i+1 << "_" << j+1 << "_mid = 0\n";
		}
		}
		if (k == 1) {
		if (map1[i][j][k][l-1] != -1) {
fout << "			valid_force_values_" << i+1 << "_" << j+1 << "_top = neighbor_force_data_from_FIFO_1[" << map1[i][j][k][l-1]+1 << "*FORCE_EVAL_FIFO_DATA_WIDTH-1:" << map1[i][j][k][l-1] << "*FORCE_EVAL_FIFO_DATA_WIDTH];\n";
		}
		else if (map2[i][j][k][l-1] != -1) {
fout << "			valid_force_values_" << i+1 << "_" << j+1 << "_top = neighbor_force_data_from_FIFO_2[" << map2[i][j][k][l-1]+1 << "*FORCE_EVAL_FIFO_DATA_WIDTH-1:" << map2[i][j][k][l-1] << "*FORCE_EVAL_FIFO_DATA_WIDTH];\n";
		}
		else {
fout << "			valid_force_values_" << i+1 << "_" << j+1 << "_top = 0\n";
		}
		}
		if (k == 2) {
		if (map1[i][j][k][l-1] != -1) {
fout << "			valid_force_values_" << i+1 << "_" << j+1 << "_bottom = neighbor_force_data_from_FIFO_1[" << map1[i][j][k][l-1]+1 << "*FORCE_EVAL_FIFO_DATA_WIDTH-1:" << map1[i][j][k][l-1] << "*FORCE_EVAL_FIFO_DATA_WIDTH];\n";
		}
		else if (map2[i][j][k][l-1] != -1) {
fout << "			valid_force_values_" << i+1 << "_" << j+1 << "_bottom = neighbor_force_data_from_FIFO_2[" << map2[i][j][k][l-1]+1 << "*FORCE_EVAL_FIFO_DATA_WIDTH-1:" << map2[i][j][k][l-1] << "*FORCE_EVAL_FIFO_DATA_WIDTH];\n";
		}
		else {
fout << "			valid_force_values_" << i+1 << "_" << j+1 << "_bottom = 0\n";
		}
		}
		}
fout << "			end\n";		
	}
fout << "		default:\n";
fout << "			begin\n";
		if (k == 0) {
fout << "			valid_force_values_" << i+1 << "_" << j+1 << "_mid = 0\n";
		}
		if (k == 1) {
fout << "			valid_force_values_" << i+1 << "_" << j+1 << "_top = 0\n";
		}
		if (k == 2) {
fout << "			valid_force_values_" << i+1 << "_" << j+1 << "_bottom = 0\n";
		}
fout << "			end\n";		
fout << "	endcase\n";	
	}
	}
	}


	for (i = 0; i < 4; i++) {
	for (j = 0; j < 4; j++) {
	for (k = 0; k < 3; k++) {
		if (k == 0) {
fout << "			valid_force_values[" << i*16+j*4+(cellz+4)%4+1 << "*FORCE_EVAL_FIFO_DATA_WIDTH-1:" << i*16+j*4+(cellz+4)%4 << "*FORCE_EVAL_FIFO_DATA_WIDTH] = valid_force_values_" << i+1 << "_" << j+1 << "_mid;\n";
		}
		if (k == 1) {
fout << "			valid_force_values[" << i*16+j*4+(cellz+1)%4+1 << "*FORCE_EVAL_FIFO_DATA_WIDTH-1:" << i*16+j*4+(cellz+1)%4 << "*FORCE_EVAL_FIFO_DATA_WIDTH] = valid_force_values_" << i+1 << "_" << j+1 << "_top;\n";
		}
		if (k == 2) {
fout << "			valid_force_values[" << i*16+j*4+(cellz+3)%4+1 << "*FORCE_EVAL_FIFO_DATA_WIDTH-1:" << i*16+j*4+(cellz+3)%4 << "*FORCE_EVAL_FIFO_DATA_WIDTH] = valid_force_values_" << i+1 << "_" << j+1 << "_bottom;\n";
		}
	}
	}
	}

	for (i = 0; i < 64; i++) {
		if ((i+1) % 4 == 0) {
fout << "reg_valid_force_values[" << i+1 << "*FORCE_EVAL_FIFO_DATA_WIDTH-1:" << i << "*FORCE_EVAL_FIFO_DATA_WIDTH] = 0;\n";
		} 
	}


/*
	for (i = 0; i < 4; i++) {
	for (j = 0; j < 4; j++) {
	for (k = 0; k < 3; k++) {
	for (l = 0; l < 5; l++) {
		if (k == 0) {
fout << "reg force_valid_" << i+1 << "_" << j+1 << "_mid_" << l+1 << ";\n";
		}
		if (k == 1) {
fout << "reg force_valid_" << i+1 << "_" << j+1 << "_top_" << l+1 << ";\n";
		}
		if (k == 2) {
fout << "reg force_valid_" << i+1 << "_" << j+1 << "_bottom_" << l+1 << ";\n";
		}
	}
	}
	}
	}
*/	
/*
	for (i = 0; i < 64; i++) {
fout << "assign to_force_cache_partial_force_valid[" << i << "] = valid_force_values[" << i << "*FORCE_EVAL_FIFO_DATA_WIDTH];\n";
	}
	for (i = 0; i < 64; i++) {
fout << "assign to_force_cache_particle_id[" << i+1 << "*PARTICLE_ID_WIDTH-1:" << i << "*PARTICLE_ID_WIDTH] = valid_force_values[" << i+1 << "*FORCE_EVAL_FIFO_DATA_WIDTH-3*DATA_WIDTH-1:" << i << "*FORCE_EVAL_FIFO_DATA_WIDTH+1];\n";
	}
	for (i = 0; i < 64; i++) {
fout << "assign to_force_cache_LJ_Force_Z[" << i+1 << "*DATA_WIDTH-1:" << i << "*DATA_WIDTH] = valid_force_values[" << i+1 << "*FORCE_EVAL_FIFO_DATA_WIDTH-1:" << i << "*FORCE_EVAL_FIFO_DATA_WIDTH+PARTICLE_ID_WIDTH+2*DATA_WIDTH+1];\n";
	}


	for (i = 0; i < 64; i++) {
fout << "assign to_force_cache_LJ_Force_Y[" << i+1 << "*DATA_WIDTH-1:" << i << "*DATA_WIDTH] = valid_force_values[" << i+1 << "*FORCE_EVAL_FIFO_DATA_WIDTH-DATA_WIDTH-1:" << i << "*FORCE_EVAL_FIFO_DATA_WIDTH+PARTICLE_ID_WIDTH+*DATA_WIDTH+1];\n";

	for (i = 0; i < 64; i++) {
fout << "assign to_force_cache_LJ_Force_X[" << i+1 << "*DATA_WIDTH-1:" << i << "*DATA_WIDTH] = valid_force_values[" << i+1 << "*FORCE_EVAL_FIFO_DATA_WIDTH-2*DATA_WIDTH-1:" << i << "*FORCE_EVAL_FIFO_DATA_WIDTH+PARTICLE_ID_WIDTH+1];\n";
	}
/*

	cout << endl;
	for (i = 0; i < 4; i++) {
	for (j = 0; j < 4; j++) {
	for (k = 0; k < 3; k++) {
	for (l = 0; l < 5; l++) {

		if (k == 0) {
			cout << "force_valid_" << i+1 << "_" << j+1 << "_mid_" << l+1 << " = neighbor_force_data_from_FIFO_1[" << map1[i][j][k][l] << "];\n";
		}
		if (k == 1) {
			cout << "force_valid_" << i+1 << "_" << j+1 << "_top_" << l+1 << " = neighbor_force_data_from_FIFO_1[" << map1[i][j][k][l] << "];\n";
		}
		if (k == 2) {
			cout << "force_valid_" << i+1 << "_" << j+1 << "_bottom_" << l+1 << " = neighbor_force_data_from_FIFO_1[" << map1[i][j][k][l] << "];\n";
		}

		//cout << "map1[" << i << "][" << j << "][" << k << "][" << l << "] : " << map1[i][j][k][l] << "\n";
	}
	}
	}
	}

	for (i = 0; i < 4; i++) {
	for (j = 0; j < 4; j++) {
	for (k = 0; k < 3; k++) {
	for (l = 0; l < 5; l++) {
		cout << "map2[" << i << "][" << j << "][" << k << "][" << l << "] : " << map2[i][j][k][l] << "\n";
	}
	}
	}
	}
*/
/*
	
	int a, b, c, d;
	for (a = 0; a < 4; a++) {
	for (b = 0; b < 4; b++) {
	for (c = 0; c < 3; c++) {
	if (c == 0) {
fout << "			case(Arbitration_" << a+1 << "_" << b+1 << "_mid)\n";
	}
	else if (c == 1) {
fout << "			case(Arbitration_" << a+1 << "_" << b+1 << "_top)\n";
	}
	else {
fout << "			case(Arbitration_" << a+1 << "_" << b+1 << "_bottom)\n";
	}
	for (d = 0; d < 6; d++) {
	switch(d) {
		case(0): fout << "				6'b100000:\n";
		case(1): fout << "				6'b010000:\n";
		case(2): fout << "				6'b001000:\n";
		case(3): fout << "				6'b000100:\n";
		case(4): fout << "				6'b000010:\n";
		case(5): fout << "				6'b000001:\n";
	}
	if (d == 0) {
fout <<"					valid_force_values[0]" << a*16+b*4+c+1;
	}
	for (i = 0; i < 4; i++) {
	for (j = 0; j < 4; j++) {
	for (k = 0; k < 3; k++) {
	for (l = 0; l < 5; l++) {
		if (map1[i][j][k][l] == 
	}
	}
	}
	}
	}
	}
	}
	}





*/





	for (i = 0; i < 4; i++) {
	for (j = 0; j < 4; j++) {
fout << "Force_Writeback_Arbiter\n";
fout << "#(\n";
fout << "	.FORCE_WTADDR_ARBITER_SIZE(FORCE_WTADDR_ARBITER_SIZE),\n";
fout << "	.FORCE_WTADDR_ARBITER_MSB(FORCE_WTADDR_ARBITER_MSB)\n";
fout << ")\n";
fout << "Force_Writeback_Arbiter_" << i+1 << "_" << j+1 << "_mid\n";
fout << "(\n";
fout << "	.ref_force_valid(ref_force_valid[" << 4*i+j << "]),\n";
fout << "	.force_valid_1(force_valid_" << i+1 << "_" << j+1 << "_mid_1),\n";
fout << "	.force_valid_2(force_valid_" << i+1 << "_" << j+1 << "_mid_2),\n";
fout << "	.force_valid_3(force_valid_" << i+1 << "_" << j+1 << "_mid_3),\n";
fout << "	.force_valid_4(force_valid_" << i+1 << "_" << j+1 << "_mid_4),\n";
fout << "	.force_valid_5(force_valid_" << i+1 << "_" << j+1 << "_mid_5),\n";
fout << "\n";	
fout << "	.Arbitration_Result(Arbitration_Result_" << i+1 << "_" << j+1 << "_mid)\n";
fout << ");\n";

fout << "Force_Writeback_Arbiter\n";
fout << "#(\n";
fout << "	.FORCE_WTADDR_ARBITER_SIZE(FORCE_WTADDR_ARBITER_SIZE),\n";
fout << "	.FORCE_WTADDR_ARBITER_MSB(FORCE_WTADDR_ARBITER_MSB)\n";
fout << ")\n";
fout << "Force_Writeback_Arbiter_" << i+1 << "_" << j+1 << "_top\n";
fout << "(\n";
fout << "	.ref_force_valid(ref_force_valid[" << 4*i+j << "]),\n";
fout << "	.force_valid_1(force_valid_" << i+1 << "_" << j+1 << "_top_1),\n";
fout << "	.force_valid_2(force_valid_" << i+1 << "_" << j+1 << "_top_2),\n";
fout << "	.force_valid_3(force_valid_" << i+1 << "_" << j+1 << "_top_3),\n";
fout << "	.force_valid_4(force_valid_" << i+1 << "_" << j+1 << "_top_4),\n";
fout << "	.force_valid_5(force_valid_" << i+1 << "_" << j+1 << "_top_5),\n";
fout << "\n";	
fout << "	.Arbitration_Result(Arbitration_Result_" << i+1 << "_" << j+1 << "_top)\n";
fout << ");\n";

fout << "Force_Writeback_Arbiter\n";
fout << "#(\n";
fout << "	.FORCE_WTADDR_ARBITER_SIZE(FORCE_WTADDR_ARBITER_SIZE),\n";
fout << "	.FORCE_WTADDR_ARBITER_MSB(FORCE_WTADDR_ARBITER_MSB)\n";
fout << ")\n";
fout << "Force_Writeback_Arbiter_" << i+1 << "_" << j+1 << "_bottom\n";
fout << "(\n";
fout << "	.ref_force_valid(ref_force_valid[" << 4*i+j << "]),\n";
fout << "	.force_valid_1(force_valid_" << i+1 << "_" << j+1 << "_bottom_1),\n";
fout << "	.force_valid_2(force_valid_" << i+1 << "_" << j+1 << "_bottom_2),\n";
fout << "	.force_valid_3(force_valid_" << i+1 << "_" << j+1 << "_bottom_3),\n";
fout << "	.force_valid_4(force_valid_" << i+1 << "_" << j+1 << "_bottom_4),\n";
fout << "	.force_valid_5(1'b0),\n";
fout << "\n";	
fout << "	.Arbitration_Result(Arbitration_Result_" << i+1 << "_" << j+1 << "_bottom)\n";
fout << ");\n";
	}
	}
	for (i = 0; i < 4; i++) {
	for (j = 0; j < 4; j++) {
fout << "wire [FORCE_WTADDR_ARBITER_SIZE-1:0] Arbitration_" << i+1 << "_" << j+1 << "_mid;\n";
	}
	}
	for (i = 0; i < 4; i++) {
	for (j = 0; j < 4; j++) {
fout << "wire [FORCE_WTADDR_ARBITER_SIZE-1:0] Arbitration_" << i+1 << "_" << j+1 << "_top;\n";
	}
	}
	for (i = 0; i < 4; i++) {
	for (j = 0; j < 4; j++) {
fout << "wire [FORCE_WTADDR_ARBITER_SIZE-1:0] Arbitration_" << i+1 << "_" << j+1 << "_bottom;\n";
	}
	}







//int pile_count[16][3];
	for (i = 0; i < 16; i++) {
		for (j = 0; j < 3; j++) {
			pile_count[i][j] = 1;
		}
	}
	for (i = 0; i < 4; i++) {
	for (j = 0; j < 4; j++) {
fout << "assign neighbor_force_write_success_1[" << 4*i+j << "] = ";
	for (k = 0; k < 7; k++) {
		if (k == 0 || k == 3) {
fout << "Arbitration_" << n[k][i][j]/16+1 << "_" << n[k][i][j]/4%4+1 << "_mid[" << pile_count[4*(n[k][i][j]/16)+n[k][i][j]/4%4][0] << "] | ";
		}
		else if (k == 6) {
fout << "Arbitration_" << n[k][i][j]/16+1 << "_" << n[k][i][j]/4%4+1 << "_mid[" << pile_count[4*(n[k][i][j]/16)+n[k][i][j]/4%4][0] << "];\n";
		}
		else if (k == 1 || k == 4) {
fout << "Arbitration_" << n[k][i][j]/16+1 << "_" << n[k][i][j]/4%4+1 << "_top[" << pile_count[4*(n[k][i][j]/16)+n[k][i][j]/4%4][1] << "] | ";
		}
		else {
fout << "Arbitration_" << n[k][i][j]/16+1 << "_" << n[k][i][j]/4%4+1 << "_bottom[" << pile_count[4*(n[k][i][j]/16)+n[k][i][j]/4%4][2] << "] | ";
		}
	}
	for (k = 0; k < 7; k++) {
		if (k == 0 || k == 3 || k == 6) {
			pile_count[4*(n[k][i][j]/16)+n[k][i][j]/4%4][0] += 1;
		}
		else if (k == 1 || k == 4) {
			pile_count[4*(n[k][i][j]/16)+n[k][i][j]/4%4][1] += 1;
		}
		else {			
			pile_count[4*(n[k][i][j]/16)+n[k][i][j]/4%4][2] += 1;
		}
	}
	}
	}


	for (i = 0; i < 4; i++) {
	for (j = 0; j < 4; j++) {
fout << "assign neighbor_force_write_success_2[" << 4*i+j << "] = ";
	for (k = 7; k < 14; k++) {
		if (k == 9 || k == 12) {
fout << "Arbitration_" << n[k][i][j]/16+1 << "_" << n[k][i][j]/4%4+1 << "_mid[" << pile_count[4*(n[k][i][j]/16)+n[k][i][j]/4%4][0] << "] | ";
		}
		else if (k == 7 || k == 10) {
fout << "Arbitration_" << n[k][i][j]/16+1 << "_" << n[k][i][j]/4%4+1 << "_top[" << pile_count[4*(n[k][i][j]/16)+n[k][i][j]/4%4][1] << "] | ";
		}
		else if (k == 13) {
fout << "Arbitration_" << n[k][i][j]/16+1 << "_" << n[k][i][j]/4%4+1 << "_top[" << pile_count[4*(n[k][i][j]/16)+n[k][i][j]/4%4][1] << "];\n";
		}
		else {
fout << "Arbitration_" << n[k][i][j]/16+1 << "_" << n[k][i][j]/4%4+1 << "_bottom[" << pile_count[4*(n[k][i][j]/16)+n[k][i][j]/4%4][2] << "] | ";
		}
	}
	for (k = 7; k < 14; k++) {
		if (k == 9 || k == 12) {
			pile_count[4*(n[k][i][j]/16)+n[k][i][j]/4%4][0] += 1;
		}
		else if (k == 7 || k == 10 || k == 13) {
			pile_count[4*(n[k][i][j]/16)+n[k][i][j]/4%4][1] += 1;
		}
		else {			
			pile_count[4*(n[k][i][j]/16)+n[k][i][j]/4%4][2] += 1;
		}
	}
	}
	}


/*
int xx = 0;
int yy = 0;
	for (i = 0; i < 64; i++) {
		j = 0;
		xx = i/16;
		yy = i/4%4;
	for (k = 0; k < 4; k++) {
	for (l = 0; l < 4; l++) {
	for (m = 0; m < 14; m++) {

		if (n[m][k][l] == i) {
		if (m == 0 || m == 3 || m == 6 || m == 9 || m == 12) {

		if (j == 0) {
fout << "Read_Addr_Arbiter\n";
fout << "#(\n";
fout << "	.CELL_ADDR_WIDTH(CELL_ADDR_WIDTH),\n";
fout << "	.RDADDR_ARBITER_SIZE(RDADDR_ARBITER_SIZE),\n";
fout << "	.RDADDR_ARBITER_MSB(RDADDR_ARBITER_MSB)\n";
fout << ")\n";
fout << "Read_Addr_Arbiter_" << xx+1 << "_" << yy+1 << "_mid\n";
fout << "(\n";
fout << "	.clk(clk),\n";
fout << "	.rst(rst),\n";
fout << "	.addr1(FSM_to_Cell_read_addr_" << k+1 << "_" << l+1 << "[" << m+1 << "*CELL_ADDR_WIDTH-1:" << m << "*CELL_ADDR_WIDTH]),\n";
fout << "	.enable1(enable_reading_" << k+1 << "_" << l+1 << "[" << m << "]),\n";
		}
		if (j == 1) {
fout << "	.addr2(FSM_to_Cell_read_addr_" << k+1 << "_" << l+1 << "[" << m+1 << "*CELL_ADDR_WIDTH-1:" << m << "*CELL_ADDR_WIDTH]),\n";
fout << "	.enable2(enable_reading_" << k+1 << "_" << l+1 << "[" << m << "]),\n";
		}
		if (j == 2) {
fout << "	.addr3(FSM_to_Cell_read_addr_" << k+1 << "_" << l+1 << "[" << m+1 << "*CELL_ADDR_WIDTH-1:" << m << "*CELL_ADDR_WIDTH]),\n";
fout << "	.enable3(enable_reading_" << k+1 << "_" << l+1 << "[" << m << "]),\n";
		}
		if (j == 3) {
fout << "	.addr4(FSM_to_Cell_read_addr_" << k+1 << "_" << l+1 << "[" << m+1 << "*CELL_ADDR_WIDTH-1:" << m << "*CELL_ADDR_WIDTH]),\n";
fout << "	.enable4(enable_reading_" << k+1 << "_" << l+1 << "[" << m << "]),\n";
		}
		if (j == 4) {
fout << "	.addr5(FSM_to_Cell_read_addr_" << k+1 << "_" << l+1 << "[" << m+1 << "*CELL_ADDR_WIDTH-1:" << m << "*CELL_ADDR_WIDTH]),\n";
fout << "	.enable5(enable_reading_" << k+1 << "_" << l+1 << "[" << m << "]),\n";
fout << "	.Arbitration_Result(arbiter_" << xx+1 << "_" << yy+1 << "_mid)\n";
fout << ");\n\n";
		}

//fout << "				reg_Cell_to_FSM_read_success_bit_" << k+1 << "_" << l+1 << "[" << m << "] = (arbiter_" << xx+1 << "_" << yy+1 << "_mid[" << j << "]) ? 1'b1 : 1'b0;\n";
		}
		else if (m == 1 || m == 4 || m == 7 || m == 10 || m == 13) {

if (j == 0) {
fout << "Read_Addr_Arbiter\n";
fout << "#(\n";
fout << "	.CELL_ADDR_WIDTH(CELL_ADDR_WIDTH),\n";
fout << "	.RDADDR_ARBITER_SIZE(RDADDR_ARBITER_SIZE),\n";
fout << "	.RDADDR_ARBITER_MSB(RDADDR_ARBITER_MSB)\n";
fout << ")\n";
fout << "Read_Addr_Arbiter_" << xx+1 << "_" << yy+1 << "_top\n";
fout << "(\n";
fout << "	.clk(clk),\n";
fout << "	.rst(rst),\n";
fout << "	.addr1(FSM_to_Cell_read_addr_" << k+1 << "_" << l+1 << "[" << m+1 << "*CELL_ADDR_WIDTH-1:" << m << "*CELL_ADDR_WIDTH]),\n";
fout << "	.enable1(enable_reading_" << k+1 << "_" << l+1 << "[" << m << "]),\n";
		}
		if (j == 1) {
fout << "	.addr2(FSM_to_Cell_read_addr_" << k+1 << "_" << l+1 << "[" << m+1 << "*CELL_ADDR_WIDTH-1:" << m << "*CELL_ADDR_WIDTH]),\n";
fout << "	.enable2(enable_reading_" << k+1 << "_" << l+1 << "[" << m << "]),\n";
		}
		if (j == 2) {
fout << "	.addr3(FSM_to_Cell_read_addr_" << k+1 << "_" << l+1 << "[" << m+1 << "*CELL_ADDR_WIDTH-1:" << m << "*CELL_ADDR_WIDTH]),\n";
fout << "	.enable3(enable_reading_" << k+1 << "_" << l+1 << "[" << m << "]),\n";
		}
		if (j == 3) {
fout << "	.addr4(FSM_to_Cell_read_addr_" << k+1 << "_" << l+1 << "[" << m+1 << "*CELL_ADDR_WIDTH-1:" << m << "*CELL_ADDR_WIDTH]),\n";
fout << "	.enable4(enable_reading_" << k+1 << "_" << l+1 << "[" << m << "]),\n";
		}
		if (j == 4) {
fout << "	.addr5(FSM_to_Cell_read_addr_" << k+1 << "_" << l+1 << "[" << m+1 << "*CELL_ADDR_WIDTH-1:" << m << "*CELL_ADDR_WIDTH]),\n";
fout << "	.enable5(enable_reading_" << k+1 << "_" << l+1 << "[" << m << "]),\n";
fout << "	.Arbitration_Result(arbiter_" << xx+1 << "_" << yy+1 << "_top)\n";
fout << ");\n\n";
		}

//fout << "				reg_Cell_to_FSM_read_success_bit_" << k+1 << "_" << l+1 << "[" << m << "] = (arbiter_" << xx+1 << "_" << yy+1 << "_top[" << j << "]) ? 1'b1 : 1'b0;\n";
		}
		else {

if (j == 0) {
fout << "Read_Addr_Arbiter\n";
fout << "#(\n";
fout << "	.CELL_ADDR_WIDTH(CELL_ADDR_WIDTH),\n";
fout << "	.RDADDR_ARBITER_SIZE(RDADDR_ARBITER_SIZE),\n";
fout << "	.RDADDR_ARBITER_MSB(RDADDR_ARBITER_MSB)\n";
fout << ")\n";
fout << "Read_Addr_Arbiter_" << xx+1 << "_" << yy+1 << "_bottom\n";
fout << "(\n";
fout << "	.clk(clk),\n";
fout << "	.rst(rst),\n";
fout << "	.addr1(FSM_to_Cell_read_addr_" << k+1 << "_" << l+1 << "[" << m+1 << "*CELL_ADDR_WIDTH-1:" << m << "*CELL_ADDR_WIDTH]),\n";
fout << "	.enable1(enable_reading_" << k+1 << "_" << l+1 << "[" << m << "]),\n";
		}
		if (j == 1) {
fout << "	.addr2(FSM_to_Cell_read_addr_" << k+1 << "_" << l+1 << "[" << m+1 << "*CELL_ADDR_WIDTH-1:" << m << "*CELL_ADDR_WIDTH]),\n";
fout << "	.enable2(enable_reading_" << k+1 << "_" << l+1 << "[" << m << "]),\n";
		}
		if (j == 2) {
fout << "	.addr3(FSM_to_Cell_read_addr_" << k+1 << "_" << l+1 << "[" << m+1 << "*CELL_ADDR_WIDTH-1:" << m << "*CELL_ADDR_WIDTH]),\n";
fout << "	.enable3(enable_reading_" << k+1 << "_" << l+1 << "[" << m << "]),\n";
		}
		if (j == 3) {
fout << "	.addr4(FSM_to_Cell_read_addr_" << k+1 << "_" << l+1 << "[" << m+1 << "*CELL_ADDR_WIDTH-1:" << m << "*CELL_ADDR_WIDTH]),\n";
fout << "	.enable4(enable_reading_" << k+1 << "_" << l+1 << "[" << m << "]),\n";
fout << "	.addr5({CELL_ADDR_WIDTH{1'b0}}),\n";
fout << "	.enable5(1'b0),\n";
fout << "	.Arbitration_Result(arbiter_" << xx+1 << "_" << yy+1 << "_bottom)\n";
fout << ");\n\n";
		}
		if (j == 4) {
fout << "	.addr5(FSM_to_Cell_read_addr_" << k+1 << "_" << l+1 << "[" << m+1 << "*CELL_ADDR_WIDTH-1:" << m << "*CELL_ADDR_WIDTH]),\n";
fout << "	.enable5(enable_reading_" << k+1 << "_" << l+1 << "[" << m << "]),\n";
fout << "	.Arbitration_Result(arbiter_" << xx+1 << "_" << yy+1 << "_bottom)\n";
fout << ");\n\n";
		}

//fout << "				reg_Cell_to_FSM_read_success_bit_" << k+1 << "_" << l+1 << "[" << m << "] = (arbiter_" << xx+1 << "_" << yy+1 << "_bottom[" << j << "]) ? 1'b1 : 1'b0;\n";
		}
			j++;
		}

	}
	}
	}
	}
int x = 0;
int y = 0;
	for (i = 0; i < 64; i++) {
		x = i/16;
		y = i/4%4;
		j = 0;
	for (k = 0; k < 4; k++) {
	for (l = 0; l < 4; l++) {
	for (m = 0; m < 14; m++) {

		if (n[m][k][l] == i) {
		if (m == 0 || m == 3 || m == 6 || m == 9 || m == 12) {
			if (j == 0) {
fout << "			if (arbiter_" << x+1 << "_" << y+1 << "_mid[" << j << "])\n";
fout << "				begin\n";
fout << "				reg_FSM_to_Cell_read_addr[" << i+1 << "*CELL_ADDR_WIDTH-1:" << i <<"*CELL_ADDR_WIDTH] = FSM_to_Cell_read_addr_" << k+1 << "_" << l+1 << "[" << m+1 << "*CELL_ADDR_WIDTH-1:" << m << "*CELL_ADDR_WIDTH];\n";
fout << "				end\n";
			}
			else if (j == 1) {
fout << "			else if (arbiter_" << x+1 << "_" << y+1 << "_mid[" << j << "])\n";
fout << "				begin\n";
fout << "				reg_FSM_to_Cell_read_addr[" << i+1 << "*CELL_ADDR_WIDTH-1:" << i <<"*CELL_ADDR_WIDTH] = FSM_to_Cell_read_addr_" << k+1 << "_" << l+1 << "[" << m+1 << "*CELL_ADDR_WIDTH-1:" << m << "*CELL_ADDR_WIDTH];\n";
fout << "				end\n";
			}
			else if (j == 2) {
fout << "			else if (arbiter_" << x+1 << "_" << y+1 << "_mid[" << j << "])\n";
fout << "				begin\n";
fout << "				reg_FSM_to_Cell_read_addr[" << i+1 << "*CELL_ADDR_WIDTH-1:" << i <<"*CELL_ADDR_WIDTH] = FSM_to_Cell_read_addr_" << k+1 << "_" << l+1 << "[" << m+1 << "*CELL_ADDR_WIDTH-1:" << m << "*CELL_ADDR_WIDTH];\n";
fout << "				end\n";
			}
			else if (j == 3) {
fout << "			else if (arbiter_" << x+1 << "_" << y+1 << "_mid[" << j << "])\n";
fout << "				begin\n";
fout << "				reg_FSM_to_Cell_read_addr[" << i+1 << "*CELL_ADDR_WIDTH-1:" << i <<"*CELL_ADDR_WIDTH] = FSM_to_Cell_read_addr_" << k+1 << "_" << l+1 << "[" << m+1 << "*CELL_ADDR_WIDTH-1:" << m << "*CELL_ADDR_WIDTH];\n";
fout << "				end\n";
			}
			else if (j == 4) {
fout << "			else if (arbiter_" << x+1 << "_" << y+1 << "_mid[" << j << "])\n";
fout << "				begin\n";
fout << "				reg_FSM_to_Cell_read_addr[" << i+1 << "*CELL_ADDR_WIDTH-1:" << i <<"*CELL_ADDR_WIDTH] = FSM_to_Cell_read_addr_" << k+1 << "_" << l+1 << "[" << m+1 << "*CELL_ADDR_WIDTH-1:" << m << "*CELL_ADDR_WIDTH];\n";
fout << "				end\n";
fout << "			else\n";
fout << "				begin\n";
fout << "				reg_FSM_to_Cell_read_addr[" << i+1 << "*CELL_ADDR_WIDTH-1:" << i <<"*CELL_ADDR_WIDTH] = 0;\n";
fout << "				end\n";
			}

//fout << "			reg_FSM_to_Cell_read_addr[" << i+1 << "*CELL_ADDR_WIDTH-1:" << i <<"*CELL_ADDR_WIDTH] = (arbiter_" << x+1 << "_" << y+1 << "_mid[" << j << "]) ? FSM_to_Cell_read_addr_" << k+1 << "_" << l+1 << "[" << m+1 << "*CELL_ADDR_WIDTH-1:" << m << "*CELL_ADDR_WIDTH] : reg_FSM_to_Cell_read_addr[" << i+1 << "*CELL_ADDR_WIDTH-1:" << i <<"*CELL_ADDR_WIDTH];\n";
		}
		else if (m == 1 || m == 4 || m == 7 || m == 10 || m == 13) {
			if (j == 0) {
fout << "			if (arbiter_" << x+1 << "_" << y+1 << "_top[" << j << "])\n";
fout << "				begin\n";
fout << "				reg_FSM_to_Cell_read_addr[" << i+1 << "*CELL_ADDR_WIDTH-1:" << i <<"*CELL_ADDR_WIDTH] = FSM_to_Cell_read_addr_" << k+1 << "_" << l+1 << "[" << m+1 << "*CELL_ADDR_WIDTH-1:" << m << "*CELL_ADDR_WIDTH];\n";
fout << "				end\n";
			}
			else if (j == 1) {
fout << "			else if (arbiter_" << x+1 << "_" << y+1 << "_top[" << j << "])\n";
fout << "				begin\n";
fout << "				reg_FSM_to_Cell_read_addr[" << i+1 << "*CELL_ADDR_WIDTH-1:" << i <<"*CELL_ADDR_WIDTH] = FSM_to_Cell_read_addr_" << k+1 << "_" << l+1 << "[" << m+1 << "*CELL_ADDR_WIDTH-1:" << m << "*CELL_ADDR_WIDTH];\n";
fout << "				end\n";
			}
			else if (j == 2) {
fout << "			else if (arbiter_" << x+1 << "_" << y+1 << "_top[" << j << "])\n";
fout << "				begin\n";
fout << "				reg_FSM_to_Cell_read_addr[" << i+1 << "*CELL_ADDR_WIDTH-1:" << i <<"*CELL_ADDR_WIDTH] = FSM_to_Cell_read_addr_" << k+1 << "_" << l+1 << "[" << m+1 << "*CELL_ADDR_WIDTH-1:" << m << "*CELL_ADDR_WIDTH];\n";
fout << "				end\n";
			}
			else if (j == 3) {
fout << "			else if (arbiter_" << x+1 << "_" << y+1 << "_top[" << j << "])\n";
fout << "				begin\n";
fout << "				reg_FSM_to_Cell_read_addr[" << i+1 << "*CELL_ADDR_WIDTH-1:" << i <<"*CELL_ADDR_WIDTH] = FSM_to_Cell_read_addr_" << k+1 << "_" << l+1 << "[" << m+1 << "*CELL_ADDR_WIDTH-1:" << m << "*CELL_ADDR_WIDTH];\n";
fout << "				end\n";
			}
			else if (j == 4) {
fout << "			else if (arbiter_" << x+1 << "_" << y+1 << "_top[" << j << "])\n";
fout << "				begin\n";
fout << "				reg_FSM_to_Cell_read_addr[" << i+1 << "*CELL_ADDR_WIDTH-1:" << i <<"*CELL_ADDR_WIDTH] = FSM_to_Cell_read_addr_" << k+1 << "_" << l+1 << "[" << m+1 << "*CELL_ADDR_WIDTH-1:" << m << "*CELL_ADDR_WIDTH];\n";
fout << "				end\n";
fout << "			else\n";
fout << "				begin\n";
fout << "				reg_FSM_to_Cell_read_addr[" << i+1 << "*CELL_ADDR_WIDTH-1:" << i <<"*CELL_ADDR_WIDTH] = 0;\n";
fout << "				end\n";
			}
//fout << "			reg_FSM_to_Cell_read_addr[" << i+1 << "*CELL_ADDR_WIDTH-1:" << i <<"*CELL_ADDR_WIDTH] = (arbiter_" << x+1 << "_" << y+1 << "_top[" << j << "]) ? FSM_to_Cell_read_addr_" << k+1 << "_" << l+1 << "[" << m+1 << "*CELL_ADDR_WIDTH-1:" << m << "*CELL_ADDR_WIDTH] : reg_FSM_to_Cell_read_addr[" << i+1 << "*CELL_ADDR_WIDTH-1:" << i <<"*CELL_ADDR_WIDTH];\n";
		}
		else {
			if (j == 0) {
fout << "			if (arbiter_" << x+1 << "_" << y+1 << "_bottom[" << j << "])\n";
fout << "				begin\n";
fout << "				reg_FSM_to_Cell_read_addr[" << i+1 << "*CELL_ADDR_WIDTH-1:" << i <<"*CELL_ADDR_WIDTH] = FSM_to_Cell_read_addr_" << k+1 << "_" << l+1 << "[" << m+1 << "*CELL_ADDR_WIDTH-1:" << m << "*CELL_ADDR_WIDTH];\n";
fout << "				end\n";
			}
			else if (j == 1) {
fout << "			else if (arbiter_" << x+1 << "_" << y+1 << "_bottom[" << j << "])\n";
fout << "				begin\n";
fout << "				reg_FSM_to_Cell_read_addr[" << i+1 << "*CELL_ADDR_WIDTH-1:" << i <<"*CELL_ADDR_WIDTH] = FSM_to_Cell_read_addr_" << k+1 << "_" << l+1 << "[" << m+1 << "*CELL_ADDR_WIDTH-1:" << m << "*CELL_ADDR_WIDTH];\n";
fout << "				end\n";
			}
			else if (j == 2) {
fout << "			else if (arbiter_" << x+1 << "_" << y+1 << "_bottom[" << j << "])\n";
fout << "				begin\n";
fout << "				reg_FSM_to_Cell_read_addr[" << i+1 << "*CELL_ADDR_WIDTH-1:" << i <<"*CELL_ADDR_WIDTH] = FSM_to_Cell_read_addr_" << k+1 << "_" << l+1 << "[" << m+1 << "*CELL_ADDR_WIDTH-1:" << m << "*CELL_ADDR_WIDTH];\n";
fout << "				end\n";
			}
			else if (j == 3) {
fout << "			else if (arbiter_" << x+1 << "_" << y+1 << "_bottom[" << j << "])\n";
fout << "				begin\n";
fout << "				reg_FSM_to_Cell_read_addr[" << i+1 << "*CELL_ADDR_WIDTH-1:" << i <<"*CELL_ADDR_WIDTH] = FSM_to_Cell_read_addr_" << k+1 << "_" << l+1 << "[" << m+1 << "*CELL_ADDR_WIDTH-1:" << m << "*CELL_ADDR_WIDTH];\n";
fout << "				end\n";
fout << "			else\n";
fout << "				begin\n";
fout << "				reg_FSM_to_Cell_read_addr[" << i+1 << "*CELL_ADDR_WIDTH-1:" << i <<"*CELL_ADDR_WIDTH] = 0;\n";
fout << "				end\n";
			}
//fout << "			reg_FSM_to_Cell_read_addr[" << i+1 << "*CELL_ADDR_WIDTH-1:" << i <<"*CELL_ADDR_WIDTH] = (arbiter_" << x+1 << "_" << y+1 << "_bottom[" << j << "]) ? FSM_to_Cell_read_addr_" << k+1 << "_" << l+1 << "[" << m+1 << "*CELL_ADDR_WIDTH-1:" << m << "*CELL_ADDR_WIDTH] : reg_FSM_to_Cell_read_addr[" << i+1 << "*CELL_ADDR_WIDTH-1:" << i <<"*CELL_ADDR_WIDTH];\n";
		}
			j++;
		}

	}
	}
	}
		if (j == 0) {
fout << "			reg_FSM_to_Cell_read_addr[" << i+1 << "*CELL_ADDR_WIDTH-1:" << i <<"*CELL_ADDR_WIDTH] = 0;\n";
		}
	}
*/
fout << "				end\n";
	}
fout << "		endcase\n";
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
