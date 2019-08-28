###########################################################################################################################
## !!!! Copy this file under the "mentor" folder!!!!!!!!
###########################################################################################################################

# # QSYS_SIMDIR is used in the Quartus-generated IP simulation script to
# # construct paths to the files required to simulate the IP in your Quartus
# # project. By default, the IP script assumes that you are launching the
# # simulator from the IP script location. If launching from another
# # location, set QSYS_SIMDIR to the output directory you specified when you
# # generated the IP script, relative to the directory from which you launch
# # the simulator.
# #
 set QSYS_SIMDIR /home/chunshu/Documents/Legacy

# #
# # Source the generated IP simulation script.
 source $QSYS_SIMDIR/mentor/msim_setup.tcl
# #
# # Set any compilation options you require (this is unusual).
# set USER_DEFINED_COMPILE_OPTIONS <compilation options>
# set USER_DEFINED_VHDL_COMPILE_OPTIONS <compilation options for VHDL>
# set USER_DEFINED_VERILOG_COMPILE_OPTIONS <compilation options for Verilog>
# #
# # Call command to compile the Quartus EDA simulation library.
 dev_com
# #
# # Call command to compile the Quartus-generated IP simulation files.
 com
# #
# # Add commands to compile all design files and testbench files, including
# # the top level. (These are all the files required for simulation other
# # than the files compiled by the Quartus-generated IP simulation script)
# #

# # Top Modules
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/define.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/RL_Top.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/RL_Top_tb.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/RL_LJ_Top.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/RL_LJ_Top_tb.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/RL_LJ_Pipeline_1st_Order_no_filter.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/RL_LJ_Pipeline_1st_Order_no_filter_tb.v
# # Force Evaluation Units
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/RL_Evaluation_Unit.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/RL_Force_Evaluation_Unit.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/RL_Evaluate_Pairs_1st_Order_v2.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/RL_Evaluate_Pairs_1st_Order_v2_tb.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/RL_LJ_Evaluation_Unit.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/RL_LJ_Force_Evaluation_Unit.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/RL_LJ_Force_Evaluation_Unit_simple_filter.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/Particle_Pair_Gen_HalfShell.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/RL_LJ_Evaluate_Pairs_1st_Order.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/RL_LJ_Evaluate_Pairs_1st_Order_tb.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/Filter_Bank.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/Filter_Bank_no_DSP.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/Filter_Arbiter.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/Filter_Arbiter_tb.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/Filter_Logic.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/Filter_Logic_no_DSP.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/r2_compute.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/r2_compute_tb.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/r2_compute_with_pbc.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/r2_compute_with_pbc_tb.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/Filter_Buffer.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/Filter_Buffer_tb.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/lut0_14.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/lut1_14.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/lut0_8.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/lut1_8.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/lut0_3.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/lut1_3.v
# # Accumulation Units
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/Force_Write_Back_Controller.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/Force_Write_Back_Controller_tb.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/force_cache.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/force_cache_tb.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/Force_Cache_Input_Buffer.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/Partial_Force_Acc.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/Partial_Force_Acc_tb.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/FIFO.v
# # Motion Update Units
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/Motion_Update.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/Motion_Update_tb.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/cell_boundary_mem.v
# # DSP Units
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/FP_ADD.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/FP_ACC.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/FP_MUL.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/FP_MUL_ADD.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/FP_SUB.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/FP_SUB_tb.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/FP_Comparator_Latency_tb.v
# # Position Caches
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/CellMemoryModules/cell_empty.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/CellMemoryModules/cell_2_2_2.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/CellMemoryModules/cell_2_2_3.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/CellMemoryModules/cell_2_3_1.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/CellMemoryModules/cell_2_3_2.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/CellMemoryModules/cell_2_3_3.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/CellMemoryModules/cell_3_1_1.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/CellMemoryModules/cell_3_1_2.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/CellMemoryModules/cell_3_1_3.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/CellMemoryModules/cell_3_2_1.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/CellMemoryModules/cell_3_2_2.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/CellMemoryModules/cell_3_2_3.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/CellMemoryModules/cell_3_3_1.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/CellMemoryModules/cell_3_3_2.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/CellMemoryModules/cell_3_3_3.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/CellMemoryModules/Pos_Cache_2_2_2.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/CellMemoryModules/Pos_Cache_2_2_3.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/CellMemoryModules/Pos_Cache_2_3_1.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/CellMemoryModules/Pos_Cache_2_3_2.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/CellMemoryModules/Pos_Cache_2_3_3.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/CellMemoryModules/Pos_Cache_3_1_1.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/CellMemoryModules/Pos_Cache_3_1_2.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/CellMemoryModules/Pos_Cache_3_1_3.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/CellMemoryModules/Pos_Cache_3_2_1.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/CellMemoryModules/Pos_Cache_3_2_2.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/CellMemoryModules/Pos_Cache_3_2_3.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/CellMemoryModules/Pos_Cache_3_3_1.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/CellMemoryModules/Pos_Cache_3_3_2.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/CellMemoryModules/Pos_Cache_3_3_3.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/CellMemoryModules/Pos_Cache_2_2_2_tb.v
# # Velocity Caches
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/CellMemoryModules/velocity_2_2_2.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/CellMemoryModules/Velocity_Cache_2_2_2.v
# # OpenCL Related Modules
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/RL_LJ_Evaluation_OpenCL_Top.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/RL_LJ_Evaluation_OpenCL_Top_tb.v
# # Testing Modules
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/fp_accumulation_test.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/fp_accumulation_test_tb.v
# # Depricated Modules
 #vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/RL_Pipeline_1st_Order.v
 #vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/RL_Pipeline_1st_Order_tb.v
 #vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/RL_Evaluate_Pairs_1st_Order.v
 #vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/RL_LJ_Top_Raw_Data_Testing.v
 #vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/RL_LJ_Top_Raw_Data_Testing_tb.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/CellMemoryModules/ram_ref_x.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/CellMemoryModules/ram_ref_y.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/CellMemoryModules/ram_ref_z.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/CellMemoryModules/ram_neighbor_x.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/CellMemoryModules/ram_neighbor_y.v
 vlog -vlog01compat -work work /home/chunshu/Documents/Legacy/SourceCode/CellMemoryModules/ram_neighbor_z.v
# #
# # Set the top-level simulation or testbench module/entity name, which is
# # used by the elab command to elaborate the top level.
# #
 set TOP_LEVEL_NAME RL_Top_tb
# #
# # Set any elaboration options you require.
# set USER_DEFINED_ELAB_OPTIONS <elaboration options>
# #
# # Call command to elaborate your design and testbench.
 elab
# #
# # Run the simulation.
 add wave *
 view structure
 view signals

 radix hex
 run 1000ns
# #
# # Report success to the shell.
# exit -code 0
# #
