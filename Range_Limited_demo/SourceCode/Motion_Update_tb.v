/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: Motion_Update_tb.v
//
//	Function:
//				Testing on the basic timing of Motion_Update module 			
//
// Data Organization:
//				particle_position [3*DATA_WIDTH-1:0]: {posz, posy, posx}
//				particle_velocity [3*DATA_WIDTH-1:0]: {vz, vy, vx}
//				force [3*DATA_WIDTH-1:0]: {Force_Z, Force_Y, Force_X}
//				particle_id [CELL_ADDR_WIDTH-1:0]: {cell_x, cell_y, cell_z, particle_in_cell_rd_addr}
//				destination_cell: {cell_x, cell_y, cell_z}
//
// Used by:
//				N/A.v
//
// Dependency:
//				Motion_Update.v
//
// Timing:
//				Total of 17 cycles: from the read address is address to the output valid
//				Plus in the beginning, there is 1 extra cycle to read in how many particles are in the current cell
//				Read in data: total of 3 cycles
//						From Pos Cache & Velocity Cache: 2 cycles delay: after read address is assigned, there are 2 cycles delay from the upstream cache module
//						From Force Cache: 3 cycles delay: 1 cycle for registering the input read address, 1 cycle to readout data, 1 cycle to register the output
//						In order to conpensate the 1 cycle extra read delay from force cache, delay the input from Velocity cache by one cycle
//				Data processing latency: 				total of 11 cycles
//						Evaluate Speed: 					5 cycles
//						Evaluate Position:				5 cycles
//						Compare with boundary value:	1 cycle
//
// Created by: 
//				Chen Yang 01/01/19
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ns

module Motion_Update_tb;

	parameter DATA_WIDTH 					= 32;											// Data width of a single force value, 32-bit
	parameter TIME_STEP 						= 32'h27101D7D;							// 2fs time step ()
	// Cell id this unit related to
	parameter CELL_X							= 4'd2;
	parameter CELL_Y							= 4'd2;
	parameter CELL_Z							= 4'd2;
	// Dataset defined parameters
	parameter MAX_CELL_COUNT_PER_DIM 	= 9;											// Maximum cell count among the 3 dimensions
	parameter CELL_ID_WIDTH					= 4;											// log(NUM_NEIGHBOR_CELLS)
	parameter MAX_CELL_PARTICLE_NUM		= 290;										// The maximum # of particles can be in a cell
	parameter CELL_ADDR_WIDTH				= 9;											// log(MAX_CELL_PARTICLE_NUM)
	parameter PARTICLE_ID_WIDTH			= CELL_ID_WIDTH*3+CELL_ADDR_WIDTH;	// # of bit used to represent particle ID, 9*9*7 cells, each 4-bit, each cell have max of 220 particles, 8-bit


	reg clk;
	reg rst;
	reg motion_update_start;																// Only need to keep high for 1 cycle
	wire motion_update_done;																// Remain high until the next motion update starts
	// Output the targeting home cell
	// When this module is responsible for multiple cells, then the control signal is broadcast to multiple cells, while a mux need to implement on the input side to select from those cells
	wire [CELL_ID_WIDTH-1:0] out_cur_working_cell_x;
	wire [CELL_ID_WIDTH-1:0] out_cur_working_cell_y;
	wire [CELL_ID_WIDTH-1:0] out_cur_working_cell_z;
	// Read from Position Cache
	reg [3*DATA_WIDTH-1:0] in_position_data;
	wire out_position_cache_rd_en;
	wire [CELL_ADDR_WIDTH-1:0] out_position_cache_rd_addr;
	// Read from Force Cache
	reg [3*DATA_WIDTH-1:0] in_force_data;
	reg [3*DATA_WIDTH-1:0] delay_in_force_data;				// Create the extra cycle delay to read from force cache
	wire out_force_cache_rd_en;
	wire [CELL_ADDR_WIDTH-1:0] out_force_cache_rd_addr;
	// Read from Velocity Cache
	reg [3*DATA_WIDTH-1:0] in_velocity_data;
	wire out_velocity_cache_rd_en;
	wire [CELL_ADDR_WIDTH-1:0] out_velocity_cache_rd_addr;
	// Motion update enable signal
	wire out_motion_update_enable;														// Remine high during the entire motion update process
	// Write back to Velocity Cache
	wire [3*DATA_WIDTH-1:0] out_velocity_data;										// The updated velocity value
	wire out_velocity_data_valid;
	wire [3*CELL_ID_WIDTH-1:0] out_velocity_destination_cell;
	// Write back to Position Cache
	wire [3*DATA_WIDTH-1:0] out_position_data;
	wire out_position_data_valid;
	wire [3*CELL_ID_WIDTH-1:0] out_position_destination_cell;
	
	always #1 clk <= ~clk;
	
	
	// Delay registers
	reg  rd_en_reg1;
	reg [CELL_ADDR_WIDTH-1:0] rd_addr_reg1;
	always@(posedge clk)
		begin
		rd_en_reg1 <= out_position_cache_rd_en || out_force_cache_rd_en || out_velocity_cache_rd_en;
		rd_addr_reg1 <= out_position_cache_rd_addr;
		end
	// FSM signals
	reg [1:0] state;
	reg [5:0] tmp_counter;
	parameter WAIT_FOR_START = 2'b00;
	parameter MOTION_UPDATE = 2'b01;
	parameter DONE = 2'b10;
	always@(posedge clk)
		begin
		if(rst)
			begin
			tmp_counter <= 0;
			motion_update_start <= 1'b0;
			in_position_data <= 0;
			in_force_data <= 0;
			delay_in_force_data <= 0;
			in_velocity_data <= 0;
			state <= WAIT_FOR_START;
			end
		else
			begin
			// Assign the delayed force value
			delay_in_force_data <= in_force_data;
			// FSM
			case(state)
				WAIT_FOR_START:
					begin
					tmp_counter <= tmp_counter + 1'b1;
					
					in_position_data <= 0;
					in_force_data <= 0;
					in_velocity_data <= 0;
					if(tmp_counter < 10)
						begin
						motion_update_start <= 1'b0;
						state <= WAIT_FOR_START;
						end
					else
						begin
						motion_update_start <= 1'b1;					// Give the start signal only by 1 cycle
						state <= MOTION_UPDATE;
						end
					end
				MOTION_UPDATE:
					begin
					tmp_counter <= 0;
					motion_update_start <= 1'b0;
					// Assign particle count in the current cell
					if(rd_en_reg1)
						begin
						case(rd_addr_reg1)
							0:	// Assign particle number
								begin
								in_position_data <= 10;
								in_force_data <= 0;
								in_velocity_data <= 0;
								end
							1:	// Particle data 22201
								begin
								in_position_data <= {32'h416974BC, 32'h414153F8, 32'h41668F5C};
								in_force_data <= {32'h4188C645, 32'hC097808F, 32'h41F758ED};
								in_velocity_data <= 0;
								end
							2:	// Particle data 22202
								begin
								in_position_data <= {32'h4161D2F2, 32'h41439DB2, 32'h4159126F};
								in_force_data <= {32'hC18B82F2, 32'h40A9E123, 32'hC1F27798};
								in_velocity_data <= 0;
								end
							3:	// Particle data 22203
								begin
								in_position_data <= {32'h414D0625, 32'h415C5E35, 32'h417A51EC};
								in_force_data <= {32'hC22DDD01, 32'hC00A89CE, 32'h41164BBC};
								in_velocity_data <= 0;
								end
							4:	// Particle data 22204
								begin
								in_position_data <= {32'h41573B64, 32'h4167AE14, 32'h417E24DD};
								in_force_data <= {32'h41B2AE84, 32'h41BC46B3, 32'h40F59FE5};
								in_velocity_data <= 0;
								end
							5:	// Particle data 22205
								begin
								in_position_data <= {32'h41569375, 32'h4152AC08, 32'h41729375};
								in_force_data <= {32'h41B1B661, 32'hC1AAC5A7, 32'hC18A9B0C};
								in_velocity_data <= 0;
								end
							6:	// Particle data 22206
								begin
								in_position_data <= {32'h415AD4FE, 32'h417F2F1B, 32'h4157B22D};
								in_force_data <= {32'h420FE1EC, 32'h419443CE, 32'h41385651};
								in_velocity_data <= 0;
								end
							7:	// Particle data 22207
								begin
								in_position_data <= {32'h415824DD, 32'h4176872B, 32'h414ACCCD};
								in_force_data <= {32'hC0B5B93E, 32'hC187D77C, 32'hC1C74132};
								in_velocity_data <= 0;
								end
							8:	// Particle data 22208
								begin
								in_position_data <= {32'h414CA7F0, 32'h417EB852, 32'h415E76C9};
								in_force_data <= {32'hC1EBD2C8, 32'hBFAD30D7, 32'h4158B21E};
								in_velocity_data <= 0;
								end
							9:	// Particle data 22209
								begin
								in_position_data <= {32'h4181BA5E, 32'h416F0A3D, 32'h414F6042};
								in_force_data <= {32'h4238044D, 32'h410CF868, 32'h412EF39D};
								in_velocity_data <= 0;
								end
							10:	// Particle data 2220A
								begin
								in_position_data <= {32'h417C3958, 32'h4164CCCD, 32'h4146147B};
								in_force_data <= {32'hC18E51B8, 32'hC1BE2508, 32'hC1ACE3BB};
								in_velocity_data <= 0;
								end
							default:
								begin
								in_position_data <= 0;
								in_force_data <= 0;
								in_velocity_data <= 0;
								end
						endcase
						end
					else
						begin
						in_position_data <= 0;
						in_force_data <= 0;
						in_velocity_data <= 0;
						end
					// Check if motion update is done
					if(motion_update_done)
						state <= DONE;
					else
						state <= MOTION_UPDATE;
					end
				DONE:
					begin
					tmp_counter <= tmp_counter;
					
					in_position_data <= 0;
					in_force_data <= 0;
					in_velocity_data <= 0;
					motion_update_start <= 1'b0;
					state <= DONE;
					end
			endcase
			end
		end
	
	initial begin
		clk <= 1'b1;
		rst <= 1'b1;
		
		#10
		rst <= 1'b0;
	end
	
	// UUT
	Motion_Update
	#(
		.DATA_WIDTH(DATA_WIDTH),											// Data width of a single force value, 32-bit
		.TIME_STEP(TIME_STEP),												// 2fs time step
		// Cell id this unit related to
		.CELL_X(CELL_X),
		.CELL_Y(CELL_Y),
		.CELL_Z(CELL_Z),
		// Dataset defined parameters
		.MAX_CELL_COUNT_PER_DIM(MAX_CELL_COUNT_PER_DIM),			// Maximum cell count among the 3 dimensions
		.CELL_ID_WIDTH(CELL_ID_WIDTH),									// log(NUM_NEIGHBOR_CELLS)
		.MAX_CELL_PARTICLE_NUM(MAX_CELL_PARTICLE_NUM),				// The maximum # of particles can be in a cell
		.CELL_ADDR_WIDTH(CELL_ADDR_WIDTH),								// log(MAX_CELL_PARTICLE_NUM)
		.PARTICLE_ID_WIDTH(PARTICLE_ID_WIDTH)							// # of bit used to represent particle ID, 9*9*7 cells, each 4-bit, each cell have max of 220 particles, 8-bit
	)
	UUT
	(
		.clk(clk),
		.rst(rst),
		.motion_update_start(motion_update_start),					// Only need to keep high for 1 cycle
		.motion_update_done(motion_update_done),						// Remain high until the next motion update starts
		// Output the targeting home cell
		// When this module is responsible for multiple cells, then the control signal is broadcast to multiple cells, while a mux need to implement on the input side to select from those cells
		.out_cur_working_cell_x(out_cur_working_cell_x),
		.out_cur_working_cell_y(out_cur_working_cell_y),
		.out_cur_working_cell_z(out_cur_working_cell_z),
		// Read from Position Cache
		.in_position_data(in_position_data),
		.out_position_cache_rd_en(out_position_cache_rd_en),
		.out_position_cache_rd_addr(out_position_cache_rd_addr),
		// Read from Force Cache
		.in_force_data(delay_in_force_data),
		.out_force_cache_rd_en(out_force_cache_rd_en),
		.out_force_cache_rd_addr(out_force_cache_rd_addr),
		// Read from Velocity Cache
		.in_velocity_data(in_velocity_data),
		.out_velocity_cache_rd_en(out_velocity_cache_rd_en),
		.out_velocity_cache_rd_addr(out_velocity_cache_rd_addr),
		// Motion update enable signal
		.out_motion_update_enable(out_motion_update_enable),		// Remine high during the entire motion update process
		// Write back to Velocity Cache
		.out_velocity_data(out_velocity_data),							// The updated velocity value
		.out_velocity_data_valid(out_velocity_data_valid),
		.out_velocity_destination_cell(out_velocity_destination_cell),
		// Write back to Position Cache
		.out_position_data(out_position_data),
		.out_position_data_valid(out_position_data_valid),
		.out_position_destination_cell(out_position_destination_cell)
	);
	

endmodule