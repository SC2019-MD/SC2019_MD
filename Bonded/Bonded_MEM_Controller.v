/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// 
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module Bonded_MEM_Controller
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
	input in_start,
	output reg out_done,														//	 output singal signifying all the bonded pairs has done fetching, remain high till the next start signal arrive
	// Ports connect to Bonded Pair MEM
	input [2*PARTICLE_GLOBAL_ID_WIDTH-1:0] in_Bond_Mem_rd_pairs,
	input [3*PARTICLE_GLOBAL_ID_WIDTH-1:0] in_Angle_Mem_rd_pairs,
	input [4*PARTICLE_GLOBAL_ID_WIDTH-1:0] in_Torsion_Mem_rd_pairs,
	output reg [BOND_PAIR_MEM_ADDR_WIDTH-1:0] out_Bond_Mem_rd_addr,
	output reg [BOND_PAIR_MEM_ADDR_WIDTH-1:0] out_Angle_Mem_rd_addr,
	output reg [BOND_PAIR_MEM_ADDR_WIDTH-1:0] out_Torsion_Mem_rd_addr,
	// Ports connect to Particle Position MEM
	output reg [PARTICLE_GLOBAL_ID_WIDTH-1:0] out_Position_Mem_rd_addr_1,
	output reg [PARTICLE_GLOBAL_ID_WIDTH-1:0] out_Position_Mem_rd_addr_2,
	// signifying which force is being evaluated. 1: bond, 2: angle, 3: torsion, 0: non
	output [1:0] out_current_active_force
);
	
	// Bonded Pair Mem related signals
	parameter WAIT_FOR_START = 3'b000;
	parameter FETCH_MEM_DEPTH = 3'b001;
	parameter FETCH_BOND_MEM = 3'b010;
	parameter FETCH_ANGLE_MEM = 3'b011;
	parameter FETCH_TORSION_MEM = 3'b100;
	parameter DONE = 3'b101;
	reg [2:0] state;
	reg [1:0] tmp_counter = 0;
	// counters for number of pairs of each type
	reg [BOND_PAIR_MEM_ADDR_WIDTH-1:0] bond_pair_num, angle_pair_num, torsion_pair_num;
	// signifying which pair mem is being fetched. 1: bond, 2: angle, 3: torsion, 0: non
	reg [1:0] current_active_pair_mem;
	assign out_current_active_force = current_active_pair_mem;
	

	////////////////////////////////////////////////////////////////////////////////////////////
	// Control the read from Bonded Pair MEM
	////////////////////////////////////////////////////////////////////////////////////////////
	always@(posedge clk)
		begin
		if(rst)
			begin
			state <= WAIT_FOR_START;
			tmp_counter <= 0;
			current_active_pair_mem <= 2'd0;
			bond_pair_num <= 0;
			angle_pair_num <= 0;
			torsion_pair_num <= 0;
			out_Bond_Mem_rd_addr <= 0;
			out_Angle_Mem_rd_addr <= 0;
			out_Torsion_Mem_rd_addr <= 0;
			out_done <= 1'b0;
			end
		else
			begin
			case(state)
				WAIT_FOR_START:
					begin
					tmp_counter <= 0;
					current_active_pair_mem <= 2'd0;
					bond_pair_num <= bond_pair_num;
					angle_pair_num <= angle_pair_num;
					torsion_pair_num <= torsion_pair_num;
					out_Bond_Mem_rd_addr <= 0;
					out_Angle_Mem_rd_addr <= 0;
					out_Torsion_Mem_rd_addr <= 0;
					out_done <= out_done;
					if(in_start)
						begin
						state <= FETCH_MEM_DEPTH;
						end
					else
						begin
						state <= WAIT_FOR_START;
						end
					end
				FETCH_MEM_DEPTH:
					begin
					tmp_counter <= 0;
					current_active_pair_mem <= 2'd0;
					bond_pair_num <= in_Bond_Mem_rd_pairs[BOND_PAIR_MEM_ADDR_WIDTH-1:0];
					angle_pair_num <= in_Angle_Mem_rd_pairs[BOND_PAIR_MEM_ADDR_WIDTH-1:0];
					torsion_pair_num <= in_Torsion_Mem_rd_pairs[BOND_PAIR_MEM_ADDR_WIDTH-1:0];
					out_Bond_Mem_rd_addr <= 1;
					out_Angle_Mem_rd_addr <= 0;
					out_Torsion_Mem_rd_addr <= 0;
					out_done <= 1'b0;
					
					state <= FETCH_BOND_MEM;
					end
				FETCH_BOND_MEM:
					begin
					tmp_counter <= 0;
					current_active_pair_mem <= 2'd1;
					bond_pair_num <= bond_pair_num;
					angle_pair_num <= angle_pair_num;
					torsion_pair_num <= torsion_pair_num;
					out_done <= 1'b0;
					// Read one pair out each cycle
					if(out_Bond_Mem_rd_addr < bond_pair_num)
						begin
						out_Bond_Mem_rd_addr <= out_Bond_Mem_rd_addr + 1'b1;
						out_Angle_Mem_rd_addr <= 0;
						out_Torsion_Mem_rd_addr <= out_Torsion_Mem_rd_addr;
						state <= FETCH_BOND_MEM;
						end
					else
						begin
						out_Bond_Mem_rd_addr <= out_Bond_Mem_rd_addr;
						out_Angle_Mem_rd_addr <= 1;
						out_Torsion_Mem_rd_addr <= out_Torsion_Mem_rd_addr;
						state <= FETCH_ANGLE_MEM;
						end
					end
				FETCH_ANGLE_MEM:
					begin
					current_active_pair_mem <= 2'd2;
					if (tmp_counter == 2)
						begin
						tmp_counter <= 0;
						end
					else
						begin
						tmp_counter <= tmp_counter + 1'b1;
						end
					bond_pair_num <= bond_pair_num;
					angle_pair_num <= angle_pair_num;
					torsion_pair_num <= torsion_pair_num;
					out_done <= 1'b0;
					// Read 2 pairs out every 3 cycles
					if(out_Angle_Mem_rd_addr < angle_pair_num)
						begin
						out_Bond_Mem_rd_addr <= out_Bond_Mem_rd_addr;
						out_Torsion_Mem_rd_addr <= out_Torsion_Mem_rd_addr;
						if(tmp_counter == 0 || tmp_counter == 1)
							begin
							out_Angle_Mem_rd_addr <= out_Angle_Mem_rd_addr + 1'b1;
							end
						else
							begin
							out_Angle_Mem_rd_addr <= out_Angle_Mem_rd_addr;
							end
						state <= FETCH_BOND_MEM;
						end
					else
						begin
						out_Bond_Mem_rd_addr <= out_Bond_Mem_rd_addr;
						out_Angle_Mem_rd_addr <= out_Angle_Mem_rd_addr;
						out_Torsion_Mem_rd_addr <= 1;
						state <= FETCH_TORSION_MEM;
						end
					end
				FETCH_TORSION_MEM:
					begin
					tmp_counter <= tmp_counter + 1'b1;
					current_active_pair_mem <= 2'd3;
					bond_pair_num <= bond_pair_num;
					angle_pair_num <= angle_pair_num;
					torsion_pair_num <= torsion_pair_num;
					out_done <= 1'b0;
					// Read one pair out every other cycle
					if(out_Angle_Mem_rd_addr < angle_pair_num)
						begin
						out_Bond_Mem_rd_addr <= out_Bond_Mem_rd_addr;
						out_Angle_Mem_rd_addr <= out_Angle_Mem_rd_addr;
						if(tmp_counter == 1 || tmp_counter == 3)
							begin
							out_Torsion_Mem_rd_addr <= out_Torsion_Mem_rd_addr+1'b1;
							end
						else
							begin
							out_Torsion_Mem_rd_addr <= out_Torsion_Mem_rd_addr;
							end
						state <= FETCH_BOND_MEM;
						end
					else
						begin
						out_Bond_Mem_rd_addr <= out_Bond_Mem_rd_addr;
						out_Angle_Mem_rd_addr <= out_Angle_Mem_rd_addr;
						out_Torsion_Mem_rd_addr <= out_Torsion_Mem_rd_addr;
						state <= DONE;
						end
					end
				DONE:
					begin
					tmp_counter <= 0;
					current_active_pair_mem <= 2'd0;
					bond_pair_num <= bond_pair_num;
					angle_pair_num <= angle_pair_num;
					torsion_pair_num <= torsion_pair_num;
					out_Bond_Mem_rd_addr <= out_Bond_Mem_rd_addr;
					out_Angle_Mem_rd_addr <= out_Angle_Mem_rd_addr;
					out_Torsion_Mem_rd_addr <= out_Torsion_Mem_rd_addr;
					out_done <= 1'b1;
					state <= WAIT_FOR_START;
					end
				default:
					begin
					state <= WAIT_FOR_START;
					tmp_counter <= 0;
					current_active_pair_mem <= 2'd0;
					bond_pair_num <= 0;
					angle_pair_num <= 0;
					torsion_pair_num <= 0;
					out_Bond_Mem_rd_addr <= 0;
					out_Angle_Mem_rd_addr <= 0;
					out_Torsion_Mem_rd_addr <= 0;
					out_done <= 1'b0;
					end
			endcase
			end
		end
	
		////////////////////////////////////////////////////////////////////////////////////////////
		// Control the read from Particle Position MEM
		////////////////////////////////////////////////////////////////////////////////////////////
		always@(posedge clk)
			begin
			if(rst)
				begin
				out_Position_Mem_rd_addr_1 <= 0;
				out_Position_Mem_rd_addr_2 <= 0;
				end
			else
				begin
				case(current_active_pair_mem)
					2'd1:
						begin
						out_Position_Mem_rd_addr_1 <= in_Bond_Mem_rd_pairs[1*PARTICLE_GLOBAL_ID_WIDTH-1:0*PARTICLE_GLOBAL_ID_WIDTH];
						out_Position_Mem_rd_addr_2 <= in_Bond_Mem_rd_pairs[2*PARTICLE_GLOBAL_ID_WIDTH-1:1*PARTICLE_GLOBAL_ID_WIDTH];
						end
					2'd2:
						begin
						if(tmp_counter == 1)
							begin
							out_Position_Mem_rd_addr_1 <= in_Angle_Mem_rd_pairs[1*PARTICLE_GLOBAL_ID_WIDTH-1:0*PARTICLE_GLOBAL_ID_WIDTH];
							out_Position_Mem_rd_addr_2 <= in_Angle_Mem_rd_pairs[2*PARTICLE_GLOBAL_ID_WIDTH-1:1*PARTICLE_GLOBAL_ID_WIDTH];
							end
						else if(tmp_counter == 2)
							begin
							out_Position_Mem_rd_addr_1 <= in_Angle_Mem_rd_pairs[3*PARTICLE_GLOBAL_ID_WIDTH-1:2*PARTICLE_GLOBAL_ID_WIDTH];
							out_Position_Mem_rd_addr_2 <= in_Angle_Mem_rd_pairs[1*PARTICLE_GLOBAL_ID_WIDTH-1:0*PARTICLE_GLOBAL_ID_WIDTH];
							end
						else
							begin
							out_Position_Mem_rd_addr_1 <= in_Angle_Mem_rd_pairs[2*PARTICLE_GLOBAL_ID_WIDTH-1:1*PARTICLE_GLOBAL_ID_WIDTH];
							out_Position_Mem_rd_addr_2 <= in_Angle_Mem_rd_pairs[3*PARTICLE_GLOBAL_ID_WIDTH-1:2*PARTICLE_GLOBAL_ID_WIDTH];
							end
						end
					2'd3:
						begin
						if(tmp_counter == 0 || tmp_counter == 1)
							begin
							out_Position_Mem_rd_addr_1 <= in_Torsion_Mem_rd_pairs[1*PARTICLE_GLOBAL_ID_WIDTH-1:0*PARTICLE_GLOBAL_ID_WIDTH];
							out_Position_Mem_rd_addr_2 <= in_Torsion_Mem_rd_pairs[2*PARTICLE_GLOBAL_ID_WIDTH-1:1*PARTICLE_GLOBAL_ID_WIDTH];
							end
						else //if(tmp_counter == 2 || tmp_counter == 3)
							begin
							out_Position_Mem_rd_addr_1 <= in_Torsion_Mem_rd_pairs[3*PARTICLE_GLOBAL_ID_WIDTH-1:2*PARTICLE_GLOBAL_ID_WIDTH];
							out_Position_Mem_rd_addr_2 <= in_Torsion_Mem_rd_pairs[4*PARTICLE_GLOBAL_ID_WIDTH-1:3*PARTICLE_GLOBAL_ID_WIDTH];
							end
						end
					default:
						begin
						out_Position_Mem_rd_addr_1 <= 0;
						out_Position_Mem_rd_addr_2 <= 0;
						end
				endcase
				end
			end

endmodule