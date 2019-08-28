/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: RL_Evaluate_Pairs_Direct.v
//
//	Function: Evaluate the piarwise non-bonded force between the intput particle pair using direct compututation
// 			Taking the square distance as input
//				!!!!!!!!! This module is mainly used for resource estimation !!!!!!
//
// Dependency:
//				FP_ADD
//				FP_SUB
//				FP_MUL
//				FP_MUL_ADD
//				FP_Div
//				FP_Sqrt
//
//
// FP IP timing:
//				FP_SUB: ay - ax = result				latency: 3
//				FP_MUL: ay * az = result				latency: 4
//				FP_MUL_ADD: ay * az + ax  = result	latency: 5
//				FP_Div: ay / ax = result				latency: 38
//				FP_Sqrt:	sqrt(a) = result 				latency: 18
//
// Latency: total: ~66 cycles
//				Input level: wait for table lookup to finish													2 cycle
//				Level 1: Get inv_r3, inv_r4, inv_r8																~50 cycle
//				Level 2: calculate Coulomb force (MUL)															4 cycles
//				Level 3: calculate Coulomb force + r8 term (MUL_ADD)										5 cycles
//				Level 4: calculate Final force (MUL_ADD)														5 cycles
//
// Need to be done (10/03/18):
//		Calculate the output for force components on each direction
//		When select output force, need to propgate the r2 value along with the force evaluation datapath, to select the output force value
//
// Created by:
//				Chen Yang 09/06/18
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module RL_Evaluate_Pairs_Direct
#(
	parameter DATA_WIDTH 				= 32
)
(
	input  clk,
	input  rst,
	input  r2_valid,
	input  [DATA_WIDTH-1:0] r2,										// in IEEE floating point
	input  [DATA_WIDTH-1:0] p_a,										// in IEEE floating point
	input  [DATA_WIDTH-1:0] p_b,										// in IEEE floating point
	input  [DATA_WIDTH-1:0] p_qq,										// in IEEE floating point
	input  [DATA_WIDTH-1:0] p_G0,										// in IEEE floating point, C3 smooth function coefficient
	input  [DATA_WIDTH-1:0] p_G1,										// in IEEE floating point, C3 smooth function coefficient
	input  [DATA_WIDTH-1:0] p_G2,										// in IEEE floating point, C3 smooth function coefficient
	output [DATA_WIDTH-1:0] RL_force,								// in IEEE floating point
	output reg RL_force_valid
);

	// Force evaluation intermediate results
	wire [31:0] r;
	wire [31:0] inv_r2;
	wire [31:0] inv_r3;
	wire [31:0] inv_r4;
	wire [31:0] inv_r6;
	wire [31:0] inv_r8;
	wire [31:0] inv_r14;
	wire [31:0] coulomb_force_partial;
	wire [31:0] coulomb_force;
	wire [31:0] partial_force;
	
	// C3 smooth function results
	wire [31:0] r4;
	wire [31:0] smooth_result1;
	wire [31:0] smooth_result2;
	wire [31:0] smooth_final;


	// Calculate: r4 = r2 * r2
	FP_MUL FP_MUL_r4 (
		.ay(r2),     		//     ay.ay
		.az(r2),     			//     az.az
		.clk(clk),    				//    clk.clk
		.clr(rst),    				//    clr.clr
		.ena(r2_valid),    		//    ena.ena
		.result(r4)  // result.result
	);
	
	// Calculate: G1 * r2
	FP_MUL FP_MUL_smooth_result1 (
		.ay(p_G1),     		//     ay.ay
		.az(r2),     			//     az.az
		.clk(clk),    				//    clk.clk
		.clr(rst),    				//    clr.clr
		.ena(r2_valid),    		//    ena.ena
		.result(smooth_result1)  // result.result
	);
	
	// Calculate: G2 * r4 + G1 * r2
	FP_MUL_ADD FP_MUL_ADD_smooth_result2 (
		.ax     (smooth_result1), //   input,  width = 32,     ax.ax
		.ay     (r4),     //   input,  width = 32,     ay.ay
		.az     (p_G2),     		 //   input,  width = 32,     az.az
		.clk    (clk),           //   input,   width = 1,    clk.clk
		.clr    (rst),           //   input,   width = 2,    clr.clr
		.ena    (r2_valid),     //   input,   width = 1,    ena.ena
		.result (smooth_result2)  //   output,  width = 32, result.result
	);
	
	// Calculate: C3 Smooth function: G2 * r4 + G1 * r2 + G0
	FP_ADD FP_ADD_smooth_final(
		.ax     (smooth_result2),     //   input,  width = 32,     ax.ax
		.ay     (p_G0),     //   input,  width = 32,     ay.ay
		.clk    (clk),    //   input,   width = 1,    clk.clk
		.clr    (rst),    //   input,   width = 2,    clr.clr
		.ena    (r2_valid),    //   input,   width = 1,    ena.ena
		.result (smooth_final)  //  output,  width = 32, result.result
	);
	
	// Get r = sqrt(r2)
	FP_Sqrt FP_Sqrt_r(
		.a(r2),
		.areset(rst),
		.clk(clk),
		.q(r)
	);
	
	// Get inv_r2
	FP_Div FP_Div_inv_r2(
		.a      (r2),      //   input,  width = 32,      a.a
		.areset (rst), //   input,   width = 1, areset.reset
		.b      (32'h3F800000),      //   input,  width = 32, value is 1.0
		.clk    (clk),    //   input,   width = 1,    clk.clk
		.q      (inv_r2)       //  output,  width = 32,      q.q
	);
	
	// Calculate: inv_r4 = inv_r2 * inv_r2
	FP_MUL FP_MUL_inv_r4 (
		.ay(inv_r2),     		//     ay.ay
		.az(inv_r2),     			//     az.az
		.clk(clk),    				//    clk.clk
		.clr(rst),    				//    clr.clr
		.ena(r2_valid),    		//    ena.ena
		.result(inv_r4)  // result.result
	);
	
	// Calculate: inv_r3 = inv_r4 * r
	FP_MUL FP_MUL_inv_r3 (
		.ay(inv_r4),     		//     ay.ay
		.az(r),     			//     az.az
		.clk(clk),    				//    clk.clk
		.clr(rst),    				//    clr.clr
		.ena(r2_valid),    		//    ena.ena
		.result(inv_r3)  // result.result
	);
	
	// Calculate: inv_r6 = inv_r4 * inv_r2
	FP_MUL FP_MUL_inv_r6 (
		.ay(inv_r4),     		//     ay.ay
		.az(inv_r2),     			//     az.az
		.clk(clk),    				//    clk.clk
		.clr(rst),    				//    clr.clr
		.ena(r2_valid),    		//    ena.ena
		.result(inv_r6)  // result.result
	);
	
	// Calculate: inv_r8 = inv_r4 * inv_r4
	FP_MUL FP_MUL_inv_r8 (
		.ay(inv_r4),     		//     ay.ay
		.az(inv_r4),     			//     az.az
		.clk(clk),    				//    clk.clk
		.clr(rst),    				//    clr.clr
		.ena(r2_valid),    		//    ena.ena
		.result(inv_r8)  // result.result
	);

// Calculate: inv_r14 = inv_r8 * inv_r6
	FP_MUL FP_MUL_inv_r14 (
		.ay(inv_r8),     		//     ay.ay
		.az(inv_r6),     			//     az.az
		.clk(clk),    				//    clk.clk
		.clr(rst),    				//    clr.clr
		.ena(r2_valid),    		//    ena.ena
		.result(inv_r14)  // result.result
	);	
	
	
	// Calculate: Coulomb_Force_partial = inv_r3 + smooth_final
	FP_ADD FP_ADD_Coulomb_Force_Partial(
		.ax     (inv_r3),     //   input,  width = 32,     ax.ax
		.ay     (smooth_final),     //   input,  width = 32,     ay.ay
		.clk    (clk),    //   input,   width = 1,    clk.clk
		.clr    (rst),    //   input,   width = 2,    clr.clr
		.ena    (r2_valid),    //   input,   width = 1,    ena.ena
		.result (coulomb_force_partial)  //  output,  width = 32, result.result
	);

	// Calculate: Coulomb_Force = QQ * inv_r3
	FP_MUL FP_MUL_Coulomb_Force (
		.ay(coulomb_force_partial),     		//     ay.ay
		.az(p_qq),     			//     az.az
		.clk(clk),    				//    clk.clk
		.clr(rst),    				//    clr.clr
		.ena(r2_valid),    		//    ena.ena
		.result(coulomb_force)  // result.result
	);
	
	// Get intermediate force Coulomb_Force + r8 * B
	FP_MUL_ADD FP_MUL_ADD_Partial_Force (
		.ax     (coulomb_force), //   input,  width = 32,     ax.ax
		.ay     (inv_r8),     //   input,  width = 32,     ay.ay
		.az     (p_b),     		 //   input,  width = 32,     az.az
		.clk    (clk),           //   input,   width = 1,    clk.clk
		.clr    (rst),           //   input,   width = 2,    clr.clr
		.ena    (r2_valid),     //   input,   width = 1,    ena.ena
		.result (partial_force)  //   output,  width = 32, result.result
	);
	
	// Get total force Coulomb_Force + r8 * B + r14 * A
	FP_MUL_ADD FP_MUL_ADD_Total_Force (
		.ax     (partial_force), //   input,  width = 32,     ax.ax
		.ay     (inv_r14),    //   input,  width = 32,     ay.ay
		.az     (p_a),     		 //   input,  width = 32,     az.az
		.clk    (clk),           //   input,   width = 1,    clk.clk
		.clr    (rst),           //   input,   width = 2,    clr.clr
		.ena    (r2_valid),     //   input,   width = 1,    ena.ena
		.result (RL_force)       //   output,  width = 32, result.result
	);
	
endmodule

