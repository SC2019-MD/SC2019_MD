These sets of scripts will do:
0: Generate input particle initilization files for cell memeories based on particle positions
	GenInputCellList_ApoA1.m
1, Generate input particle initilization files based on raw ApoA1 data for on-chip particle memory modules (based on ApoA1 dataset)
	GenInputPositionFile_ApoA1.m
2, Generate interpolation tables for 1st, 2nd, 3rd order interpolation
	LJ_no_smooth_poly_interpolation_accuracy.m, LJ_no_smooth_poly_interpolation_function.m: 
3, Generate verification file for simulation in HEX format
	Simulation_Verification_LJ_no_smooth.m -> VERIFICATION_REFERENCE_OUTPUT.txt
	Simulation_Verification_Input_Pair_Gen_ApoA1.m  -> VERIFICATION_PARTICLE_PAIR_INPUT.txt

**To use this for generating cell list data:
1, Run LJ_no_smooth_poly_interpolation_accuracy.m: to generate the table lookup form (c0_8.txt, etc. and c0_8.mif, etc)
2, Convert the .mif file to .hex using Quartus (open the .mif file in quartus and save as .hex)
3, Before run simulation, initialize the lut modules with the c0_8.hex and etc. files
4, Run GenInputCellList_ApoA1.m to generate the cell list initialization file, each file contains the particles belongs to one cell (cell_ini_file_cellx_celly_cellz.mif ex. cell_ini_file_1_2_3.mif)
5, Convert the .mif file to .hex using Quartus (open the .mif file in quartus and save as .hex)
6, Initilize the cell memory module with .hex file
7, Verification on input particle pairs sending to filters:
	Simulation_Verification_Input_Pair_Gen_ApoA1.m  -> VERIFICATION_PARTICLE_PAIR_INPUT.txt


**To use this for quick testing based on raw ApoA1 data:
1, Run LJ_no_smooth_poly_interpolation_accuracy.m: to generate the table lookup form (c0_8.txt, etc. and c0_8.mif, etc)
2, Convert the .mif file to .hex using Quartus (open the .mif file in quartus and save as .hex)
3, Before run simulation, initialize the lut modules with the c0_8.hex and etc. files
4, Run GenInputPositionFile_ApoA1.m: genearte the position data (particle_neighbor_x.mif, etc.)
5, Convert the position .mif file to .hex
6, Initilize the position module with .hex file
7, Run Simulation_Verification_LJ_no_smooth.m: This will generate VERIFICATION_REFERENCE_OUTPUT.txt, which in HEX format, use this directly to compare with the simulation waveform