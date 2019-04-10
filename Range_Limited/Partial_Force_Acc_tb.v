/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: Partial_Force_Acc_tb.v
//
//	Function: Testbench for Partial_Force_Acc.v
//
// Dependency:
//				Partial_Force_Acc.v
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ns
module Partial_Force_Acc_tb;

	parameter DATA_WIDTH 					= 32;
	parameter PARTICLE_ID_WIDTH			= 20;								// # of bit used to represent particle ID, 9*9*7 cells, each 4-bit, each cell have max of 200 particles, 8-bit

	reg clk, rst;
	reg in_input_valid;
	reg [PARTICLE_ID_WIDTH-1:0] in_particle_id;
	reg [DATA_WIDTH-1:0] in_partial_force;
	wire [DATA_WIDTH-1:0] in_partial_force_x, in_partial_force_y, in_partial_force_z;
	wire [PARTICLE_ID_WIDTH-1:0] out_particle_id;
	wire [DATA_WIDTH-1:0] out_particle_acc_force_x, out_particle_acc_force_y, out_particle_acc_force_z;
	wire out_acc_force_valid;
	
	assign in_partial_force_x = in_partial_force;
	assign in_partial_force_y = in_partial_force;
	assign in_partial_force_z = in_partial_force;

	always #1 clk <= ~clk;
	
	reg [9:0] tmp_counter;
	
	always@(posedge clk)
		if(rst)
			begin
			in_input_valid <= 1'b0;
			in_particle_id <= 0;
			in_partial_force <= 0;
			
			tmp_counter <= 0;
			end
		else
			begin
			tmp_counter <= tmp_counter + 1'b1;
			
			if(tmp_counter < 2)
				begin
				in_input_valid <= 1'b0;
				in_particle_id <= 0;
				in_partial_force <= 32'h40000000;				// 2.0
				end
			// Particle 0 start
			else if(tmp_counter < 6)
				begin
				in_input_valid <= 1'b1;
				in_particle_id <= 0;
				in_partial_force <= 32'h40000000;				// 2.0
				end
			// Particle 0 invalid in the middle
			else if(tmp_counter < 8)
				begin
				in_input_valid <= 1'b0;
				in_particle_id <= 0;
				in_partial_force <= 32'h40000000;				// 2.0
				end
			// Particle 0 resume
			else if(tmp_counter < 10)
				begin
				in_input_valid <= 1'b1;
				in_particle_id <= 0;
				in_partial_force <= 32'h40000000;				// 2.0
				end
			
			////////////////////////////////////////////////
			// ID:0, Value is (4+2)*2 = 12 (0x41400000)
			////////////////////////////////////////////////
			
			// Particle 1 start
			else if(tmp_counter < 15)
				begin
				in_input_valid <= 1'b1;
				in_particle_id <= 1;
				in_partial_force <= 32'h3F800000;				// 1.0
				end
			
			////////////////////////////////////////////////
			// ID:1, Value is 5 * 1 = 5 (0x40A00000)
			////////////////////////////////////////////////
			
			// Particle 0 start
			else if(tmp_counter < 25)
				begin
				in_input_valid <= 1'b1;
				in_particle_id <= 0;
				in_partial_force <= 32'h4048F5C3;				// 3.14
				end
			// Particle 0 invalid
			else if(tmp_counter < 27)
				begin
				in_input_valid <= 1'b0;
				in_particle_id <= 0;
				in_partial_force <= 32'h4048F5C3;				// 3.14
				end
				
			////////////////////////////////////////////////
			// ID:0, Value is 10 * 3.14 = 31.4 (0x41FB3332)
			////////////////////////////////////////////////
			
			// Particle 3 invalid
			else if(tmp_counter < 30)
				begin
				in_input_valid <= 1'b0;
				in_particle_id <= 3;
				in_partial_force <= 32'h40800000;				// 4
				end
			
			////////////////////////////////////////////////
			// ID:3, Value is 3 * 0 = 0 (0x00000000)
			////////////////////////////////////////////////
			
			// Particle 4 invalid
			else if(tmp_counter < 32)
				begin
				in_input_valid <= 1'b0;
				in_particle_id <= 4;
				in_partial_force <= 32'h40800000;				// 4
				end
			// Particle 4 valid
			else if(tmp_counter < 35)
				begin
				in_input_valid <= 1'b1;
				in_particle_id <= 4;
				in_partial_force <= 32'h40800000;				// 4
				end
			
			////////////////////////////////////////////////
			// ID:4, Value is 3 * 4 = 12 (0x41400000)
			////////////////////////////////////////////////
			
			// Particle 5 valid
			else if(tmp_counter < 45)
				begin
				in_input_valid <= 1'b1;
				in_particle_id <= 5;
				in_partial_force <= 32'h40800000;				// 4
				end
				
			////////////////////////////////////////////////
			// ID:5, Value is 10 * 4 = 40 (0x42200000)
			////////////////////////////////////////////////
			
			// Particle 6 invalid
			else if(tmp_counter < 50)
				begin
				in_input_valid <= 1'b0;
				in_particle_id <= 6;
				in_partial_force <= 32'h40800000;				// 4
				end
			// Particle 6 valid
			else if(tmp_counter < 56)
				begin
				in_input_valid <= 1'b1;
				in_particle_id <= 6;
				in_partial_force <= 32'h3F800000;				// 1
				end
			// Particle 6 invalid
			else if(tmp_counter < 60)
				begin
				in_input_valid <= 1'b0;
				in_particle_id <= 6;
				in_partial_force <= 32'h3F800000;				// 1
				end
			
			////////////////////////////////////////////////
			// ID:6, Value is 6 * 1 = 6 (0x40C00000)
			////////////////////////////////////////////////
			
			// Particle 7 invalid
			else
				begin
				in_input_valid <= 1'b0;
				in_particle_id <= 7;
				in_partial_force <= 32'h3F800000;				// 1
				end			
			end
	
	initial begin
		clk <= 1'b1;
		rst <= 1'b1;
		
		#10
		rst <= 1'b0;
	end
	
	
	
	Partial_Force_Acc
	#(
		.DATA_WIDTH(DATA_WIDTH),
		.PARTICLE_ID_WIDTH(PARTICLE_ID_WIDTH)								// # of bit used to represent particle ID, 9*9*7 cells, each 4-bit, each cell have max of 200 particles, 8-bit
	)
	UUT
	(
		.clk(clk),
		.rst(rst),
		.in_input_valid(in_input_valid),
		.in_particle_id(in_particle_id),
		.in_partial_force_x(in_partial_force_x),
		.in_partial_force_y(in_partial_force_y),
		.in_partial_force_z(in_partial_force_z),
		.out_particle_id(out_particle_id),
		.out_particle_acc_force_x(out_particle_acc_force_x),
		.out_particle_acc_force_y(out_particle_acc_force_y),
		.out_particle_acc_force_z(out_particle_acc_force_z),
		.out_acc_force_valid(out_acc_force_valid)							// only set as valid when the particle_id changes, which means the accumulation for the current particle is done
	);

endmodule