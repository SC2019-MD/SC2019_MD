/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: RL_LJ_Evaluation_OpenCL_Top_tb.v
//
//	Function: 
//				Testbench for RL_LJ_Evaluation_OpenCL_Top.v
//				
//
// Data Organization:
//				Filter buffer: MSB-LSB: {ref_particle_id, neighbor_particle_id, r2, dz, dy, dx}
//				Input buffer: MSB-LSB: {ref_particle_id, neighbor_particle_id, refx, refy, refz, neighborx, neighbory, neighborz}
//				Output buffer: MSB-LSB: {ref_particle_id, neighbor_particle_id, LJ_Force_X, LJ_Force_Y, LJ_Force_Z}
//
// Used by:
//				N/A
//
// Dependency:
//				RL_LJ_Evaluation_OpenCL_Top.v
//
// Testbench:
//				I am testbench......
//
// Timing:
//				TBD
//
// Created by: 
//				Chen Yang 12/10/18
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ns

module RL_LJ_Evaluation_OpenCL_Top_tb;

	parameter DATA_WIDTH 					= 32;
	// Dataset defined parameters
	parameter CELL_ID_WIDTH					= 4;											// log(NUM_NEIGHBOR_CELLS)
	parameter MAX_CELL_PARTICLE_NUM		= 290;										// The maximum # of particles can be in a cell
	parameter CELL_ADDR_WIDTH				= 9;											// log(MAX_CELL_PARTICLE_NUM)
	parameter PARTICLE_ID_WIDTH			= CELL_ID_WIDTH*3+CELL_ADDR_WIDTH;	// # of bit used to represent particle ID, 9*9*7 cells, each 4-bit, each cell have max of 200 particles, 8-bit
	// In & Out buffer parameters
	parameter INPUT_BUFFER_DEPTH			= 4;
	parameter INPUT_BUFFER_ADDR_WIDTH	= 2;											// log INPUT_BUFFER_DEPTH / log 2
	parameter OUTPUT_BUFFER_DEPTH			= 32;	//64;									// This one should be large enough to hold all the values in the pipeline 
	parameter OUTPUT_BUFFER_ADDR_WIDTH	= 5;	//6;									// log OUTPUT_BUFFER_DEPTH / log 2
	// Filter parameters
	parameter FILTER_BUFFER_DEPTH 		= 32;
	parameter FILTER_BUFFER_ADDR_WIDTH	= 5;
	parameter CUTOFF_2 						= 32'h43100000;							// (12^2=144 in IEEE floating point)
	// Force Evaluation parameters
	parameter SEGMENT_NUM					= 14;
	parameter SEGMENT_WIDTH					= 4;
	parameter BIN_NUM							= 256;
	parameter BIN_WIDTH						= 8;
	parameter LOOKUP_NUM						= SEGMENT_NUM * BIN_NUM;				// SEGMENT_NUM * BIN_NUM
	parameter LOOKUP_ADDR_WIDTH			= SEGMENT_WIDTH + BIN_WIDTH;			// log LOOKUP_NUM / log 2
	
	reg clk;
	reg rst;
	wire clock;
	wire resetn;
	assign clock = clk;
	assign resetn = ~rst;
	// OpenCL ports
	reg ivalid;							// Connect to upstream
	reg iready;							// Connect to downstream
	wire ovalid;						// Connect to downstream
	wire oready;						//	Connect to upstream
	// Data ports
	reg [PARTICLE_ID_WIDTH-1:0] in_ref_particle_id;
	reg [PARTICLE_ID_WIDTH-1:0] in_neighbor_particle_id;
	reg [DATA_WIDTH-1:0] in_refx;
	reg [DATA_WIDTH-1:0] in_refy;
	reg [DATA_WIDTH-1:0] in_refz;
	reg [DATA_WIDTH-1:0] in_neighborx;
	reg [DATA_WIDTH-1:0] in_neighbory;
	reg [DATA_WIDTH-1:0] in_neighborz;
	wire [PARTICLE_ID_WIDTH-1:0] out_ref_particle_id;
	wire [PARTICLE_ID_WIDTH-1:0] out_neighbor_particle_id;
	wire [DATA_WIDTH-1:0] out_LJ_Force_X;
	wire [DATA_WIDTH-1:0] out_LJ_Force_Y;
	wire [DATA_WIDTH-1:0] out_LJ_Force_Z;
	
	// Real Data ports
	wire [2*DATA_WIDTH-1:0] in_particle_id;					// Input
	wire [4*DATA_WIDTH-1:0] in_reference_pos;					// Input
	wire [4*DATA_WIDTH-1:0] in_neighbor_pos;					// Input
	wire [2*DATA_WIDTH-1:0] out_particle_id;					// Output
	wire [4*DATA_WIDTH-1:0] out_forceoutput;					// Output
	assign in_particle_id[PARTICLE_ID_WIDTH+DATA_WIDTH-1:DATA_WIDTH] = in_ref_particle_id;
	assign in_particle_id[PARTICLE_ID_WIDTH-1:0] = in_neighbor_particle_id;
	assign in_reference_pos[1*DATA_WIDTH-1:0*DATA_WIDTH] = in_refx;
	assign in_reference_pos[2*DATA_WIDTH-1:1*DATA_WIDTH] = in_refy;
	assign in_reference_pos[3*DATA_WIDTH-1:2*DATA_WIDTH] = in_refz;
	assign in_neighbor_pos[1*DATA_WIDTH-1:0*DATA_WIDTH] = in_neighborx;
	assign in_neighbor_pos[2*DATA_WIDTH-1:1*DATA_WIDTH] = in_neighbory;
	assign in_neighbor_pos[3*DATA_WIDTH-1:2*DATA_WIDTH] = in_neighborz;
	assign out_ref_particle_id = out_particle_id[PARTICLE_ID_WIDTH+DATA_WIDTH-1:DATA_WIDTH];
	assign out_neighbor_particle_id = out_particle_id[PARTICLE_ID_WIDTH-1:0];
	assign out_LJ_Force_X = out_forceoutput[1*DATA_WIDTH-1:0*DATA_WIDTH];
	assign out_LJ_Force_Y = out_forceoutput[2*DATA_WIDTH-1:1*DATA_WIDTH];
	assign out_LJ_Force_Z = out_forceoutput[3*DATA_WIDTH-1:2*DATA_WIDTH];
	
	
	always #1 clk <= ~clk;

	reg [7:0] counter;
	always@(posedge clk)
		begin
		if(rst)
			begin
			counter <= 0;
			
			ivalid <= 1'b0;
			in_ref_particle_id <= {4'd2, 4'd2, 4'd2, 9'd1};
			in_neighbor_particle_id <= {4'd2, 4'd2, 4'd3, 9'h16};
			in_refx <= 0;
			in_refy <= 0;
			in_refz <= 0;
			in_neighborx <= 0;
			in_neighbory <= 0;
			in_neighborz <= 0;
			end
		else
			begin
			// Only when HDL is ready to take data, then proceed on generating data
			if (oready)
				begin
				counter <= counter + 1'b1;
				end
			else
				begin
				counter <= counter;
				end
				
			// Valid input
			if(counter < 10 || counter == 15 || counter == 16 || counter == 18 || counter == 20)
				begin
				ivalid <= 1'b1;
				in_ref_particle_id <= {4'd2, 4'd2, 4'd2, 9'd1};
				in_neighbor_particle_id <= {4'd2, 4'd2, 4'd3, 1'b0, counter};
				in_refx <= 32'h41668F5C;
				in_refy <= 32'h414153F8;
				in_refz <= 32'h416974BC;
				in_neighborx <= 32'h41719581;
				in_neighbory <= 32'h414445A2;
				in_neighborz <= 32'h41C9FDF4;
				end
			// Outside cutoff
			else if(counter >= 30 && counter < 35)
				begin
				ivalid <= 1'b1;
				in_ref_particle_id <= {4'd2, 4'd2, 4'd2, 9'd1};
				in_neighbor_particle_id <= {4'd2, 4'd2, 4'd3, 1'b0, counter};
				in_refx <= 32'h41668F5C;
				in_refy <= 32'h414153F8;
				in_refz <= 32'h416974BC;
				in_neighborx <= 32'h419D999A;
				in_neighbory <= 32'h41B47AE1;
				in_neighborz <= 32'h42004396;
				end
			// Keep sending valid input to add pressure to the test module
			else if(counter < 100)
				begin
				ivalid <= 1'b1;
				in_ref_particle_id <= {4'd2, 4'd2, 4'd2, 9'd1};
				in_neighbor_particle_id <= {4'd2, 4'd2, 4'd3, 1'b0, counter};
				in_refx <= 32'h41668F5C;
				in_refy <= 32'h414153F8;
				in_refz <= 32'h416974BC;
				in_neighborx <= 32'h41719581;
				in_neighbory <= 32'h414445A2;
				in_neighborz <= 32'h41C9FDF4;
				end
			// Invalid
			else
				begin
				ivalid <= 1'b0;
				in_ref_particle_id <= {4'd2, 4'd2, 4'd2, 9'd1};
				in_neighbor_particle_id <= {4'd2, 4'd2, 4'd3, 1'b0, counter};
				in_refx <= 32'h41668F5C;
				in_refy <= 32'h414153F8;
				in_refz <= 32'h416974BC;
				in_neighborx <= 32'h41719581;
				in_neighbory <= 32'h414445A2;
				in_neighborz <= 32'h41C9FDF4;
				end
			end
		end
	
	initial begin
		clk <= 1'b1;
		rst <= 1'b1;
		iready <= 1'b0;
	
		#10
		rst <= 1'b0;
		iready <= 1'b0;
		
		// Control the downstream ready signal see if the backpressure mechanism works
		#10
		iready <= 1'b1;
		
		#10
		iready <= 1'b0;
		
		#200
		iready <= 1'b1;
	end
	
	// UUT
	RL_LJ_Evaluation_OpenCL_Top
	#(
		.DATA_WIDTH(DATA_WIDTH),
		// Dataset defined parameters
		.CELL_ID_WIDTH(CELL_ID_WIDTH),											// log(NUM_NEIGHBOR_CELLS)
		.MAX_CELL_PARTICLE_NUM(MAX_CELL_PARTICLE_NUM),						// The maximum # of particles can be in a cell
		.CELL_ADDR_WIDTH(CELL_ADDR_WIDTH),										// log(MAX_CELL_PARTICLE_NUM)
		.PARTICLE_ID_WIDTH(PARTICLE_ID_WIDTH),									// # of bit used to represent particle ID, 9*9*7 cells, each 4-bit, each cell have max of 200 particles, 8-bit
		// In & Out buffer parameters
		.INPUT_BUFFER_DEPTH(INPUT_BUFFER_DEPTH),
		.INPUT_BUFFER_ADDR_WIDTH(INPUT_BUFFER_ADDR_WIDTH),					// log INPUT_BUFFER_DEPTH / log 2
		.OUTPUT_BUFFER_DEPTH(OUTPUT_BUFFER_DEPTH),							// This one should be large enough to hold all the values in the pipeline 
		.OUTPUT_BUFFER_ADDR_WIDTH(OUTPUT_BUFFER_ADDR_WIDTH),				// log OUTPUT_BUFFER_DEPTH / log 2
		// Filter parameters
		.FILTER_BUFFER_DEPTH(FILTER_BUFFER_DEPTH),
		.FILTER_BUFFER_ADDR_WIDTH(FILTER_BUFFER_ADDR_WIDTH),
		.CUTOFF_2(CUTOFF_2),															// (12^2=144 in IEEE floating point)
		// Force Evaluation parameters
		.SEGMENT_NUM(SEGMENT_NUM),
		.SEGMENT_WIDTH(SEGMENT_WIDTH),
		.BIN_NUM(BIN_NUM),
		.BIN_WIDTH(BIN_WIDTH),
		.LOOKUP_NUM(LOOKUP_NUM),													// SEGMENT_NUM * BIN_NUM
		.LOOKUP_ADDR_WIDTH(LOOKUP_ADDR_WIDTH)									// log LOOKUP_NUM / log 2
	)
	UUT
	(
		.clock(clock),
		.resetn(resetn),
		// OpenCL ports
		.ivalid(ivalid),						// Connect to upstream
		.iready(iready),						// Connect to downstream
		.ovalid(ovalid),						// Connect to downstream
		.oready(oready),						//	Connect to upstream
		// Data ports
/*		
		.in_ref_particle_id(in_ref_particle_id),
		.in_neighbor_particle_id(in_neighbor_particle_id),
		.in_refx(in_refx),
		.in_refy(in_refy),
		.in_refz(in_refz),
		.in_neighborx(in_neighborx),
		.in_neighbory(in_neighbory),
		.in_neighborz(in_neighborz),
		.out_ref_particle_id(out_ref_particle_id),
		.out_neighbor_particle_id(out_neighbor_particle_id),
		.out_LJ_Force_X(out_LJ_Force_X),
		.out_LJ_Force_Y(out_LJ_Force_Y),
		.out_LJ_Force_Z(out_LJ_Force_Z)
*/
		.in_particle_id(in_particle_id),
		.in_reference_pos(in_reference_pos),
		.in_neighbor_pos(in_neighbor_pos),
//		.out_particle_id(out_particle_id),
		.out_forceoutput(out_forceoutput)
	);

endmodule