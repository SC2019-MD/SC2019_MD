/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: Particle_Pair_Gen_HalfShell.v
//
//	Function: 
//				Generating particle pairs based on the Half-Shell Method
//				Each home cell has 13 neighbor cells
//				This module interact with cell memeory modules and Force Evaluation unit in the follow way:
//					1, Read data from Cell Memory
//					2, Travserse all the particle in the home cell
//					3, Assemble particle pairs along with the particle ID and send to force evaluation unit
//					4, When all the reference particles in the home cell is done processing, issue a done signal
//				Cell coordinates start from (1,1,1) instead of (0,0,0)
//
// Mapping Scheme:
//				Half-shell method: each home cell interact with 13 nearest neighbors
//				For 8 Filters configurations, the mapping is follows(cell_x, cell_y, cell_z):
//					Filter 0: 222 (home)
//					Filter 1: 223 (face) 
//					Filter 2: 231 (edge) 232 (face) 
//					Filter 3: 233 (edge) 311 (corner) 
//					Filter 4: 312 (edge) 313 (corner) 
//					Filter 5: 321 (edge) 322 (face) 
//					Filter 6: 323 (edge) 331 (corner) 
//					Filter 7: 332 (edge) 333 (corner) 
//
// Signal Explaination:
//				1. input [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] Cell_to_FSM_readout_particle_position:
//						Order: MSB->LSB {333,332,331,323,322,321,313,312,311,233,232,231,223,222} Homecell is on LSB side
//				2. done: (Will keep high until next start signal arrive)
//						When refernece particles in a home cell have all done processing, this signal will set high, until the next start signal arrives
//
// Format:
//				particle_id [PARTICLE_ID_WIDTH-1:0]:  {cell_x, cell_y, cell_z, particle_in_cell_rd_addr}
//				in_ref_particle_position [3*DATA_WIDTH-1:0]: {refz, refy, refx}
//				in_neighbor_particle_position [3*DATA_WIDTH-1:0]: {neighborz, neighbory, neighborx}
//
// Used by:
//				RL_LJ_Top.v
//
// Dependency:
//				None
//
// Testbench:
//				RL_LJ_Top_tb.v
//
// Latency: 
//				Memory Read: 2 cycles latency between the assignment of read address and the realted data appear on the output port
//					* Possible reason: the read address is assigned as register
//
// Todo:
//				This is a work in progress module that will be used in the final system
//				1, Implement a general numbering mechanism for all the cell in the simulation space, currently using fixed cells id for each input to filters
//				1.1, Apply boundary conditions to cell ID when CELL_ID == 1 or CELL_ID = MAX
//				2, parameterize # of force evaluation units in it
//
// Created by:
//				Chen Yang 11/01/18
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module Particle_Pair_Gen_HalfShell
#(
	parameter DATA_WIDTH 					= 32,
	// The home cell this unit is working on
	parameter CELL_X							= 2,
	parameter CELL_Y							= 2,
	parameter CELL_Z							= 2,
	// High level parameters
	parameter NUM_EVAL_UNIT					= 1,											// # of evaluation units in the design
	// Dataset defined parameters
	parameter NUM_NEIGHBOR_CELLS			= 13,											// # of neighbor cells per home cell, for Half-shell method, is 13
	parameter CELL_ID_WIDTH					= 4,											// log(NUM_NEIGHBOR_CELLS)
	parameter MAX_CELL_PARTICLE_NUM		= 290,										// The maximum # of particles can be in a cell
	parameter CELL_ADDR_WIDTH				= 9,											// log(MAX_CELL_PARTICLE_NUM)
	parameter PARTICLE_ID_WIDTH			= CELL_ID_WIDTH*3+CELL_ADDR_WIDTH,	// # of bit used to represent particle ID, 9*9*7 cells, each 4-bit, each cell have max of 220 particles, 8-bit
	// Filter parameters
	parameter NUM_FILTER						= 8,		//4
	parameter ARBITER_MSB 					= 128,	//8								// 2^(NUM_FILTER-1)
	parameter FILTER_BUFFER_DEPTH 		= 32,
	parameter FILTER_BUFFER_ADDR_WIDTH	= 5
)
(
	input  clk,
	input  rst,
	input  start,
	// Ports connect to Cell Memory Module
	// Order: MSB->LSB {333,332,331,323,322,321,313,312,311,233,232,231,223,222} Homecell is on LSB side
	input  [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] Cell_to_FSM_readout_particle_position,
	output [(NUM_NEIGHBOR_CELLS+1)*CELL_ADDR_WIDTH-1:0] FSM_to_Cell_read_addr,
	output FSM_to_Cell_rden,
	// Ports connect to Force Evaluation Unit
	input  [NUM_FILTER-1:0] ForceEval_to_FSM_backpressure,				// Backpressure signal from Force Evaluation Unit
	input  ForceEval_to_FSM_all_buffer_empty,									// Only when all the filter buffers are empty, then the FSM will move on to the next reference particle
	output reg [NUM_FILTER*3*DATA_WIDTH-1:0] FSM_to_ForceEval_ref_particle_position,
	output reg [NUM_FILTER*3*DATA_WIDTH-1:0] FSM_to_ForceEval_neighbor_particle_position,
	output reg [NUM_FILTER*PARTICLE_ID_WIDTH-1:0] FSM_to_ForceEval_ref_particle_id,					// {cell_z, cell_y, cell_x, ref_particle_rd_addr}
	output reg [NUM_FILTER*PARTICLE_ID_WIDTH-1:0] FSM_to_ForceEval_neighbor_particle_id,			// {cell_z, cell_y, cell_x, neighbor_particle_rd_addr}
	output reg [NUM_FILTER-1:0] FSM_to_ForceEval_input_pair_valid,		// Signify the valid of input particle data, this signal should have 1 cycle delay of the rden signal, thus wait for the data read out from BRAM
	//** This signal is specifically added for handling the last reference particle **//
	// When the last reference particle finish its evaluation, since there's no valid particle comming in, the reference particle accumulator won't detect the change of particle id, thus won't create the output valid for the last reference particle's accumulated force
	// This signal will only set as high for one cycle for the entire home cell evaluation. When this signal is high, assign the 'ref_forceoutput_valid' as high
	output reg FSM_almost_done_generation,
	// Ports to top level modules
	// done signal, when entire home cell is done processing, this will keep high until the next time 'start' signal turn high
	output done
);
	
	genvar i;
	
	///////////////////////////////////////////////////////////////////////////////////////////////
	// FSM controller variables
	///////////////////////////////////////////////////////////////////////////////////////////////
	// State variables
	parameter WAIT_FOR_START			= 3'b000;
	parameter READ_CELL_INFO			= 3'b001;
	parameter READ_REF_PARTICLE		= 3'b010;
	parameter RECORD_REF_PARTICLE		= 3'b011;
	parameter EVALUATION 	  			= 3'b100;
	parameter CHECK_HOME_CELL_DONE	= 3'b101;
	parameter WAIT_FOR_FINISH 			= 3'b110;
	parameter DONE 			  			= 3'b111;
	// Cell ID information
	// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	// !!!!!!!ATTENTION: when CELL_ID is less than 1, need to apply boundary conditions
	// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	wire [CELL_ID_WIDTH-1:0] home_cell_id_x;
	wire [CELL_ID_WIDTH-1:0] home_cell_id_y;
	wire [CELL_ID_WIDTH-1:0] home_cell_id_z;
	wire [CELL_ID_WIDTH-1:0] home_cell_id_x_plus_1;
	wire [CELL_ID_WIDTH-1:0] home_cell_id_y_plus_1;
	wire [CELL_ID_WIDTH-1:0] home_cell_id_y_minus_1;
	wire [CELL_ID_WIDTH-1:0] home_cell_id_z_plus_1;
	wire [CELL_ID_WIDTH-1:0] home_cell_id_z_minus_1;
	assign home_cell_id_x = CELL_X;
	assign home_cell_id_y = CELL_Y;
	assign home_cell_id_z = CELL_Z;
	assign home_cell_id_x_plus_1 = CELL_X + 1'b1;
	assign home_cell_id_y_plus_1 = CELL_Y + 1'b1;
	assign home_cell_id_z_plus_1 = CELL_Z + 1'b1;
	assign home_cell_id_y_minus_1 = CELL_Y - 1'b1;
	assign home_cell_id_z_minus_1 = CELL_Z - 1'b1;
	
	// Control Signals
	reg FSM_to_Output_homecell_done;
	assign done = FSM_to_Output_homecell_done;
	reg rden;
	assign FSM_to_Cell_rden = rden;
	reg [2:0] state;
	// Counter that wait for the last pair to finish evaluation (17+14=31 cycles)
	reg [5:0] wait_finish_counter;
	// Delay registers to record the previous backpressure input (since there are 2 cycles before the backpressure is here and the data actually stop generating)
	// Use this sigal to determine whether the output particle pairs should be valid
	reg [NUM_FILTER-1:0] ForceEval_to_FSM_backpressure_reg1;
	reg [NUM_FILTER-1:0] delay_ForceEval_to_FSM_backpressure;
	// Register recording how many particles in each cell
	// Order: MSB->LSB {333,332,331,323,322,321,313,312,311,233,232,231,223,222} Homecell is on LSB side
	reg [(NUM_NEIGHBOR_CELLS+1)*CELL_ADDR_WIDTH-1:0] FSM_Cell_Particle_Num;
	// Register recording which cell is being read by each filter
	// Filter 0 & 1 has only a single cell to read from, while 2~7 has 2 cells, after finished reading one cell, need to flip the bit to read from the next one
	reg [NUM_FILTER-1:0] FSM_Filter_Sel_Cell;
	reg [NUM_FILTER-1:0] FSM_Filter_Sel_Cell_reg1;
	reg [NUM_FILTER-1:0] delay_FSM_Filter_Sel_Cell;
	// Register for travering all the particles in each cell independently 
	// Used as read address for cells (1 cycle delay between address and readout particle info)
	// Also used to assemble the FSM_to_ForceEval_ref_particle_id
	// Order: MSB->LSB {Filter7, Filter6, ..., Filter 0}
	reg [NUM_FILTER*CELL_ADDR_WIDTH-1:0] FSM_Filter_Read_Addr;
	reg [NUM_FILTER*CELL_ADDR_WIDTH-1:0] FSM_Filter_Read_Addr_reg1;
	reg [NUM_FILTER*CELL_ADDR_WIDTH-1:0] delay_FSM_Filter_Read_Addr;
	// Flags signify if the workload on each Filter is finished
	reg [NUM_FILTER-1:0] FSM_Filter_Done_Processing;
	reg [NUM_FILTER-1:0] FSM_Filter_Done_Processing_reg1;
	reg [NUM_FILTER-1:0] delay_FSM_Filter_Done_Processing;
	wire [NUM_FILTER-1:0] FSM_Filter_Done_Processing_all_1_flag;
	assign FSM_Filter_Done_Processing_all_1_flag = -1;
	// Registers for pointing to the current reference particle
	reg [CELL_ADDR_WIDTH-1:0] FSM_Ref_Particle_Addr;
	// Registers for current reference particle position
	reg [3*DATA_WIDTH-1:0] FSM_Ref_Particle_Position;
	// Wire for composing the reference particle global id
	wire [NUM_EVAL_UNIT*PARTICLE_ID_WIDTH-1:0] FSM_Ref_Particle_ID;
	assign FSM_Ref_Particle_ID = {home_cell_id_x,home_cell_id_y,home_cell_id_z,FSM_Ref_Particle_Addr};
	// Wires for assembling the Neighbor_Particle_ID
	wire [NUM_FILTER*PARTICLE_ID_WIDTH-1:0] FSM_Neighbor_Particle_ID;
	wire [3*CELL_ID_WIDTH-1:0] FILTER_0_CELL_ID_1;
	wire [3*CELL_ID_WIDTH-1:0] FILTER_1_CELL_ID_1;
	wire [3*CELL_ID_WIDTH-1:0] FILTER_2_CELL_ID_1;
	wire [3*CELL_ID_WIDTH-1:0] FILTER_2_CELL_ID_2;
	wire [3*CELL_ID_WIDTH-1:0] FILTER_3_CELL_ID_1;
	wire [3*CELL_ID_WIDTH-1:0] FILTER_3_CELL_ID_2;
	wire [3*CELL_ID_WIDTH-1:0] FILTER_4_CELL_ID_1;
	wire [3*CELL_ID_WIDTH-1:0] FILTER_4_CELL_ID_2;
	wire [3*CELL_ID_WIDTH-1:0] FILTER_5_CELL_ID_1;
	wire [3*CELL_ID_WIDTH-1:0] FILTER_5_CELL_ID_2;
	wire [3*CELL_ID_WIDTH-1:0] FILTER_6_CELL_ID_1;
	wire [3*CELL_ID_WIDTH-1:0] FILTER_6_CELL_ID_2;
	wire [3*CELL_ID_WIDTH-1:0] FILTER_7_CELL_ID_1;
	wire [3*CELL_ID_WIDTH-1:0] FILTER_7_CELL_ID_2;
	assign FILTER_0_CELL_ID_1 = {home_cell_id_x,home_cell_id_y,home_cell_id_z};									// 222
	assign FILTER_1_CELL_ID_1 = {home_cell_id_x,home_cell_id_y,home_cell_id_z_plus_1};							// 223
	assign FILTER_2_CELL_ID_1 = {home_cell_id_x,home_cell_id_y_plus_1,home_cell_id_z_minus_1};				// 231
	assign FILTER_2_CELL_ID_2 = {home_cell_id_x,home_cell_id_y_plus_1,home_cell_id_z};							// 232
	assign FILTER_3_CELL_ID_1 = {home_cell_id_x,home_cell_id_y_plus_1,home_cell_id_z_plus_1};					// 233
	assign FILTER_3_CELL_ID_2 = {home_cell_id_x_plus_1,home_cell_id_y_minus_1,home_cell_id_z_minus_1};		// 311
	assign FILTER_4_CELL_ID_1 = {home_cell_id_x_plus_1,home_cell_id_y_minus_1,home_cell_id_z};				// 312
	assign FILTER_4_CELL_ID_2 = {home_cell_id_x_plus_1,home_cell_id_y_minus_1,home_cell_id_z_plus_1};		// 313
	assign FILTER_5_CELL_ID_1 = {home_cell_id_x_plus_1,home_cell_id_y,home_cell_id_z_minus_1};				// 321
	assign FILTER_5_CELL_ID_2 = {home_cell_id_x_plus_1,home_cell_id_y,home_cell_id_z};							// 322
	assign FILTER_6_CELL_ID_1 = {home_cell_id_x_plus_1,home_cell_id_y,home_cell_id_z_plus_1};					// 323
	assign FILTER_6_CELL_ID_2 = {home_cell_id_x_plus_1,home_cell_id_y_plus_1,home_cell_id_z_minus_1};		// 331
	assign FILTER_7_CELL_ID_1 = {home_cell_id_x_plus_1,home_cell_id_y_plus_1,home_cell_id_z};					// 332
	assign FILTER_7_CELL_ID_2 = {home_cell_id_x_plus_1,home_cell_id_y_plus_1,home_cell_id_z_plus_1};		// 333
	assign FSM_Neighbor_Particle_ID[1*PARTICLE_ID_WIDTH-1:0*PARTICLE_ID_WIDTH] = {FILTER_0_CELL_ID_1,delay_FSM_Filter_Read_Addr[1*CELL_ADDR_WIDTH-1:0*CELL_ADDR_WIDTH]};
	assign FSM_Neighbor_Particle_ID[2*PARTICLE_ID_WIDTH-1:1*PARTICLE_ID_WIDTH] = {FILTER_1_CELL_ID_1,delay_FSM_Filter_Read_Addr[2*CELL_ADDR_WIDTH-1:1*CELL_ADDR_WIDTH]};
	assign FSM_Neighbor_Particle_ID[3*PARTICLE_ID_WIDTH-1:2*PARTICLE_ID_WIDTH] = (delay_FSM_Filter_Sel_Cell[2]) ? {FILTER_2_CELL_ID_2,delay_FSM_Filter_Read_Addr[3*CELL_ADDR_WIDTH-1:2*CELL_ADDR_WIDTH]} : {FILTER_2_CELL_ID_1,delay_FSM_Filter_Read_Addr[3*CELL_ADDR_WIDTH-1:2*CELL_ADDR_WIDTH]};
	assign FSM_Neighbor_Particle_ID[4*PARTICLE_ID_WIDTH-1:3*PARTICLE_ID_WIDTH] = (delay_FSM_Filter_Sel_Cell[3]) ? {FILTER_3_CELL_ID_2,delay_FSM_Filter_Read_Addr[4*CELL_ADDR_WIDTH-1:3*CELL_ADDR_WIDTH]} : {FILTER_3_CELL_ID_1,delay_FSM_Filter_Read_Addr[4*CELL_ADDR_WIDTH-1:3*CELL_ADDR_WIDTH]};
	assign FSM_Neighbor_Particle_ID[5*PARTICLE_ID_WIDTH-1:4*PARTICLE_ID_WIDTH] = (delay_FSM_Filter_Sel_Cell[4]) ? {FILTER_4_CELL_ID_2,delay_FSM_Filter_Read_Addr[5*CELL_ADDR_WIDTH-1:4*CELL_ADDR_WIDTH]} : {FILTER_4_CELL_ID_1,delay_FSM_Filter_Read_Addr[5*CELL_ADDR_WIDTH-1:4*CELL_ADDR_WIDTH]};
	assign FSM_Neighbor_Particle_ID[6*PARTICLE_ID_WIDTH-1:5*PARTICLE_ID_WIDTH] = (delay_FSM_Filter_Sel_Cell[5]) ? {FILTER_5_CELL_ID_2,delay_FSM_Filter_Read_Addr[6*CELL_ADDR_WIDTH-1:5*CELL_ADDR_WIDTH]} : {FILTER_5_CELL_ID_1,delay_FSM_Filter_Read_Addr[6*CELL_ADDR_WIDTH-1:5*CELL_ADDR_WIDTH]};
	assign FSM_Neighbor_Particle_ID[7*PARTICLE_ID_WIDTH-1:6*PARTICLE_ID_WIDTH] = (delay_FSM_Filter_Sel_Cell[6]) ? {FILTER_6_CELL_ID_2,delay_FSM_Filter_Read_Addr[7*CELL_ADDR_WIDTH-1:6*CELL_ADDR_WIDTH]} : {FILTER_6_CELL_ID_1,delay_FSM_Filter_Read_Addr[7*CELL_ADDR_WIDTH-1:6*CELL_ADDR_WIDTH]};
	assign FSM_Neighbor_Particle_ID[8*PARTICLE_ID_WIDTH-1:7*PARTICLE_ID_WIDTH] = (delay_FSM_Filter_Sel_Cell[7]) ? {FILTER_7_CELL_ID_2,delay_FSM_Filter_Read_Addr[8*CELL_ADDR_WIDTH-1:7*CELL_ADDR_WIDTH]} : {FILTER_7_CELL_ID_1,delay_FSM_Filter_Read_Addr[8*CELL_ADDR_WIDTH-1:7*CELL_ADDR_WIDTH]};
	
	///////////////////////////////////////////////////////////////////////////////////////////////
	// Signals between Cell Module and FSM
	///////////////////////////////////////////////////////////////////////////////////////////////
	//// Signals connect from cell module to FSM
	// Position Data
	// Order: MSB->LSB {333,332,331,323,322,321,313,312,311,233,232,231,223,222} Homecell is on LSB side
	// wire [(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] Cell_to_FSM_readout_particle_position;
	// **** Wires for assembling the Neighbor_Particle_Position
	wire [NUM_FILTER*3*DATA_WIDTH-1:0] FSM_Neighbor_Particle_Position;
	// Filter 0, cell 222
	assign FSM_Neighbor_Particle_Position[1*3*DATA_WIDTH-1:0*3*DATA_WIDTH] = Cell_to_FSM_readout_particle_position[1*3*DATA_WIDTH-1:0*3*DATA_WIDTH];
	// Filter 1, cell 223
	assign FSM_Neighbor_Particle_Position[2*3*DATA_WIDTH-1:1*3*DATA_WIDTH] = Cell_to_FSM_readout_particle_position[2*3*DATA_WIDTH-1:1*3*DATA_WIDTH];
	// Filter 2, cell 231 or cell 232
	assign FSM_Neighbor_Particle_Position[3*3*DATA_WIDTH-1:2*3*DATA_WIDTH] = (delay_FSM_Filter_Sel_Cell[2]) ? Cell_to_FSM_readout_particle_position[4*3*DATA_WIDTH-1:3*3*DATA_WIDTH] : Cell_to_FSM_readout_particle_position[3*3*DATA_WIDTH-1:2*3*DATA_WIDTH];
	// Filter 3, cell 233 or cell 311
	assign FSM_Neighbor_Particle_Position[4*3*DATA_WIDTH-1:3*3*DATA_WIDTH] = (delay_FSM_Filter_Sel_Cell[3]) ? Cell_to_FSM_readout_particle_position[6*3*DATA_WIDTH-1:5*3*DATA_WIDTH] : Cell_to_FSM_readout_particle_position[5*3*DATA_WIDTH-1:4*3*DATA_WIDTH];
	// Filter 4, cell 312 or cell 313
	assign FSM_Neighbor_Particle_Position[5*3*DATA_WIDTH-1:4*3*DATA_WIDTH] = (delay_FSM_Filter_Sel_Cell[4]) ? Cell_to_FSM_readout_particle_position[8*3*DATA_WIDTH-1:7*3*DATA_WIDTH] : Cell_to_FSM_readout_particle_position[7*3*DATA_WIDTH-1:6*3*DATA_WIDTH];
	// Filter 5, cell 321 or cell 322
	assign FSM_Neighbor_Particle_Position[6*3*DATA_WIDTH-1:5*3*DATA_WIDTH] = (delay_FSM_Filter_Sel_Cell[5]) ? Cell_to_FSM_readout_particle_position[10*3*DATA_WIDTH-1:9*3*DATA_WIDTH] : Cell_to_FSM_readout_particle_position[9*3*DATA_WIDTH-1:8*3*DATA_WIDTH];
	// Filter 6, cell 323 or cell 331
	assign FSM_Neighbor_Particle_Position[7*3*DATA_WIDTH-1:6*3*DATA_WIDTH] = (delay_FSM_Filter_Sel_Cell[6]) ? Cell_to_FSM_readout_particle_position[12*3*DATA_WIDTH-1:11*3*DATA_WIDTH] : Cell_to_FSM_readout_particle_position[11*3*DATA_WIDTH-1:10*3*DATA_WIDTH];
	// Filter 7, cell 332 or cell 333
	assign FSM_Neighbor_Particle_Position[8*3*DATA_WIDTH-1:7*3*DATA_WIDTH] = (delay_FSM_Filter_Sel_Cell[7]) ? Cell_to_FSM_readout_particle_position[14*3*DATA_WIDTH-1:13*3*DATA_WIDTH] : Cell_to_FSM_readout_particle_position[13*3*DATA_WIDTH-1:12*3*DATA_WIDTH];
	
	//// Signals connect from FSM to cell modules
	// Read Address to cells
	// wire [(NUM_NEIGHBOR_CELLS+1)*CELL_ADDR_WIDTH-1:0] FSM_to_Cell_read_addr;
	// ******** This is closely related with the mapping scheme
	// ******** Should the mapping scheme changes, or # of filters changes, redo this part
	assign FSM_to_Cell_read_addr[1*CELL_ADDR_WIDTH-1:0*CELL_ADDR_WIDTH] = FSM_Filter_Read_Addr[1*CELL_ADDR_WIDTH-1:0*CELL_ADDR_WIDTH];				// Cell 0, Filter 0
	assign FSM_to_Cell_read_addr[2*CELL_ADDR_WIDTH-1:1*CELL_ADDR_WIDTH] = FSM_Filter_Read_Addr[2*CELL_ADDR_WIDTH-1:1*CELL_ADDR_WIDTH];				// Cell 1, Filter 1
	generate
		for(i = 2; i < NUM_FILTER; i = i + 1)		// For each filter
			begin: assign_read_addr_FSM_to_Cell
			assign FSM_to_Cell_read_addr[(2*i-1)*CELL_ADDR_WIDTH-1:(2*i-2)*CELL_ADDR_WIDTH] = (FSM_Filter_Sel_Cell[i]) ? 0 : FSM_Filter_Read_Addr[(i+1)*CELL_ADDR_WIDTH-1:i*CELL_ADDR_WIDTH];
			assign FSM_to_Cell_read_addr[(2*i)*CELL_ADDR_WIDTH-1:(2*i-1)*CELL_ADDR_WIDTH] = (FSM_Filter_Sel_Cell[i]) ? FSM_Filter_Read_Addr[(i+1)*CELL_ADDR_WIDTH-1:i*CELL_ADDR_WIDTH] : 0 ;
			end
	endgenerate
	
	///////////////////////////////////////////////////////////////////////////////////////////////
	// FSM for pariticle pairs generation
	///////////////////////////////////////////////////////////////////////////////////////////////
	always@(posedge clk)
		begin
		//////////////////////////////////////////////////////////
		// Assign a bunch of prev registers for processing use
		//////////////////////////////////////////////////////////
		// Used in assigning the FSM_to_ForceEval_input_pair_valid, to make up the 2 cycles delay when read address is assigned but actual data comes later
		FSM_Filter_Done_Processing_reg1 <= FSM_Filter_Done_Processing;
		delay_FSM_Filter_Done_Processing <= FSM_Filter_Done_Processing_reg1;
		// Used in generating reference particle ID, to make up the 2 cycles delay between read address and readout data
		FSM_Filter_Read_Addr_reg1 <= FSM_Filter_Read_Addr;
		delay_FSM_Filter_Read_Addr <= FSM_Filter_Read_Addr_reg1;
		// Used in generating neighbor particle ID, to select from one of the cell IDs assigned to filter
		FSM_Filter_Sel_Cell_reg1 <= FSM_Filter_Sel_Cell;
		delay_FSM_Filter_Sel_Cell <= FSM_Filter_Sel_Cell_reg1;
		// Used in determine whether the output is valid due to backpressure
		ForceEval_to_FSM_backpressure_reg1 <= ForceEval_to_FSM_backpressure;
		delay_ForceEval_to_FSM_backpressure <= ForceEval_to_FSM_backpressure_reg1;
		
		if(rst)
			begin
			rden <= 1'b0;
			wait_finish_counter <= 0;
			// Special signal to handle the output valid for the last reference particle
			FSM_almost_done_generation <= 1'b0;
			// FSM control registers
			FSM_Cell_Particle_Num <= 0;
			FSM_Filter_Sel_Cell <= 0;
			FSM_Filter_Read_Addr <= 0;
			FSM_Filter_Done_Processing <= 0;
			FSM_Ref_Particle_Addr <= 0;
			FSM_Ref_Particle_Position <= 0;
			// FSM to Force Evaluation
			FSM_to_ForceEval_ref_particle_position <= 0;
			FSM_to_ForceEval_neighbor_particle_position <= 0;
			FSM_to_ForceEval_ref_particle_id <= 0;
			FSM_to_ForceEval_neighbor_particle_id <= 0;
			FSM_to_ForceEval_input_pair_valid <= 0;
			// FSM to Output
			FSM_to_Output_homecell_done <= 1'b0;
			
			// FSM state control
			state <= WAIT_FOR_START;
			end			
		else
			begin
			rden <= 1'b1;
			case(state)
				// Wait for the start signal to arrive
				WAIT_FOR_START:
					begin
					wait_finish_counter <= 0;
					// Special signal to handle the output valid for the last reference particle
					FSM_almost_done_generation <= 1'b0;
					// FSM to Output
					// Maintain the previous done signal while waiting for the next start signal, thus to keep the done signal high
					FSM_to_Output_homecell_done <= FSM_to_Output_homecell_done;
					// FSM control registers
					FSM_Cell_Particle_Num <= 0;
					FSM_Filter_Sel_Cell <= 0;
					FSM_Filter_Read_Addr <= 0;			// always read address 0 to get the # of particles
					FSM_Filter_Done_Processing <= 0;
					FSM_Ref_Particle_Addr <= 1;		// Starting from the 1st particle in the home cell
					FSM_Ref_Particle_Position <= 0;
					// FSM to Force Evaluation
					FSM_to_ForceEval_ref_particle_position <= 0;
					FSM_to_ForceEval_neighbor_particle_position <= 0;
					FSM_to_ForceEval_ref_particle_id <= 0;
					FSM_to_ForceEval_neighbor_particle_id <= 0;
					FSM_to_ForceEval_input_pair_valid <= 0;
					
					// State control
					if(start)
						begin
//						// Pre-fetch the first particle in the home cell as the first reference particle
//						FSM_Filter_Read_Addr[CELL_ADDR_WIDTH-1:0] <= 1;
//						FSM_Filter_Read_Addr[NUM_FILTER*CELL_ADDR_WIDTH-1:CELL_ADDR_WIDTH] <= 0;
						state <= READ_CELL_INFO;
						end
					else
						begin
//						FSM_Filter_Read_Addr <= 0;
						state <= WAIT_FOR_START;
						end
					end
				
				// Read out the particle number from each cell
				// This state kept for 1 cycles: since the rden is always high, and the read address is initialized as 0, then the output port on each cell memory should already have the particle number ready
				READ_CELL_INFO:
					begin
					wait_finish_counter <= 0;
					// Special signal to handle the output valid for the last reference particle
					FSM_almost_done_generation <= 1'b0;
					// FSM to Output
					FSM_to_Output_homecell_done <= 1'b0;
					// FSM control registers
					FSM_Filter_Sel_Cell <= 0;
					FSM_Filter_Read_Addr <= 0;			// always read out the first particle in the home cell as reference particle
					FSM_Filter_Done_Processing <= 0;
					FSM_Ref_Particle_Addr <= 1;		// Starting from the 1st particle in the home cell
					FSM_Ref_Particle_Position <= 0;
					// FSM to Force Evaluation
					FSM_to_ForceEval_ref_particle_position <= 0;
					FSM_to_ForceEval_neighbor_particle_position <= 0;
					FSM_to_ForceEval_ref_particle_id <= 0;
					FSM_to_ForceEval_neighbor_particle_id <= 0;
					FSM_to_ForceEval_input_pair_valid <= 0;
					
					// State control
					state <= READ_REF_PARTICLE;
					
					// Write the cell particle num register
					FSM_Cell_Particle_Num[ 1*CELL_ADDR_WIDTH-1: 0*CELL_ADDR_WIDTH] <= Cell_to_FSM_readout_particle_position[CELL_ADDR_WIDTH+ 0*3*DATA_WIDTH-1: 0*3*DATA_WIDTH];
					FSM_Cell_Particle_Num[ 2*CELL_ADDR_WIDTH-1: 1*CELL_ADDR_WIDTH] <= Cell_to_FSM_readout_particle_position[CELL_ADDR_WIDTH+ 1*3*DATA_WIDTH-1: 1*3*DATA_WIDTH];
					FSM_Cell_Particle_Num[ 3*CELL_ADDR_WIDTH-1: 2*CELL_ADDR_WIDTH] <= Cell_to_FSM_readout_particle_position[CELL_ADDR_WIDTH+ 2*3*DATA_WIDTH-1: 2*3*DATA_WIDTH];
					FSM_Cell_Particle_Num[ 4*CELL_ADDR_WIDTH-1: 3*CELL_ADDR_WIDTH] <= Cell_to_FSM_readout_particle_position[CELL_ADDR_WIDTH+ 3*3*DATA_WIDTH-1: 3*3*DATA_WIDTH];
					FSM_Cell_Particle_Num[ 5*CELL_ADDR_WIDTH-1: 4*CELL_ADDR_WIDTH] <= Cell_to_FSM_readout_particle_position[CELL_ADDR_WIDTH+ 4*3*DATA_WIDTH-1: 4*3*DATA_WIDTH];
					FSM_Cell_Particle_Num[ 6*CELL_ADDR_WIDTH-1: 5*CELL_ADDR_WIDTH] <= Cell_to_FSM_readout_particle_position[CELL_ADDR_WIDTH+ 5*3*DATA_WIDTH-1: 5*3*DATA_WIDTH];
					FSM_Cell_Particle_Num[ 7*CELL_ADDR_WIDTH-1: 6*CELL_ADDR_WIDTH] <= Cell_to_FSM_readout_particle_position[CELL_ADDR_WIDTH+ 6*3*DATA_WIDTH-1: 6*3*DATA_WIDTH];
					FSM_Cell_Particle_Num[ 8*CELL_ADDR_WIDTH-1: 7*CELL_ADDR_WIDTH] <= Cell_to_FSM_readout_particle_position[CELL_ADDR_WIDTH+ 7*3*DATA_WIDTH-1: 7*3*DATA_WIDTH];
					FSM_Cell_Particle_Num[ 9*CELL_ADDR_WIDTH-1: 8*CELL_ADDR_WIDTH] <= Cell_to_FSM_readout_particle_position[CELL_ADDR_WIDTH+ 8*3*DATA_WIDTH-1: 8*3*DATA_WIDTH];
					FSM_Cell_Particle_Num[10*CELL_ADDR_WIDTH-1: 9*CELL_ADDR_WIDTH] <= Cell_to_FSM_readout_particle_position[CELL_ADDR_WIDTH+ 9*3*DATA_WIDTH-1: 9*3*DATA_WIDTH];
					FSM_Cell_Particle_Num[11*CELL_ADDR_WIDTH-1:10*CELL_ADDR_WIDTH] <= Cell_to_FSM_readout_particle_position[CELL_ADDR_WIDTH+10*3*DATA_WIDTH-1:10*3*DATA_WIDTH];
					FSM_Cell_Particle_Num[12*CELL_ADDR_WIDTH-1:11*CELL_ADDR_WIDTH] <= Cell_to_FSM_readout_particle_position[CELL_ADDR_WIDTH+11*3*DATA_WIDTH-1:11*3*DATA_WIDTH];
					FSM_Cell_Particle_Num[13*CELL_ADDR_WIDTH-1:12*CELL_ADDR_WIDTH] <= Cell_to_FSM_readout_particle_position[CELL_ADDR_WIDTH+12*3*DATA_WIDTH-1:12*3*DATA_WIDTH];
					FSM_Cell_Particle_Num[14*CELL_ADDR_WIDTH-1:13*CELL_ADDR_WIDTH] <= Cell_to_FSM_readout_particle_position[CELL_ADDR_WIDTH+13*3*DATA_WIDTH-1:13*3*DATA_WIDTH];
					end
				
				// Readout the reference particle
				// There are 2 cycles latency between address assigned and data on the output port, need to wait at this state for 3 cycles
				// 1st cycle: assign the read address, 2nd cycle: read address appear on RAM, 3rd cycle: data read out at the end of this cycle
				READ_REF_PARTICLE:
					begin
					wait_finish_counter <= wait_finish_counter + 1'b1;
					// Special signal to handle the output valid for the last reference particle
					FSM_almost_done_generation <= 1'b0;
					// FSM to Output
					FSM_to_Output_homecell_done <= 1'b0;
					// FSM control registers
					FSM_Cell_Particle_Num <= FSM_Cell_Particle_Num;					// Keep the Cell_Particle_Num during the entire process
					FSM_Filter_Sel_Cell <= 0;
					FSM_Filter_Done_Processing <= 0;
					FSM_Ref_Particle_Addr <= FSM_Ref_Particle_Addr;					// Keep the current Ref_Particle_Addr
					FSM_Ref_Particle_Position <= FSM_Ref_Particle_Position;		// Keep the prev Ref_Particle_Position
					// FSM to Force Evaluation
					FSM_to_ForceEval_ref_particle_position <= 0;
					FSM_to_ForceEval_neighbor_particle_position <= 0;
					FSM_to_ForceEval_ref_particle_id <= 0;
					FSM_to_ForceEval_neighbor_particle_id <= 0;
					FSM_to_ForceEval_input_pair_valid <= 0;
					
					// Assign the state
					if(wait_finish_counter == 2)
						state <= RECORD_REF_PARTICLE;
					else
						state <= READ_REF_PARTICLE;
					
					// Assign the read address for the home cell to fetch reference particles
					// Latency for this is 2 cycles for a single reference particle case
					// *** A prefetch of course can be done in the READ_CELL_INFO or the WAIT_FOR_START stage, but for consistant when there are multiple filters workin on different reference particle, we implement this independent state to process the reference particles
					if(wait_finish_counter == 0)
						//	The first cycle read the reference particle
						begin
						FSM_Filter_Read_Addr[CELL_ADDR_WIDTH-1:0] <= FSM_Ref_Particle_Addr;
						FSM_Filter_Read_Addr[NUM_FILTER*CELL_ADDR_WIDTH-1:CELL_ADDR_WIDTH] <= 0;
						end
					else if(wait_finish_counter == 1)
						//	The second cycle prefetch the neighbor particles
						begin
						FSM_Filter_Read_Addr[1*CELL_ADDR_WIDTH-1:0*CELL_ADDR_WIDTH] = 1;
						FSM_Filter_Read_Addr[2*CELL_ADDR_WIDTH-1:1*CELL_ADDR_WIDTH] = 1;
						FSM_Filter_Read_Addr[3*CELL_ADDR_WIDTH-1:2*CELL_ADDR_WIDTH] = 1;
						FSM_Filter_Read_Addr[4*CELL_ADDR_WIDTH-1:3*CELL_ADDR_WIDTH] = 1;
						FSM_Filter_Read_Addr[5*CELL_ADDR_WIDTH-1:4*CELL_ADDR_WIDTH] = 1;
						FSM_Filter_Read_Addr[6*CELL_ADDR_WIDTH-1:5*CELL_ADDR_WIDTH] = 1;
						FSM_Filter_Read_Addr[7*CELL_ADDR_WIDTH-1:6*CELL_ADDR_WIDTH] = 1;
						FSM_Filter_Read_Addr[8*CELL_ADDR_WIDTH-1:7*CELL_ADDR_WIDTH] = 1;
						end
					else
						//	The thrid cycle prefetch the 2nd neighbor particles
						begin
						FSM_Filter_Read_Addr[1*CELL_ADDR_WIDTH-1:0*CELL_ADDR_WIDTH] = 2;
						FSM_Filter_Read_Addr[2*CELL_ADDR_WIDTH-1:1*CELL_ADDR_WIDTH] = 2;
						FSM_Filter_Read_Addr[3*CELL_ADDR_WIDTH-1:2*CELL_ADDR_WIDTH] = 2;
						FSM_Filter_Read_Addr[4*CELL_ADDR_WIDTH-1:3*CELL_ADDR_WIDTH] = 2;
						FSM_Filter_Read_Addr[5*CELL_ADDR_WIDTH-1:4*CELL_ADDR_WIDTH] = 2;
						FSM_Filter_Read_Addr[6*CELL_ADDR_WIDTH-1:5*CELL_ADDR_WIDTH] = 2;
						FSM_Filter_Read_Addr[7*CELL_ADDR_WIDTH-1:6*CELL_ADDR_WIDTH] = 2;
						FSM_Filter_Read_Addr[8*CELL_ADDR_WIDTH-1:7*CELL_ADDR_WIDTH] = 2;
						end
					end
				
				// Recording the current reference particle
				RECORD_REF_PARTICLE:
					begin
					wait_finish_counter <= 0;
					// Special signal to handle the output valid for the last reference particle
					FSM_almost_done_generation <= 1'b0;
					// FSM to Output
					FSM_to_Output_homecell_done <= 1'b0;
					// FSM control registers
					FSM_Cell_Particle_Num <= FSM_Cell_Particle_Num;					// Keep the Cell_Particle_Num during the entire process
					FSM_Filter_Sel_Cell <= FSM_Filter_Sel_Cell;			
					FSM_Filter_Done_Processing <= 0;			// Keep the selection bit
					FSM_Ref_Particle_Addr <= FSM_Ref_Particle_Addr;					// Keep the current Ref_Particle_Addr
					// FSM to Force Evaluation
					FSM_to_ForceEval_ref_particle_position <= 0;
					FSM_to_ForceEval_neighbor_particle_position <= 0;
					FSM_to_ForceEval_ref_particle_id <= 0;
					FSM_to_ForceEval_neighbor_particle_id <= 0;
					FSM_to_ForceEval_input_pair_valid <= 0;
					
					// Assign state
					state <= EVALUATION;
					
					// Assign the new ref particle position
					// The readout data from Home cell
					FSM_Ref_Particle_Position <= Cell_to_FSM_readout_particle_position[3*DATA_WIDTH-1:0];
					
					// Pre assign the read address for the 2nd neighbor particle
					// *** Suppose there are more than 3 particles in each cell
					FSM_Filter_Read_Addr[1*CELL_ADDR_WIDTH-1:0*CELL_ADDR_WIDTH] = 3;
					FSM_Filter_Read_Addr[2*CELL_ADDR_WIDTH-1:1*CELL_ADDR_WIDTH] = 3;
					FSM_Filter_Read_Addr[3*CELL_ADDR_WIDTH-1:2*CELL_ADDR_WIDTH] = 3;
					FSM_Filter_Read_Addr[4*CELL_ADDR_WIDTH-1:3*CELL_ADDR_WIDTH] = 3;
					FSM_Filter_Read_Addr[5*CELL_ADDR_WIDTH-1:4*CELL_ADDR_WIDTH] = 3;
					FSM_Filter_Read_Addr[6*CELL_ADDR_WIDTH-1:5*CELL_ADDR_WIDTH] = 3;
					FSM_Filter_Read_Addr[7*CELL_ADDR_WIDTH-1:6*CELL_ADDR_WIDTH] = 3;
					FSM_Filter_Read_Addr[8*CELL_ADDR_WIDTH-1:7*CELL_ADDR_WIDTH] = 3;
					end
				
				// Start generating particle pairs
				EVALUATION:
					begin
					wait_finish_counter <= 0;
					// FSM to Output
					FSM_to_Output_homecell_done <= 1'b0;
					// FSM control registers
					FSM_Cell_Particle_Num <= FSM_Cell_Particle_Num;					// Keep the Cell_Particle_Num during the entire process
					FSM_Ref_Particle_Addr <= FSM_Ref_Particle_Addr;					// Keep the current Ref_Particle_Addr
					FSM_Ref_Particle_Position <= FSM_Ref_Particle_Position;		// Keep the current Ref_Particle_Position
					// Special signal to handle the output valid for the last reference particle
					FSM_almost_done_generation <= 1'b0;
					//////////////////////////////////////////////////////////////////////////////////////////////
					// Process Filter Read Address
					//////////////////////////////////////////////////////////////////////////////////////////////
					// Only increment the read address when there is no backpressure
					if(ForceEval_to_FSM_backpressure == 0)
						begin
						// Filter 0
						// Handle home cell (222)
						if(FSM_Filter_Read_Addr[1*CELL_ADDR_WIDTH-1:0*CELL_ADDR_WIDTH] < FSM_Cell_Particle_Num[1*CELL_ADDR_WIDTH-1:0*CELL_ADDR_WIDTH])
							begin
							FSM_Filter_Sel_Cell[0] <= 1'b0;
							FSM_Filter_Read_Addr[1*CELL_ADDR_WIDTH-1:0*CELL_ADDR_WIDTH] <= FSM_Filter_Read_Addr[1*CELL_ADDR_WIDTH-1:0*CELL_ADDR_WIDTH] + 1'b1;
							FSM_Filter_Done_Processing[0] <= 1'b0;
							end
						else
							begin
							FSM_Filter_Sel_Cell[0] <= 1'b0;
							FSM_Filter_Read_Addr[1*CELL_ADDR_WIDTH-1:0*CELL_ADDR_WIDTH] <= FSM_Filter_Read_Addr[1*CELL_ADDR_WIDTH-1:0*CELL_ADDR_WIDTH];
							FSM_Filter_Done_Processing[0] <= 1'b1;
							end

						// Filter 1
						// Handle 1 cell (223)
						if(FSM_Filter_Read_Addr[2*CELL_ADDR_WIDTH-1:1*CELL_ADDR_WIDTH] < FSM_Cell_Particle_Num[2*CELL_ADDR_WIDTH-1:1*CELL_ADDR_WIDTH])
							begin
							FSM_Filter_Sel_Cell[1] <= 1'b0;
							FSM_Filter_Read_Addr[2*CELL_ADDR_WIDTH-1:1*CELL_ADDR_WIDTH] <= FSM_Filter_Read_Addr[2*CELL_ADDR_WIDTH-1:1*CELL_ADDR_WIDTH] + 1'b1;
							FSM_Filter_Done_Processing[1] <= 1'b0;
							end
						else
							begin
							FSM_Filter_Sel_Cell[1] <= 1'b0;
							FSM_Filter_Read_Addr[2*CELL_ADDR_WIDTH-1:1*CELL_ADDR_WIDTH] <= FSM_Filter_Read_Addr[2*CELL_ADDR_WIDTH-1:1*CELL_ADDR_WIDTH];
							FSM_Filter_Done_Processing[1] <= 1'b1;
							end

						// Filter 2
						// Handles 2 cells (231, 232)
						if(FSM_Filter_Sel_Cell[2] == 1'b0)			// Processing the 1st neighbor cell
							begin
							FSM_Filter_Done_Processing[2] <= 1'b0;		// Processing not finished
							if(FSM_Filter_Read_Addr[3*CELL_ADDR_WIDTH-1:2*CELL_ADDR_WIDTH] < FSM_Cell_Particle_Num[3*CELL_ADDR_WIDTH-1:2*CELL_ADDR_WIDTH])
								begin
								FSM_Filter_Sel_Cell[2] <= 1'b0;
								FSM_Filter_Read_Addr[3*CELL_ADDR_WIDTH-1:2*CELL_ADDR_WIDTH] <= FSM_Filter_Read_Addr[3*CELL_ADDR_WIDTH-1:2*CELL_ADDR_WIDTH] + 1'b1;
								end
							else
								begin
								FSM_Filter_Sel_Cell[2] <= 1'b1;
								FSM_Filter_Read_Addr[3*CELL_ADDR_WIDTH-1:2*CELL_ADDR_WIDTH] <= 1;			// Start from address 1 for the next cell
								end
							end
						else					// Processing the 2nd neighbor cell
							begin
							FSM_Filter_Sel_Cell[2] <= FSM_Filter_Sel_Cell[2];					// Sel bit remains
							if(FSM_Filter_Read_Addr[3*CELL_ADDR_WIDTH-1:2*CELL_ADDR_WIDTH] < FSM_Cell_Particle_Num[4*CELL_ADDR_WIDTH-1:3*CELL_ADDR_WIDTH])
								begin
								FSM_Filter_Read_Addr[3*CELL_ADDR_WIDTH-1:2*CELL_ADDR_WIDTH] <= FSM_Filter_Read_Addr[3*CELL_ADDR_WIDTH-1:2*CELL_ADDR_WIDTH] + 1'b1;
								FSM_Filter_Done_Processing[2] <= 1'b0;
								end
							else
								begin
								FSM_Filter_Read_Addr[3*CELL_ADDR_WIDTH-1:2*CELL_ADDR_WIDTH] <= FSM_Filter_Read_Addr[3*CELL_ADDR_WIDTH-1:2*CELL_ADDR_WIDTH];
								FSM_Filter_Done_Processing[2] <= 1'b1;								// Processing done
								end
							end
							
						// Filter 3
						// Handles 2 cells (233, 311)
						if(FSM_Filter_Sel_Cell[3] == 1'b0)			// Processing the 1st neighbor cell
							begin
							FSM_Filter_Done_Processing[3] <= 1'b0;		// Processing not finished
							if(FSM_Filter_Read_Addr[4*CELL_ADDR_WIDTH-1:3*CELL_ADDR_WIDTH] < FSM_Cell_Particle_Num[5*CELL_ADDR_WIDTH-1:4*CELL_ADDR_WIDTH])
								begin
								FSM_Filter_Sel_Cell[3] <= 1'b0;
								FSM_Filter_Read_Addr[4*CELL_ADDR_WIDTH-1:3*CELL_ADDR_WIDTH] <= FSM_Filter_Read_Addr[4*CELL_ADDR_WIDTH-1:3*CELL_ADDR_WIDTH] + 1'b1;
								end
							else
								begin
								FSM_Filter_Sel_Cell[3] <= 1'b1;
								FSM_Filter_Read_Addr[4*CELL_ADDR_WIDTH-1:3*CELL_ADDR_WIDTH] <= 1;			// Start from address 1 for the next cell
								end
							end
						else					// Processing the 2nd neighbor cell
							begin
							FSM_Filter_Sel_Cell[3] <= FSM_Filter_Sel_Cell[3];					// Sel bit remains
							if(FSM_Filter_Read_Addr[4*CELL_ADDR_WIDTH-1:3*CELL_ADDR_WIDTH] < FSM_Cell_Particle_Num[6*CELL_ADDR_WIDTH-1:5*CELL_ADDR_WIDTH])
								begin
								FSM_Filter_Read_Addr[4*CELL_ADDR_WIDTH-1:3*CELL_ADDR_WIDTH] <= FSM_Filter_Read_Addr[4*CELL_ADDR_WIDTH-1:3*CELL_ADDR_WIDTH] + 1'b1;
								FSM_Filter_Done_Processing[3] <= 1'b0;
								end
							else
								begin
								FSM_Filter_Read_Addr[4*CELL_ADDR_WIDTH-1:3*CELL_ADDR_WIDTH] <= FSM_Filter_Read_Addr[4*CELL_ADDR_WIDTH-1:3*CELL_ADDR_WIDTH];
								FSM_Filter_Done_Processing[3] <= 1'b1;								// Processing done
								end
							end
							
						// Filter 4
						// Handles 2 cells (312, 313)
						if(FSM_Filter_Sel_Cell[4] == 1'b0)			// Processing the 1st neighbor cell
							begin
							FSM_Filter_Done_Processing[4] <= 1'b0;		// Processing not finished
							if(FSM_Filter_Read_Addr[5*CELL_ADDR_WIDTH-1:4*CELL_ADDR_WIDTH] < FSM_Cell_Particle_Num[7*CELL_ADDR_WIDTH-1:6*CELL_ADDR_WIDTH])
								begin
								FSM_Filter_Sel_Cell[4] <= 1'b0;
								FSM_Filter_Read_Addr[5*CELL_ADDR_WIDTH-1:4*CELL_ADDR_WIDTH] <= FSM_Filter_Read_Addr[5*CELL_ADDR_WIDTH-1:4*CELL_ADDR_WIDTH] + 1'b1;
								end
							else
								begin
								FSM_Filter_Sel_Cell[4] <= 1'b1;
								FSM_Filter_Read_Addr[5*CELL_ADDR_WIDTH-1:4*CELL_ADDR_WIDTH] <= 1;			// Start from address 1 for the next cell
								end
							end
						else					// Processing the 2nd neighbor cell
							begin
							FSM_Filter_Sel_Cell[4] <= FSM_Filter_Sel_Cell[4];					// Sel bit remains
							if(FSM_Filter_Read_Addr[5*CELL_ADDR_WIDTH-1:4*CELL_ADDR_WIDTH] < FSM_Cell_Particle_Num[8*CELL_ADDR_WIDTH-1:7*CELL_ADDR_WIDTH])
								begin
								FSM_Filter_Read_Addr[5*CELL_ADDR_WIDTH-1:4*CELL_ADDR_WIDTH] <= FSM_Filter_Read_Addr[5*CELL_ADDR_WIDTH-1:4*CELL_ADDR_WIDTH] + 1'b1;
								FSM_Filter_Done_Processing[4] <= 1'b0;
								end
							else
								begin
								FSM_Filter_Read_Addr[5*CELL_ADDR_WIDTH-1:4*CELL_ADDR_WIDTH] <= FSM_Filter_Read_Addr[5*CELL_ADDR_WIDTH-1:4*CELL_ADDR_WIDTH];
								FSM_Filter_Done_Processing[4] <= 1'b1;								// Processing done
								end
							end	
						
						// Filter 5
						// Handles 2 cells (321, 322)
						if(FSM_Filter_Sel_Cell[5] == 1'b0)			// Processing the 1st neighbor cell
							begin
							FSM_Filter_Done_Processing[5] <= 1'b0;		// Processing not finished
							if(FSM_Filter_Read_Addr[6*CELL_ADDR_WIDTH-1:5*CELL_ADDR_WIDTH] < FSM_Cell_Particle_Num[9*CELL_ADDR_WIDTH-1:8*CELL_ADDR_WIDTH])
								begin
								FSM_Filter_Sel_Cell[5] <= 1'b0;
								FSM_Filter_Read_Addr[6*CELL_ADDR_WIDTH-1:5*CELL_ADDR_WIDTH] <= FSM_Filter_Read_Addr[6*CELL_ADDR_WIDTH-1:5*CELL_ADDR_WIDTH] + 1'b1;
								end
							else
								begin
								FSM_Filter_Sel_Cell[5] <= 1'b1;
								FSM_Filter_Read_Addr[6*CELL_ADDR_WIDTH-1:5*CELL_ADDR_WIDTH] <= 1;			// Start from address 1 for the next cell
								end
							end
						else					// Processing the 2nd neighbor cell
							begin
							FSM_Filter_Sel_Cell[5] <= FSM_Filter_Sel_Cell[5];					// Sel bit remains
							if(FSM_Filter_Read_Addr[6*CELL_ADDR_WIDTH-1:5*CELL_ADDR_WIDTH] < FSM_Cell_Particle_Num[10*CELL_ADDR_WIDTH-1:9*CELL_ADDR_WIDTH])
								begin
								FSM_Filter_Read_Addr[6*CELL_ADDR_WIDTH-1:5*CELL_ADDR_WIDTH] <= FSM_Filter_Read_Addr[6*CELL_ADDR_WIDTH-1:5*CELL_ADDR_WIDTH] + 1'b1;
								FSM_Filter_Done_Processing[5] <= 1'b0;
								end
							else
								begin
								FSM_Filter_Read_Addr[6*CELL_ADDR_WIDTH-1:5*CELL_ADDR_WIDTH] <= FSM_Filter_Read_Addr[6*CELL_ADDR_WIDTH-1:5*CELL_ADDR_WIDTH];
								FSM_Filter_Done_Processing[5] <= 1'b1;								// Processing done
								end
							end	
				
						// Filter 6
						// Handles 2 cells (323, 331)
						if(FSM_Filter_Sel_Cell[6] == 1'b0)			// Processing the 1st neighbor cell
							begin
							FSM_Filter_Done_Processing[6] <= 1'b0;		// Processing not finished
							if(FSM_Filter_Read_Addr[7*CELL_ADDR_WIDTH-1:6*CELL_ADDR_WIDTH] < FSM_Cell_Particle_Num[11*CELL_ADDR_WIDTH-1:10*CELL_ADDR_WIDTH])
								begin
								FSM_Filter_Sel_Cell[6] <= 1'b0;
								FSM_Filter_Read_Addr[7*CELL_ADDR_WIDTH-1:6*CELL_ADDR_WIDTH] <= FSM_Filter_Read_Addr[7*CELL_ADDR_WIDTH-1:6*CELL_ADDR_WIDTH] + 1'b1;
								end
							else
								begin
								FSM_Filter_Sel_Cell[6] <= 1'b1;
								FSM_Filter_Read_Addr[7*CELL_ADDR_WIDTH-1:6*CELL_ADDR_WIDTH] <= 1;			// Start from address 1 for the next cell
								end
							end
						else					// Processing the 2nd neighbor cell
							begin
							FSM_Filter_Sel_Cell[6] <= FSM_Filter_Sel_Cell[6];					// Sel bit remains
							if(FSM_Filter_Read_Addr[7*CELL_ADDR_WIDTH-1:6*CELL_ADDR_WIDTH] < FSM_Cell_Particle_Num[12*CELL_ADDR_WIDTH-1:11*CELL_ADDR_WIDTH])
								begin
								FSM_Filter_Read_Addr[7*CELL_ADDR_WIDTH-1:6*CELL_ADDR_WIDTH] <= FSM_Filter_Read_Addr[7*CELL_ADDR_WIDTH-1:6*CELL_ADDR_WIDTH] + 1'b1;
								FSM_Filter_Done_Processing[6] <= 1'b0;
								end
							else
								begin
								FSM_Filter_Read_Addr[7*CELL_ADDR_WIDTH-1:6*CELL_ADDR_WIDTH] <= FSM_Filter_Read_Addr[7*CELL_ADDR_WIDTH-1:6*CELL_ADDR_WIDTH];
								FSM_Filter_Done_Processing[6] <= 1'b1;								// Processing done
								end
							end	
				
						// Filter 7
						// Handles 2 cells (332, 333)
						if(FSM_Filter_Sel_Cell[7] == 1'b0)			// Processing the 1st neighbor cell
							begin
							FSM_Filter_Done_Processing[7] <= 1'b0;		// Processing not finished
							if(FSM_Filter_Read_Addr[8*CELL_ADDR_WIDTH-1:7*CELL_ADDR_WIDTH] < FSM_Cell_Particle_Num[13*CELL_ADDR_WIDTH-1:12*CELL_ADDR_WIDTH])
								begin
								FSM_Filter_Sel_Cell[7] <= 1'b0;
								FSM_Filter_Read_Addr[8*CELL_ADDR_WIDTH-1:7*CELL_ADDR_WIDTH] <= FSM_Filter_Read_Addr[8*CELL_ADDR_WIDTH-1:7*CELL_ADDR_WIDTH] + 1'b1;
								end
							else
								begin
								FSM_Filter_Sel_Cell[7] <= 1'b1;
								FSM_Filter_Read_Addr[8*CELL_ADDR_WIDTH-1:7*CELL_ADDR_WIDTH] <= 1;			// Start from address 1 for the next cell
								end
							end
						else					// Processing the 2nd neighbor cell
							begin
							FSM_Filter_Sel_Cell[7] <= FSM_Filter_Sel_Cell[7];					// Sel bit remains
							if(FSM_Filter_Read_Addr[8*CELL_ADDR_WIDTH-1:7*CELL_ADDR_WIDTH] < FSM_Cell_Particle_Num[14*CELL_ADDR_WIDTH-1:13*CELL_ADDR_WIDTH])
								begin
								FSM_Filter_Read_Addr[8*CELL_ADDR_WIDTH-1:7*CELL_ADDR_WIDTH] <= FSM_Filter_Read_Addr[8*CELL_ADDR_WIDTH-1:7*CELL_ADDR_WIDTH] + 1'b1;
								FSM_Filter_Done_Processing[7] <= 1'b0;
								end
							else
								begin
								FSM_Filter_Read_Addr[8*CELL_ADDR_WIDTH-1:7*CELL_ADDR_WIDTH] <= FSM_Filter_Read_Addr[8*CELL_ADDR_WIDTH-1:7*CELL_ADDR_WIDTH];
								FSM_Filter_Done_Processing[7] <= 1'b1;								// Processing done
								end
							end
						
						end
					
					// When there is backpressure, stop incrementing the read address
					else
						begin
						FSM_Filter_Sel_Cell <= FSM_Filter_Sel_Cell;
						FSM_Filter_Read_Addr <= FSM_Filter_Read_Addr;
						FSM_Filter_Done_Processing <= FSM_Filter_Done_Processing;
						end
					
					//////////////////////////////////////////////////////////////////////////////////////////////
					// Process Input Data to Force Evaluation Unit
					//////////////////////////////////////////////////////////////////////////////////////////////
					// All share the same reference particles
					FSM_to_ForceEval_ref_particle_position <= {FSM_Ref_Particle_Position,FSM_Ref_Particle_Position,FSM_Ref_Particle_Position,FSM_Ref_Particle_Position,FSM_Ref_Particle_Position,FSM_Ref_Particle_Position,FSM_Ref_Particle_Position,FSM_Ref_Particle_Position};
					// Reference particle ID is the same
					FSM_to_ForceEval_ref_particle_id <= {FSM_Ref_Particle_ID,FSM_Ref_Particle_ID,FSM_Ref_Particle_ID,FSM_Ref_Particle_ID,FSM_Ref_Particle_ID,FSM_Ref_Particle_ID,FSM_Ref_Particle_ID,FSM_Ref_Particle_ID};
					FSM_to_ForceEval_neighbor_particle_position <= FSM_Neighbor_Particle_Position;
					FSM_to_ForceEval_neighbor_particle_id <= FSM_Neighbor_Particle_ID;
					// If the filter is not done processing, then the input should be valid
					// Since there are 2 cycles delay here, implementing a delay_FSM_Filter_Done_Processing register is necessary
					// There are 2 things have impact the output valid:
					//		1, whether the filter has done processing all the cells it assigned
					//		2, whether there is a backpressure: if so, the FSM will stop generating the pairs, and invalidate all the output
					FSM_to_ForceEval_input_pair_valid <= (delay_ForceEval_to_FSM_backpressure == 0) ? ~delay_FSM_Filter_Done_Processing : {(NUM_FILTER){1'b0}};
					
					//////////////////////////////////////////////////////////////////////////////////////////////
					// Assign Next State
					//////////////////////////////////////////////////////////////////////////////////////////////
					// Move to next reference particle when
					//		1, If input to all the filters are done processing
					//		2, All filter buffer are empty (Avoid the cases when the force pipelines are evaluating for 2 different reference particles when switching after one reference particle, this will lead to the accumulation error for the reference particle)
					if(FSM_Filter_Done_Processing == FSM_Filter_Done_Processing_all_1_flag && ForceEval_to_FSM_all_buffer_empty)
						state <= CHECK_HOME_CELL_DONE;
					else
						state <= EVALUATION;					
					end
					
				// After the current reference particle is done evaluating, check if all the particles in home cell has done evaluation
				// If not, assign the next reference particle, jump back to EVALUATION
				// If so, jump to WAIT_FOR_FINISH, wait for the last particle pair traverse the entire pipeline
				CHECK_HOME_CELL_DONE:
					begin
					wait_finish_counter <= 0;
					// Special signal to handle the output valid for the last reference particle
					FSM_almost_done_generation <= 1'b0;
					// FSM to Output
					FSM_to_Output_homecell_done <= 1'b0;
					// FSM control registers					
					FSM_Cell_Particle_Num <= FSM_Cell_Particle_Num;					// Keep the Cell_Particle_Num during the entire process
					FSM_Filter_Sel_Cell <= FSM_Filter_Sel_Cell;						// Keep the selection bit
					FSM_Filter_Read_Addr <= FSM_Filter_Read_Addr;					// Reset filter read address to 0
					FSM_Filter_Done_Processing <= FSM_Filter_Done_Processing;
					FSM_Ref_Particle_Position <= FSM_Ref_Particle_Position;		// Keep the current Ref_Particle_Position
					// FSM to Force Evaluation
					// ** Keep assigning the reference &neighbor particle information since there is a 2 cycles delay between read address assigned and actual data readout
					FSM_to_ForceEval_ref_particle_position <= {FSM_Ref_Particle_Position,FSM_Ref_Particle_Position,FSM_Ref_Particle_Position,FSM_Ref_Particle_Position,FSM_Ref_Particle_Position,FSM_Ref_Particle_Position,FSM_Ref_Particle_Position,FSM_Ref_Particle_Position};
					FSM_to_ForceEval_neighbor_particle_position <= FSM_Neighbor_Particle_Position;
					FSM_to_ForceEval_ref_particle_id <= {FSM_Ref_Particle_ID,FSM_Ref_Particle_ID,FSM_Ref_Particle_ID,FSM_Ref_Particle_ID,FSM_Ref_Particle_ID,FSM_Ref_Particle_ID,FSM_Ref_Particle_ID,FSM_Ref_Particle_ID};
					FSM_to_ForceEval_neighbor_particle_id <= FSM_Neighbor_Particle_ID;
					FSM_to_ForceEval_input_pair_valid <= ~delay_FSM_Filter_Done_Processing;
					
					// if there are still reference particles not traversed, increment the read address (the fetch will be done in READ_REF_PARTICLE stage)
					if(FSM_Ref_Particle_Addr < FSM_Cell_Particle_Num[CELL_ADDR_WIDTH-1:0])
						begin
						FSM_Ref_Particle_Addr <= FSM_Ref_Particle_Addr + 1'b1;
						state <= READ_REF_PARTICLE;
						end
					// If all reference particles has been traversed, then move on to the wait stage
					else
						begin
						FSM_Ref_Particle_Addr <= FSM_Ref_Particle_Addr;
						state <= WAIT_FOR_FINISH;
						end
						
					end
				
				// After the last refernece particle is done, wait for the last pair of paricles traverse the entire pipeline
				WAIT_FOR_FINISH:
					begin
					wait_finish_counter <= wait_finish_counter + 1'b1;
					// FSM to Output
					FSM_to_Output_homecell_done <= 1'b0;
					// FSM control registers					
					FSM_Cell_Particle_Num <= FSM_Cell_Particle_Num;					// Keep the Cell_Particle_Num during the entire process
					FSM_Filter_Sel_Cell <= 0;												// Reset the selection bit
					FSM_Filter_Read_Addr <= 0;												// Reset filter read address to 0
					FSM_Filter_Done_Processing <= 0;
					FSM_Ref_Particle_Addr <= FSM_Ref_Particle_Addr;
					FSM_Ref_Particle_Position <= FSM_Ref_Particle_Position;		// Keep the current Ref_Particle_Position
					// FSM to Force Evaluation
					FSM_to_ForceEval_ref_particle_position <= 0;
					FSM_to_ForceEval_neighbor_particle_position <= 0;
					FSM_to_ForceEval_ref_particle_id <= 0;
					FSM_to_ForceEval_neighbor_particle_id <= 0;
					FSM_to_ForceEval_input_pair_valid <= 0;
				
					// Special signal to handle the output valid for the last reference particle
					// Set the almost done a few cycles before the wait process ends, thus give it more time to let the force cache to write in the value
					// After entering the next state, the motion update will start and new value can no longer write in the force cache
					// The value 35 here is depending on the wait cycle below, always make it 5 less than the threshold below
					if(wait_finish_counter == 35)
						FSM_almost_done_generation <= 1'b1;
					else
						FSM_almost_done_generation <= 1'b0;
				
					// Assgin the next state
					// !!!!! The wait cycle 40 is given arbitraily, may need for some adjustments
					if(wait_finish_counter < 40)
						state <= WAIT_FOR_FINISH;
					else
						state <= DONE;
					
					end
				// Send out a flag signify the current home cell is done evaluation, the motion update can proceed
				DONE:
					begin
					wait_finish_counter <= 0;
					// Special signal to handle the output valid for the last reference particle
					FSM_almost_done_generation <= 1'b0;
					// FSM to Output
					FSM_to_Output_homecell_done <= 1'b1;
					// FSM control registers					
					FSM_Cell_Particle_Num <= FSM_Cell_Particle_Num;					// Keep the Cell_Particle_Num during the entire process
					FSM_Filter_Sel_Cell <= 0;												// Reset the selection bit
					FSM_Filter_Read_Addr <= 0;												// Reset filter read address to 0
					FSM_Filter_Done_Processing <= 0;
					FSM_Ref_Particle_Addr <= 0;
					FSM_Ref_Particle_Position <= 0;										// Reset the current Ref_Particle_Position
					// FSM to Force Evaluation
					FSM_to_ForceEval_ref_particle_position <= 0;
					FSM_to_ForceEval_neighbor_particle_position <= 0;
					FSM_to_ForceEval_ref_particle_id <= 0;
					FSM_to_ForceEval_neighbor_particle_id <= 0;
					FSM_to_ForceEval_input_pair_valid <= 0;
					// Assgin the next state
					state <= WAIT_FOR_START;
					end
					
			endcase
			end
		end

endmodule


