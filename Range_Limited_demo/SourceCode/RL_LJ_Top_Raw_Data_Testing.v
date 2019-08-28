/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: RL_LJ_Top_Raw_Data_Testing.v
//
//	Function: 
//				Evaluate the dataset using 1st order interpolation (interpolation index is generated in Matlab (under Ethan_GoldenModel/Matlab_Interpolation))
// 			The input data is raw ApoA1 data without sorting into cells
//				Mapping a single reference pariticle memory and a single neighbor particle memory onto one RL_LJ_Evaluation_Unit (memory content in ref and neighbor are the same)
//				No force accumulation & No Motion Update
//
//	Purpose:
//				Filter version, used for testing and verification only
//
// Used by:
//				TBD
//
// Dependency:
//				RL_LJ_Force_Evaluation_Unit.v
//
// Latency: TBD
//
// Todo:
//				This is a temperoal module that used for verification
//				1, parameterize # of force evaluation units in it
//
// Created by:
//				Chen Yang 10/18/18
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module RL_LJ_Top_Raw_Data_Testing
#(
	parameter DATA_WIDTH 					= 32,
	// High level parameters
	parameter NUM_FORCE_EVAL_UNIT			= 1,
	// Dataset defined parameters
	parameter PARTICLE_ID_WIDTH			= 20,										// # of bit used to represent particle ID, 9*9*7 cells, each 4-bit, each cell have max of 200 particles, 8-bit
	parameter REF_PARTICLE_NUM				= 100,
	parameter REF_RAM_ADDR_WIDTH			= 7,										// log(REF_PARTICLE_NUM)
	parameter NEIGHBOR_PARTICLE_NUM		= 100,
	parameter NEIGHBOR_RAM_ADDR_WIDTH	= 7,										// log(NEIGHBOR_RAM_ADDR_WIDTH)
	// Filter parameters
	parameter NUM_FILTER						= 4,	// 8
	parameter ARBITER_MSB 					= 8,	//128								// 2^(NUM_FILTER-1)
	parameter FILTER_BUFFER_DEPTH 		= 32,
	parameter FILTER_BUFFER_ADDR_WIDTH	= 5,
	parameter CUTOFF_2 						= 32'h43100000,						// (12^2=144 in IEEE floating point)
	// Force Evaluation parameters
	parameter SEGMENT_NUM					= 14,
	parameter SEGMENT_WIDTH					= 4,
	parameter BIN_NUM							= 256,
	parameter BIN_WIDTH						= 8,
	parameter LOOKUP_NUM						= SEGMENT_NUM * BIN_NUM,			// SEGMENT_NUM * BIN_NUM
	parameter LOOKUP_ADDR_WIDTH			= SEGMENT_WIDTH + BIN_WIDTH		// log LOOKUP_NUM / log 2
)
(
	input  clk,
	input  rst,
	input  start,
	output [NUM_FORCE_EVAL_UNIT*PARTICLE_ID_WIDTH-1:0] ref_particle_id,
	output [NUM_FORCE_EVAL_UNIT*PARTICLE_ID_WIDTH-1:0] neighbor_particle_id,
	output [NUM_FORCE_EVAL_UNIT*DATA_WIDTH-1:0] LJ_Force_X,
	output [NUM_FORCE_EVAL_UNIT*DATA_WIDTH-1:0] LJ_Force_Y,
	output [NUM_FORCE_EVAL_UNIT*DATA_WIDTH-1:0] LJ_Force_Z,
	output [NUM_FORCE_EVAL_UNIT-1:0] forceoutput_valid,
	output reg done
);

	// Controller variables
	parameter WAIT_FOR_START  = 3'b000;
	parameter START 			  = 3'b001;
	parameter EVALUATION 	  = 3'b010;
	parameter WAIT_FOR_FINISH = 3'b011;
	parameter DONE 			  = 3'b100;
	
	// FSM controller variables
	reg rden;
	reg wren;
	reg [2:0] state;
	reg [REF_RAM_ADDR_WIDTH-1:0] wraddr;
	reg [NEIGHBOR_RAM_ADDR_WIDTH-1:0] neighbor_rdaddr;
	reg [REF_RAM_ADDR_WIDTH-1:0] home_rdaddr;
	reg input_valid;												// signify the valid of input particle data, this signal should have 1 cycle delay of the rden signal, thus wait for the data read out from BRAM
	reg [4:0] wait_counter;										// Counter that wait for the last pair to finish evaluation (17+14=31 cycles)
		
	// Wires between particle memeories and Evaluation units
	wire [DATA_WIDTH-1:0] neighborx;
	wire [DATA_WIDTH-1:0] neighbory;
	wire [DATA_WIDTH-1:0] neighborz;
	wire [DATA_WIDTH-1:0] refx;
	wire [DATA_WIDTH-1:0] refy;
	wire [DATA_WIDTH-1:0] refz;
	wire [NUM_FILTER-1:0] input_valid_wire;
	wire [NUM_FILTER-1:0] back_pressure_to_input_wire;
	wire [NUM_FILTER*DATA_WIDTH-1:0] refx_in_wire, refy_in_wire, refz_in_wire;
	wire [NUM_FILTER*DATA_WIDTH-1:0] neighborx_in_wire, neighbory_in_wire, neighborz_in_wire;
	reg [NUM_FILTER*PARTICLE_ID_WIDTH-1:0] ref_particle_id_in_reg, neighbor_particle_id_in_reg;			// One cycle delay needed between read address and assignment of particle id
	genvar i;
	generate 
		for(i = 0; i < NUM_FILTER; i = i + 1)
			begin: input_wire_assignment
			assign input_valid_wire[i] = input_valid;
			assign refx_in_wire[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH] = refx;
			assign refy_in_wire[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH] = refy;
			assign refz_in_wire[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH] = refz;
			assign neighborx_in_wire[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH] = neighborx;
			assign neighbory_in_wire[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH] = neighbory;
			assign neighborz_in_wire[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH] = neighborz;
			// One cycle delay needed between read address and assignment of particle id
			always@(posedge clk)
				begin
				ref_particle_id_in_reg[(i+1)*PARTICLE_ID_WIDTH-1:i*PARTICLE_ID_WIDTH] <= home_rdaddr;
				neighbor_particle_id_in_reg[(i+1)*PARTICLE_ID_WIDTH-1:i*PARTICLE_ID_WIDTH] <= neighbor_rdaddr;
				end
			end
	endgenerate
	
	// Data RAM rd&wr Controller
	always@(posedge clk)
		if(rst)
			begin
			neighbor_rdaddr <= 0;
			home_rdaddr <= 0;
			wraddr <= 0;
			wren <= 1'b0;
			rden <= 1'b0;
			input_valid <= 1'b0;
			wait_counter <= 5'd0;
			done <= 1'b0;
			
			state <= WAIT_FOR_START;
			end
		else
			begin
			// The input_valid should kept high until the FP operation is finished!!!!!!!!
			input_valid <= rden;				// Assign the input_valid signal, one cycle delay from the rden signal
			
			wren <= 1'b0;						// temporarily disable write back to position ram
			wraddr <= 0;
			case(state)
				WAIT_FOR_START:				// Wait for the input start signal from outside
					begin
					neighbor_rdaddr <= 0;
					home_rdaddr <= 0;
					rden <= 1'b0;
					done <= 1'b0;
					wait_counter <= 5'd0;
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
					wait_counter <= 5'd0;
					if(back_pressure_to_input_wire == 0)
						begin
						state <= EVALUATION;
						rden <= 1'b1;
						end
					else
						begin
						state <= START;
						rden <= 1'b0;
						end
					end
					
				EVALUATION:						// Evaluating all the particle pairs
					begin
					done <= 1'b0;
					wait_counter <= 5'd0;
					// Only readout the next particle data if there no backpressure from filters
					if(back_pressure_to_input_wire == 0)
						begin
						rden <= 1'b1;
						// Generate home cell and neighbor cell address
						if(neighbor_rdaddr == NEIGHBOR_PARTICLE_NUM - 1)
							begin
							home_rdaddr <= home_rdaddr + 1'b1;
							neighbor_rdaddr <= 0;
							end
						else
							begin
							home_rdaddr <= home_rdaddr;
							neighbor_rdaddr <= neighbor_rdaddr + 1'b1;
							end
						end
					else
						begin
						rden <= 1'b0;
						home_rdaddr <= home_rdaddr;
						neighbor_rdaddr <= neighbor_rdaddr;
						end
					
					if((home_rdaddr == REF_PARTICLE_NUM - 1) && (neighbor_rdaddr == NEIGHBOR_PARTICLE_NUM - 1))
						state <= WAIT_FOR_FINISH;
					else
						state <= EVALUATION;
/*
					if(home_rdaddr < REF_PARTICLE_NUM)
						state <= EVALUATION;
					else
						state <= DONE;
*/
					end
				
				WAIT_FOR_FINISH:				// Wait for the last pair to finish force evaluation, for a total of 17+14=31 cycles
					begin
					done <= 1'b0;
					neighbor_rdaddr <= 0;
					home_rdaddr <= 0;
					rden <= 1'b0;
					wait_counter <= wait_counter + 1'b1;
					if (wait_counter < 31)
						state <= WAIT_FOR_FINISH;
					else
						state <= DONE;
					end
				
				DONE:								// Output a done signal
					begin
					done <= 1'b1;
					neighbor_rdaddr <= 0;
					home_rdaddr <= 0;
					rden <= 1'b0;
					wait_counter <= 5'd0;
					
					state <= WAIT_FOR_START;
					end
			endcase
			end
	
	
	// Force evaluation unit
	// Including filters and force evaluation pipeline
	RL_LJ_Force_Evaluation_Unit
	#(
		.DATA_WIDTH(DATA_WIDTH),
		// Dataset defined parameters
		.PARTICLE_ID_WIDTH(PARTICLE_ID_WIDTH),							// # of bit used to represent particle ID, 9*9*7 cells, each 4-bit, each cell have max of 220 particles, 8-bit
		// Filter parameters
		.NUM_FILTER(NUM_FILTER),
		.ARBITER_MSB(ARBITER_MSB),											// 2^(NUM_FILTER-1)
		.FILTER_BUFFER_DEPTH(FILTER_BUFFER_DEPTH),
		.FILTER_BUFFER_ADDR_WIDTH(FILTER_BUFFER_ADDR_WIDTH),
		.CUTOFF_2(CUTOFF_2),													// in IEEE floating point format
		// Force Evaluation parameters
		.SEGMENT_NUM(SEGMENT_NUM),
		.SEGMENT_WIDTH(SEGMENT_WIDTH),
		.BIN_NUM(BIN_NUM),
		.BIN_WIDTH(BIN_WIDTH),
		.LOOKUP_NUM(LOOKUP_NUM),											// SEGMENT_NUM * BIN_NUM
		.LOOKUP_ADDR_WIDTH(LOOKUP_ADDR_WIDTH)							// log(LOOKUP_NUM) / log 2
	)
	RL_LJ_Force_Evaluation_Unit
	(
		.clk(clk),
		.rst(rst),
		.input_valid(input_valid_wire),												// INPUT [NUM_FILTER-1:0]
		.ref_particle_id(ref_particle_id_in_reg),									// INPUT [NUM_FILTER*PARTICLE_ID_WIDTH-1:0]
		.neighbor_particle_id(neighbor_particle_id_in_reg),					// INPUT [NUM_FILTER*PARTICLE_ID_WIDTH-1:0]
		.refx(refx_in_wire),																// INPUT [NUM_FILTER*DATA_WIDTH-1:0]
		.refy(refy_in_wire),																// INPUT [NUM_FILTER*DATA_WIDTH-1:0]
		.refz(refz_in_wire),																// INPUT [NUM_FILTER*DATA_WIDTH-1:0]
		.neighborx(neighborx_in_wire),												// INPUT [NUM_FILTER*DATA_WIDTH-1:0]
		.neighbory(neighbory_in_wire),												// INPUT [NUM_FILTER*DATA_WIDTH-1:0]
		.neighborz(neighborz_in_wire),												// INPUT [NUM_FILTER*DATA_WIDTH-1:0]
		.ref_particle_id_out(ref_particle_id[PARTICLE_ID_WIDTH-1:0]),		// OUTPUT [PARTICLE_ID_WIDTH-1:0]
		.neighbor_particle_id_out(neighbor_particle_id[PARTICLE_ID_WIDTH-1:0]),		// OUTPUT [PARTICLE_ID_WIDTH-1:0]
		.LJ_Force_X(LJ_Force_X[DATA_WIDTH-1:0]),									// OUTPUT [DATA_WIDTH-1:0]
		.LJ_Force_Y(LJ_Force_Y[DATA_WIDTH-1:0]),									// OUTPUT [DATA_WIDTH-1:0]
		.LJ_Force_Z(LJ_Force_Z[DATA_WIDTH-1:0]),									// OUTPUT [DATA_WIDTH-1:0]
		.forceoutput_valid(forceoutput_valid[0]),									// OUTPUT
		.back_pressure_to_input(back_pressure_to_input_wire)					// OUTPUT [NUM_FILTER-1:0]
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


