/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: Pos_Cache_2_2_2_tb.v
//
//	Function:
//				Testbench for Pos_Cache_2_2_2
//
//	Purpose:
//				Testing the cell memory swap function during motion update
//
// Data Organization:
//				Address 0 for each cell module: # of particles in the cell
//				Position data: MSB-LSB: {posz, posy, posx}
//				Cell address: MSB-LSB: {cell_x, cell_y, cell_z}
//
// Used by:
//				N/A.v
//
// Dependency:
//				Pos_Cache_2_2_2.v
//
// Timing:
//				1 cycle reading delay from input address and output data.
//
// Created by:
//				Chen Yang  12/18/2018
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ns

module Pos_Cache_2_2_2_tb;

	parameter DATA_WIDTH = 32;
	parameter PARTICLE_NUM = 220;
	parameter ADDR_WIDTH = 8;
	parameter CELL_ID_WIDTH = 4;
	parameter CELL_X = 2;
	parameter CELL_Y = 2;
	parameter CELL_Z = 2;
	
	reg clk;
	reg rst;
	reg motion_update_enable;										// Keep this signal as high during the motion update process
	reg [ADDR_WIDTH-1:0] in_read_address;
	reg [DATA_WIDTH-1:0] in_data;
	reg [3*CELL_ID_WIDTH-1:0] in_data_dst_cell;				// The destination cell for the incoming data
	reg in_data_valid;												// Signify if the new incoming data is valid
	reg in_rden;
	wire [DATA_WIDTH-1:0] out_particle_info;
	
	always #1 clk <= ~clk;
	
	reg [ADDR_WIDTH-1:0] counter;
	parameter DATA_READ = 2'b00;
	parameter POSITION_UPDATE = 2'b01;
	parameter WAIT_FOR_WRITE_FINISH = 2'b10;
	
	reg [1:0] state;
	
	always@(posedge clk)
		begin
		if(rst)
			begin
			counter <= 0;
			motion_update_enable <= 1'b0;
			in_read_address <= 0;
			in_data <= 0;
			in_data_dst_cell <= {4'd0, 4'd0, 4'd0};
			in_data_valid <= 1'b0;
			in_rden <= 1'b0;
			state <= DATA_READ;
			end
		else
			begin
			case(state)
				DATA_READ:
					begin
					motion_update_enable <= 1'b0;
					in_read_address <= counter;
					in_data <= 0;
					in_data_dst_cell <= {4'd0, 4'd0, 4'd0};
					in_data_valid <= 1'b0;
					in_rden <= 1'b1;
					if(counter < 15)
						begin
						counter <= counter + 1'b1;
						state <= DATA_READ;
						end
					else
						begin
						counter <= 0;
						state <= POSITION_UPDATE;
						end
					end
				
				POSITION_UPDATE:
					begin
					motion_update_enable <= 1'b1;
					in_read_address <= counter;
					in_data <= counter;
					in_data_dst_cell <= {4'd2, 4'd2, 4'd2};
					in_data_valid <= 1'b1;
					in_rden <= 1'b1;
					if(counter < 11)
						begin
						counter <= counter + 1'b1;
						state <= POSITION_UPDATE;
						end
					else
						begin
						counter <= 0;
						state <= WAIT_FOR_WRITE_FINISH;
						end
					end
				WAIT_FOR_WRITE_FINISH:
					begin
					motion_update_enable <= 1'b0;
					in_read_address <= counter;
					in_data <= counter;
					in_data_dst_cell <= {4'd2, 4'd2, 4'd2};
					in_data_valid <= 1'b0;
					in_rden <= 1'b1;
					if(counter < 4)
						begin
						counter <= counter + 1'b1;
						state <= WAIT_FOR_WRITE_FINISH;
						end
					else
						begin
						counter <= 0;
						state <= DATA_READ;
						end
					end
			endcase
			end
		end
	
	initial begin
		rst <= 1'b1;
		clk <= 1'b1;
		
		#10
		rst <= 1'b0;
	end
	
	Pos_Cache_2_2_2
	#(
		.DATA_WIDTH(DATA_WIDTH),
		.PARTICLE_NUM(PARTICLE_NUM),
		.ADDR_WIDTH(ADDR_WIDTH),
		.CELL_ID_WIDTH(CELL_ID_WIDTH),
		.CELL_X(CELL_X),
		.CELL_Y(CELL_Y),
		.CELL_Z(CELL_Z)
	)
	UUT
	(
		.clk(clk),
		.rst(rst),
		.motion_update_enable(motion_update_enable),					// Keep this signal as high during the motion update process
		.in_read_address(in_read_address),
		.in_data(in_data),
		.in_data_dst_cell(in_data_dst_cell),							// The destination cell for the incoming data
		.in_data_valid(in_data_valid),									// Signify if the new incoming data is valid
		.in_rden(in_rden),
		.out_particle_info(out_particle_info)
);
	
endmodule