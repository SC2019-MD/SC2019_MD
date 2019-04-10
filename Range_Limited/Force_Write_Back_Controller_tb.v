/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: Force_Write_Back_Controller_tb.v
//
//	Function: 
//				Testbench for Force_Write_Back_Controller.v
//
//	Purpose:
//				Testing the cases when consequective input are targeting the same particle
//				Verify the input buffer mechanism
//
// Data Organization:
//				Force_Cache_Input_Buffer: {particle_address[CELL_ADDR_WIDTH-1:0], Force_Z, Force_Y, Force_X}
//				
//
// Used by:
//				N/A
//
// Dependency:
//				Force_Write_Back_Controller.v
//
// Timing:
//				7 cycles: From the input of a valid result targeting this cell, till the accumulated value is successfully written into the force cache
//				Cycle 1: register input & read from input FIFO (This may not necessary);
//				Cycle 2: select from input or input FIFO;
//				Cycle 3: read out previous force & delay the selected input force by one cycle to meet the previous force;
//				Cycle 4-6: accumulation (1 cycle read in the signals, then 2 more cycles for actual evaluation);
//				Cycle 7: write back force
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ns
module Force_Write_Back_Controller_tb;

	parameter DATA_WIDTH 					= 32;											// Data width of a single force value, 32-bit
	// Cell id this unit related to
	parameter CELL_X							= 2;
	parameter CELL_Y							= 2;
	parameter CELL_Z							= 2;
	// Force cache input buffer
	parameter FORCE_CACHE_BUFFER_DEPTH	= 16;
	parameter FORCE_CACHE_BUFFER_ADDR_WIDTH = 4;										// log(FORCE_CACHE_BUFFER_DEPTH) / log 2
	// Dataset defined parameters
	parameter CELL_ID_WIDTH					= 4;
	parameter MAX_CELL_PARTICLE_NUM		= 290;										// The maximum # of particles can be in a cell
	parameter CELL_ADDR_WIDTH				= 9;											// log(MAX_CELL_PARTICLE_NUM)
	parameter PARTICLE_ID_WIDTH			= CELL_ID_WIDTH*3+CELL_ADDR_WIDTH;	// # of bit used to represent particle ID, 9*9*7 cells, each 4-bit, each cell have max of 220 particles, 8-bit

	reg clk, rst;
	// Cache input force
	reg  in_partial_force_valid;
	reg  [PARTICLE_ID_WIDTH-1:0] in_particle_id;
	reg  [3*DATA_WIDTH-1:0] in_partial_force;
	// Cache output force
	reg  in_read_data_request;																	// Enables read data from the force cache, if this signal is high, then no write operation is permitted
	reg  [CELL_ADDR_WIDTH-1:0] in_cache_read_address;
	wire [3*DATA_WIDTH-1:0] out_partial_force;
	wire [PARTICLE_ID_WIDTH-1:0] out_particle_id;
	wire out_cache_readout_valid;
	
	reg [CELL_ADDR_WIDTH-1:0] particle_address;
	
	reg [6:0] global_counter;				// range: 0~127
	reg [4:0] tmp_counter;					// covering range 1~31
	
	always@(*)
		begin
		in_particle_id <= {4'd2,4'd2,4'd2, particle_address};
		end
		
	always #1 clk <= ~clk;
	
	always@(posedge clk)
		begin
		if(rst)
			begin
			global_counter <= 1;
			tmp_counter <= 1;
			
			in_partial_force_valid <= 1'b0;
			particle_address <= 9'd0;
			in_partial_force <= {32'h3F800000, 32'h3F800000, 32'h3F800000};				// input value: {1.0,1.0,1.0}
			in_read_data_request <= 1'b0;
			in_cache_read_address <= 9'd0;
			end
		else if(global_counter == 0)
			begin
			global_counter <= 1;
			tmp_counter <= 1;
			
			in_partial_force_valid <= 1'b0;
			particle_address <= 9'd0;
			in_partial_force <= {32'h3F800000, 32'h3F800000, 32'h3F800000};				// input value: {1.0,1.0,1.0}
			in_read_data_request <= 1'b0;
			in_cache_read_address <= 9'd0;
			end
		// Acc 1 to particle 1~20
		else if(global_counter < 20)
			begin
			global_counter <= global_counter + 1'b1;
			tmp_counter <= 1;
			
			in_partial_force_valid <= 1'b1;
			particle_address <= {2'd0, global_counter};
			in_partial_force <= {32'h3F800000, 32'h3F800000, 32'h3F800000};				// input value: {1.0,1.0,1.0}
			in_read_data_request <= 1'b0;
			in_cache_read_address <= 9'd0;
			end
		// Acc fix number to address 1~3
		else if(global_counter < 40)
			begin
			// Disable particle read
			in_read_data_request <= 1'b0;
			in_cache_read_address <= 9'd0;
			// Assign global_counter
			global_counter <= global_counter + 1'b1;
			// Assign tmp_counter
			if(tmp_counter == 3)
				tmp_counter <= 1;
			else
				tmp_counter <= tmp_counter + 1'b1;

			// Assign force input
			if(tmp_counter == 1)
				begin
				in_partial_force_valid <= 1'b1;
				particle_address <= {4'd0, tmp_counter};
				in_partial_force <= {32'h40080000, 32'h40080000, 32'h40080000};				// input value: {2.125,2.125,2.125}
				end
			else if(tmp_counter == 2)
				begin
				in_partial_force_valid <= 1'b1;
				particle_address <= {4'd0, tmp_counter};
				in_partial_force <= {32'h417E0000, 32'h417E0000, 32'h417E0000};				// input value: {15.875,15.875,15.875}
				end
			else if(tmp_counter == 3)
				begin
				in_partial_force_valid <= 1'b1;
				particle_address <= {4'd0, tmp_counter};
				in_partial_force <= {32'h42E04000, 32'h42E04000, 32'h42E04000};				// input value: {112.125,112.125,112.125}
				end
			else
				begin
				in_partial_force_valid <= 1'b0;
				particle_address <= 0;
				in_partial_force <= {32'h3F800000, 32'h3F800000, 32'h3F800000};				// input value: {1.0,1.0,1.0}
				end
			end
		// Disable input, wait for data process done
		else if(global_counter < 90)
			begin
			// Assign global_counter
			global_counter <= global_counter + 1'b1;
			tmp_counter <= 1;
			// Disable particle read
			in_read_data_request <= 1'b0;
			in_cache_read_address <= 9'd0;
			// Invalidate input
			in_partial_force_valid <= 1'b0;
			particle_address <= 9'd0;
			in_partial_force <= {32'h3F800000, 32'h3F800000, 32'h3F800000};				// input value: {1.0,1.0,1.0}
			end
		// Enable read
		else if(global_counter < 125)
			begin
			// Assign global_counter
			global_counter <= global_counter + 1'b1;
			tmp_counter <= tmp_counter + 1'b1;
			// Enable particle read
			in_read_data_request <= 1'b1;
			in_cache_read_address <= {4'd0, tmp_counter};
			// Invalidate input
			in_partial_force_valid <= 1'b0;
			particle_address <= 9'd0;
			in_partial_force <= {32'h3F800000, 32'h3F800000, 32'h3F800000};				// input value: {1.0,1.0,1.0}
			end
		// Wait for read finish
		else
			begin
			// Assign global_counter
			global_counter <= global_counter + 1'b1;
			tmp_counter <= 1;
			// Disable particle read
			in_read_data_request <= 1'b0;
			in_cache_read_address <= 9'd0;
			// Invalidate input
			in_partial_force_valid <= 1'b0;
			particle_address <= 9'd0;
			in_partial_force <= {32'h3F800000, 32'h3F800000, 32'h3F800000};				// input value: {1.0,1.0,1.0}
			end
		end
		
	//////////////////////////////////////////////////////////
	// Final value:
	//	1: 1.0+2.125*7 = 15.875 (32'h417E0000)
	//	2: 1.0+15.875*7 = 112.125 (32'h42E04000)
	//	3: 1.0+112.125*6 = 673.75 (32'h44287000)
	//	4~19: 1.0 (32'h3F800000)
	//	19~...: 0.0 (32'h00000000)
	//  
	//////////////////////////////////////////////////////////
	
	initial begin
		clk <= 1'b1;
		rst <= 1'b1;
		in_partial_force_valid <= 1'b0;
		particle_address <= 9'd0;
		in_partial_force <= {32'h3F800000, 32'h3F800000, 32'h3F800000};				// input value: {1.0,1.0,1.0}
		in_read_data_request <= 1'b0;
		in_cache_read_address <= 9'd0;
		
		// Clear reset signal
		#10
		rst <= 1'b0;
/*		
		// ID: 1, Value 1.0, for 5 cycles
		#10
		in_partial_force_valid <= 1'b1;
		particle_address <= 9'd1;
		
		// ID: 2, Value 1.0
		#10
		in_partial_force_valid <= 1'b1;
		particle_address <= 9'd2;
		
		// ID: 4, Value 1.0
		#2
		in_partial_force_valid <= 1'b1;
		particle_address <= 9'd4;
			
		// ID: 3, Value 1.0, Input invalid
		#2
		in_partial_force_valid <= 1'b0;
		particle_address <= 9'd3;
		
		// ID: 3, Value 1.0
		#2
		in_partial_force_valid <= 1'b1;
		particle_address <= 9'd3;
		
		// ID: 4, Value 1.0
		#2
		in_partial_force_valid <= 1'b1;
		particle_address <= 9'd4;
		
		// ID: 3, Value 1.0
		#2
		in_partial_force_valid <= 1'b1;
		particle_address <= 9'd3;
		
		// ID: 5, Value 1.0
		#2
		in_partial_force_valid <= 1'b1;
		particle_address <= 9'd5;
		
		// ID: 2, Value 1.0
		#2
		in_partial_force_valid <= 1'b1;
		particle_address <= 9'd2;
		
		// ID: 2, Value 1.0, invalid
		#2
		in_partial_force_valid <= 1'b0;
		particle_address <= 9'd2;
		
		// ID: 4, Value 1.0
		#2
		in_partial_force_valid <= 1'b1;
		particle_address <= 9'd4;
		
		// ID: 3, Value 1.0
		#2
		in_partial_force_valid <= 1'b1;
		particle_address <= 9'd3;
		
		// ID: 4, Value 1.0
		#2
		in_partial_force_valid <= 1'b1;
		particle_address <= 9'd4;
		
		// ID: 3, Value 1.0
		#2
		in_partial_force_valid <= 1'b1;
		particle_address <= 9'd3;
		
		// ID: 4, Value 1.0
		#2
		in_partial_force_valid <= 1'b1;
		particle_address <= 9'd4;
		
		// Invalidate input to let the accumulation finish
		#2
		in_partial_force_valid <= 1'b0;
		
		// Readout the final result
		#200
		in_read_data_request <= 1'b1;
		in_cache_read_address <= 9'd1;
		
		#2
		in_cache_read_address <= 9'd2;
		
		#2
		in_cache_read_address <= 9'd3;
		
		#2
		in_cache_read_address <= 9'd4;
		
		#2
		in_cache_read_address <= 9'd5;
		
		#2
		in_read_data_request <= 1'b0;
		
		//////////////////////////////////////////////////////////
		// Final value:
		//	1: 5.0 (32'h40A00000)
		//	2: 2.0 (32'h40000000)
		//	3: 4.0 (32'h40800000)
		//	4: 5.0 (32'h40A00000)
		//	5: 1.0 (32'h3F800000)
		//////////////////////////////////////////////////////////
		
		
		// ID: 3, Value 1.36
		#20
		in_partial_force_valid <= 1'b1;
		particle_address <= 9'd3;
		in_partial_force <= {32'h3FAE47B0, 32'h3FAE47B0, 32'h3FAE47B0};				// input value: {1.36,1.36,1.36}
		
		// ID: 4, Value 2.48
		#2
		in_partial_force_valid <= 1'b1;
		particle_address <= 9'd4;
		in_partial_force <= {32'h401EB852, 32'h401EB852, 32'h401EB852};				// input value: {2.48,2.48,2.48}
		
		// ID: 5, Value 3.14
		#2
		in_partial_force_valid <= 1'b1;
		particle_address <= 9'd5;
		in_partial_force <= {32'h4048F5C3, 32'h4048F5C3, 32'h4048F5C3};				// input value: {3.14,3.14,3.14}
		
		// ID: 3, Value 1.36
		#2
		in_partial_force_valid <= 1'b1;
		particle_address <= 9'd3;
		in_partial_force <= {32'h3FAE47B0, 32'h3FAE47B0, 32'h3FAE47B0};				// input value: {1.36,1.36,1.36}
		
		// ID: 4, Value 2.48
		#2
		in_partial_force_valid <= 1'b1;
		particle_address <= 9'd4;
		in_partial_force <= {32'h401EB852, 32'h401EB852, 32'h401EB852};				// input value: {2.48,2.48,2.48}
		
		// ID: 5, Value 3.14
		#2
		in_partial_force_valid <= 1'b1;
		particle_address <= 9'd5;
		in_partial_force <= {32'h4048F5C3, 32'h4048F5C3, 32'h4048F5C3};				// input value: {3.14,3.14,3.14}
		
		// Invalidate input to let the accumulation finish
		#2
		in_partial_force_valid <= 1'b0;
		
		// Readout the final result
		#200
		in_read_data_request <= 1'b1;
		in_cache_read_address <= 9'd1;
		
		#2
		in_cache_read_address <= 9'd2;
		
		#2
		in_cache_read_address <= 9'd3;
		
		#2
		in_cache_read_address <= 9'd4;
		
		#2
		in_cache_read_address <= 9'd5;
		
		#2
		in_read_data_request <= 1'b0;
		
		//////////////////////////////////////////////////////////
		// Final value:
		//	1: 5.0 (32'h40A00000)
		//	2: 2.0 (32'h40000000)
		//	3: 4.0+1.36*2 = 6.72 (32'h40D70A3D)
		//	4: 5.0+2.48*2 = 9.96 (32'h411F5C29)
		//	5: 1.0+3.14*2 = 7.28 (32'h40E8F5C3)
		//////////////////////////////////////////////////////////
*/		
	end
	
	
	// UUT
	Force_Write_Back_Controller
	#(
		.DATA_WIDTH(DATA_WIDTH),									// Data width of a single force value, 32-bit
		// Dell id this unit related to
		.CELL_X(CELL_X),
		.CELL_Y(CELL_Y),
		.CELL_Z(CELL_Z),
		// Dataset defined parameters
		.CELL_ID_WIDTH(CELL_ID_WIDTH),
		.MAX_CELL_PARTICLE_NUM(MAX_CELL_PARTICLE_NUM),		// The maximum # of particles can be in a cell
		.CELL_ADDR_WIDTH(CELL_ADDR_WIDTH),						// log(MAX_CELL_PARTICLE_NUM)
		.PARTICLE_ID_WIDTH(PARTICLE_ID_WIDTH)					// # of bit used to represent particle ID, 9*9*7 cells, each 4-bit, each cell have max of 220 particles, 8-bit
	)
	Force_Write_Back_Controller
	(
		.clk(clk),
		.rst(rst),
		// Cache input force
		.in_partial_force_valid(in_partial_force_valid),
		.in_particle_id(in_particle_id),
		.in_partial_force(in_partial_force),
		// Cache output force
		.in_read_data_request(in_read_data_request),									// Enables read data from the force cache, if this signal is high, then no write operation is permitted
		.in_cache_read_address(in_cache_read_address),
		.out_partial_force(out_partial_force),
		.out_particle_id(out_particle_id),
		.out_cache_readout_valid(out_cache_readout_valid)
	);

endmodule