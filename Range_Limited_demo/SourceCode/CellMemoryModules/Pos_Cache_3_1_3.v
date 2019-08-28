/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: Pos_Cache_3_1_3.v
//
//	Function:
//				Position cache with double buffering for motion update
//
//	Purpose:
//				Providing particle position data for force evaluation and motion update
//				Have a secondary buffer to hold the new data after motion update process
//				During motion update process, the motion update module will broadcast the valid data and destination cell to all cells
//				Upon receiving valid particle data, first determine if this is the target destination cell
//
// Data Organization:
//				Address 0 for each cell module: # of particles in the cell
//				Position data: MSB-LSB: {posz, posy, posx}
//				Cell address: MSB-LSB: {cell_x, cell_y, cell_z}
//
// Used by:
//				RL_LJ_Top.v
//
// Dependency:
//				cell_x_y_z.v
//				cell_empty.v
//
// Testbench:
//				Pos_Cache_2_2_2_tb.v			(testing the swap function during motion update)
//				RL_LJ_Top_tb.v					(testing the correctness of read & write)
//
// Timing:
//				1 cycle reading delay from input address and output data.
//
// Created by:
//				Chunshu's Script (Gen_Pos_Cache.cpp).
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module Pos_Cache_3_1_3
#(
	parameter DATA_WIDTH = 32,
	parameter PARTICLE_NUM = 220,
	parameter ADDR_WIDTH = 8,
	parameter CELL_ID_WIDTH = 4,
	parameter CELL_X = 3,
	parameter CELL_Y = 1,
	parameter CELL_Z = 3
)
(
	input clk,
	input rst,
	input motion_update_enable,										// Keep this signal as high during the motion update process
	input [ADDR_WIDTH-1:0] in_read_address,
	input [3*DATA_WIDTH-1:0] in_data,
	input [3*CELL_ID_WIDTH-1:0] in_data_dst_cell,				// The destination cell for the incoming data
	input in_data_valid,													// Signify if the new incoming data is valid
	input in_rden,
	//input in_wren,
	output [3*DATA_WIDTH-1:0] out_particle_info
);

	//////////////////////////////////////////////////////////////////////////////////////////////
	// Control FSM to switch between the 2 memory modules
	//////////////////////////////////////////////////////////////////////////////////////////////
	parameter WAIT_FOR_MOTION_UPDATE_START = 2'b00;
	parameter MOTION_UPDATE_PROCESS = 2'b01;
	parameter WRITE_PARTICLE_NUM = 2'b10;
	parameter MOTION_UPDATE_DONE = 2'b11;
	reg [1:0] state;
	// Flag slecting which cell is the active one for processing
	reg active_cell;
	// Counter for recording the # of new particles
	reg [ADDR_WIDTH-1:0] new_particle_counter;
	// Memory module control signal
	reg cell_wr_en;
	reg [ADDR_WIDTH-1:0] cell_wr_address;
	reg [3*DATA_WIDTH-1:0] cell_wr_data;
	// Assign the current cell ID
	wire [CELL_ID_WIDTH-1:0] cur_cell_x, cur_cell_y, cur_cell_z;
	assign cur_cell_x = CELL_X;
	assign cur_cell_y = CELL_Y;
	assign cur_cell_z = CELL_Z;
	// Check if the incoming particle is targeting the current cell
	wire data_valid;
	assign data_valid = in_data_valid && (in_data_dst_cell == {cur_cell_x, cur_cell_y, cur_cell_z});
	always@(posedge clk)
		begin
		if(rst)
			begin
			active_cell <= 1'b0;
			new_particle_counter <= 1;								// Counter starts from 1, to avoid write to Address 0
			cell_wr_en <= 1'b0;
			cell_wr_address <= {(ADDR_WIDTH){1'b0}};
			cell_wr_data <= {(3*DATA_WIDTH){1'b0}};
			
			state <= WAIT_FOR_MOTION_UPDATE_START;
			end
		else
			begin
			case(state)
				// Wait for the start signal
				WAIT_FOR_MOTION_UPDATE_START:
					begin
					if(motion_update_enable)
						begin
						active_cell <= active_cell;
						// Check if the first data is valid
						if(data_valid)
							begin
							new_particle_counter <= new_particle_counter + 1'b1;
							cell_wr_en <= 1'b1;
							cell_wr_address <= new_particle_counter;
							cell_wr_data <= in_data;
							end
						else
							begin
							new_particle_counter <= new_particle_counter;
							cell_wr_en <= 1'b0;
							cell_wr_address <= 0;
							cell_wr_data <= 0;
							end
						state <= MOTION_UPDATE_PROCESS;
						end
					else
						begin
						active_cell <= active_cell;
						new_particle_counter <= 1;
						cell_wr_en <= 1'b0;
						cell_wr_address <= {(ADDR_WIDTH){1'b0}};
						cell_wr_data <= {(3*DATA_WIDTH){1'b0}};
						state <= WAIT_FOR_MOTION_UPDATE_START;
						end
					end
				// Record the new particle data
				MOTION_UPDATE_PROCESS:
					begin
					active_cell <= active_cell;
					// Check if the first data is valid
					if(data_valid)
						begin
						new_particle_counter <= new_particle_counter + 1'b1;
						cell_wr_en <= 1'b1;
						cell_wr_address <= new_particle_counter;
						cell_wr_data <= in_data;
						end
					else
						begin
						new_particle_counter <= new_particle_counter;
						cell_wr_en <= 1'b0;
						cell_wr_address <= 0;
						cell_wr_data <= 0;
						end
					// Update the next state
					// The motion_update_enable is suppose to keep high during the process
					if(motion_update_enable)
						begin
						state <= MOTION_UPDATE_PROCESS;
						end
					else
						begin
						state <= WRITE_PARTICLE_NUM;
						end
					end
				// Write the paticle # to address 0
				WRITE_PARTICLE_NUM:
					begin
					active_cell <= active_cell;
					// Write the new particle # to address 0
					new_particle_counter <= new_particle_counter;
					cell_wr_en <= 1'b1;
					cell_wr_address <= 0;
					cell_wr_data <= new_particle_counter - 1'b1;					// new_particle_counter = actual_current_# + 1'b1
					// Move to the DONE state
					state <= MOTION_UPDATE_DONE;
					end
				// Flip the active_cell bit
				MOTION_UPDATE_DONE:
					begin
					// Inverse the sel bit
					active_cell <= ~active_cell;
					// Reset the counter to 1
					new_particle_counter <= 1;
					cell_wr_en <= 1'b0;
					cell_wr_address <= 0;
					cell_wr_data <= 0;
					// Move to the initial state
					state <= WAIT_FOR_MOTION_UPDATE_START;
					end
			endcase
			end
		end

	//////////////////////////////////////////////////////////////////////////////////////////////
	// Signals connect to 2 cell memories
	//////////////////////////////////////////////////////////////////////////////////////////////
	// Assign the read address
	wire [ADDR_WIDTH-1:0] input_to_cell_addr_0, input_to_cell_addr_1;
	assign input_to_cell_addr_0 = (active_cell) ? cell_wr_address : in_read_address;
	assign input_to_cell_addr_1 = (active_cell) ? in_read_address : cell_wr_address;
	// Assign the write data
	wire [3*DATA_WIDTH-1:0] input_to_cell_new_position_data_0, input_to_cell_new_position_data_1;
	assign input_to_cell_new_position_data_0 = (active_cell) ? cell_wr_data : 0;
	assign input_to_cell_new_position_data_1 = (active_cell) ? 0 : cell_wr_data;
	// Assign the read enable
	wire input_to_cell_rden_0, input_to_cell_rden_1;
	assign input_to_cell_rden_0 = (active_cell) ? 1'b0 : in_rden;
	assign input_to_cell_rden_1 = (active_cell) ? in_rden : 1'b0;
	// Assign the write enable
	wire input_to_cell_wren_0, input_to_cell_wren_1;
	assign input_to_cell_wren_0 = (active_cell) ? cell_wr_en : 1'b0;
	assign input_to_cell_wren_1 = (active_cell) ? 1'b0 : cell_wr_en;
	// Assign the read out data to output
	wire [3*DATA_WIDTH-1:0] cell_to_output_position_readout_0, cell_to_output_position_readout_1;
	assign out_particle_info = (active_cell) ? cell_to_output_position_readout_1 : cell_to_output_position_readout_0;

	//////////////////////////////////////////////////////////////////////////////////////////////
	// Memory Modules
	//////////////////////////////////////////////////////////////////////////////////////////////
	// Original Cell with initial value
	cell_3_1_3
	#(
		.DATA_WIDTH(3*DATA_WIDTH),
		.PARTICLE_NUM(PARTICLE_NUM),
		.ADDR_WIDTH(ADDR_WIDTH)
	)
	cell_0
	(
		.address(input_to_cell_addr_0),
		.clock(clk),
		.data(input_to_cell_new_position_data_0),
		.rden(input_to_cell_rden_0),
		.wren(input_to_cell_wren_0),
		.q(cell_to_output_position_readout_0)
	);

	// Alternative cell
	cell_empty
	#(
		.DATA_WIDTH(3*DATA_WIDTH),
		.PARTICLE_NUM(PARTICLE_NUM),
		.ADDR_WIDTH(ADDR_WIDTH)
	)
	cell_1
	(
		.address(input_to_cell_addr_1),
		.clock(clk),
		.data(input_to_cell_new_position_data_1),
		.rden(input_to_cell_rden_1),
		.wren(input_to_cell_wren_1),
		.q(cell_to_output_position_readout_1)
	);

endmodule	
