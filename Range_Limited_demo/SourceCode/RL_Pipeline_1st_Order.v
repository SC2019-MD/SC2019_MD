/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: RL_Pipeline_1st_Order.v
//
//	Function: Evaluate the piarwise non-bonded force between particle pairs using 1st order interpolation (interpolation index is generated in Matlab (under Ethan_GoldenModel/Matlab_Interpolation))
// 			1 tile of force pipeline, without filter
//				for each force pipeline, there are 2 banks of brams to feed position data of particle pairs which are already filtered.
//
// Dependency:
// 			RL_Evaluate_Pairs_1st_Order.v
//
// To do:
//			done signal should not be issued until the last pair of particles is finished evaluation!
//
// Created by: Tony Geng 03/01/18
// Update by: Chen Yang 05/21/18
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module RL_Pipeline_1st_Order
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
	parameter LOOKUP_NUM					= SEGMENT_NUM * BIN_NUM,			// SEGMENT_NUM * BIN_NUM
	parameter LOOKUP_ADDR_WIDTH		= SEGMENT_WIDTH + BIN_WIDTH		// log LOOKUP_NUM / log 2
)
(
	input  clk,
	input  rst,
	input  start,
	output [DATA_WIDTH-1:0] forceoutput,
	output forceoutput_valid,
	output reg done
);
	
	// rst & start signal is given by in-memory content editor
//	wire rst;
//	wire start;
	
	wire [DATA_WIDTH-1:0] p_a;
	wire [DATA_WIDTH-1:0] p_b;
	wire [DATA_WIDTH-1:0] p_qq;
	
	assign p_a  = 32'h40000000;				// p_a = 2, in IEEE floating point format
	assign p_b  = 32'h40800000;				// p_b = 4, in IEEE floating point format
	assign p_qq = 32'h41000000;				// p_qq = 8, in IEEE floating point format
	
	wire [DATA_WIDTH-1:0] refx;
	wire [DATA_WIDTH-1:0] neighborx;
	wire [DATA_WIDTH-1:0] refy;
	wire [DATA_WIDTH-1:0] neighbory;
	wire [DATA_WIDTH-1:0] refz;
	wire [DATA_WIDTH-1:0] neighborz;

	reg rden;
	reg wren;

	reg [REF_RAM_ADDR_WIDTH-1:0] wraddr;
	reg [NEIGHBOR_RAM_ADDR_WIDTH-1:0] neighbor_rdaddr;
	reg [REF_RAM_ADDR_WIDTH-1:0] home_rdaddr;

	reg r2_enable;									// control signal that enables R2 calculation, this signal should have 1 cycle delay of the rden signal, thus wait for the data read out from BRAM
	wire [DATA_WIDTH-1:0] r2;
	wire r2_valid;
	
	parameter WAIT_FOR_START = 2'b00;
	parameter START 			 = 2'b01;
	parameter EVALUATION 	 = 2'b10;
	parameter DONE 			 = 2'b11;
	reg [1:0] state;
	
	always@(posedge clk)
		if(rst)
			begin
			neighbor_rdaddr <= 0;
			home_rdaddr <= 0;
			wraddr <= 0;
			wren <= 1'b0;
			rden <= 1'b0;
			r2_enable <= 1'b0;
			
			state <= WAIT_FOR_START;
			end
		else if(start)
			begin
			r2_enable <= rden;				// Assign the r2_enable signal, one cycle delay from the rden signal
			
			wren <= 1'b0;						// temporarily disable write back to position ram
			wraddr <= 0;
			case(state)
				WAIT_FOR_START:				// Wait for the input start signal from outside
					begin
					neighbor_rdaddr <= 0;
					home_rdaddr <= 0;
					rden <= 1'b0;
					done <= 1'b0;
					if(start)
						state <= START;
					else
						state <= WAIT_FOR_START;
					end
					
				START:							// Evaluate the first pair (start from addr = 0)
					begin
					neighbor_rdaddr <= 0;
					home_rdaddr <= 0;
					
					done <= 1'b0;
					rden <= 1'b1;
					state <= EVALUATION;
					end
					
				EVALUATION:						// Evaluating all the particle pairs
					begin
					done <= 1'b0;
					
					neighbor_rdaddr <= neighbor_rdaddr + 1'b1;
					rden <= 1'b1;
					if(neighbor_rdaddr == NEIGHBOR_PARTICLE_NUM)
						home_rdaddr <= home_rdaddr + 1'b1;

					if(home_rdaddr < REF_PARTICLE_NUM)
						state <= EVALUATION;
					else
						state <= DONE;
					end
					
				DONE:								// Output a done signal
					begin
					done <= 1'b1;
					neighbor_rdaddr <= 0;
					home_rdaddr <= 0;
					rden <= 1'b0;
					
					state <= WAIT_FOR_START;
					end
			endcase
			end
			
	r2_compute #(DATA_WIDTH) r2_evaluate(
		.clk(clk),
		.rst(rst),
		.enable(r2_enable),
		.refx(refx),
		.refy(refy),
		.refz(refz),
		.neighborx(neighborx),
		.neighbory(neighbory),
		.neighborz(neighborz),
		.r2(r2),
		.r2_valid(r2_valid)
		);

	RL_Evaluate_Pairs_1st_Order #(
		DATA_WIDTH,
		SEGMENT_NUM,
		SEGMENT_WIDTH,
		BIN_WIDTH,
		BIN_NUM,
		LOOKUP_NUM,
		LOOKUP_ADDR_WIDTH
	)
	RL_Evaluate_Pairs(
		.clk(clk),
		.rst(rst),
		.r2_valid(r2_valid),
		.r2(r2),
		.p_a(p_a),
		.p_b(p_b),
		.p_qq(p_qq),
		.RL_force(forceoutput),
		.RL_force_valid(forceoutput_valid)
		);

	// Reference particle position ram
	ram_ref_x
	#(
		.DATA_WIDTH(DATA_WIDTH),
		.PARTICLE_NUM(REF_PARTICLE_NUM),
		.ADDR_WIDTH(REF_RAM_ADDR_WIDTH)
	)
	ram_ref_x
	(
		.address(home_rdaddr),
		.clock(clk),
		.data(),
		.rden(rden),
		.wren(wren),
		.q(refx)
	);

	ram_ref_y
	#(
		.DATA_WIDTH(DATA_WIDTH),
		.PARTICLE_NUM(REF_PARTICLE_NUM),
		.ADDR_WIDTH(REF_RAM_ADDR_WIDTH)
	)
	ram_ref_y
	(
		.address(home_rdaddr),
		.clock(clk),
		.data(),
		.rden(rden),
		.wren(wren),
		.q(refy)
	);

	ram_ref_z
	#(
		.DATA_WIDTH(DATA_WIDTH),
		.PARTICLE_NUM(REF_PARTICLE_NUM),
		.ADDR_WIDTH(REF_RAM_ADDR_WIDTH)
	)
	ram_ref_z
	(
		.address(home_rdaddr),
		.clock(clk),
		.data(),
		.rden(rden),
		.wren(wren),
		.q(refz)
	);


	ram_neighbor_x
	#(
		.DATA_WIDTH(DATA_WIDTH),
		.PARTICLE_NUM(NEIGHBOR_PARTICLE_NUM),
		.ADDR_WIDTH(NEIGHBOR_RAM_ADDR_WIDTH)
	)
	ram_neighbor_x
	(
		.address(neighbor_rdaddr),
		.clock(clk),
		.data(),
		.rden(rden),
		.wren(wren),
		.q(neighborx)
	);
	
	ram_neighbor_y
	#(
		.DATA_WIDTH(DATA_WIDTH),
		.PARTICLE_NUM(NEIGHBOR_PARTICLE_NUM),
		.ADDR_WIDTH(NEIGHBOR_RAM_ADDR_WIDTH)
	)
	ram_neighbor_y
	(
		.address(neighbor_rdaddr),
		.clock(clk),
		.data(),
		.rden(rden),
		.wren(wren),
		.q(neighbory)
	);
	
	ram_neighbor_z
	#(
		.DATA_WIDTH(DATA_WIDTH),
		.PARTICLE_NUM(NEIGHBOR_PARTICLE_NUM),
		.ADDR_WIDTH(NEIGHBOR_RAM_ADDR_WIDTH)
	)
	ram_neighbor_z
	(
		.address(neighbor_rdaddr),
		.clock(clk),
		.data(),
		.rden(rden),
		.wren(wren),
		.q(neighborz)
	);

endmodule


