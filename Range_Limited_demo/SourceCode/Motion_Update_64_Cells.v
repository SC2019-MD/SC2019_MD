/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: Motion_Update_64_Cells.v
//
//	Function: 
//				Perform motion update based on the accumulated force inside each cells
//				Determine target cell: pos >= low boundary && pos < high boundary
//
// Datapath:
//				Global control send in the motion update start signal
//				Receive data from:
//						Position Cache
//						Force Cache
//						Velocity Cache
//				Send data to:
//						Position Cache
//
// Data Organization:
//				particle_position [3*DATA_WIDTH-1:0]: {posz, posy, posx}
//				particle_velocity [3*DATA_WIDTH-1:0]: {vz, vy, vx}
//				force [3*DATA_WIDTH-1:0]: {Force_Z, Force_Y, Force_X}
//				particle_id [CELL_ADDR_WIDTH-1:0]: {cell_x, cell_y, cell_z, particle_in_cell_rd_addr}
//				destination_cell: {cell_x, cell_y, cell_z}
//
// Used by:
//				RL_LJ_Top_64_Cells.v
//
// Dependency:
//				FP_MUL_ADD.v 					(5 cycles)
//				FP_ADD.v 						(3 cycles)
//				FP_GreaterThan_or_Equal.v 	(4 cycle)
//				FP_LessThan.v					(4 cycle)
//				cell_boundary_mem_64_Cells.v 			(1 cycle)
//
// Testbench:
//				Motion_Update_tb.v
//
// Timing:
//				Total of 17 cycles: from the read address is address to the output valid
//				Plus in the beginning, there is 1 extra cycle to read in how many particles are in the current cell
//				Read in data: total of 3 cycles
//						From Pos Cache & Velocity Cache: 2 cycles delay: after read address is assigned, there are 2 cycles delay from the upstream cache module
//						From Force Cache: 3 cycles delay: 1 cycle for registering the input read address, 1 cycle to readout data, 1 cycle to register the output
//						In order to conpensate the 1 cycle extra read delay from force cache, delay the input from Velocity cache by one cycle
//				Data processing latency: 				total of 14 cycles
//						Evaluate Speed: 					5 cycles
//						Evaluate Position:				5 cycles
//						Compare with boundary value:	4 cycle
//
// To do:
//				0, after motion update, there need to be a mechanism to clear all the force value in the cache
//				0.1, apply boundary condition when assigning the target cell
//				1, Working on multiple cells???
//				2, arrival latency variance: after the read address is assigned, the postion data will come in the next cycle, but the force value will come in 2 cycles....
//
// Created by: 
//				Chen Yang 12/25/18
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module Motion_Update_64_Cells
#(
	parameter DATA_WIDTH 					= 32,											// Data width of a single force value, 32-bit
	parameter TIME_STEP 						= 32'h27101D7D,							// 2fs time step
	parameter GLOBAL_CELL_ADDR_LEN		= 7,
	// Dataset defined parameters
	parameter X_DIM							= 4,
	parameter Y_DIM							= 4,
	parameter Z_DIM							= 4,
	parameter TOTAL_CELL_NUM				= 64,
	parameter MAX_CELL_COUNT_PER_DIM 	= 7,											// Maximum cell count among the 3 dimensions
	parameter CELL_ID_WIDTH					= 4,											// log(NUM_NEIGHBOR_CELLS)
	parameter MAX_CELL_PARTICLE_NUM		= 290,										// The maximum # of particles can be in a cell
	parameter CELL_ADDR_WIDTH				= 9,											// log(MAX_CELL_PARTICLE_NUM)
	parameter PARTICLE_ID_WIDTH			= CELL_ID_WIDTH*3+CELL_ADDR_WIDTH	// # of bit used to represent particle ID, 9*9*7 cells, each 4-bit, each cell have max of 220 particles, 8-bit
)
(
	input clk,
	input rst,
	input motion_update_start,																// Only need to keep high for 1 cycle
	output reg motion_update_done,														// Remain high until the next motion update starts
	// Output the targeting home cell
	// When this module is responsible for multiple cells, then the control signal is broadcast to multiple cells, while a mux need to implement on the input side to select from those cells
	output [CELL_ID_WIDTH-1:0] out_cur_working_cell_x,
	output [CELL_ID_WIDTH-1:0] out_cur_working_cell_y,
	output [CELL_ID_WIDTH-1:0] out_cur_working_cell_z,
	// Read from Position Cache
	input [3*DATA_WIDTH-1:0] in_position_data,
	output out_position_cache_rd_en,
	output [CELL_ADDR_WIDTH-1:0] out_position_cache_rd_addr,
	// Read from Force Cache
	input [3*DATA_WIDTH-1:0] in_force_data,
	output out_force_cache_rd_en,
	output [CELL_ADDR_WIDTH-1:0] out_force_cache_rd_addr,
	// Read from Velocity Cache
	input [3*DATA_WIDTH-1:0] in_velocity_data,
	output out_velocity_cache_rd_en,
	output [CELL_ADDR_WIDTH-1:0] out_velocity_cache_rd_addr,
	// Motion update enable signal
	output reg out_motion_update_enable,											// Remain high during the entire motion update process
	// Write back to Velocity Cache
	output [3*DATA_WIDTH-1:0] out_velocity_data,									// The updated velocity value
	output out_velocity_data_valid,
	output [3*CELL_ID_WIDTH-1:0] out_velocity_destination_cell,
	// Write back to Position Cache
	output [3*DATA_WIDTH-1:0] out_position_data,
	output out_position_data_valid,
	output [3*CELL_ID_WIDTH-1:0] out_position_destination_cell,
	// Tell the upper module which home cell is being processed so the correct data shall be provided
	output [GLOBAL_CELL_ADDR_LEN-1:0] out_cell_num
);
	
	reg [CELL_ID_WIDTH-1:0] CELL_X;
	reg [CELL_ID_WIDTH-1:0] CELL_Y;
	reg [CELL_ID_WIDTH-1:0] CELL_Z;
	reg [GLOBAL_CELL_ADDR_LEN-1:0] homecell_num;
	assign out_cell_num = homecell_num;
	// Assign temperal output ports
	// Suppose each motion module only work for a single cell
	assign out_cur_working_cell_x = CELL_X;
	assign out_cur_working_cell_y = CELL_Y;
	assign out_cur_working_cell_z = CELL_Z;
	
	/////////////////////////////////////////////////////////////////////////////////////////////////
	// Signals connected from Input ports
	/////////////////////////////////////////////////////////////////////////////////////////////////
	// Assign simulation timestep for speed and position update
	wire [DATA_WIDTH-1:0] time_step;
	assign time_step = TIME_STEP;
	
	/////////////////////////////////////////////////////////////////////////////////////////////////
	// Velocity signals
	/////////////////////////////////////////////////////////////////////////////////////////////////
	wire [3*DATA_WIDTH-1:0] wire_evaluated_velocity;				// {vz, vy, vx}
	
	/////////////////////////////////////////////////////////////////////////////////////////////////
	// Evaluated position signals
	/////////////////////////////////////////////////////////////////////////////////////////////////
	wire [3*DATA_WIDTH-1:0] wire_evaluated_position;				// {[posz, posy, posx}
	
	/////////////////////////////////////////////////////////////////////////////////////////////////
	// Target cell evaluation signals
	/////////////////////////////////////////////////////////////////////////////////////////////////
	// Signals connect to boundary memory
	reg [CELL_ID_WIDTH-1:0] bound_mem_rd_addr;
	reg bound_mem_rd_en;
	wire [DATA_WIDTH-1:0] bound_men_rd_data;
	// Boundary value
	reg [DATA_WIDTH-1:0] boundary_low_x, boundary_low_y, boundary_low_z;
	reg [DATA_WIDTH-1:0] boundary_high_x, boundary_high_y, boundary_high_z;
	// Boundary value read FSM
	reg [3:0] boundary_read_state;
	reg [CELL_ID_WIDTH-1:0] prev_working_cell_x, prev_working_cell_y, prev_working_cell_z;
	// Signals connect to comparators
	wire meet_low_boundary_x, meet_high_boundary_x;
	wire meet_low_boundary_y, meet_high_boundary_y;
	wire meet_low_boundary_z, meet_high_boundary_z;
	// Signals determine the target cell
	reg [CELL_ID_WIDTH-1:0] target_cell_x, target_cell_y, target_cell_z;
	
	/////////////////////////////////////////////////////////////////////////////////////////////////
	// Delay registers
	/////////////////////////////////////////////////////////////////////////////////////////////////
	// Delay the incoming velocity data by 1 cycle to wait for force data arrive
	reg [3*DATA_WIDTH-1:0] delay_in_velocity_data;
	// Delay the incoming valid signal to generate the output valid signal (14 cycles for the entire datapath)
	// Full datapath has 14 cycles, but the initial incoming_valid signal is assigned in FSM, already including 1 cycle delay, should delay for 13 cycles
	// However there is an extra delay for conpensate for the force cache's 3 cycle read delay instead of 2 from other caches
	// Thus a total of 14 cycles delay
	reg incoming_data_valid_reg1;
	reg incoming_data_valid_reg2;
	reg incoming_data_valid_reg3;
	reg incoming_data_valid_reg4;
	reg incoming_data_valid_reg5;
	reg incoming_data_valid_reg6;
	reg incoming_data_valid_reg7;
	reg incoming_data_valid_reg8;
	reg incoming_data_valid_reg9;
	reg incoming_data_valid_reg10;
	reg incoming_data_valid_reg11;
	reg incoming_data_valid_reg12;
	reg incoming_data_valid_reg13;
	reg delay_incoming_data_valid;
	// Delay registers conpensating the 6 cycle delay between position data arrival and evaluating velocity finish
	// 5 cycles for velocity evaluation
	// 1 cycle for conpensating the 1 more cycle read delay from force cache
	reg [3*DATA_WIDTH-1:0] in_position_data_reg1;
	reg [3*DATA_WIDTH-1:0] in_position_data_reg2;
	reg [3*DATA_WIDTH-1:0] in_position_data_reg3;
	reg [3*DATA_WIDTH-1:0] in_position_data_reg4;
	reg [3*DATA_WIDTH-1:0] in_position_data_reg5;
	reg [3*DATA_WIDTH-1:0] delay_in_position_data;
	// Delay registers to propogate the evaluated velocity data to meet the target cell information (9 cycles from speed evaluation to output)
	reg [3*DATA_WIDTH-1:0] evaluated_velocity_reg1;
	reg [3*DATA_WIDTH-1:0] evaluated_velocity_reg2;
	reg [3*DATA_WIDTH-1:0] evaluated_velocity_reg3;
	reg [3*DATA_WIDTH-1:0] evaluated_velocity_reg4;
	reg [3*DATA_WIDTH-1:0] evaluated_velocity_reg5;
	reg [3*DATA_WIDTH-1:0] evaluated_velocity_reg6;
	reg [3*DATA_WIDTH-1:0] evaluated_velocity_reg7;
	reg [3*DATA_WIDTH-1:0] evaluated_velocity_reg8;
	reg [3*DATA_WIDTH-1:0] delay_evaluated_velocity;
	// Delay registers to propogate the evaluated position data to meet the target cell information (4 cycle from position evaluation to output)
	reg [3*DATA_WIDTH-1:0] evaluated_position_reg1;
	reg [3*DATA_WIDTH-1:0] evaluated_position_reg2;
	reg [3*DATA_WIDTH-1:0] evaluated_position_reg3;
	reg [3*DATA_WIDTH-1:0] delay_evaluated_position;
	
	/////////////////////////////////////////////////////////////////////////////////////////////////
	// Determine the target cell, Combinational logic
	// !!!!! Attention: not condering boundary conditions !!!!!!!!
	/////////////////////////////////////////////////////////////////////////////////////////////////
	always@(*)
		begin
		if(~meet_low_boundary_x)
			target_cell_x <= (out_cur_working_cell_x == 1) ? X_DIM : out_cur_working_cell_x - 1'b1;
		else if(~meet_high_boundary_x)
			target_cell_x <= (out_cur_working_cell_x == X_DIM) ? 1 : out_cur_working_cell_x + 1'b1;
		else
			target_cell_x <= out_cur_working_cell_x;
		end
	always@(*)
		begin
		if(~meet_low_boundary_y)
			target_cell_y <= (out_cur_working_cell_y == 1) ? Y_DIM : out_cur_working_cell_y - 1'b1;
		else if(~meet_high_boundary_y)
			target_cell_y <= (out_cur_working_cell_y == Y_DIM) ? 1 : out_cur_working_cell_y + 1'b1;
		else
			target_cell_y <= out_cur_working_cell_y;
		end
	always@(*)
		begin
		if(~meet_low_boundary_z)
			target_cell_z <= (out_cur_working_cell_z == 1) ? Z_DIM : out_cur_working_cell_z - 1'b1;
		else if(~meet_high_boundary_z)
			target_cell_z <= (out_cur_working_cell_z == Z_DIM) ? 1 : out_cur_working_cell_z + 1'b1;
		else
			target_cell_z <= out_cur_working_cell_z;
		end
	
	/////////////////////////////////////////////////////////////////////////////////////////////////
	// Boundary information read FSM
	// After the read address is assigned, there are 2 cycles delay when the value is read out
	// Plus, there's one cycle delay when assign the read address
	/////////////////////////////////////////////////////////////////////////////////////////////////
	parameter DETECT_NEW_CELL = 4'd0;
	parameter FIRST_CYCLE_GAP = 4'd1;						// To conpensate the 2 cycle delay from read address till memory content read out
	parameter SECONE_CYCLE_CAP = 4'd2;						// To conpensate the extra cycle to assign the read address
	parameter READ_X_LOW_BOUND = 4'd3;
	parameter READ_X_HIGH_BOUND = 4'd4;
	parameter READ_Y_LOW_BOUND = 4'd5;
	parameter READ_Y_HIGH_BOUND = 4'd6;
	parameter READ_Z_LOW_BOUND = 4'd7;
	parameter READ_Z_HIGH_BOUND = 4'd8;
	always@(posedge clk)
		begin
		if(rst)
			begin
			bound_mem_rd_addr <= 0;
			bound_mem_rd_en <= 1'b0;
			boundary_low_x <= 0;
			boundary_low_y <= 0;
			boundary_low_z <= 0;
			boundary_high_x <= 0;
			boundary_high_y <= 0;
			boundary_high_z <= 0;
			prev_working_cell_x <= 0;
			prev_working_cell_y <= 0;
			prev_working_cell_z <= 0;
			
			boundary_read_state <= DETECT_NEW_CELL;
			end
		else
			begin
			prev_working_cell_x <= out_cur_working_cell_x;
			prev_working_cell_y <= out_cur_working_cell_y;
			prev_working_cell_z <= out_cur_working_cell_z;
			
			case(boundary_read_state)
				DETECT_NEW_CELL:
					begin
					// Keep the original boundary value
					boundary_low_x <= boundary_low_x;
					boundary_low_y <= boundary_low_y;
					boundary_low_z <= boundary_low_z;
					boundary_high_x <= boundary_high_x;
					boundary_high_y <= boundary_high_y;
					boundary_high_z <= boundary_high_z;
					// If the working home cell has changed, then re-read the boundary information
					if(prev_working_cell_x == out_cur_working_cell_x && prev_working_cell_y == out_cur_working_cell_y && prev_working_cell_z == out_cur_working_cell_z)
						begin
						bound_mem_rd_addr <= 0;
						bound_mem_rd_en <= 1'b0;
						boundary_read_state <= DETECT_NEW_CELL;
						end
					else
						begin
						bound_mem_rd_addr <= out_cur_working_cell_x - 1'b1;				// Read X low bound
						bound_mem_rd_en <= 1'b1;							
						boundary_read_state <= FIRST_CYCLE_GAP;
						end
					end
				// Conpensate the 2 cycles delay from address to readout actual data
				// Assign nothing, Gen address to read X high bound
				FIRST_CYCLE_GAP:
					begin
					// Assign X low boundary value
					boundary_low_x <= boundary_low_x;
					boundary_low_y <= boundary_low_y;
					boundary_low_z <= boundary_low_z;
					boundary_high_x <= boundary_high_x;
					boundary_high_y <= boundary_high_y;
					boundary_high_z <= boundary_high_z;
					
					bound_mem_rd_addr <= out_cur_working_cell_x;								// Read X high bound
					bound_mem_rd_en <= 1'b1;							
					boundary_read_state <= SECONE_CYCLE_CAP;
					end
				// Conpensate the extra cycle to assign the read address
				// Assign nothing, Gen address to read Y low bound
				SECONE_CYCLE_CAP:
					begin
					// Assign X low boundary value
					boundary_low_x <= boundary_low_x;
					boundary_low_y <= boundary_low_y;
					boundary_low_z <= boundary_low_z;
					boundary_high_x <= boundary_high_x;
					boundary_high_y <= boundary_high_y;
					boundary_high_z <= boundary_high_z;
					
					bound_mem_rd_addr <= out_cur_working_cell_y - 1'b1;					// Read Y low bound
					bound_mem_rd_en <= 1'b1;							
					boundary_read_state <= READ_X_LOW_BOUND;
					end
				// Assgin the X low bound, gen address to read Y high bound
				READ_X_LOW_BOUND:
					begin
					// Assign X low boundary value
					boundary_low_x <= bound_men_rd_data;
					boundary_low_y <= boundary_low_y;
					boundary_low_z <= boundary_low_z;
					boundary_high_x <= boundary_high_x;
					boundary_high_y <= boundary_high_y;
					boundary_high_z <= boundary_high_z;
					
					bound_mem_rd_addr <= out_cur_working_cell_y;								// Read Y high bound
					bound_mem_rd_en <= 1'b1;							
					boundary_read_state <= READ_X_HIGH_BOUND;
					end
				// Assgin the X high bound, gen address to read Z low bound
				READ_X_HIGH_BOUND:
					begin
					// Assign X high boundary value
					boundary_low_x <= boundary_low_x;
					boundary_low_y <= boundary_low_y;
					boundary_low_z <= boundary_low_z;
					boundary_high_x <= bound_men_rd_data;
					boundary_high_y <= boundary_high_y;
					boundary_high_z <= boundary_high_z;
					
					bound_mem_rd_addr <= out_cur_working_cell_z - 1'b1;					// Read Z low bound
					bound_mem_rd_en <= 1'b1;							
					boundary_read_state <= READ_Y_LOW_BOUND;
					end
				// Assgin the Y low bound, gen address to read Z high bound
				READ_Y_LOW_BOUND:
					begin
					// Assign Y low boundary value
					boundary_low_x <= boundary_low_x;
					boundary_low_y <= bound_men_rd_data;
					boundary_low_z <= boundary_low_z;
					boundary_high_x <= boundary_high_x;
					boundary_high_y <= boundary_high_y;
					boundary_high_z <= boundary_high_z;
					
					bound_mem_rd_addr <= out_cur_working_cell_z;								// Read Z high bound
					bound_mem_rd_en <= 1'b1;							
					boundary_read_state <= READ_Y_HIGH_BOUND;
					end
				// Assgin the Y high bound, read nothing
				READ_Y_HIGH_BOUND:
					begin
					// Assign Y high boundary value
					boundary_low_x <= boundary_low_x;
					boundary_low_y <= boundary_low_y;
					boundary_low_z <= boundary_low_z;
					boundary_high_x <= boundary_high_x;
					boundary_high_y <= bound_men_rd_data;
					boundary_high_z <= boundary_high_z;
					
					bound_mem_rd_addr <= 0;
					bound_mem_rd_en <= 1'b0;							
					boundary_read_state <= READ_Z_LOW_BOUND;
					end
				// Assgin the Z low bound, read nothing
				READ_Z_LOW_BOUND:
					begin
					// Assign Z low boundary value
					boundary_low_x <= boundary_low_x;
					boundary_low_y <= boundary_low_y;
					boundary_low_z <= bound_men_rd_data;
					boundary_high_x <= boundary_high_x;
					boundary_high_y <= boundary_high_y;
					boundary_high_z <= boundary_high_z;
					
					bound_mem_rd_addr <= 0;
					bound_mem_rd_en <= 1'b0;							
					boundary_read_state <= READ_Z_HIGH_BOUND;
					end
				// Assgin the Z high bound, read nothing
				READ_Z_HIGH_BOUND:
					begin
					// Assign Z high boundary value
					boundary_low_x <= boundary_low_x;
					boundary_low_y <= boundary_low_y;
					boundary_low_z <= boundary_low_z;
					boundary_high_x <= boundary_high_x;
					boundary_high_y <= boundary_high_y;
					boundary_high_z <= bound_men_rd_data;
					// Stop read, wait for next time home cell changes
					bound_mem_rd_addr <= 0;
					bound_mem_rd_en <= 1'b0;							
					boundary_read_state <= DETECT_NEW_CELL;
					end
			endcase
			end
		end
	
	/////////////////////////////////////////////////////////////////////////////////////////////////
	// Postion and velocity information read FSM
	// After the read address is assigned, there are 2 cycles delay when the value is read out
	// Plus, there's one cycle delay when assign the read address
	/////////////////////////////////////////////////////////////////////////////////////////////////
	parameter WAIT_FOR_START = 3'd0;
	parameter READ_PARTICLE_NUM = 3'd1;
	parameter READ_PARTICLE_INFO = 3'd2;
	parameter WAIT_FOR_FINISH = 3'd3;
	parameter MOTION_UPDATE_DONE = 3'd4;
	reg [2:0] state;
	reg [5:0] delay_counter;
	reg [CELL_ADDR_WIDTH-1:0] particle_num;
	reg [CELL_ADDR_WIDTH-1:0] rd_addr;
	reg rd_enable;
	reg incoming_data_valid;											// Assign the valid signal after 2 cycles when a valid address is assigned
	always@(posedge clk)
		begin
		if(rst)
			begin
			delay_counter <= 0;
			particle_num <= 0;
			homecell_num <= 1;
			rd_addr <= 0;
			rd_enable <= 1'b0;
			incoming_data_valid <= 1'b0;
			out_motion_update_enable <= 1'b0;
			motion_update_done <= 1'b1;
			CELL_X <= 1;
			CELL_Y <= 1;
			CELL_Z <= 1;
			
			state <= WAIT_FOR_START;
			end
		else
			begin
			case(state)
				// While wait for the start signal, read in the particle num first
				WAIT_FOR_START:
					begin
					delay_counter <= 0;
					particle_num <= 0;
					homecell_num <= homecell_num;
					rd_addr <= 0;
					incoming_data_valid <= 1'b0;								// Incoming data is not valid during wait process
					out_motion_update_enable <= 1'b0;
					motion_update_done <= motion_update_done;				// Done signal remain high until the next motion update starts
					if(motion_update_start)
						begin
						state <= READ_PARTICLE_NUM;
						rd_enable <= 1'b1;			// Pre enable the read
						end
					else
						begin
						state <= WAIT_FOR_START;
						rd_enable <= 1'b0;
						end
					end
				
				// There are a total of 3 cycles delay to read from the data in the particle cache
				// 2 cycles from the memory module
				// 1 cycle to assign the address value
				READ_PARTICLE_NUM:
					begin
					delay_counter <= delay_counter + 1'b1;
					particle_num <= in_position_data[CELL_ADDR_WIDTH-1:0];
					homecell_num <= homecell_num;
					rd_addr <= rd_addr + 1'b1;									// Start to increment the read address
					rd_enable <= 1'b1;
					incoming_data_valid <= 1'b0;								// Wait for cell particle number readout, incoming data not valid
					out_motion_update_enable <= 1'b1;
					motion_update_done <= 1'b0;								// Clear motion update done
					// Wait for 2 more cycles here to let the particle num read out
					// When jump to the next state, the particle count will be ready
					if(delay_counter < 2)
						begin
						state <= READ_PARTICLE_NUM;
						end
					else
						begin
						state <= READ_PARTICLE_INFO;
						end
					end
				
				// Consequtively read out particle data one by one
				READ_PARTICLE_INFO:
					begin
					delay_counter <= 0;											// Reset the delay counter
					particle_num <= particle_num;								// Keep the particle_num
					homecell_num <= homecell_num;
					//rd_addr <= rd_addr + 1'b1;									// Keep incrementing the read address
					rd_enable <= 1'b1;											// Keep the read enable as high
					incoming_data_valid <= 1'b1;								// The data read out are valid from now on
					out_motion_update_enable <= 1'b1;						// Motion update remain high during the entire process
					motion_update_done <= 1'b0;								// Clear motion update done
					// Wait for one more cycle here to let the particle num read out
					if(rd_addr < particle_num)
						begin
						rd_addr <= rd_addr + 1'b1;								// Keep incrementing the read address
						state <= READ_PARTICLE_INFO;
						end
					else
						begin
						rd_addr <= 0;												// After read is done, reset the read address
						state <= WAIT_FOR_FINISH;
						end
					end
				
				// Wait till the last particle is processed
				WAIT_FOR_FINISH:
					begin
					delay_counter <= delay_counter + 1'b1;					// Increment the delay counter
					particle_num <= particle_num;								// Keep the particle_num
					rd_addr <= 0;													// Reset the read address
					out_motion_update_enable <= 1'b1;						// Motion update remain high during the entire process
					motion_update_done <= 1'b0;								// Clear motion update done
					// Keep the incoming_data_valid high for two more cycles to take in the last data
					if(delay_counter < 2)
						incoming_data_valid <= 1'b1;
					else
						incoming_data_valid <= 1'b0;
					rd_enable <= 1'b1;
			/*
					// Keep read-enable high for one more cycle to let read finish
					// But is this necessary??
					if(delay_counter < 1)
						rd_enable <= 1'b1;										
					else
						rd_enable <= 1'b0;
			*/
					// Wait for all the processing finish, the value 40 is an arbitrary number here, may subject to change
					if(delay_counter < 40)
						begin
						state <= WAIT_FOR_FINISH;
						end
					else		// This can be optimized
						begin
						delay_counter <= 0;
						if (homecell_num < TOTAL_CELL_NUM)
							begin
							homecell_num <= homecell_num+1;
							end
						else
							begin
							homecell_num <= 1;
							end
						if (CELL_Z < Z_DIM)
							begin
							CELL_Z <= CELL_Z+1'b1;
							state <= READ_PARTICLE_NUM;
							end
						else
							begin
							CELL_Z <= 1;
							if (CELL_Y < Y_DIM)
								begin
								CELL_Y <= CELL_Y+1'b1;
								state <= READ_PARTICLE_NUM;
								end
							else
								begin
								CELL_Y <= 1;
								if (CELL_X < X_DIM)
									begin
									CELL_X <= CELL_X+1'b1;
									state <= READ_PARTICLE_NUM;
									end
								else
									begin
									CELL_X <= 1;
									state <= MOTION_UPDATE_DONE;
									end
								end
							end
						end
					end
				
				// Set the done signal, initialize the control signals
				MOTION_UPDATE_DONE:
					begin
					delay_counter <= 0;											// Reset delay counter
					particle_num <= particle_num;								// Keep the particle_num
					homecell_num <= homecell_num;								// Keep the homecell num
					rd_addr <= 0;													// Reset the read address
					incoming_data_valid <= 1'b0;								// Incoming data is not valid during this state
					out_motion_update_enable <= 1'b0;						// Clear motion update enable signal
					motion_update_done <= 1'b1;								// Set motion update done
					rd_enable <= 1'b0;											// Disable particle read
					state <= WAIT_FOR_START;									// Jump back to the initial state
					end
			endcase
			end
		end
	
	/////////////////////////////////////////////////////////////////////////////////////////////////
	// Assign delay registers
	/////////////////////////////////////////////////////////////////////////////////////////////////
	always@(posedge clk)
		begin
		if(rst)
			begin
			// Delay the incoming velocity data by 1 cycle to wait for force data arrive
			delay_in_velocity_data <= 0;
			// Delay the incoming valid signal to generate the output valid signal
			incoming_data_valid_reg1 <= 1'b0;
			incoming_data_valid_reg2 <= 1'b0;
			incoming_data_valid_reg3 <= 1'b0;
			incoming_data_valid_reg4 <= 1'b0;
			incoming_data_valid_reg5 <= 1'b0;
			incoming_data_valid_reg6 <= 1'b0;
			incoming_data_valid_reg7 <= 1'b0;
			incoming_data_valid_reg8 <= 1'b0;
			incoming_data_valid_reg9 <= 1'b0;
			incoming_data_valid_reg10 <= 1'b0;
			incoming_data_valid_reg11 <= 1'b0;
			incoming_data_valid_reg12 <= 1'b0;
			incoming_data_valid_reg13 <= 1'b0;
			delay_incoming_data_valid <= 1'b0;
			// Delay position data
			in_position_data_reg1 <= 0;
			in_position_data_reg2 <= 0;
			in_position_data_reg3 <= 0;
			in_position_data_reg4 <= 0;
			in_position_data_reg5 <= 0;
			delay_in_position_data <= 0;
			// Delay registers to propogate the evaluated velocity data to meet the target cell information
			evaluated_velocity_reg1 <= 0;
			evaluated_velocity_reg2 <= 0;
			evaluated_velocity_reg3 <= 0;
			evaluated_velocity_reg4 <= 0;
			evaluated_velocity_reg5 <= 0;
			evaluated_velocity_reg6 <= 0;
			evaluated_velocity_reg7 <= 0;
			evaluated_velocity_reg8 <= 0;
			delay_evaluated_velocity <= 0;
			// Delay registers to propogate the evaluated position data to meet the target cell information
			evaluated_position_reg1 <= 0;
			evaluated_position_reg2 <= 0;
			evaluated_position_reg3 <= 0;
			delay_evaluated_position <= 0;
			end
		else
			begin
			// Delay the incoming velocity data by 1 cycle to wait for force data arrive
			delay_in_velocity_data <= in_velocity_data;
			// Delay the incoming valid signal to generate the output valid signal
			incoming_data_valid_reg1 <= incoming_data_valid;
			incoming_data_valid_reg2 <= incoming_data_valid_reg1;
			incoming_data_valid_reg3 <= incoming_data_valid_reg2;
			incoming_data_valid_reg4 <= incoming_data_valid_reg3;
			incoming_data_valid_reg5 <= incoming_data_valid_reg4;
			incoming_data_valid_reg6 <= incoming_data_valid_reg5;
			incoming_data_valid_reg7 <= incoming_data_valid_reg6;
			incoming_data_valid_reg8 <= incoming_data_valid_reg7;
			incoming_data_valid_reg9 <= incoming_data_valid_reg8;
			incoming_data_valid_reg10 <= incoming_data_valid_reg9;
			incoming_data_valid_reg11 <= incoming_data_valid_reg10;
			incoming_data_valid_reg12 <= incoming_data_valid_reg11;
			incoming_data_valid_reg13 <= incoming_data_valid_reg12;
			delay_incoming_data_valid <= incoming_data_valid_reg13;
			// Delay position data
			in_position_data_reg1 <= in_position_data;
			in_position_data_reg2 <= in_position_data_reg1;
			in_position_data_reg3 <= in_position_data_reg2;
			in_position_data_reg4 <= in_position_data_reg3;
			in_position_data_reg5 <= in_position_data_reg4;
			delay_in_position_data <= in_position_data_reg5;
			// Delay registers to propogate the evaluated velocity data to meet the target cell information
			evaluated_velocity_reg1 <= wire_evaluated_velocity;
			evaluated_velocity_reg2 <= evaluated_velocity_reg1;
			evaluated_velocity_reg3 <= evaluated_velocity_reg2;
			evaluated_velocity_reg4 <= evaluated_velocity_reg3;
			evaluated_velocity_reg5 <= evaluated_velocity_reg4;
			evaluated_velocity_reg6 <= evaluated_velocity_reg5;
			evaluated_velocity_reg7 <= evaluated_velocity_reg6;
			evaluated_velocity_reg8 <= evaluated_velocity_reg7;
			delay_evaluated_velocity <= evaluated_velocity_reg8;
			// Delay registers to propogate the evaluated position data to meet the target cell information
			evaluated_position_reg1 <= wire_evaluated_position;
			evaluated_position_reg2 <= evaluated_position_reg1;
			evaluated_position_reg3 <= evaluated_position_reg2;
			delay_evaluated_position <= evaluated_position_reg3;
			end
		end
	
	/////////////////////////////////////////////////////////////////////////////////////////////////
	// Update Output ports
	/////////////////////////////////////////////////////////////////////////////////////////////////
	// Assign read singals to Pos Cache
	assign out_position_cache_rd_en = rd_enable;
	assign out_position_cache_rd_addr = rd_addr;
	// Assign read singals to Force Cache
	assign out_force_cache_rd_en = rd_enable;
	assign out_force_cache_rd_addr = rd_addr;
	// Assign read singals to Velocity Cache
	assign out_velocity_cache_rd_en = rd_enable;
	assign out_velocity_cache_rd_addr = rd_addr;
	// Assign output to Velocity Cache
	assign out_velocity_data_valid = delay_incoming_data_valid;
	assign out_velocity_data = delay_evaluated_velocity;
	assign out_velocity_destination_cell = {target_cell_x, target_cell_y, target_cell_z};
	// Assign output to Position Cache
	assign out_position_data_valid = delay_incoming_data_valid;
	assign out_position_data = delay_evaluated_position;
	assign out_position_destination_cell = {target_cell_x, target_cell_y, target_cell_z};
	
	
	/////////////////////////////////////////////////////////////////////////////////////////////////
	// Velocity Evaluation
	// result = ay * az + ax
	// 5 cycle delay
	/////////////////////////////////////////////////////////////////////////////////////////////////
	// Evaluate vx
	FP_MUL_ADD Eval_vx (
		.ax     (delay_in_velocity_data[1*DATA_WIDTH-1:0*DATA_WIDTH]),
		.ay     (in_force_data[1*DATA_WIDTH-1:0*DATA_WIDTH]),
		.az     (time_step), 
		.clk    (clk),
		.clr    (rst), 
		.ena    (1'b1),
		.result (wire_evaluated_velocity[1*DATA_WIDTH-1:0*DATA_WIDTH]) 
	);
	
	// Evaluate vy
	FP_MUL_ADD Eval_vy (
		.ax     (delay_in_velocity_data[2*DATA_WIDTH-1:1*DATA_WIDTH]),
		.ay     (in_force_data[2*DATA_WIDTH-1:1*DATA_WIDTH]),
		.az     (time_step), 
		.clk    (clk),
		.clr    (rst), 
		.ena    (1'b1),
		.result (wire_evaluated_velocity[2*DATA_WIDTH-1:1*DATA_WIDTH]) 
	);
	
	// Evaluate vz
	FP_MUL_ADD Eval_vz (
		.ax     (delay_in_velocity_data[3*DATA_WIDTH-1:2*DATA_WIDTH]),
		.ay     (in_force_data[3*DATA_WIDTH-1:2*DATA_WIDTH]),
		.az     (time_step), 
		.clk    (clk),
		.clr    (rst), 
		.ena    (1'b1),
		.result (wire_evaluated_velocity[3*DATA_WIDTH-1:2*DATA_WIDTH]) 
	);
	
	/////////////////////////////////////////////////////////////////////////////////////////////////
	// Position Evaluation
	// result = ay * az + ax
	// 5 cycle delay
	/////////////////////////////////////////////////////////////////////////////////////////////////
	// Evaluate posx
	FP_MUL_ADD Eval_posx (
		.ax     (delay_in_position_data[1*DATA_WIDTH-1:0*DATA_WIDTH]),
		.ay     (wire_evaluated_velocity[1*DATA_WIDTH-1:0*DATA_WIDTH]),
		.az     (time_step), 
		.clk    (clk),
		.clr    (rst), 
		.ena    (1'b1),
		.result (wire_evaluated_position[1*DATA_WIDTH-1:0*DATA_WIDTH]) 
	);
	
	// Evaluate posy
	FP_MUL_ADD Eval_posy (
		.ax     (delay_in_position_data[2*DATA_WIDTH-1:1*DATA_WIDTH]),
		.ay     (wire_evaluated_velocity[2*DATA_WIDTH-1:1*DATA_WIDTH]),
		.az     (time_step), 
		.clk    (clk),
		.clr    (rst), 
		.ena    (1'b1),
		.result (wire_evaluated_position[2*DATA_WIDTH-1:1*DATA_WIDTH]) 
	);
	
	// Evaluate posz
	FP_MUL_ADD Eval_posz (
		.ax     (delay_in_position_data[3*DATA_WIDTH-1:2*DATA_WIDTH]),
		.ay     (wire_evaluated_velocity[3*DATA_WIDTH-1:2*DATA_WIDTH]),
		.az     (time_step), 
		.clk    (clk),
		.clr    (rst), 
		.ena    (1'b1),
		.result (wire_evaluated_position[3*DATA_WIDTH-1:2*DATA_WIDTH]) 
	);
	
	/////////////////////////////////////////////////////////////////////////////////////////////////
	// Determine Target Cells
	/////////////////////////////////////////////////////////////////////////////////////////////////
	// Low boundary x
	FP_GreaterThan_or_Equal Low_Bondary_x(
		.a(wire_evaluated_position[1*DATA_WIDTH-1:0*DATA_WIDTH]),
		.areset(rst),
		.b(boundary_low_x),
		.clk(clk),
		.q(meet_low_boundary_x)
	);
	// High boundary x
	FP_LessThan High_Bondary_x(
		.a(wire_evaluated_position[1*DATA_WIDTH-1:0*DATA_WIDTH]),
		.areset(rst),
		.b(boundary_high_x),
		.clk(clk),
		.q(meet_high_boundary_x)
	);
	// Low boundary y
	FP_GreaterThan_or_Equal Low_Bondary_y(
		.a(wire_evaluated_position[2*DATA_WIDTH-1:1*DATA_WIDTH]),
		.areset(rst),
		.b(boundary_low_y),
		.clk(clk),
		.q(meet_low_boundary_y)
	);
	// High boundary y
	FP_LessThan High_Bondary_y(
		.a(wire_evaluated_position[2*DATA_WIDTH-1:1*DATA_WIDTH]),
		.areset(rst),
		.b(boundary_high_y),
		.clk(clk),
		.q(meet_high_boundary_y)
	);
	// Low boundary z
	FP_GreaterThan_or_Equal Low_Bondary_z(
		.a(wire_evaluated_position[3*DATA_WIDTH-1:2*DATA_WIDTH]),
		.areset(rst),
		.b(boundary_low_z),
		.clk(clk),
		.q(meet_low_boundary_z)
	);
	// High boundary z
	FP_LessThan High_Bondary_z(
		.a(wire_evaluated_position[3*DATA_WIDTH-1:2*DATA_WIDTH]),
		.areset(rst),
		.b(boundary_high_z),
		.clk(clk),
		.q(meet_high_boundary_z)
	);
	
	/////////////////////////////////////////////////////////////////////////////////////////////////
	// Cell Boundary Memory
	/////////////////////////////////////////////////////////////////////////////////////////////////
	cell_boundary_mem_64_Cells
	#(
		.DATA_WIDTH(DATA_WIDTH),
		.DEPTH(MAX_CELL_COUNT_PER_DIM+1'b1),
		.ADDR_WIDTH(CELL_ID_WIDTH)
	)
	cell_boundary_mem
	(
		.address(bound_mem_rd_addr),
		.clock(clk),
		.data(),
		.rden(bound_mem_rd_en),
		.wren(1'b0),
		.q(bound_men_rd_data)
	);

endmodule