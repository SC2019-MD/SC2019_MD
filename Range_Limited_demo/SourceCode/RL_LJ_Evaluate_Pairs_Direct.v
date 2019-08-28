/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: RL_LJ_Evaluate_Pairs_Direct.v
//
//	Function: 
//				Using 32-bit fixed point datatype, only use this module for resource estimation.....
//				Evaluate the piarwise non-bonded force between the intput particle pair using direct compututation
// 			Taking the square distance as input
//				!!!!!!!!! This module is mainly used for resource estimation !!!!!!
//
// Dependency:
//				FP_SUB
//				FP_MUL
//				FP_DIV
//				FP_SQRT
//
// FP IP timing:
//				FP_SUB: ay - ax = result				latency: 3
//				FP_MUL: ay * az = result				latency: 4
//				FP_Div: ay / ax = result				latency: 38
//				FP_Sqrt:	sqrt(a) = result 				latency: 18
//
// Latency: total: 59 cycles
//				Input level: wait for table lookup to finish			2 cycles
//				Level 1: Get inv_r2 (DIV)									38 cycles
//				Level 2: Get inv_r4 = inv_r2 * inv_r2 (MUL)			4 cycles
//				Level 3: Get inv_r8, inv_r6 (MUL)						4 cycles
//				Level 4: Get inv_14 (MUL)									4 cycles
//				Level 5: Get r14_term, r8_term (MUL)					4 cycles
//				Level 6: Get RL_LJ_Force (SUB)							3 cycles
//
// Created by:
//				Chen Yang 03/28/2019
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module RL_LJ_Evaluate_Pairs_Direct
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
	output [DATA_WIDTH-1:0] RL_LJ_force,							// in IEEE floating point
	output RL_LJ_force_valid
);

	// Force evaluation intermediate results
	wire [31:0] r;
	wire [31:0] inv_r2;
	wire [31:0] inv_r4;
	wire [31:0] inv_r6;
	wire [31:0] inv_r8;
	wire [31:0] inv_r14;
	wire [31:0] r14_term;
	wire [31:0] r8_term;
	wire [31:0] partial_force;
	
	assign RL_LJ_force_valid = r2_valid;

/*	
	// Get r = sqrt(r2)
	FP_Sqrt FP_Sqrt_r(
		.a(r2),
		.areset(rst),
		.clk(clk),
		.q(r)
	);
*/	

	// ********** Level 1 ********** //
	// Get inv_r2
	// Latency: 38 cycles
	FP_Div FP_Div_inv_r2(
		.a      (r2),      //   input,  width = 32,      a.a
		.areset (rst), //   input,   width = 1, areset.reset
		.b      (32'h3F800000),      //   input,  width = 32, value is 1.0
		.clk    (clk),    //   input,   width = 1,    clk.clk
		.q      (inv_r2)       //  output,  width = 32,      q.q
	);
	
	// ********** Level 2 ********** //
	// Calculate: inv_r4 = inv_r2 * inv_r2
	// Latency: 4 cycles
	FP_MUL FP_MUL_inv_r4 (
		.ay(inv_r2),     		//     ay.ay
		.az(inv_r2),     			//     az.az
		.clk(clk),    				//    clk.clk
		.clr(rst),    				//    clr.clr
		.ena(r2_valid),    		//    ena.ena
		.result(inv_r4)  // result.result
	);
	
	// ********** Level 3 ********** //
	// Calculate: inv_r6 = inv_r4 * inv_r2
	// Latency: 4 cycles
	FP_MUL FP_MUL_inv_r6 (
		.ay(inv_r4),     		//     ay.ay
		.az(inv_r2),     			//     az.az
		.clk(clk),    				//    clk.clk
		.clr(rst),    				//    clr.clr
		.ena(r2_valid),    		//    ena.ena
		.result(inv_r6)  // result.result
	);
	
	// Calculate: inv_r8 = inv_r4 * inv_r4
	// Latency: 4 cycles
	FP_MUL FP_MUL_inv_r8 (
		.ay(inv_r4),     		//     ay.ay
		.az(inv_r4),     			//     az.az
		.clk(clk),    				//    clk.clk
		.clr(rst),    				//    clr.clr
		.ena(r2_valid),    		//    ena.ena
		.result(inv_r8)  // result.result
	);

	// ********** Level 4 ********** //
	// Calculate: inv_r14 = inv_r8 * inv_r6
	// Latency: 4 cycles
	FP_MUL FP_MUL_inv_r14 (
		.ay(inv_r8),     		//     ay.ay
		.az(inv_r6),     			//     az.az
		.clk(clk),    				//    clk.clk
		.clr(rst),    				//    clr.clr
		.ena(r2_valid),    		//    ena.ena
		.result(inv_r14)  // result.result
	);	
	
	// ********** Level 5 ********** //
	// Get r8_term = p_b * inv_r8
	// Latency: 4 cycles
	FP_MUL FP_MUL_r8_term (
		.ay     (inv_r8),     //   input,  width = 32,     ay.ay
		.az     (p_b),     		 //   input,  width = 32,     az.az
		.clk    (clk),           //   input,   width = 1,    clk.clk
		.clr    (rst),           //   input,   width = 2,    clr.clr
		.ena    (r2_valid),     //   input,   width = 1,    ena.ena
		.result (r8_term)  //   output,  width = 32, result.result
	);
	
	// Get r14_term = p_a * inv_r14
	// Latency: 4 cycles
	FP_MUL FP_MUL_r14_term (
		.ay     (inv_r14),    //   input,  width = 32,     ay.ay
		.az     (p_a),     		 //   input,  width = 32,     az.az
		.clk    (clk),           //   input,   width = 1,    clk.clk
		.clr    (rst),           //   input,   width = 2,    clr.clr
		.ena    (r2_valid),     //   input,   width = 1,    ena.ena
		.result (r14_term)       //   output,  width = 32, result.result
	);
	
	// ********** Level 6 ********** //
	// Get RL_LJ_Force = r14_term - r8_term
	// Latency: 1 cycle
	FP_SUB FP_SUB_Total_Force(
		.ay     (r14_term),    //   input,  width = 32,     ay.ay
		.ax     (r8_term),     		 //   input,  width = 32,     az.az
		.clk    (clk),           //   input,   width = 1,    clk.clk
		.clr    (rst),           //   input,   width = 2,    clr.clr
		.ena    (r2_valid),     //   input,   width = 1,    ena.ena
		.result (RL_LJ_force)       //   output,  width = 32, result.result
	);
	
endmodule

