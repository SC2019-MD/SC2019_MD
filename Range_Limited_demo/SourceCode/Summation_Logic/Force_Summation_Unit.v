/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: Force_Summation_Unit.v
//
// Function: 
//				Sum up the 3 forces: Short Range, Long Range, and Bonded Force on a singel particle
//
// Data Organization:
//
// Used by:
//				Summation_Logic.v
//
// Dependency:
//				FP_Add.v
//
// Testbench:
//				_tb.v
//
// Timing:
//				Total Latency:		6 cycles
//				FP_ADD: 				3 cycles
//
// Created by: 
//				Tong Geng 03/26/2019
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module Force_Summation_Unit
#(
	parameter DATA_WIDTH 					= 32
)
(
	input clk,
	input rst,
	input valid_in,
	input [3*DATA_WIDTH-1:0] force_to_sum_from_lr,
	input [3*DATA_WIDTH-1:0] force_to_sum_from_sr,
	input [3*DATA_WIDTH-1:0] force_to_sum_from_bf,
	output [3*DATA_WIDTH-1:0] out_Sumed_Force,
	output valid_out
);
 
	wire [DATA_WIDTH-1:0] force_x1;
	wire [DATA_WIDTH-1:0] force_y1;
	wire [DATA_WIDTH-1:0] force_z1;
	wire [DATA_WIDTH-1:0] force_x;
	wire [DATA_WIDTH-1:0] force_y;
	wire [DATA_WIDTH-1:0] force_z;
	reg valid_out_reg0;
	reg valid_out_reg1;
	reg valid_out_reg2;
	reg valid_out_reg3;
	reg valid_out_reg4;
	reg valid_out_reg5;
	assign valid_out = valid_out_reg5;

	always@(posedge clk)
		begin
		valid_out_reg0 <= valid_in;
		valid_out_reg1 <= valid_out_reg0;
		valid_out_reg2 <= valid_out_reg1;
		valid_out_reg3 <= valid_out_reg2;
		valid_out_reg4 <= valid_out_reg3;
		valid_out_reg5 <= valid_out_reg4;
		end


	////////////////////////////////////////////////////////////////////////////////////////
	// ********************* Level 1 ***********************
	// Sum up Long Range and Short Range Force
	////////////////////////////////////////////////////////////////////////////////////////
	FP_ADD forcex_lr_sr(
		.clk(clk),
		.ena(valid_in),
		.clr(rst),
		.ax(force_to_sum_from_lr[1*DATA_WIDTH-1:0*DATA_WIDTH]),
		.ay(force_to_sum_from_sr[1*DATA_WIDTH-1:0*DATA_WIDTH]),
		.result(force_x1)
	);

	FP_ADD forcey_lr_sr(
		.clk(clk),
		.ena(valid_in),
		.clr(rst),
		.ax(force_to_sum_from_lr[2*DATA_WIDTH-1:1*DATA_WIDTH]),
		.ay(force_to_sum_from_sr[2*DATA_WIDTH-1:1*DATA_WIDTH]),
		.result(force_y1)
	);
	 
	FP_ADD forcez_lr_sr(
		.clk(clk),
		.ena(valid_in),
		.clr(rst),
		.ax(force_to_sum_from_lr[3*DATA_WIDTH-1:2*DATA_WIDTH]),
		.ay(force_to_sum_from_sr[3*DATA_WIDTH-1:2*DATA_WIDTH]),
		.result(force_z1)
	);

	////////////////////////////////////////////////////////////////////////////////////////
	// ********************* Level 2 ***********************
	// Sum up Bonded Force and Previous particle sum
	////////////////////////////////////////////////////////////////////////////////////////
	FP_ADD forcex_bf(
		.clk(clk),
		.ena(valid_out_reg),
		.clr(rst),
		.ax(force_x1),
		.ay(force_to_sum_from_bf[1*DATA_WIDTH-1:0*DATA_WIDTH]),
		.result(force_x)
	);

	FP_ADD forcey_bf(
		.clk(clk),
		.ena(valid_out_reg),
		.clr(rst),
		.ax(force_y1),
		.ay(force_to_sum_from_bf[2*DATA_WIDTH-1:1*DATA_WIDTH]),
		.result(force_y)
	);
	  
	FP_ADD forcez_bf(
		.clk(clk),
		.ena(valid_out_reg),
		.clr(rst),
		.ax(force_z1),
		.ay(force_to_sum_from_bf[3*DATA_WIDTH-1:2*DATA_WIDTH]),
		.result(force_z)
	);

	assign out_Sumed_Force = {force_z,force_y,force_x};
 
endmodule
