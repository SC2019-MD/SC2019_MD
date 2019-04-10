/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: RL_LJ_Evaluate_Pairs_Direct_fixed.v
//
//	Function: 
//				Using 32-bit fixed point datatype, only use this module for resource estimation.....
//				Evaluate the piarwise non-bonded force between the intput particle pair using direct compututation
// 			Taking the square distance as input
//				!!!!!!!!! This module is mainly used for resource estimation !!!!!!
//
// Dependency:
//				FIX_ADD
//				FIX_MUL
//				FIX_DIV
//				FIX_SQRT
//
// FP IP timing:
//				FIX_ADD: a0 + a1 = result							latency: 1
//				FIX_MUL: a * b = result								latency: 9
//				FIX_DIV: numerator / denominator = result		latency: 50
//				FIX_SQRT: sqrt(radical) = result 				latency: 63
//
// Latency: total: 89 cycles
//				Input level: wait for table lookup to finish			2 cycles
//				Level 1: Get inv_r2 (DIV)									50 cycles
//				Level 2: Get inv_r4 = inv_r2 * inv_r2 (MUL)			9 cycles
//				Level 3: Get inv_r8, inv_r6 (MUL)						9 cycles
//				Level 4: Get inv_14 (MUL)									9 cycles
//				Level 5: Get r14_term, r8_term (MUL)					9 cycles
//				Level 6: Get RL_LJ_Force (SUB)							1 cycles

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module RL_LJ_Evaluate_Pairs_Direct_fixed
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
	// Latency: 50 cycles
	FIX_DIV FIX_Div_inv_r2(
		.denominator (r2),      //   input,  width = 32,      a.a
		.rst (rst), //   input,   width = 1, areset.reset
		.en(r2_valid),
		.numerator (32'h3F800000),      //   input,  width = 32, value is 1.0
		.clk    (clk),    //   input,   width = 1,    clk.clk
		.result (inv_r2)       //  output,  width = 32,      q.q
	);
	
	// ********** Level 2 ********** //
	// Calculate: inv_r4 = inv_r2 * inv_r2
	// Latency: 9 cycles
	FIX_MUL FIX_MUL_inv_r4 (
		.a(inv_r2),     		//     ay.ay
		.b(inv_r2),     			//     az.az
		.clk(clk),    				//    clk.clk
		.rst(rst),    				//    clr.clr
		.en(r2_valid),    		//    ena.ena
		.result(inv_r4)  // result.result
	);
	
	// ********** Level 3 ********** //
	// Calculate: inv_r6 = inv_r4 * inv_r2
	// Latency: 9 cycles
	FIX_MUL FIX_MUL_inv_r6 (
		.a(inv_r4),     		//     ay.ay
		.b(inv_r2),     			//     az.az
		.clk(clk),    				//    clk.clk
		.rst(rst),    				//    clr.clr
		.en(r2_valid),    		//    ena.ena
		.result(inv_r6)  // result.result
	);
	
	// Calculate: inv_r8 = inv_r4 * inv_r4
	// Latency: 9 cycles
	FIX_MUL FIX_MUL_inv_r8 (
		.a(inv_r4),     		//     ay.ay
		.b(inv_r4),     			//     az.az
		.clk(clk),    				//    clk.clk
		.rst(rst),    				//    clr.clr
		.en(r2_valid),    		//    ena.ena
		.result(inv_r8)  // result.result
	);

	// ********** Level 4 ********** //
	// Calculate: inv_r14 = inv_r8 * inv_r6
	// Latency: 9 cycles
	FIX_MUL FIX_MUL_inv_r14 (
		.a(inv_r8),     		//     ay.ay
		.b(inv_r6),     			//     az.az
		.clk(clk),    				//    clk.clk
		.rst(rst),    				//    clr.clr
		.en(r2_valid),    		//    ena.ena
		.result(inv_r14)  // result.result
	);	
	
	// ********** Level 4 ********** //
	// Get r8_term = p_b * inv_r8
	// Latency: 9 cycles
	FIX_MUL FIX_MUL_r8_term (
		.a     (inv_r8),     //   input,  width = 32,     ay.ay
		.b     (p_b),     		 //   input,  width = 32,     az.az
		.clk    (clk),           //   input,   width = 1,    clk.clk
		.rst    (rst),           //   input,   width = 2,    clr.clr
		.en    (r2_valid),     //   input,   width = 1,    ena.ena
		.result (r8_term)  //   output,  width = 32, result.result
	);
	
	// Get r14_term = p_a * inv_r14
	// Latency: 9 cycles
	FIX_MUL FIX_MUL_r14_term (
		.a     (inv_r14),    //   input,  width = 32,     ay.ay
		.b     (p_a),     		 //   input,  width = 32,     az.az
		.clk    (clk),           //   input,   width = 1,    clk.clk
		.rst    (rst),           //   input,   width = 2,    clr.clr
		.en    (r2_valid),     //   input,   width = 1,    ena.ena
		.result (r14_term)       //   output,  width = 32, result.result
	);
	
	// ********** Level 5 ********** //
	// Get RL_LJ_Force = r14_term - r8_term
	// Latency: 1 cycle
	FIX_ADD FIX_SUB_Total_Force(
		.clk(clk),
		.rst(rst),
		.a0(r14_term),
		.a1({r8_term[DATA_WIDTH-1],r8_term[DATA_WIDTH-2:0]}),
		.en(r2_valid),
		.result(RL_LJ_force)
	);
	
endmodule

