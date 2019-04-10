/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: Board_Test_Top_RL_Pipeline_1st_Order.v
//
//	Function: Serve as the top module for on-board test
//				The rst and start signal is given by memory modules controlled by in memory content editor
//
// Dependency:
// 			RL_Pipeline_1st_Order.v
//
//	Todo:
//			Add results storage memory (check Board_Test_Top_RL_LJ_Pipeline_1st_Order.v)
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module Board_Test_Top_RL_Pipeline_1st_Order
#(
	parameter DATA_WIDTH 				= 32,
	parameter REF_PARTICLE_NUM			= 100,
	parameter REF_RAM_ADDR_WIDTH		= 7,										// log(REF_PARTICLE_NUM)
	parameter NEIGHBOR_PARTICLE_NUM	= 100,
	parameter NEIGHBOR_RAM_ADDR_WIDTH= 7,										// log(NEIGHBOR_RAM_ADDR_WIDTH)
	parameter INTERPOLATION_ORDER		= 1,
	parameter SEGMENT_NUM				= 12,
	parameter SEGMENT_WIDTH				= 4,
	parameter BIN_WIDTH					= 8,
	parameter BIN_NUM						= 256,
	parameter LOOKUP_NUM					= SEGMENT_NUM * BIN_NUM,			// SEGMENT_NUM * BIN_NUM
	parameter LOOKUP_ADDR_WIDTH		= SEGMENT_WIDTH + BIN_WIDTH		// log LOOKUP_NUM / log 2
)
(
	input  ref_clk,
	output [DATA_WIDTH-1:0] forceoutput,
	output forceoutput_valid,
	output done
);

	wire rst;
	wire start;
	wire clk;
	
	// Input pll
	INPUT_PLL INPUT_PLL(
		.locked(),   //  locked.export
		.outclk_0(clk), // outclk0.clk
		.refclk(ref_clk),   //  refclk.clk
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
	
	// RL LJ pipeline
	RL_Pipeline_1st_Order
	#(
		.DATA_WIDTH(DATA_WIDTH),
		.REF_PARTICLE_NUM(REF_PARTICLE_NUM),
		.REF_RAM_ADDR_WIDTH(REF_RAM_ADDR_WIDTH),							// log(REF_PARTICLE_NUM)
		.NEIGHBOR_PARTICLE_NUM(NEIGHBOR_PARTICLE_NUM),
		.NEIGHBOR_RAM_ADDR_WIDTH(NEIGHBOR_RAM_ADDR_WIDTH),				// log(NEIGHBOR_RAM_ADDR_WIDTH)
		.INTERPOLATION_ORDER(INTERPOLATION_ORDER),
		.SEGMENT_NUM(SEGMENT_NUM),
		.SEGMENT_WIDTH(SEGMENT_WIDTH),
		.BIN_WIDTH(BIN_WIDTH),
		.BIN_NUM(BIN_NUM),
		.LOOKUP_NUM(LOOKUP_NUM),
		.LOOKUP_ADDR_WIDTH(LOOKUP_ADDR_WIDTH)
	)
	RL_Pipeline_1st_Order
	(
		.clk(clk),
		.rst(rst),
		.start(start),
		.forceoutput(forceoutput),
		.forceoutput_valid(forceoutput_valid),
		.done(done)
	);
	


endmodule