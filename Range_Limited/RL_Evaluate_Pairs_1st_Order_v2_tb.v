/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: RL_Evaluate_Pairs_1st_Order_v2_tb.v
//
//	Function: Testbench for timing evaluation of RL_Evaluate_Pairs_1st_Order_v2.v
//
// Dependency:
// 			RL_Evaluate_Pairs_1st_Order_v2.v
//
//
// FP IP timing:
//				FP_SUB: ay - ax = result				latency: 2
//				FP_MUL: ay * az = result				latency: 3
//				FP_MUL_ADD: ay * az + ax  = result	latency: 4
//
// Latency: total: 17 cycles
//				Input level: wait for table lookup to finish							2 cycle
//				Level 1: calculate r3, r8, r14 terms (MUL_ADD)						5 cycles
//				Level 2: calculate LJ Force (SUB)										3 cycles
//				Level 3: calculate RL Force (ADD)										3 cycles
//				Level 4: calculate Force components in each direction (MUL)		4 cycles
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ns

module RL_Evaluate_Pairs_1st_Order_v2_tb;

	parameter DATA_WIDTH 				= 32;
	parameter SEGMENT_NUM				= 9;
	parameter SEGMENT_WIDTH				= 4;
	parameter BIN_NUM						= 256;
	parameter BIN_WIDTH					= 8;
	parameter CUTOFF_2					= 32'h43100000;						// (12^2=144 in IEEE floating point)
	parameter LOOKUP_NUM					= SEGMENT_NUM * BIN_NUM;			// SEGMENT_NUM * BIN_NUM
	parameter LOOKUP_ADDR_WIDTH		= SEGMENT_WIDTH + BIN_WIDTH;		// log LOOKUP_NUM / log 2


	reg clk;
	reg rst;
	reg r2_valid_wire;
	reg [31:0] r2_wire;
	reg [31:0] dx_wire;
	reg [31:0] dy_wire;
	reg [31:0] dz_wire;
	
	reg r2_valid;
	reg [31:0] r2;
	reg [31:0] dx;
	reg [31:0] dy;
	reg [31:0] dz;
	
	wire [31:0] RL_Force_X;
	wire [31:0] RL_Force_Y;
	wire [31:0] RL_Force_Z;
	wire RL_force_valid;

	RL_Evaluate_Pairs_1st_Order_v2
	#(
		.DATA_WIDTH(DATA_WIDTH),
		.SEGMENT_NUM(SEGMENT_NUM),
		.SEGMENT_WIDTH(SEGMENT_WIDTH),
		.BIN_NUM(BIN_NUM),
		.BIN_WIDTH(BIN_WIDTH),
		.CUTOFF_2(CUTOFF_2),
		.LOOKUP_NUM(LOOKUP_NUM),
		.LOOKUP_ADDR_WIDTH(LOOKUP_ADDR_WIDTH)
	)
	UUT
	(
		.clk(clk),
		.rst(rst),
		.r2_valid(r2_valid),
		.r2(r2),										// in IEEE floating point
		.dx(dx),										// in IEEE floating point
		.dy(dy),										// in IEEE floating point
		.dz(dz),										// in IEEE floating point
		.RL_Force_X(RL_Force_X),				// in IEEE floating point
		.RL_Force_Y(RL_Force_Y),				// in IEEE floating point
		.RL_Force_Z(RL_Force_Z),				// in IEEE floating point
		.RL_force_valid(RL_force_valid)
	);
	
	always #1 clk <= ~clk;
	
	always@(posedge clk)
		begin
		r2_valid <= r2_valid_wire;
		r2 <= r2_wire;
		dx <= dx_wire;
		dy <= dy_wire;
		dz <= dz_wire;
		end
	
	initial begin
		clk <= 1'b1;
		rst <= 1'b1;
		r2_valid_wire <= 1'b0;
		r2_wire <= 32'd0;
		dx_wire <= 32'd0;
		dy_wire <= 32'd0;
		dz_wire <= 32'd0;
		
		#10
		rst <= 1'b0;
		
		#10
		// F = -0.0412
		// Fx = -0.0412
		// Fy = -0.0824
		// Fz = -0.1648
		r2_valid_wire <= 1'b1;
		dx_wire <= 32'h3F800000;				// 1.0
		dy_wire <= 32'h40000000;				// 2.0
		dz_wire <= 32'h40800000;				// 4.0
		r2_wire <= 32'h41A80000;				// 1+4+16 = 21.0
		
		#2
		r2_valid_wire <= 1'b1;
		dx_wire <= 32'h40000000;				// 2.0
		dy_wire <= 32'h40000000;				// 2.0
		dz_wire <= 32'h40000000;				// 2.0
		r2_wire <= 32'h41400000;				// 4+4+4 = 12.0
		
		#2
		r2_valid_wire <= 1'b1;
		dx_wire <= 32'h3F800000;				// 1.0
		dy_wire <= 32'h40000000;				// 2.0
		dz_wire <= 32'h40800000;				// 4.0
		r2_wire <= 32'h41A80000;				// 1+4+16 = 21.0
		
		#10
		r2_valid_wire <= 1'b0;

		#100
		$stop;
		
	end
	
endmodule