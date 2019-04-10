/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: Board_Test_Top_RL_LJ_Pipeline_1st_Order.v
//
//	Function: 
//				Serve as the top module for on-board test
//				The rst and start signal is given by memory modules controlled by in memory content editor
//
// Purpose:
//				Performance estimation against MiniMD
//
// Dependency:
// 			RL_LJ_Pipeline_1st_Order_no_filter.v
//
// Created by:
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module Board_Test_Top_RL_LJ_Pipeline_1st_Order
#(
	parameter DATA_WIDTH 				= 32,
	parameter REF_PARTICLE_NUM			= 100,
	parameter REF_RAM_ADDR_WIDTH		= 7,										// log(REF_PARTICLE_NUM)
	parameter NEIGHBOR_PARTICLE_NUM	= 100,
	parameter NEIGHBOR_RAM_ADDR_WIDTH= 7,										// log(NEIGHBOR_RAM_ADDR_WIDTH)
	parameter INTERPOLATION_ORDER		= 1,
	parameter SEGMENT_NUM				= 14,
	parameter SEGMENT_WIDTH				= 4,
	parameter BIN_WIDTH					= 8,
	parameter BIN_NUM						= 256,
	parameter CUTOFF_2					= 32'h43100000,						// (12^2=144 in IEEE floating point)
	parameter LOOKUP_NUM					= SEGMENT_NUM * BIN_NUM,			// SEGMENT_NUM * BIN_NUM
	parameter LOOKUP_ADDR_WIDTH		= SEGMENT_WIDTH + BIN_WIDTH,		// log LOOKUP_NUM / log 2
	
	parameter RESULTS_DATA_WIDTH		= 32*3,
	parameter RESULTS_DATA_NUM			= REF_PARTICLE_NUM * NEIGHBOR_PARTICLE_NUM,
	parameter RESULTS_ADDR_WIDTH		= 14										// log(RESULTS_DATA_NUM) / log(2)
)
(
	input  ref_clk_125mhz,															// Pin AN27, 125MHz input from oscillator
	output [DATA_WIDTH-1:0] LJ_Force_X,
	output [DATA_WIDTH-1:0] LJ_Force_Y,
	output [DATA_WIDTH-1:0] LJ_Force_Z,
	output forceoutput_valid,
	output done
);

	wire rst;
	wire start;
	wire clk;
	
	// Signals for results storage
	reg [RESULTS_ADDR_WIDTH-1:0] result_storage_wr_addr;
	always@(posedge clk)
		begin
		if(rst)
			result_storage_wr_addr <= 0;
		else if(forceoutput_valid)
			result_storage_wr_addr <= result_storage_wr_addr + 1'b1;
		end
	
	// Input pll
	INPUT_PLL INPUT_PLL(
		.locked(),   //  locked.export
		.outclk_0(clk), // outclk0.clk
		.refclk(ref_clk_125mhz),   //  refclk.clk
		.rst(rst)       //   reset.reset
	);
	
	// rst signal from Memory content editor
	CTRL_RST CTRL_RST (
		.data    (),    //   input,  width = 1,  ram_input.datain
		.address (1'b0), //   input,  width = 1,           .address
		.wren    (1'b0),    //   input,  width = 1,           .wren
		.clock   (clk),   //   input,  width = 1,           .clk
		.q       (rst)        //  output,  width = 1, ram_output.dataout
	);
	
//	On_Board_Test_Control_RAM_rst CTRL_rst (
//		.data    (),    //   input,  width = 1,  ram_input.datain
//		.address (1'b0), //   input,  width = 1,           .address
//		.wren    (1'b0),    //   input,  width = 1,           .wren
//		.clock   (clk),   //   input,  width = 1,           .clk
//		.q       (rst)        //  output,  width = 1, ram_output.dataout
//	);
	
	// start signal from Memory content editor
	CTRL_START CTRL_START (
		.data    (),    //   input,  width = 1,  ram_input.datain
		.address (1'b0), //   input,  width = 1,           .address
		.wren    (1'b0),    //   input,  width = 1,           .wren
		.clock   (clk),   //   input,  width = 1,           .clk
		.q       (start)        //  output,  width = 1, ram_output.dataout
	);
	
//	On_Board_Test_Control_RAM_start CTRL_start (
//		.data    (),    //   input,  width = 1,  ram_input.datain
//		.address (1'b0), //   input,  width = 1,           .address
//		.wren    (1'b0),    //   input,  width = 1,           .wren
//		.clock   (clk),   //   input,  width = 1,           .clk
//		.q       (start)        //  output,  width = 1, ram_output.dataout
//	);
	

	
	// Results on-chip storage
	Force_Value_Mem
	#(
		.DATA_WIDTH(RESULTS_DATA_WIDTH),
		.DEPTH(RESULTS_DATA_NUM),
		.ADDR_WIDTH(RESULTS_ADDR_WIDTH)
	)
	Force_Value_Mem
	(
		.address(result_storage_wr_addr),
		.clock(clk),
		.data({LJ_Force_Z, LJ_Force_Y, LJ_Force_X}),
		.rden(1'b0),
		.wren(forceoutput_valid),
		.q()
	);
	
	// RL LJ pipeline
	RL_LJ_Pipeline_1st_Order_no_filter
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
		.CUTOFF_2(CUTOFF_2),
		.LOOKUP_NUM(LOOKUP_NUM),
		.LOOKUP_ADDR_WIDTH(LOOKUP_ADDR_WIDTH)
	)
	RL_LJ_Pipeline_1st_Order_no_filter
	(
		.clk(clk),
		.rst(rst),
		.start(start),
		.LJ_Force_X(LJ_Force_X),
		.LJ_Force_Y(LJ_Force_Y),
		.LJ_Force_Z(LJ_Force_Z),
		.forceoutput_valid(forceoutput_valid),
		.done(done)
	);
	


endmodule