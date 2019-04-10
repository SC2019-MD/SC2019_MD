/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: RL_LJ_Evaluate_Pairs_LJ_1st_Order_tb.v
//
//	Function: Testbench for timing evaluation of RL_Evaluate_Pairs_LJ_1st_Order.v
//
// Dependency:
// 			RL_LJ_Evaluate_Pairs_1st_Order.v
//
//
// FP IP timing:
//				FP_SUB: ay - ax = result				latency: 2
//				FP_MUL: ay * az = result				latency: 3
//				FP_MUL_ADD: ay * az + ax  = result	latency: 4
//
// Latency: total: 11 cycles
//				Input level: wait for table lookup to finish					      2 cycle
//				Level 1: calculate r8, r14 (MUL_ADD)						         4 cycles
//				Level 2: calculate LJ force (SUB)							         2 cycles
//				Level 3: calculate Force component in each direction (MUL)		3 cycles
//

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
`timescale 1ps/1ps

module RL_Evaluate_Pairs_LJ_1st_Order_tb;

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
	
	wire [31:0] LJ_Force_X;
	wire [31:0] LJ_Force_Y;
	wire [31:0] LJ_Force_Z;
	wire LJ_force_valid;

	RL_Evaluate_Pairs_LJ_1st_Order test_inst
	(
		.clk(clk),
		.rst(rst),
		.r2_valid(r2_valid),
		.r2(r2),										// in IEEE floating point
		.dx(dx),										// in IEEE floating point
		.dy(dy),										// in IEEE floating point
		.dz(dz),										// in IEEE floating point
		.LJ_Force_X(LJ_Force_X),								// in IEEE floating point
		.LJ_Force_Y(LJ_Force_Y),								// in IEEE floating point
		.LJ_Force_Z(LJ_Force_Z),								// in IEEE floating point
		.LJ_force_valid(LJ_force_valid)
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