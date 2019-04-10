/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: RL_LJ_Force_Evaluation_Unit_simple_filter.v
//
//	Function: 
//				Version with no DSP filter logic
//				Evaluate the LJ force of given datasets using 1st order interpolation (interpolation index is generated in Matlab (under Ethan_GoldenModel/Matlab_Interpolation))
// 			Including a set of Filters and a single Force evaluation pipeline
//				The module connected the Filter_Bank and Force_Evaluation_Pipeline together for easy implementation
//				The module also contains the delay register chain to pass the particle ID from r2_compute output along with the force output
//
//	Used by:
//				RL_LJ_Evaluation_Unit.v
//
// Dependency:
// 			RL_LJ_Evaluate_Pairs_1st_Order.v
//				r2_compute.v
//				Filter_Bank_no_DSP.v
//					- Filter_Logic_no_DSP.v
//						-- Filter_Buffer.v
//					- Filter_Arbiter.v
//
// Latency:
//				r2_compute: 									17 cycles
//				RL_LJ_Pipeline_1st_Order: 					14 cycles
//				Filter_Arbiter:								0 cycle
//
// Created by:
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module RL_LJ_Force_Evaluation_Unit_simple_filter
#(
	parameter DATA_WIDTH 					= 32,
	// Dataset defined parameters
	parameter PARTICLE_ID_WIDTH			= 20,									// # of bit used to represent particle ID, 9*9*7 cells, each 4-bit, each cell have max of 200 particles, 8-bit
	// Filter parameters
	parameter NUM_FILTER						= 8,
	parameter ARBITER_MSB 					= 128,								// 2^(NUM_FILTER-1)
	parameter FILTER_BUFFER_DEPTH 		= 32,
	parameter FILTER_BUFFER_ADDR_WIDTH	= 5,
	parameter CUTOFF_2 						= 32'h43100000,					// (12^2=144 in IEEE floating point)
	parameter CUTOFF_TIMES_SQRT_3			= 32'h41A646DC,					// sqrt(3) * CUTOFF
	parameter FIXED_POINT_WIDTH 			= 32,
	parameter FILTER_IN_PATCH_0_BITS		= 8'b0,								// Width = FIXED_POINT_WIDTH - 1 - 23
	parameter BOUNDING_BOX_X				= 32'h42D80000,					// 12*9 = 108 in IEEE floating point
	parameter BOUNDING_BOX_Y				= 32'h42D80000,					// 12*9 = 108 in IEEE floating point
	parameter BOUNDING_BOX_Z				= 32'h42A80000,					// 12*7 = 84 in IEEE floating point
	// Force Evaluation parameters
	parameter SEGMENT_NUM					= 14,
	parameter SEGMENT_WIDTH					= 4,
	parameter BIN_NUM							= 256,
	parameter BIN_WIDTH						= 8,
	parameter LOOKUP_NUM						= SEGMENT_NUM * BIN_NUM,			// SEGMENT_NUM * BIN_NUM
	parameter LOOKUP_ADDR_WIDTH			= SEGMENT_WIDTH + BIN_WIDTH		// log LOOKUP_NUM / log 2
)
(
	input clk,
	input rst,
	input [NUM_FILTER-1:0] input_valid,
	input [NUM_FILTER*PARTICLE_ID_WIDTH-1:0] ref_particle_id,
	input [NUM_FILTER*PARTICLE_ID_WIDTH-1:0] neighbor_particle_id,
	input [NUM_FILTER*DATA_WIDTH-1:0] refx,
	input [NUM_FILTER*DATA_WIDTH-1:0] refy,
	input [NUM_FILTER*DATA_WIDTH-1:0] refz,
	input [NUM_FILTER*DATA_WIDTH-1:0] neighborx,
	input [NUM_FILTER*DATA_WIDTH-1:0] neighbory,
	input [NUM_FILTER*DATA_WIDTH-1:0] neighborz,
	output [PARTICLE_ID_WIDTH-1:0] ref_particle_id_out,
	output [PARTICLE_ID_WIDTH-1:0] neighbor_particle_id_out,
	output [DATA_WIDTH-1:0] LJ_Force_X,
	output [DATA_WIDTH-1:0] LJ_Force_Y,
	output [DATA_WIDTH-1:0] LJ_Force_Z,
	output forceoutput_valid,
	
	output [NUM_FILTER-1:0] out_back_pressure_to_input,			// If one of the FIFO is full, then set the back_pressure flag to stop more incoming particle pairs
	output out_all_buffer_empty_to_input								// Output to FSM that generate particle pairs. Only when all the filter buffers are empty, then the FSM will move on to the next reference particle
																					// Avoid the cases when the force pipelines are evaluating for 2 different reference particles when switching after one reference particle, this will lead to the accumulation error for the reference particle
);

	// Assign parameters for A, B, QQ (currently not used)
	wire [DATA_WIDTH-1:0] p_a;
	wire [DATA_WIDTH-1:0] p_b;
	wire [DATA_WIDTH-1:0] p_qq;
	assign p_a  = 32'h40000000;				// p_a = 2, in IEEE floating point format
	assign p_b  = 32'h40800000;				// p_b = 4, in IEEE floating point format
	assign p_qq = 32'h41000000;				// p_qq = 8, in IEEE floating point format

	// Wires connect Filter_Bank and r2_evaluate
	wire [PARTICLE_ID_WIDTH-1:0] filter_out_ref_particle_id;
	wire [PARTICLE_ID_WIDTH-1:0] filter_out_neighbor_particle_id;
	wire [DATA_WIDTH-1:0] filter_out_refx;
	wire [DATA_WIDTH-1:0] filter_out_refy;
	wire [DATA_WIDTH-1:0] filter_out_refz;
	wire [DATA_WIDTH-1:0] filter_out_neighborx;
	wire [DATA_WIDTH-1:0] filter_out_neighbory;
	wire [DATA_WIDTH-1:0] filter_out_neighborz;
	wire filter_out_valid;
	
	// Wires connect r2_evaluate and RL_LJ_Evaluate_Pairs_1st_Order
	wire [DATA_WIDTH-1:0] r2_out_r2;
	wire [DATA_WIDTH-1:0] r2_out_dx;
	wire [DATA_WIDTH-1:0] r2_out_dy;
	wire [DATA_WIDTH-1:0] r2_out_dz;
	wire r2_out_valid;
	
	// Delay registers for particle IDs from filter_bank to force output
	// Delay for 17 + 14 = 31 cycles
	reg [PARTICLE_ID_WIDTH-1:0] ref_particle_id_reg0;
	reg [PARTICLE_ID_WIDTH-1:0] ref_particle_id_reg1;
	reg [PARTICLE_ID_WIDTH-1:0] ref_particle_id_reg2;
	reg [PARTICLE_ID_WIDTH-1:0] ref_particle_id_reg3;
	reg [PARTICLE_ID_WIDTH-1:0] ref_particle_id_reg4;
	reg [PARTICLE_ID_WIDTH-1:0] ref_particle_id_reg5;
	reg [PARTICLE_ID_WIDTH-1:0] ref_particle_id_reg6;
	reg [PARTICLE_ID_WIDTH-1:0] ref_particle_id_reg7;
	reg [PARTICLE_ID_WIDTH-1:0] ref_particle_id_reg8;
	reg [PARTICLE_ID_WIDTH-1:0] ref_particle_id_reg9;
	reg [PARTICLE_ID_WIDTH-1:0] ref_particle_id_reg10;
	reg [PARTICLE_ID_WIDTH-1:0] ref_particle_id_reg11;
	reg [PARTICLE_ID_WIDTH-1:0] ref_particle_id_reg12;
	reg [PARTICLE_ID_WIDTH-1:0] ref_particle_id_reg13;
	reg [PARTICLE_ID_WIDTH-1:0] ref_particle_id_reg14;
	reg [PARTICLE_ID_WIDTH-1:0] ref_particle_id_reg15;
	reg [PARTICLE_ID_WIDTH-1:0] ref_particle_id_reg16;
	reg [PARTICLE_ID_WIDTH-1:0] ref_particle_id_reg17;
	reg [PARTICLE_ID_WIDTH-1:0] ref_particle_id_reg18;
	reg [PARTICLE_ID_WIDTH-1:0] ref_particle_id_reg19;
	reg [PARTICLE_ID_WIDTH-1:0] ref_particle_id_reg20;
	reg [PARTICLE_ID_WIDTH-1:0] ref_particle_id_reg21;
	reg [PARTICLE_ID_WIDTH-1:0] ref_particle_id_reg22;
	reg [PARTICLE_ID_WIDTH-1:0] ref_particle_id_reg23;
	reg [PARTICLE_ID_WIDTH-1:0] ref_particle_id_reg24;
	reg [PARTICLE_ID_WIDTH-1:0] ref_particle_id_reg25;
	reg [PARTICLE_ID_WIDTH-1:0] ref_particle_id_reg26;
	reg [PARTICLE_ID_WIDTH-1:0] ref_particle_id_reg27;
	reg [PARTICLE_ID_WIDTH-1:0] ref_particle_id_reg28;
	reg [PARTICLE_ID_WIDTH-1:0] ref_particle_id_reg29;
	reg [PARTICLE_ID_WIDTH-1:0] ref_particle_id_delayed;
	reg [PARTICLE_ID_WIDTH-1:0] neighbor_particle_id_reg0;
	reg [PARTICLE_ID_WIDTH-1:0] neighbor_particle_id_reg1;
	reg [PARTICLE_ID_WIDTH-1:0] neighbor_particle_id_reg2;
	reg [PARTICLE_ID_WIDTH-1:0] neighbor_particle_id_reg3;
	reg [PARTICLE_ID_WIDTH-1:0] neighbor_particle_id_reg4;
	reg [PARTICLE_ID_WIDTH-1:0] neighbor_particle_id_reg5;
	reg [PARTICLE_ID_WIDTH-1:0] neighbor_particle_id_reg6;
	reg [PARTICLE_ID_WIDTH-1:0] neighbor_particle_id_reg7;
	reg [PARTICLE_ID_WIDTH-1:0] neighbor_particle_id_reg8;
	reg [PARTICLE_ID_WIDTH-1:0] neighbor_particle_id_reg9;
	reg [PARTICLE_ID_WIDTH-1:0] neighbor_particle_id_reg10;
	reg [PARTICLE_ID_WIDTH-1:0] neighbor_particle_id_reg11;
	reg [PARTICLE_ID_WIDTH-1:0] neighbor_particle_id_reg12;
	reg [PARTICLE_ID_WIDTH-1:0] neighbor_particle_id_reg13;
	reg [PARTICLE_ID_WIDTH-1:0] neighbor_particle_id_reg14;
	reg [PARTICLE_ID_WIDTH-1:0] neighbor_particle_id_reg15;
	reg [PARTICLE_ID_WIDTH-1:0] neighbor_particle_id_reg16;
	reg [PARTICLE_ID_WIDTH-1:0] neighbor_particle_id_reg17;
	reg [PARTICLE_ID_WIDTH-1:0] neighbor_particle_id_reg18;
	reg [PARTICLE_ID_WIDTH-1:0] neighbor_particle_id_reg19;
	reg [PARTICLE_ID_WIDTH-1:0] neighbor_particle_id_reg20;
	reg [PARTICLE_ID_WIDTH-1:0] neighbor_particle_id_reg21;
	reg [PARTICLE_ID_WIDTH-1:0] neighbor_particle_id_reg22;
	reg [PARTICLE_ID_WIDTH-1:0] neighbor_particle_id_reg23;
	reg [PARTICLE_ID_WIDTH-1:0] neighbor_particle_id_reg24;
	reg [PARTICLE_ID_WIDTH-1:0] neighbor_particle_id_reg25;
	reg [PARTICLE_ID_WIDTH-1:0] neighbor_particle_id_reg26;
	reg [PARTICLE_ID_WIDTH-1:0] neighbor_particle_id_reg27;
	reg [PARTICLE_ID_WIDTH-1:0] neighbor_particle_id_reg28;
	reg [PARTICLE_ID_WIDTH-1:0] neighbor_particle_id_reg29;
	reg [PARTICLE_ID_WIDTH-1:0] neighbor_particle_id_delayed;
	// Assign output port
	assign ref_particle_id_out = ref_particle_id_delayed;
	assign neighbor_particle_id_out = neighbor_particle_id_delayed;
	// Delay register
	always@(posedge clk)
		begin
		if(rst)
			begin
			ref_particle_id_reg0 <= 0;
			ref_particle_id_reg1 <= 0;
			ref_particle_id_reg2 <= 0;
			ref_particle_id_reg3 <= 0;
			ref_particle_id_reg4 <= 0;
			ref_particle_id_reg5 <= 0;
			ref_particle_id_reg6 <= 0;
			ref_particle_id_reg7 <= 0;
			ref_particle_id_reg8 <= 0;
			ref_particle_id_reg9 <= 0;
			ref_particle_id_reg10 <= 0;
			ref_particle_id_reg11 <= 0;
			ref_particle_id_reg12 <= 0;
			ref_particle_id_reg13 <= 0;
			ref_particle_id_reg14 <= 0;
			ref_particle_id_reg15 <= 0;
			ref_particle_id_reg16 <= 0;
			ref_particle_id_reg17 <= 0;
			ref_particle_id_reg18 <= 0;
			ref_particle_id_reg19 <= 0;
			ref_particle_id_reg20 <= 0;
			ref_particle_id_reg21 <= 0;
			ref_particle_id_reg22 <= 0;
			ref_particle_id_reg23 <= 0;
			ref_particle_id_reg24 <= 0;
			ref_particle_id_reg25 <= 0;
			ref_particle_id_reg26 <= 0;
			ref_particle_id_reg27 <= 0;
			ref_particle_id_reg28 <= 0;
			ref_particle_id_reg29 <= 0;
			ref_particle_id_delayed <= 0;
			neighbor_particle_id_reg0 <= 0;
			neighbor_particle_id_reg1 <= 0;
			neighbor_particle_id_reg2 <= 0;
			neighbor_particle_id_reg3 <= 0;
			neighbor_particle_id_reg4 <= 0;
			neighbor_particle_id_reg5 <= 0;
			neighbor_particle_id_reg6 <= 0;
			neighbor_particle_id_reg7 <= 0;
			neighbor_particle_id_reg8 <= 0;
			neighbor_particle_id_reg9 <= 0;
			neighbor_particle_id_reg10 <= 0;
			neighbor_particle_id_reg11 <= 0;
			neighbor_particle_id_reg12 <= 0;
			neighbor_particle_id_reg13 <= 0;
			neighbor_particle_id_reg14 <= 0;
			neighbor_particle_id_reg15 <= 0;
			neighbor_particle_id_reg16 <= 0;
			neighbor_particle_id_reg17 <= 0;
			neighbor_particle_id_reg18 <= 0;
			neighbor_particle_id_reg19 <= 0;
			neighbor_particle_id_reg20 <= 0;
			neighbor_particle_id_reg21 <= 0;
			neighbor_particle_id_reg22 <= 0;
			neighbor_particle_id_reg23 <= 0;
			neighbor_particle_id_reg24 <= 0;
			neighbor_particle_id_reg25 <= 0;
			neighbor_particle_id_reg26 <= 0;
			neighbor_particle_id_reg27 <= 0;
			neighbor_particle_id_reg28 <= 0;
			neighbor_particle_id_reg29 <= 0;
			neighbor_particle_id_delayed <= 0;
			end
		else
			begin
			ref_particle_id_reg0 <= filter_out_ref_particle_id;
			ref_particle_id_reg1 <= ref_particle_id_reg0;
			ref_particle_id_reg2 <= ref_particle_id_reg1;
			ref_particle_id_reg3 <= ref_particle_id_reg2;
			ref_particle_id_reg4 <= ref_particle_id_reg3;
			ref_particle_id_reg5 <= ref_particle_id_reg4;
			ref_particle_id_reg6 <= ref_particle_id_reg5;
			ref_particle_id_reg7 <= ref_particle_id_reg6;
			ref_particle_id_reg8 <= ref_particle_id_reg7;
			ref_particle_id_reg9 <= ref_particle_id_reg8;
			ref_particle_id_reg10 <= ref_particle_id_reg9;
			ref_particle_id_reg11 <= ref_particle_id_reg10;
			ref_particle_id_reg12 <= ref_particle_id_reg11;
			ref_particle_id_reg13 <= ref_particle_id_reg12;
			ref_particle_id_reg14 <= ref_particle_id_reg13;
			ref_particle_id_reg15 <= ref_particle_id_reg14;
			ref_particle_id_reg16 <= ref_particle_id_reg15;
			ref_particle_id_reg17 <= ref_particle_id_reg16;
			ref_particle_id_reg18 <= ref_particle_id_reg17;
			ref_particle_id_reg19 <= ref_particle_id_reg18;
			ref_particle_id_reg20 <= ref_particle_id_reg19;
			ref_particle_id_reg21 <= ref_particle_id_reg20;
			ref_particle_id_reg22 <= ref_particle_id_reg21;
			ref_particle_id_reg23 <= ref_particle_id_reg22;
			ref_particle_id_reg24 <= ref_particle_id_reg23;
			ref_particle_id_reg25 <= ref_particle_id_reg24;
			ref_particle_id_reg26 <= ref_particle_id_reg25;
			ref_particle_id_reg27 <= ref_particle_id_reg26;
			ref_particle_id_reg28 <= ref_particle_id_reg27;
			ref_particle_id_reg29 <= ref_particle_id_reg28;
			ref_particle_id_delayed <= ref_particle_id_reg29;
			neighbor_particle_id_reg0 <= filter_out_neighbor_particle_id;
			neighbor_particle_id_reg1 <= neighbor_particle_id_reg0;
			neighbor_particle_id_reg2 <= neighbor_particle_id_reg1;
			neighbor_particle_id_reg3 <= neighbor_particle_id_reg2;
			neighbor_particle_id_reg4 <= neighbor_particle_id_reg3;
			neighbor_particle_id_reg5 <= neighbor_particle_id_reg4;
			neighbor_particle_id_reg6 <= neighbor_particle_id_reg5;
			neighbor_particle_id_reg7 <= neighbor_particle_id_reg6;
			neighbor_particle_id_reg8 <= neighbor_particle_id_reg7;
			neighbor_particle_id_reg9 <= neighbor_particle_id_reg8;
			neighbor_particle_id_reg10 <= neighbor_particle_id_reg9;
			neighbor_particle_id_reg11 <= neighbor_particle_id_reg10;
			neighbor_particle_id_reg12 <= neighbor_particle_id_reg11;
			neighbor_particle_id_reg13 <= neighbor_particle_id_reg12;
			neighbor_particle_id_reg14 <= neighbor_particle_id_reg13;
			neighbor_particle_id_reg15 <= neighbor_particle_id_reg14;
			neighbor_particle_id_reg16 <= neighbor_particle_id_reg15;
			neighbor_particle_id_reg17 <= neighbor_particle_id_reg16;
			neighbor_particle_id_reg18 <= neighbor_particle_id_reg17;
			neighbor_particle_id_reg19 <= neighbor_particle_id_reg18;
			neighbor_particle_id_reg20 <= neighbor_particle_id_reg19;
			neighbor_particle_id_reg21 <= neighbor_particle_id_reg20;
			neighbor_particle_id_reg22 <= neighbor_particle_id_reg21;
			neighbor_particle_id_reg23 <= neighbor_particle_id_reg22;
			neighbor_particle_id_reg24 <= neighbor_particle_id_reg23;
			neighbor_particle_id_reg25 <= neighbor_particle_id_reg24;
			neighbor_particle_id_reg26 <= neighbor_particle_id_reg25;
			neighbor_particle_id_reg27 <= neighbor_particle_id_reg26;
			neighbor_particle_id_reg28 <= neighbor_particle_id_reg27;
			neighbor_particle_id_reg29 <= neighbor_particle_id_reg28;
			neighbor_particle_id_delayed <= neighbor_particle_id_reg29;
			end
		end

	// Filters
	Filter_Bank_no_DSP
	#(
		.DATA_WIDTH(DATA_WIDTH),
		.NUM_FILTER(NUM_FILTER),
		.ARBITER_MSB(ARBITER_MSB),											// 2^(NUM_FILTER-1)
		.PARTICLE_ID_WIDTH(PARTICLE_ID_WIDTH),
		.FILTER_BUFFER_DEPTH(FILTER_BUFFER_DEPTH),
		.FILTER_BUFFER_ADDR_WIDTH(FILTER_BUFFER_ADDR_WIDTH),
		.CUTOFF_TIMES_SQRT_3(CUTOFF_TIMES_SQRT_3),					// sqrt(3) * CUTOFF
		.FIXED_POINT_WIDTH(FIXED_POINT_WIDTH),
		.FILTER_IN_PATCH_0_BITS(FILTER_IN_PATCH_0_BITS),			// Width = FIXED_POINT_WIDTH - 1 - 23
		.BOUNDING_BOX_X(BOUNDING_BOX_X),									// 12*9 = 108 in IEEE floating point
		.BOUNDING_BOX_Y(BOUNDING_BOX_Y),									// 12*9 = 108 in IEEE floating point
		.BOUNDING_BOX_Z(BOUNDING_BOX_Z)									// 12*7 = 84 in IEEE floating point
	)
	Filter_Bank
	(
		.clk(clk),
		.rst(rst),
		.input_valid(input_valid),
		.ref_particle_id(ref_particle_id),
		.neighbor_particle_id(neighbor_particle_id),
		.refx(refx),
		.refy(refy),
		.refz(refz),
		.neighborx(neighborx),
		.neighbory(neighbory),
		.neighborz(neighborz),
		.ref_particle_id_out(filter_out_ref_particle_id),
		.neighbor_particle_id_out(filter_out_neighbor_particle_id),
		.out_refx(filter_out_refx),
		.out_refy(filter_out_refy),
		.out_refz(filter_out_refz),
		.out_neighborx(filter_out_neighborx),
		.out_neighbory(filter_out_neighbory),
		.out_neighborz(filter_out_neighborz),
		.out_valid(filter_out_valid),
		.out_back_pressure_to_input(out_back_pressure_to_input),						// If one of the FIFO is full, then set the back_pressure flag to stop more incoming particle pairs
		.out_all_buffer_empty(out_all_buffer_empty_to_input)
	);
	
	// Evaluate r2 between particle pairs
	r2_compute #(
		.DATA_WIDTH(DATA_WIDTH)
	)
	r2_evaluate(
		.clk(clk),
		.rst(rst),
		.enable(filter_out_valid),
		.refx(filter_out_refx),
		.refy(filter_out_refy),
		.refz(filter_out_refz),
		.neighborx(filter_out_neighborx),
		.neighbory(filter_out_neighbory),
		.neighborz(filter_out_neighborz),
		.r2(r2_out_r2),
		.dx_out(r2_out_dx),
		.dy_out(r2_out_dy),
		.dz_out(r2_out_dz),
		.r2_valid(r2_out_valid)
	);

	// Evaluate Pair-wise LJ forces
	// Latency 14 cycles
	RL_LJ_Evaluate_Pairs_1st_Order #(
		.DATA_WIDTH(DATA_WIDTH),
		.SEGMENT_NUM(SEGMENT_NUM),
		.SEGMENT_WIDTH(SEGMENT_WIDTH),
		.BIN_WIDTH(BIN_WIDTH),
		.BIN_NUM(BIN_NUM),
		.CUTOFF_2(CUTOFF_2),
		.LOOKUP_NUM(LOOKUP_NUM),
		.LOOKUP_ADDR_WIDTH(LOOKUP_ADDR_WIDTH)
	)
	RL_LJ_Evaluate_Pairs_1st_Order(
		.clk(clk),
		.rst(rst),
		.r2_valid(r2_out_valid),
		.r2(r2_out_r2),
		.dx(r2_out_dx),
		.dy(r2_out_dy),
		.dz(r2_out_dz),
		.p_a(p_a),
		.p_b(p_b),
		.p_qq(p_qq),
		.LJ_Force_X(LJ_Force_X),
		.LJ_Force_Y(LJ_Force_Y),
		.LJ_Force_Z(LJ_Force_Z),
		.LJ_force_valid(forceoutput_valid)
	);



endmodule