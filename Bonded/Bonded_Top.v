/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: Bonded_Top.v
//
//	Function: 
//				Evaluate the Bonded Force Part in MD simulation
//				Including:
//						Bonded Force
//						Angle Force
//						Torsion Force
//
// Data Organization:
//				2 sets of memory:
//					Particle Data Memory, including Position and Force Data
//						Width: 32 * 3 = 96 bits
//						Depth: 20,000
//						Address Width: 15
//					Bond information memory, initialized by the input dataset, and remain unchanged during the simuluation process
//						Width:
//							Bond: 15*2 = 30
//							Angle: 15*3 = 45
//							Torsion: 15*4 = 60
//						Depth:
//							Bond: ~16,384
//							Angle: ~16,384
//							Torsion: ~16,384
//							
// **************************************************************************************************
// ************* OLD DESIGN *************************************************************************
// **************************************************************************************************
//		Bond packet 
// 		Width: 4'b0001 + 284(payload) = 288 bits
// 		MSB 4 bits :  0001 Bond term
// 		[283:92] then atom1 position: 32bits*3, atom2 position: 32:bits*3
// 		lower 92 bits: Atom1:14bits Atom2:14bits restLength 32 springConstant 32
// 	Angle packet
// 		Width: 4'b0010 + 458(payload) = 462 bits
//			MSB 4 bits :  0010 Angle term
// 		[457:170] atom1 position: 32bits*3, atom2 position: 32:bits*3, atom3 position: 32:bits*3
// 		lower 170 bits: Atom1:14bits Atom2:14bits Atom3:14bits 32'h40f51eb8 32 32'h402ef9db 32 32'h3f4ccccd 32 32'h3f4ccccd 32
// 	Torsion packet
// 		Width: 4'b0011 + 568(payload) = 572 bits
// 		MSB 4 bits :  0011 Torsion term
// 		[567:184] 
// 		lower 184 bits: Atom1:14bits Atom2:14bits Atom3:14bits Atom4:14bits multiplicity forceConstant periodicity phaseShift
//
// Dependency:
//				.v
//
// Testbench:
//				_tb.v
//
// Timing:
//				TBD				
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module Bonded_Top
#(
	parameter TOTAL_PARTICLE_NUM 				= 20000,
	parameter PARTICLE_GLOBAL_ID_WIDTH 		= 15,						// log(TOTAL_PARTICLE_NUM)/log(2)
	parameter BOND_PAIRS_NUM 					= 16384,
	parameter ANGLE_PAIRS_NUM 					= 16384,
	parameter TORSION_PAIRS_NUM 				= 16384,
	parameter BOND_PAIR_MEM_ADDR_WIDTH 		= 14
)
(
	input clk,
	input rst,
	input in_start_bond_evaluation,
	// Signals Connect to Motion Update output
	input in_Position_Mem_wr_en,
	input [PARTICLE_GLOBAL_ID_WIDTH-1:0] in_Position_Mem_wr_addr,
	input [32*3-1:0] in_Position_Mem_wr_data,
	// Signals Connect to Summation Logic
	input in_request_bonded_force,
	input [PARTICLE_GLOBAL_ID_WIDTH-1:0] in_Bonded_Force_rd_addr,
	output [32*3-1:0] out_Bonded_Force_rd_data,
	// Done signal
	output out_Bonded_Force_evaluation_done
	
);

	// Signals connect to controller
	// signifying which force is being evaluated. 1: bond, 2: angle, 3: torsion, 0: non
	wire [1:0] active_force_type;
	wire [PARTICLE_GLOBAL_ID_WIDTH-1:0] Pos_Mem_rd_addr_1, Pos_Mem_rd_addr_2;
	
	// Signals connect to Particle Memory
	wire [95:0] Pos_Mem_wr_data_1, Pos_Mem_wr_data_2;
	wire [PARTICLE_GLOBAL_ID_WIDTH-1:0] Pos_Mem_addr_1, Pos_Mem_addr_2;
	wire Pos_Mem_wr_en_1, Pos_Mem_wr_en_2;
	wire [95:0] Pos_Mem_rd_data_1, Pos_Mem_rd_data_2;
	reg [95:0] Pos_Mem_rd_data_1_Delay, Pos_Mem_rd_data_2_Delay;
	always@(posedge clk)
		begin
		Pos_Mem_rd_data_1_Delay <= Pos_Mem_rd_data_1;
		Pos_Mem_rd_data_2_Delay <= Pos_Mem_rd_data_2;
		end
	
	reg [95:0] F_Mem_wr_data_1, F_Mem_wr_data_2;
	reg [PARTICLE_GLOBAL_ID_WIDTH-1:0] F_Mem_addr_1, F_Mem_addr_2;
	reg F_Mem_wr_en_1, F_Mem_wr_en_2;
	wire [95:0] F_Mem_rd_data_1, F_Mem_rd_data_2;
	
	// Signals connect to Bonded Pair Memory
	wire [BOND_PAIR_MEM_ADDR_WIDTH-1:0] Bond_Mem_rd_addr;
	wire [BOND_PAIR_MEM_ADDR_WIDTH-1:0] Angle_Mem_rd_addr;
	wire [BOND_PAIR_MEM_ADDR_WIDTH-1:0] Torsion_Mem_rd_addr;
	wire [2*PARTICLE_GLOBAL_ID_WIDTH-1:0] Bond_Mem_rd_pairs;
	wire [3*PARTICLE_GLOBAL_ID_WIDTH-1:0] Angle_Mem_rd_pairs;
	wire [4*PARTICLE_GLOBAL_ID_WIDTH+128-1:0] Torsion_Mem_rd_pairs;
	
	// Signals connect to Pipeline Output
	wire [2*96-1:0] Bond_Force_out;
	wire [3*96-1:0] Angle_Force_out;
	wire [4*96-1:0] Torsion_Force_out;
	wire [2*PARTICLE_GLOBAL_ID_WIDTH-1:0] Bond_Particle_ID_out;
	wire [3*PARTICLE_GLOBAL_ID_WIDTH-1:0] Angle_Particle_ID_out;
	wire [4*PARTICLE_GLOBAL_ID_WIDTH-1:0] Torsion_Particle_ID_out;
	wire Bond_Force_valid, Angle_Force_valid, Torsion_Force_valid;
	
	/////////////////////////////////////////////////////////////////////////////////////////////
	// Dummy Control logic on Position Memory
	// 
	/////////////////////////////////////////////////////////////////////////////////////////////
	// Use Port 1 to update Position Memory
	assign Pos_Mem_wr_data_1 = in_Position_Mem_wr_data;
	assign Pos_Mem_addr_1 = (out_Bonded_Force_evaluation_done) ? in_Position_Mem_wr_addr : Pos_Mem_rd_addr_1;
	assign Pos_Mem_addr_2 = Pos_Mem_rd_addr_2;
	assign Pos_Mem_wr_en_1 = in_Position_Mem_wr_en;
	assign Pos_Mem_wr_en_2 = 1'b0;
	
	/////////////////////////////////////////////////////////////////////////////////////////////
	// Dummy Control logic on Force Memory
	// 
	/////////////////////////////////////////////////////////////////////////////////////////////
	// Use Port 1 to output the force data for summation logic
	assign out_Bonded_Force_rd_data = F_Mem_rd_data_1;
	
	always@(posedge clk)
		begin
		if(rst)
			begin
			F_Mem_wr_data_1 <= 0;
			F_Mem_wr_data_2 <= 0;
			F_Mem_addr_1 <= 0;
			F_Mem_addr_2 <= 0;
			F_Mem_wr_en_1 <= 1'b0;
			F_Mem_wr_en_2 <= 1'b0;
			end
		else
			begin
			// Need to rewrite the assignment to Force Memory input signals
			// !!!!! Need to Handle the cases of time multiplexing the Angle and Torsion force
			case(active_force_type)
				// Bond force write back
				2'b01:
					begin
					F_Mem_wr_data_1 <= Bond_Force_out[1*96-1:0*96];
					F_Mem_wr_data_2 <= Bond_Force_out[2*96-1:1*96];
					F_Mem_wr_en_1 <= 1'b1;
					F_Mem_wr_en_2 <= 1'b1;
					F_Mem_addr_2 <= Bond_Particle_ID_out[2*PARTICLE_GLOBAL_ID_WIDTH-1:1*PARTICLE_GLOBAL_ID_WIDTH];
					F_Mem_addr_1 <= (in_request_bonded_force) ? in_Bonded_Force_rd_addr : Bond_Particle_ID_out[1*PARTICLE_GLOBAL_ID_WIDTH-1:0*PARTICLE_GLOBAL_ID_WIDTH];
					end
				// Angle force write back
				2'b10:
					begin
					F_Mem_wr_data_1 <= Angle_Force_out[1*96-1:0*96];
					F_Mem_wr_data_2 <= Angle_Force_out[2*96-1:1*96] | Angle_Force_out[3*96-1:2*96];
					F_Mem_wr_en_1 <= 1'b1;
					F_Mem_wr_en_2 <= 1'b1;
					F_Mem_addr_2 <= Angle_Particle_ID_out[2*PARTICLE_GLOBAL_ID_WIDTH-1:1*PARTICLE_GLOBAL_ID_WIDTH] | Angle_Particle_ID_out[3*PARTICLE_GLOBAL_ID_WIDTH-1:2*PARTICLE_GLOBAL_ID_WIDTH];
					F_Mem_addr_1 <= (in_request_bonded_force) ? in_Bonded_Force_rd_addr : Angle_Particle_ID_out[1*PARTICLE_GLOBAL_ID_WIDTH-1:0*PARTICLE_GLOBAL_ID_WIDTH];
					end
				// Torsion force write back
				2'b11:
					begin
					F_Mem_wr_data_1 <= Torsion_Force_out[1*96-1:0*96] | Torsion_Force_out[3*96-1:2*96];
					F_Mem_wr_data_2 <= Torsion_Force_out[2*96-1:1*96] | Torsion_Force_out[4*96-1:3*96];
					F_Mem_wr_en_1 <= 1'b1;
					F_Mem_wr_en_2 <= 1'b1;
					F_Mem_addr_2 <= Torsion_Particle_ID_out[2*PARTICLE_GLOBAL_ID_WIDTH-1:1*PARTICLE_GLOBAL_ID_WIDTH] | Torsion_Particle_ID_out[4*PARTICLE_GLOBAL_ID_WIDTH-1:3*PARTICLE_GLOBAL_ID_WIDTH];
					F_Mem_addr_1 <= (in_request_bonded_force) ? in_Bonded_Force_rd_addr : (Torsion_Particle_ID_out[1*PARTICLE_GLOBAL_ID_WIDTH-1:0*PARTICLE_GLOBAL_ID_WIDTH] | Torsion_Particle_ID_out[3*PARTICLE_GLOBAL_ID_WIDTH-1:2*PARTICLE_GLOBAL_ID_WIDTH]);
					end
				default:
					begin
					F_Mem_wr_data_1 <= 0;
					F_Mem_wr_data_2 <= 0;
					F_Mem_addr_1 <= 0;
					F_Mem_addr_2 <= 0;
					F_Mem_wr_en_1 <= 1'b0;
					F_Mem_wr_en_2 <= 1'b0;
					end
			endcase
			end
		end
	
	/////////////////////////////////////////////////////////////////////////////////////////////
	// Controller respsonsible for Read Pair and Position Memory
	/////////////////////////////////////////////////////////////////////////////////////////////
	Bonded_MEM_Controller
	#(
		.TOTAL_PARTICLE_NUM(TOTAL_PARTICLE_NUM),
		.PARTICLE_GLOBAL_ID_WIDTH(PARTICLE_GLOBAL_ID_WIDTH),
		.BOND_PAIRS_NUM(BOND_PAIRS_NUM),
		.ANGLE_PAIRS_NUM(ANGLE_PAIRS_NUM),
		.TORSION_PAIRS_NUM(TORSION_PAIRS_NUM),
		.BOND_PAIR_MEM_ADDR_WIDTH(BOND_PAIR_MEM_ADDR_WIDTH)
	)
	Bonded_MEM_Controller
	(
		.clk(clk),
		.rst(rst),
		.in_start(in_start_bond_evaluation),
		//	Output singal signifying all the bonded pairs has done fetching, remain high till the next start signal arrive
		.out_done(out_Bonded_Force_evaluation_done),
		// Ports connect to Bonded Pair MEM
		.in_Bond_Mem_rd_pairs(Bond_Mem_rd_pairs),
		.in_Angle_Mem_rd_pairs(Angle_Mem_rd_pairs),
		.in_Torsion_Mem_rd_pairs(Torsion_Mem_rd_pairs[4*PARTICLE_GLOBAL_ID_WIDTH-1:0]),
		.out_Bond_Mem_rd_addr(Bond_Mem_rd_addr),
		.out_Angle_Mem_rd_addr(Angle_Mem_rd_addr),
		.out_Torsion_Mem_rd_addr(Torsion_Mem_rd_addr),
		// Ports connect to Particle Position MEM
		.out_Position_Mem_rd_addr_1(Pos_Mem_rd_addr_1),
		.out_Position_Mem_rd_addr_2(Pos_Mem_rd_addr_2),
		// signifying which force is being evaluated. 1: bond, 2: angle, 3: torsion, 0: non
		.out_current_active_force(active_force_type)
	);
	
	/////////////////////////////////////////////////////////////////////////////////////////////
	// Particle Memory
	// Read and Write
	/////////////////////////////////////////////////////////////////////////////////////////////
	// Position Memory, Ture Dual Ports
	// Datawidth: 96 bits (32 * 3)
	// Depth: 20,000
	// Organized based on Initial Input Particle ID
	DualPortRam Position_Mem (
		.clock     (clk),
		// Address Input, 2 sources of input: Force Evaluation, and Position Update
		.address_a (Pos_Mem_addr_1),
		.address_b (Pos_Mem_addr_2),
		// Ports used for Bonded Force Evaluation
		.q_a       (Pos_Mem_rd_data_1),
		.q_b       (Pos_Mem_rd_data_2),
		// Ports used for Motion Update
		.wren_a    (Pos_Mem_wr_en_1),
		.wren_b    (Pos_Mem_wr_en_2),
		.data_a    (Pos_Mem_wr_data_1),
		.data_b    (Pos_Mem_wr_data_2)		
	);
	
	// Force Memory, Ture Dual Ports
	// Datawidth: 96 bits (32 * 3)
	// Depth: 20,000
	// Organized based on Initial Input Particle ID
	DualPortRam Force_Mem (
		.clock     (clk),
		// Address Input, 2 sources of input: Force Evaluation, and Position Update
		.address_a (F_Mem_addr_1),
		.address_b (F_Mem_addr_2),
		// Ports used for Bonded Force Accumulation and Motion Update
		.q_a       (F_Mem_rd_data_1),
		.q_b       (F_Mem_rd_data_2),
		// Ports used for Bonded Force Accumulation
		.wren_a    (F_Mem_wr_en_1),
		.wren_b    (F_Mem_wr_en_2),
		.data_a    (F_Mem_wr_data_1),
		.data_b    (F_Mem_wr_data_2)
	);

	/////////////////////////////////////////////////////////////////////////////////////////////
	// Bonded Pairs Memory (ROM)
	// Read Only
	// Address 0 has total number of particle pairs
	/////////////////////////////////////////////////////////////////////////////////////////////
	// Bond Pairs Memory
	Bond_Pair_MEM
	#(
		.DATA_WIDTH(15*2),
		.PARTICLE_NUM(BOND_PAIRS_NUM),
		.ADDR_WIDTH(BOND_PAIR_MEM_ADDR_WIDTH)
	)
	Bond_Pair_MEM
	(
		.address(Bond_Mem_rd_addr),
		.clock(clk),
		.q(Bond_Mem_rd_pairs)
	);
	// Angle Pairs Memory
	Angle_Pair_MEM
	#(
		.DATA_WIDTH(15*3),
		.PARTICLE_NUM(ANGLE_PAIRS_NUM),
		.ADDR_WIDTH(BOND_PAIR_MEM_ADDR_WIDTH)
	)
	Angle_Pair_MEM
	(
		.address(Angle_Mem_rd_addr),
		.clock(clk),
		.q(Angle_Mem_rd_pairs)
	);
	// Torsion Pairs Memory
	Torsion_Pair_MEM
	#(
		.DATA_WIDTH(15*4+128),
		.PARTICLE_NUM(TORSION_PAIRS_NUM),
		.ADDR_WIDTH(BOND_PAIR_MEM_ADDR_WIDTH)
	)
	Torsion_Pair_MEM
	(
		.address(Torsion_Mem_rd_addr),
		.clock(clk),
		.q(Torsion_Mem_rd_pairs)
	);
	
	
	/////////////////////////////////////////////////////////////////////////////////////////////
	// Bonded Pairs Memory (ROM)
	// Read Only
	// Address 0 has total number of particle pairs
	/////////////////////////////////////////////////////////////////////////////////////////////
	calcBond_v2
	#(
		.PARTICLE_GLOBAL_ID_WIDTH(PARTICLE_GLOBAL_ID_WIDTH)
	)
	bond_force_pipeline
	(
		.clk(clk),
		.rst(rst),
		.in_Particle_Pos_1(Pos_Mem_rd_data_1),
		.in_Particle_Pos_2(Pos_Mem_rd_data_2),
		.in_Particle_ID_1(Bond_Mem_rd_pairs[1*PARTICLE_GLOBAL_ID_WIDTH-1:0*PARTICLE_GLOBAL_ID_WIDTH]),
		.in_Particle_ID_2(Bond_Mem_rd_pairs[2*PARTICLE_GLOBAL_ID_WIDTH-1:1*PARTICLE_GLOBAL_ID_WIDTH]),
		.out_Bond_Force_out_1(Bond_Force_out[1*96-1:0*96]),
		.out_Bond_Force_out_2(Bond_Force_out[2*96-1:1*96]),
		.out_Particle_ID_1(Bond_Particle_ID_out[1*PARTICLE_GLOBAL_ID_WIDTH-1:0*PARTICLE_GLOBAL_ID_WIDTH]),
		.out_Particle_ID_2(Bond_Particle_ID_out[2*PARTICLE_GLOBAL_ID_WIDTH-1:1*PARTICLE_GLOBAL_ID_WIDTH])
		//.out_Bond_Force_valid(Bond_Force_valid)
	);

	calcAngle_v2
	#(
		.PARTICLE_GLOBAL_ID_WIDTH(PARTICLE_GLOBAL_ID_WIDTH)
	)
	angle_force_pipeline
	(
		.clk(clk),
		.rst(rst),
		.in_Particle_Pos_1(Pos_Mem_rd_data_1),
		.in_Particle_Pos_2(Pos_Mem_rd_data_2),
		.in_Particle_Pos_3(Pos_Mem_rd_data_1_Delay),
		.in_Particle_ID_1(Angle_Mem_rd_pairs[1*PARTICLE_GLOBAL_ID_WIDTH-1:0*PARTICLE_GLOBAL_ID_WIDTH]),
		.in_Particle_ID_2(Angle_Mem_rd_pairs[2*PARTICLE_GLOBAL_ID_WIDTH-1:1*PARTICLE_GLOBAL_ID_WIDTH]),
		.in_Particle_ID_3(Angle_Mem_rd_pairs[3*PARTICLE_GLOBAL_ID_WIDTH-1:2*PARTICLE_GLOBAL_ID_WIDTH]),
		.out_Angle_Force_1(Angle_Force_out[1*96-1:0*96]),
		.out_Angle_Force_2(Angle_Force_out[2*96-1:1*96]),
		.out_Angle_Force_3(Angle_Force_out[3*96-1:2*96]),
		.out_Particle_ID_1(Angle_Particle_ID_out[1*PARTICLE_GLOBAL_ID_WIDTH-1:0*PARTICLE_GLOBAL_ID_WIDTH]),
		.out_Particle_ID_2(Angle_Particle_ID_out[2*PARTICLE_GLOBAL_ID_WIDTH-1:1*PARTICLE_GLOBAL_ID_WIDTH]),
		.out_Particle_ID_3(Angle_Particle_ID_out[3*PARTICLE_GLOBAL_ID_WIDTH-1:2*PARTICLE_GLOBAL_ID_WIDTH])
		//.out_Angle_Force_valid(Angle_Force_valid)
	);

	calcTorsion_v2
	#(
		.PARTICLE_GLOBAL_ID_WIDTH(PARTICLE_GLOBAL_ID_WIDTH)
	)
	torsion_force_pipeline
	(
		.clk(clk),
		.rst(rst),
		.in_Particle_Pos_1(Pos_Mem_rd_data_1),
		.in_Particle_Pos_2(Pos_Mem_rd_data_2),
		.in_Particle_Pos_3(Pos_Mem_rd_data_1_Delay),
		.in_Particle_Pos_4(Pos_Mem_rd_data_2_Delay),
		.in_Particle_ID_1(Torsion_Mem_rd_pairs[1*PARTICLE_GLOBAL_ID_WIDTH-1:0*PARTICLE_GLOBAL_ID_WIDTH]),
		.in_Particle_ID_2(Torsion_Mem_rd_pairs[2*PARTICLE_GLOBAL_ID_WIDTH-1:1*PARTICLE_GLOBAL_ID_WIDTH]),
		.in_Particle_ID_3(Torsion_Mem_rd_pairs[3*PARTICLE_GLOBAL_ID_WIDTH-1:2*PARTICLE_GLOBAL_ID_WIDTH]),
		.in_Particle_ID_4(Torsion_Mem_rd_pairs[4*PARTICLE_GLOBAL_ID_WIDTH-1:3*PARTICLE_GLOBAL_ID_WIDTH]),
		.in_Torsion_Param(Torsion_Mem_rd_pairs[4*PARTICLE_GLOBAL_ID_WIDTH+127:4*PARTICLE_GLOBAL_ID_WIDTH]),
		.out_Torsion_Force_1(Torsion_Force_out[1*96-1:0*96]),
		.out_Torsion_Force_2(Torsion_Force_out[2*96-1:1*96]),
		.out_Torsion_Force_3(Torsion_Force_out[3*96-1:2*96]),
		.out_Torsion_Force_4(Torsion_Force_out[4*96-1:3*96]),
		.out_Particle_ID_1(Torsion_Particle_ID_out[1*PARTICLE_GLOBAL_ID_WIDTH-1:0*PARTICLE_GLOBAL_ID_WIDTH]),
		.out_Particle_ID_2(Torsion_Particle_ID_out[2*PARTICLE_GLOBAL_ID_WIDTH-1:1*PARTICLE_GLOBAL_ID_WIDTH]),
		.out_Particle_ID_3(Torsion_Particle_ID_out[3*PARTICLE_GLOBAL_ID_WIDTH-1:2*PARTICLE_GLOBAL_ID_WIDTH]),
		.out_Particle_ID_4(Torsion_Particle_ID_out[4*PARTICLE_GLOBAL_ID_WIDTH-1:3*PARTICLE_GLOBAL_ID_WIDTH])
		//.out_Torsion_Force_valid(Torsion_Force_valid)
	);



endmodule