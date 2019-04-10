/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: Board_Test_RL_LJ_Top.v
//
//	Function: 
//				On Board test for RL_LJ_Top.v
//				The rst and start signal is given by memory modules controlled by in memory content editor
//				Use PLL to regulate input clock
//
//	Timing: 275MHz
//
// Mapping Scheme:
//				Half-shell method: each home cell interact with 13 nearest neighbors
//				For 8 Filters configurations, the mapping is follows:
//					Filter 0: 222 (home)
//					Filter 1: 223 (face) 
//					Filter 2: 231 (edge) 232 (face) 
//					Filter 3: 233 (edge) 311 (corner) 
//					Filter 4: 312 (edge) 313 (corner) 
//					Filter 5: 321 (edge) 322 (face) 
//					Filter 6: 323 (edge) 331 (corner) 
//					Filter 7: 332 (edge) 333 (corner) 
//
// Format:
//				particle_id [PARTICLE_ID_WIDTH-1:0]:  {cell_z, cell_y, cell_x, particle_in_cell_rd_addr}
//
// Used by:
//				TBD
//
// Dependency:
//				RL_LJ_Top.v
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module Board_Test_RL_LJ_Top
#(
	parameter DATA_WIDTH 					= 32,
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
	parameter FILTER_BUFFER_ADDR_WIDTH	= 5,
	parameter CUTOFF_2 						= 32'h43100000,							// (12^2=144 in IEEE floating point)
	// Force Evaluation parameters
	parameter SEGMENT_NUM					= 14,
	parameter SEGMENT_WIDTH					= 4,
	parameter BIN_NUM							= 256,
	parameter BIN_WIDTH						= 8,
	parameter LOOKUP_NUM						= SEGMENT_NUM * BIN_NUM,				// SEGMENT_NUM * BIN_NUM
	parameter LOOKUP_ADDR_WIDTH			= SEGMENT_WIDTH + BIN_WIDTH			// log LOOKUP_NUM / log 2
)
(
	input  ref_clk_125mhz,																	// Pin AN27, 125MHz input from oscillator
	// These are all temp output ports
	output [NUM_EVAL_UNIT*PARTICLE_ID_WIDTH-1:0] ref_particle_id,
	output [NUM_EVAL_UNIT*DATA_WIDTH-1:0] ref_LJ_Force_X,
	output [NUM_EVAL_UNIT*DATA_WIDTH-1:0] ref_LJ_Force_Y,
	output [NUM_EVAL_UNIT*DATA_WIDTH-1:0] ref_LJ_Force_Z,
	output [NUM_EVAL_UNIT-1:0] ref_forceoutput_valid,
	output [NUM_EVAL_UNIT*PARTICLE_ID_WIDTH-1:0] neighbor_particle_id,
	output [NUM_EVAL_UNIT*DATA_WIDTH-1:0] neighbor_LJ_Force_X,
	output [NUM_EVAL_UNIT*DATA_WIDTH-1:0] neighbor_LJ_Force_Y,
	output [NUM_EVAL_UNIT*DATA_WIDTH-1:0] neighbor_LJ_Force_Z,
	output [NUM_EVAL_UNIT-1:0] neighbor_forceoutput_valid,
	// Done signal, when entire home cell is done processing, this will keep high until the next time 'start' signal turn high
	output done
);

	wire clk, rst, start;
	
	// Input pll
	// Output Freq: 270MHz
	Input_Clk_Gen INPUT_PLL(
		.locked(),   //  locked.export
		.outclk_0(clk), // outclk0.clk
		.refclk(ref_clk_125mhz),   //  refclk.clk
		.rst(rst)       //   reset.reset
	);
	
	// rst signal from Memory content editor
	On_Board_Test_Control_RAM_rst CTRL_rst (
		.data    (),    //   input,  width = 1,  ram_input.datain
		.address (1'b0), //   input,  width = 1,           .address
		.wren    (1'b0),    //   input,  width = 1,           .wren
		.clock   (clk),   //   input,  width = 1,           .clk
		.q       (rst)        //  output,  width = 1, ram_output.dataout
	);
	
	// Start signal from Memory content editor
	On_Board_Test_Control_RAM_start CTRL_start (
		.data    (),    //   input,  width = 1,  ram_input.datain
		.address (1'b0), //   input,  width = 1,           .address
		.wren    (1'b0),    //   input,  width = 1,           .wren
		.clock   (clk),   //   input,  width = 1,           .clk
		.q       (start)        //  output,  width = 1, ram_output.dataout
	);
	
	
	RL_LJ_Top
	#(
		.DATA_WIDTH(DATA_WIDTH),
		// High level parameters
		.NUM_EVAL_UNIT(NUM_EVAL_UNIT),											// # of evaluation units in the design
		// Dataset defined parameters
		.NUM_NEIGHBOR_CELLS(NUM_NEIGHBOR_CELLS),											// # of neighbor cells per home cell, for Half-shell method, is 13
		.CELL_ID_WIDTH(CELL_ID_WIDTH),											// log(NUM_NEIGHBOR_CELLS)
		.MAX_CELL_PARTICLE_NUM(MAX_CELL_PARTICLE_NUM),										// The maximum # of particles can be in a cell
		.CELL_ADDR_WIDTH(CELL_ADDR_WIDTH),											// log(MAX_CELL_PARTICLE_NUM)
		.PARTICLE_ID_WIDTH(PARTICLE_ID_WIDTH),	// # of bit used to represent particle ID, 9*9*7 cells, each 4-bit, each cell have max of 220 particles, 8-bit
		// Filter parameters
		.NUM_FILTER(NUM_FILTER),		//4
		.ARBITER_MSB(ARBITER_MSB),	//8								// 2^(NUM_FILTER-1)
		.FILTER_BUFFER_DEPTH(FILTER_BUFFER_DEPTH),
		.FILTER_BUFFER_ADDR_WIDTH(FILTER_BUFFER_ADDR_WIDTH),
		.CUTOFF_2(CUTOFF_2),							// (12^2=144 in IEEE floating point)
		// Force Evaluation parameters
		.SEGMENT_NUM(SEGMENT_NUM),
		.SEGMENT_WIDTH(SEGMENT_WIDTH),
		.BIN_NUM(BIN_NUM),
		.BIN_WIDTH(BIN_WIDTH),
		.LOOKUP_NUM(LOOKUP_NUM),				// SEGMENT_NUM * BIN_NUM
		.LOOKUP_ADDR_WIDTH(LOOKUP_ADDR_WIDTH)			// log LOOKUP_NUM / log 2
	)
	RL_LJ_Top
	(
		.clk(clk),
		.rst(rst),
		.start(start),
		// These are all temp output ports
		.ref_particle_id(ref_particle_id),
		.ref_LJ_Force_X(ref_LJ_Force_X),
		.ref_LJ_Force_Y(ref_LJ_Force_Y),
		.ref_LJ_Force_Z(ref_LJ_Force_Z),
		.ref_forceoutput_valid(ref_forceoutput_valid),
		.neighbor_particle_id(neighbor_particle_id),
		.neighbor_LJ_Force_X(neighbor_LJ_Force_X),
		.neighbor_LJ_Force_Y(neighbor_LJ_Force_Y),
		.neighbor_LJ_Force_Z(neighbor_LJ_Force_Z),
		.neighbor_forceoutput_valid(neighbor_forceoutput_valid),
		// Done signal, when entire home cell is done processing, this will keep high until the next time 'start' signal turn high
		.done(done)
	);

endmodule