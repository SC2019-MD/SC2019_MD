#include <fstream>
#include <math.h>
#include <ctime>
#include <string>
#include <stdlib.h>

#include "Gen_Sim_Script.h"

using namespace std;

int Gen_Sim_Script(std::string* common_path, std::string* sim_script_out_path, std::string* sim_top_module){

//	// Set the simulation top module
//	std::string sim_top_module = "Pos_Cache_2_2_2_tb";

	// Setup Generating file
	char filename[100];
	sprintf(filename,"MD_RL.do");

	std::string path = *common_path + "/SourceCode/";
	std::string cell_mem_path = *common_path + "/SourceCode/CellMemoryModules/";
	std::string output_path = *common_path + *sim_script_out_path + "/" + filename;
	std::ofstream fout;
	fout.open(output_path.c_str());
	if (fout.fail()){
		printf("open %s failed, exiting\n", output_path.c_str());
		exit(-1);
	}
	 
	fout << "###########################################################################################################################\n";
	fout << "## !!!! Copy this file under the \"mentor\" folder!!!!!!!!\n";
	fout << "###########################################################################################################################\n\n";

	fout << "# # QSYS_SIMDIR is used in the Quartus-generated IP simulation script to\n";
	fout << "# # construct paths to the files required to simulate the IP in your Quartus\n";
	fout << "# # project. By default, the IP script assumes that you are launching the\n";
	fout << "# # simulator from the IP script location. If launching from another\n";
	fout << "# # location, set QSYS_SIMDIR to the output directory you specified when you\n";
	fout << "# # generated the IP script, relative to the directory from which you launch\n";
	fout << "# # the simulator.\n";
	fout << "# #\n";
	fout << " set QSYS_SIMDIR " << *common_path << "\n\n";

	fout << "# #\n";
	fout << "# # Source the generated IP simulation script.\n";
	fout << " source $QSYS_SIMDIR/mentor/msim_setup.tcl\n";
	fout << "# #\n";
	fout << "# # Set any compilation options you require (this is unusual).\n";
	fout << "# set USER_DEFINED_COMPILE_OPTIONS <compilation options>\n";
	fout << "# set USER_DEFINED_VHDL_COMPILE_OPTIONS <compilation options for VHDL>\n";
	fout << "# set USER_DEFINED_VERILOG_COMPILE_OPTIONS <compilation options for Verilog>\n";
	fout << "# #\n";
	fout << "# # Call command to compile the Quartus EDA simulation library.\n";
	fout << " dev_com\n";
	fout << "# #\n";
	fout << "# # Call command to compile the Quartus-generated IP simulation files.\n";
	fout << " com\n";
	fout << "# #\n";
	fout << "# # Add commands to compile all design files and testbench files, including\n";
	fout << "# # the top level. (These are all the files required for simulation other\n";
	fout << "# # than the files compiled by the Quartus-generated IP simulation script)\n";
	fout << "# #\n\n";
	
	// Generate Top Modules
	fout << "# # Top Modules\n";
	fout << " vlog -vlog01compat -work work " << path << "define.v\n";
	fout << " vlog -vlog01compat -work work " << path << "RL_Top.v\n";
	fout << " vlog -vlog01compat -work work " << path << "RL_Top_tb.v\n";
	fout << " vlog -vlog01compat -work work " << path << "RL_LJ_Top.v\n";
	fout << " vlog -vlog01compat -work work " << path << "RL_LJ_Top_tb.v\n";
	fout << " vlog -vlog01compat -work work " << path << "RL_LJ_Pipeline_1st_Order_no_filter.v\n";
	fout << " vlog -vlog01compat -work work " << path << "RL_LJ_Pipeline_1st_Order_no_filter_tb.v\n";
	
	// Generate Force Evaluation Units
	fout << "# # Force Evaluation Units\n";
	fout << " vlog -vlog01compat -work work " << path << "RL_Evaluation_Unit.v\n";
	fout << " vlog -vlog01compat -work work " << path << "RL_Force_Evaluation_Unit.v\n";
	fout << " vlog -vlog01compat -work work " << path << "RL_Evaluate_Pairs_1st_Order_v2.v\n";
	fout << " vlog -vlog01compat -work work " << path << "RL_Evaluate_Pairs_1st_Order_v2_tb.v\n";
	fout << " vlog -vlog01compat -work work " << path << "RL_LJ_Evaluation_Unit.v\n";
	fout << " vlog -vlog01compat -work work " << path << "RL_LJ_Force_Evaluation_Unit.v\n";
	fout << " vlog -vlog01compat -work work " << path << "RL_LJ_Force_Evaluation_Unit_simple_filter.v\n";
	fout << " vlog -vlog01compat -work work " << path << "Particle_Pair_Gen_HalfShell.v\n";
	fout << " vlog -vlog01compat -work work " << path << "RL_LJ_Evaluate_Pairs_1st_Order.v\n";
	fout << " vlog -vlog01compat -work work " << path << "RL_LJ_Evaluate_Pairs_1st_Order_tb.v\n";
	fout << " vlog -vlog01compat -work work " << path << "Filter_Bank.v\n";
	fout << " vlog -vlog01compat -work work " << path << "Filter_Bank_no_DSP.v\n";
	fout << " vlog -vlog01compat -work work " << path << "Filter_Arbiter.v\n";
	fout << " vlog -vlog01compat -work work " << path << "Filter_Arbiter_tb.v\n";
	fout << " vlog -vlog01compat -work work " << path << "Filter_Logic.v\n";
	fout << " vlog -vlog01compat -work work " << path << "Filter_Logic_no_DSP.v\n";
	fout << " vlog -vlog01compat -work work " << path << "r2_compute.v\n";
	fout << " vlog -vlog01compat -work work " << path << "r2_compute_tb.v\n";
	fout << " vlog -vlog01compat -work work " << path << "r2_compute_with_pbc.v\n";
	fout << " vlog -vlog01compat -work work " << path << "r2_compute_with_pbc_tb.v\n";
	fout << " vlog -vlog01compat -work work " << path << "Filter_Buffer.v\n";
	fout << " vlog -vlog01compat -work work " << path << "Filter_Buffer_tb.v\n";
	fout << " vlog -vlog01compat -work work " << path << "lut0_14.v\n";
	fout << " vlog -vlog01compat -work work " << path << "lut1_14.v\n";
	fout << " vlog -vlog01compat -work work " << path << "lut0_8.v\n";
	fout << " vlog -vlog01compat -work work " << path << "lut1_8.v\n";
	fout << " vlog -vlog01compat -work work " << path << "lut0_3.v\n";
	fout << " vlog -vlog01compat -work work " << path << "lut1_3.v\n";
	// Generate Accumulation Units
	fout << "# # Accumulation Units\n";
	fout << " vlog -vlog01compat -work work " << path << "Force_Write_Back_Controller.v\n";
	fout << " vlog -vlog01compat -work work " << path << "Force_Write_Back_Controller_tb.v\n";
	fout << " vlog -vlog01compat -work work " << path << "force_cache.v\n";
	fout << " vlog -vlog01compat -work work " << path << "force_cache_tb.v\n";
	fout << " vlog -vlog01compat -work work " << path << "Force_Cache_Input_Buffer.v\n";
	fout << " vlog -vlog01compat -work work " << path << "Partial_Force_Acc.v\n";
	fout << " vlog -vlog01compat -work work " << path << "Partial_Force_Acc_tb.v\n";
	fout << " vlog -vlog01compat -work work " << path << "FIFO.v\n";
	// Generate Motion Update Units
	fout << "# # Motion Update Units\n";
	fout << " vlog -vlog01compat -work work " << path << "Motion_Update.v\n";
	fout << " vlog -vlog01compat -work work " << path << "Motion_Update_tb.v\n";
	fout << " vlog -vlog01compat -work work " << path << "cell_boundary_mem.v\n";
	// DSP Units
	fout << "# # DSP Units\n";
	fout << " vlog -vlog01compat -work work " << path << "FP_ADD.v\n";
	fout << " vlog -vlog01compat -work work " << path << "FP_ACC.v\n";
	fout << " vlog -vlog01compat -work work " << path << "FP_MUL.v\n";
	fout << " vlog -vlog01compat -work work " << path << "FP_MUL_ADD.v\n";
	fout << " vlog -vlog01compat -work work " << path << "FP_SUB.v\n";
	fout << " vlog -vlog01compat -work work " << path << "FP_SUB_tb.v\n";
	fout << " vlog -vlog01compat -work work " << path << "FP_Comparator_Latency_tb.v\n";
	// Position Caches
	fout << "# # Position Caches\n";
	fout << " vlog -vlog01compat -work work " << cell_mem_path << "cell_empty.v\n";
	fout << " vlog -vlog01compat -work work " << cell_mem_path << "cell_2_2_2.v\n";
	fout << " vlog -vlog01compat -work work " << cell_mem_path << "cell_2_2_3.v\n";
	fout << " vlog -vlog01compat -work work " << cell_mem_path << "cell_2_3_1.v\n";
	fout << " vlog -vlog01compat -work work " << cell_mem_path << "cell_2_3_2.v\n";
	fout << " vlog -vlog01compat -work work " << cell_mem_path << "cell_2_3_3.v\n";
	fout << " vlog -vlog01compat -work work " << cell_mem_path << "cell_3_1_1.v\n";
	fout << " vlog -vlog01compat -work work " << cell_mem_path << "cell_3_1_2.v\n";
	fout << " vlog -vlog01compat -work work " << cell_mem_path << "cell_3_1_3.v\n";
	fout << " vlog -vlog01compat -work work " << cell_mem_path << "cell_3_2_1.v\n";
	fout << " vlog -vlog01compat -work work " << cell_mem_path << "cell_3_2_2.v\n";
	fout << " vlog -vlog01compat -work work " << cell_mem_path << "cell_3_2_3.v\n";
	fout << " vlog -vlog01compat -work work " << cell_mem_path << "cell_3_3_1.v\n";
	fout << " vlog -vlog01compat -work work " << cell_mem_path << "cell_3_3_2.v\n";
	fout << " vlog -vlog01compat -work work " << cell_mem_path << "cell_3_3_3.v\n";
	fout << " vlog -vlog01compat -work work " << cell_mem_path << "Pos_Cache_2_2_2.v\n";
	fout << " vlog -vlog01compat -work work " << cell_mem_path << "Pos_Cache_2_2_3.v\n";
	fout << " vlog -vlog01compat -work work " << cell_mem_path << "Pos_Cache_2_3_1.v\n";
	fout << " vlog -vlog01compat -work work " << cell_mem_path << "Pos_Cache_2_3_2.v\n";
	fout << " vlog -vlog01compat -work work " << cell_mem_path << "Pos_Cache_2_3_3.v\n";
	fout << " vlog -vlog01compat -work work " << cell_mem_path << "Pos_Cache_3_1_1.v\n";
	fout << " vlog -vlog01compat -work work " << cell_mem_path << "Pos_Cache_3_1_2.v\n";
	fout << " vlog -vlog01compat -work work " << cell_mem_path << "Pos_Cache_3_1_3.v\n";
	fout << " vlog -vlog01compat -work work " << cell_mem_path << "Pos_Cache_3_2_1.v\n";
	fout << " vlog -vlog01compat -work work " << cell_mem_path << "Pos_Cache_3_2_2.v\n";
	fout << " vlog -vlog01compat -work work " << cell_mem_path << "Pos_Cache_3_2_3.v\n";
	fout << " vlog -vlog01compat -work work " << cell_mem_path << "Pos_Cache_3_3_1.v\n";
	fout << " vlog -vlog01compat -work work " << cell_mem_path << "Pos_Cache_3_3_2.v\n";
	fout << " vlog -vlog01compat -work work " << cell_mem_path << "Pos_Cache_3_3_3.v\n";
	fout << " vlog -vlog01compat -work work " << cell_mem_path << "Pos_Cache_2_2_2_tb.v\n";
	// Velocity Caches
	fout << "# # Velocity Caches\n";
	fout << " vlog -vlog01compat -work work " << cell_mem_path << "velocity_2_2_2.v\n";
	fout << " vlog -vlog01compat -work work " << cell_mem_path << "Velocity_Cache_2_2_2.v\n";
	// OpenCL Related Modules
	fout << "# # OpenCL Related Modules\n";
	fout << " vlog -vlog01compat -work work " << path << "RL_LJ_Evaluation_OpenCL_Top.v\n";
	fout << " vlog -vlog01compat -work work " << path << "RL_LJ_Evaluation_OpenCL_Top_tb.v\n";
	// Testing Modules
	fout << "# # Testing Modules\n";
	fout << " vlog -vlog01compat -work work " << path << "fp_accumulation_test.v\n";
	fout << " vlog -vlog01compat -work work " << path << "fp_accumulation_test_tb.v\n";
	// Depricated Modules
	fout << "# # Depricated Modules\n";
	fout << " #vlog -vlog01compat -work work " << path << "RL_Pipeline_1st_Order.v\n";
	fout << " #vlog -vlog01compat -work work " << path << "RL_Pipeline_1st_Order_tb.v\n";
	fout << " #vlog -vlog01compat -work work " << path << "RL_Evaluate_Pairs_1st_Order.v\n";
	fout << " #vlog -vlog01compat -work work " << path << "RL_LJ_Top_Raw_Data_Testing.v\n";
	fout << " #vlog -vlog01compat -work work " << path << "RL_LJ_Top_Raw_Data_Testing_tb.v\n";
	fout << " vlog -vlog01compat -work work " << cell_mem_path << "ram_ref_x.v\n";
	fout << " vlog -vlog01compat -work work " << cell_mem_path << "ram_ref_y.v\n";
	fout << " vlog -vlog01compat -work work " << cell_mem_path << "ram_ref_z.v\n";
	fout << " vlog -vlog01compat -work work " << cell_mem_path << "ram_neighbor_x.v\n";
	fout << " vlog -vlog01compat -work work " << cell_mem_path << "ram_neighbor_y.v\n";
	fout << " vlog -vlog01compat -work work " << cell_mem_path << "ram_neighbor_z.v\n";

	fout << "# #\n";
	fout << "# # Set the top-level simulation or testbench module/entity name, which is\n";
	fout << "# # used by the elab command to elaborate the top level.\n";
	fout << "# #\n";
	/////////////////////////////////////////////////////////////////////////
	// Set testbench
	/////////////////////////////////////////////////////////////////////////
	fout << " set TOP_LEVEL_NAME " << *sim_top_module << "\n";
	fout << "# #\n";
	fout << "# # Set any elaboration options you require.\n";
	fout << "# set USER_DEFINED_ELAB_OPTIONS <elaboration options>\n";
	fout << "# #\n";
	fout << "# # Call command to elaborate your design and testbench.\n";
	fout << " elab\n";
	fout << "# #\n";
	fout << "# # Run the simulation.\n";
	fout << " add wave *\n";
	fout << " view structure\n";
	fout << " view signals\n\n";

	/////////////////////////////////////////////////////////////////////////
	// Set Simulation parameters
	/////////////////////////////////////////////////////////////////////////
	// Set display radix
	fout << " radix hex\n";
	// Set default simulation run time
	fout << " run 1000ns\n";

	fout << "# #\n";
	fout << "# # Report success to the shell.\n";
	fout << "# exit -code 0\n";
	fout << "# #\n";


	fout.close();

	return 1;
}
