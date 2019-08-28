/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: RL_Evaluate_Pairs_2nd_Order.v
//
//	Function: Evaluate the piarwise non-bonded force between the intput particle pair using 2nd order interpolation (interpolation index is generated in Matlab)
// 			Taking the square distance as input
//				Based on the sqaure distance, evaluate the table look-up entry
//				!!!!!!!!! This module is mainly used for resource estimation !!!!!!
//
// Dependency:
// 			Table memory module
//				multiply and summation
//
//
// FP IP timing:
//				FP_SUB: ay - ax = result				latency: 3
//				FP_MUL: ay * az = result				latency: 4
//				FP_MUL_ADD: ay * az + ax  = result	latency: 5
//
// Latency: total: 26 cycles
//				Input level: wait for table lookup to finish													2 cycle
//				Level 1 Stage 1: calculate r3, r8, r14 stage 1 C2*r+C1 (MUL_ADD)						5 cycles
//				Level 1 Stage 2: calculate r3, r8, r14 stage 2 (C2*r+C1)*r+C0 (MUL_ADD)				5 cycles
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

module RL_Evaluate_Pairs_2nd_Order
#(
	parameter DATA_WIDTH 				= 32,
	parameter SEGMENT_NUM				= 12,
	parameter SEGMENT_WIDTH				= 4,
	parameter BIN_WIDTH					= 8,
	parameter BIN_NUM						= 256,

	parameter LOOKUP_NUM					= SEGMENT_NUM * BIN_NUM,			// SEGMENT_NUM * BIN_NUM
	parameter LOOKUP_ADDR_WIDTH		= SEGMENT_WIDTH + BIN_WIDTH		// log LOOKUP_NUM / log 2
)
(
	input  clk,
	input  rst,
	input  r2_valid,
	input  [DATA_WIDTH-1:0] r2,										// in IEEE floating point
	input  [DATA_WIDTH-1:0] p_a,										// in IEEE floating point
	input  [DATA_WIDTH-1:0] p_b,										// in IEEE floating point
	input  [DATA_WIDTH-1:0] p_qq,										// in IEEE floating point
	output [DATA_WIDTH-1:0] RL_force,								// in IEEE floating point
	output reg RL_force_valid
);

	wire table_rden;														// Table lookup enable
	wire [LOOKUP_ADDR_WIDTH - 1:0] rdaddr;							// Table lookup address
	
	// Create a 2 cycles delay of the input R2 value, thus allow the table lookup entry to be readout from RAM
	reg [DATA_WIDTH-1:0] r2_reg1;
	reg [DATA_WIDTH-1:0] r2_delay_stage1;
	reg [DATA_WIDTH-1:0] r2_delay_stage2;
	reg [DATA_WIDTH-1:0] r2_delay_stage1_reg1;
	reg [DATA_WIDTH-1:0] r2_delay_stage1_reg2;
	reg [DATA_WIDTH-1:0] r2_delay_stage1_reg3;
	reg [DATA_WIDTH-1:0] r2_delay_stage1_reg4;
	
	reg level1_stage1_en;												// Mul-Add enable: Calculate r3, r8, r14 using interpolation, 1st stage
	reg level1_en;															// Mul-Add enable: Calculate r3, r8, r14 using interpolation, 2nd stage
	reg level2_en;															// Mul enable: Calculate Coulomb force
	reg level3_en;															// Mul-Add enable: Calculate Coulomb_Force + r8 * B
	reg level4_en;															// Mul-Add enable: Calculate Final force = Coulomb_Force + r8 * B + r14 * A
	reg table_rden_reg;
	reg level1_stage1_en_reg1;
	reg level1_stage1_en_reg2;
	reg level1_stage1_en_reg3;
	reg level1_stage1_en_reg4;
	reg level1_en_reg1;
	reg level1_en_reg2;
	reg level1_en_reg3;
	reg level1_en_reg4;
	reg level2_en_reg1;
	reg level2_en_reg2;
	reg level2_en_reg3;
	reg level3_en_reg1;
	reg level3_en_reg2;
	reg level3_en_reg3;
	reg level3_en_reg4;
	reg level4_en_reg1;
	reg level4_en_reg2;
	reg level4_en_reg3;
	reg level4_en_reg4;
	
	// Delay the r8_result input before the coulomb force is calculated (4 cycles)
	reg [DATA_WIDTH-1:0] r8_result_reg1;
	reg [DATA_WIDTH-1:0] r8_result_reg2;
	reg [DATA_WIDTH-1:0] r8_result_reg3;
	reg [DATA_WIDTH-1:0] r8_result_delay;
	
	// Delay the r14_result input before the coulomb force is calculated (4+5 cycles)
	reg [DATA_WIDTH-1:0] r14_result_reg1;
	reg [DATA_WIDTH-1:0] r14_result_reg2;
	reg [DATA_WIDTH-1:0] r14_result_reg3;
	reg [DATA_WIDTH-1:0] r14_result_reg4;
	reg [DATA_WIDTH-1:0] r14_result_reg5;
	reg [DATA_WIDTH-1:0] r14_result_reg6;
	reg [DATA_WIDTH-1:0] r14_result_reg7;
	reg [DATA_WIDTH-1:0] r14_result_reg8;
	reg [DATA_WIDTH-1:0] r14_result_delay;
	
	reg [SEGMENT_WIDTH - 1:0] segment_id;							// Segment id, determined by r2 exponential part
	reg [BIN_WIDTH - 1:0] bin_id;										// Bin id, determined by r2 mantissa high order bits
	
	wire [DATA_WIDTH-1:0] terms0_r3,terms0_r8,terms0_r14,terms1_r3,terms1_r8,terms1_r14,terms2_r3,terms2_r8,terms2_r14;
	
	wire [DATA_WIDTH-1:0] r14_result_stage1, r8_result_stage1, r3_result_stage1;	// stage 1 result for r3, r8, r14
	wire [DATA_WIDTH-1:0] r14_result, r8_result, r3_result;	// final result for r3, r8, r14
	
	wire [DATA_WIDTH-1:0] coulomb_force;							// coulomb force
	wire [DATA_WIDTH-1:0] partial_force;							// partial force: coulomb force + r8 * B
	
	assign table_rden = r2_valid;
	
	assign rdaddr = {segment_id, bin_id};							// asssign the table lookup address
	
	// Generate table lookup address
	always@(*)
		if(rst)
			begin		
			segment_id <= 0;
			bin_id <= 0;
			end
		else
			begin
				// assign bin_id
				bin_id = r2[22:22-BIN_WIDTH+1];
				
				// assign segment_id
				if(r2[30:23] - 8'd127 < 8'd12 && r2[30:23] - 8'd127 >= 0)
					segment_id = r2[30:23] - 8'd127;
				else
					segment_id = 0;
			end
	
	
	always@(posedge clk)
		begin
		if(rst)
			begin
			// delay the input r2 value by 2 cycle to wait for table lookup to finish
			r2_reg1 <= 0;
			r2_delay_stage1 <= 0;
			r2_delay_stage2 <= 0;
			r2_delay_stage1_reg1 <= 0;
			r2_delay_stage1_reg2 <= 0;
			r2_delay_stage1_reg3 <= 0;
			r2_delay_stage1_reg4 <= 0;
			// delay registers to propagate the enable signal of FP IP units
			table_rden_reg <= 1'b0;
			level1_stage1_en <= 1'b0;
			level1_stage1_en_reg1 <= 1'b0;
			level1_stage1_en_reg2 <= 1'b0;
			level1_stage1_en_reg3 <= 1'b0;
			level1_stage1_en_reg4 <= 1'b0;
			level1_en <= 1'b0;
			level1_en_reg1 <= 1'b0;
			level1_en_reg2 <= 1'b0;
			level1_en_reg3 <= 1'b0;
			level1_en_reg4 <= 1'b0;
			level2_en <= 1'b0;
			level2_en_reg1 <= 1'b0;
			level2_en_reg2 <= 1'b0;
			level2_en_reg3 <= 1'b0;
			level3_en <= 1'b0;
			level3_en_reg1 <= 1'b0;
			level3_en_reg2 <= 1'b0;
			level3_en_reg3 <= 1'b0;
			level3_en_reg4 <= 1'b0;
			level4_en <= 1'b0;
			level4_en_reg1 <= 1'b0;
			level4_en_reg2 <= 1'b0;
			level4_en_reg3 <= 1'b0;
			level4_en_reg4 <= 1'b0;
			RL_force_valid <= 1'b0;
			// delay registers to propage the r8 value before Coulomb force is finished calculation
			r8_result_reg1 <= 0;
			r8_result_reg2 <= 0;
			r8_result_reg3 <= 0;
			r8_result_delay <= 0;
			// delay registers to propage the r8 value before Coulomb force is finished calculation
			r14_result_reg1 <= 0;
			r14_result_reg2 <= 0;
			r14_result_reg3 <= 0;
			r14_result_reg4 <= 0;
			r14_result_reg5 <= 0;
			r14_result_reg6 <= 0;
			r14_result_reg7 <= 0;
			r14_result_reg8 <= 0;
			r14_result_delay <= 0;
			end
		else
			begin
			// delay the input r2 value by 1 cycle to wait for table lookup to finish
			r2_reg1 <= r2;
			r2_delay_stage1 <= r2_reg1;
			// 5 cycle delay between r2_delay_stage1 and r2_delay_stage2
			r2_delay_stage1_reg1 <= r2_delay_stage1;
			r2_delay_stage1_reg2 <= r2_delay_stage1_reg1;
			r2_delay_stage1_reg3 <= r2_delay_stage1_reg2;
			r2_delay_stage1_reg4 <= r2_delay_stage1_reg3;
			r2_delay_stage2 <= r2_delay_stage1_reg4;
			// 2 cycle delay between table lookup enable and polynomial calculation stage1
			table_rden_reg <= table_rden;
			level1_stage1_en <= table_rden_reg;
			// 5 cycle delay between the starting of polynomical calculation stage 1 and polynomical calculation stage 2
			level1_stage1_en_reg1 <= level1_stage1_en;
			level1_stage1_en_reg2 <= level1_stage1_en_reg1;
			level1_stage1_en_reg3 <= level1_stage1_en_reg2;
			level1_stage1_en_reg4 <= level1_stage1_en_reg3;
			level1_en <= level1_stage1_en_reg4;
			// 5 cycle delay between the starting of polynomical calculation stage 2 and Coulomb force calculation
			level1_en_reg1 <= level1_en;
			level1_en_reg2 <= level1_en_reg1;
			level1_en_reg3 <= level1_en_reg2;
			level1_en_reg4 <= level1_en_reg3;			
			level2_en <= level1_en_reg4;
			// 4 cycle delay between the starting of Coulomb force calculation and Coulomb_Force + r8 * B
			level2_en_reg1 <= level2_en;
			level2_en_reg2 <= level2_en_reg1;
			level2_en_reg3 <= level2_en_reg2;
			level3_en <= level2_en_reg3;
			// 5 cycle delay between the starting of Coulomb_Force + r8 * B calculation and the final output static force
			level3_en_reg1 <= level3_en;
			level3_en_reg2 <= level3_en_reg1;
			level3_en_reg3 <= level3_en_reg2;
			level3_en_reg4 <= level3_en_reg3;
			level4_en <= level3_en_reg4;
			// 5 cycle delay between the starting of final force calculation and the valid output
			level4_en_reg1 <= level4_en;
			level4_en_reg2 <= level4_en_reg1;
			level4_en_reg3 <= level4_en_reg2;
			level4_en_reg4 <= level4_en_reg3;
			RL_force_valid <= level4_en_reg4;
			
			// delay registers to propage the r8 value before Coulomb force is finished calculation
			r8_result_reg1 <= r8_result;
			r8_result_reg2 <= r8_result_reg1;
			r8_result_reg3 <= r8_result_reg2;
			r8_result_delay <= r8_result_reg3;
			// delay registers to propage the r8 value before Coulomb force is finished calculation
			r14_result_reg1 <= r14_result;
			r14_result_reg2 <= r14_result_reg1;
			r14_result_reg3 <= r14_result_reg2;
			r14_result_reg4 <= r14_result_reg3;
			r14_result_reg5 <= r14_result_reg4;
			r14_result_reg6 <= r14_result_reg5;
			r14_result_reg7 <= r14_result_reg6;
			r14_result_reg8 <= r14_result_reg7;
			r14_result_delay <= r14_result_reg8;
			end
		end

	lut0_14
	#(
//		LOOKUP_NUM,
//		LOOKUP_ADDR_WIDTH
	)
	lut0_14 (
		.data(32'd0),
		.address(rdaddr),
		.wren(1'd0),
		.clock(clk),
		.rden(table_rden),
		.q(terms0_r14)
		);

	lut1_14
	#(
//		LOOKUP_NUM,
//		LOOKUP_ADDR_WIDTH
	)
	lut1_14 (
		.data(32'd0),
		.address(rdaddr),
		.wren(1'd0),
		.clock(clk),
		.rden(table_rden),
		.q(terms1_r14)
		);

	lut2_14
	#(
//		LOOKUP_NUM,
//		LOOKUP_ADDR_WIDTH
	)
	lut2_14 (
		.data(32'd0),
		.address(rdaddr),
		.wren(1'd0),
		.clock(clk),
		.rden(table_rden),
		.q(terms2_r14)
		);	
		
	lut0_8
	#(
//		LOOKUP_NUM,
//		LOOKUP_ADDR_WIDTH
	)
	lut0_8 (
		.data(32'd0),
		.address(rdaddr),
		.wren(1'd0),
		.clock(clk),
		.rden(table_rden),
		.q(terms0_r8)
		);

	lut1_8
	#(
//		LOOKUP_NUM,
//		LOOKUP_ADDR_WIDTH
	)
	lut1_8 (
		.data(32'd0),
		.address(rdaddr),
		.wren(1'd0),
		.clock(clk),
		.rden(table_rden),
		.q(terms1_r8)
		);
	
	lut2_8
	#(
//		LOOKUP_NUM,
//		LOOKUP_ADDR_WIDTH
	)
	lut2_8 (
		.data(32'd0),
		.address(rdaddr),
		.wren(1'd0),
		.clock(clk),
		.rden(table_rden),
		.q(terms2_r8)
		);

	lut0_3
	#(
//		LOOKUP_NUM,
//		LOOKUP_ADDR_WIDTH
	)
	lut0_3 (
		.data(32'd0),
		.address(rdaddr),
		.wren(1'd0),
		.clock(clk),
		.rden(table_rden),
		.q(terms0_r3)
		);

	lut1_3
	#(
//		LOOKUP_NUM,
//		LOOKUP_ADDR_WIDTH
	)
	lut1_3 (
		.data(32'd0),
		.address(rdaddr),
		.wren(1'd0),
		.clock(clk),
		.rden(table_rden),
		.q(terms1_r3)
		);
		
	lut2_3
	#(
//		LOOKUP_NUM,
//		LOOKUP_ADDR_WIDTH
	)
	lut2_3 (
		.data(32'd0),
		.address(rdaddr),
		.wren(1'd0),
		.clock(clk),
		.rden(table_rden),
		.q(terms2_r3)
		);
	
	// Get r3 term stage 1 = c2 * r2 + c1
	FP_MUL_ADD FP_MUL_r3_term_stage1 (
		.ax     (terms1_r3),     //   input,  width = 32,     ax.ax
		.ay     (terms2_r3),     //   input,  width = 32,     ay.ay
		.az     (r2_delay_stage1),      //   input,  width = 32,     az.az
		.clk    (clk),           //   input,   width = 1,    clk.clk
		.clr    (rst),           //   input,   width = 2,    clr.clr
		.ena    (level1_stage1_en),     //   input,   width = 1,    ena.ena
		.result (r3_result_stage1)      //   output,  width = 32, result.result
	);
	
	// Get r8 term stage 1 = c2 * r2 + c1
	FP_MUL_ADD FP_MUL_r8_term_stage1 (
		.ax     (terms1_r8),     //   input,  width = 32,     ax.ax
		.ay     (terms2_r8),     //   input,  width = 32,     ay.ay
		.az     (r2_delay_stage1),      //   input,  width = 32,     az.az
		.clk    (clk),           //   input,   width = 1,    clk.clk
		.clr    (rst),           //   input,   width = 2,    clr.clr
		.ena    (level1_stage1_en),     //   input,   width = 1,    ena.ena
		.result (r8_result_stage1)      //   output,  width = 32, result.result
	);
	
	// Get r14 term stage 1 = c2 * r2 + c1
	FP_MUL_ADD FP_MUL_r14_term_stage1 (
		.ax     (terms1_r14),    //   input,  width = 32,     ax.ax
		.ay     (terms2_r14),    //   input,  width = 32,     ay.ay
		.az     (r2_delay_stage1),      //   input,  width = 32,     az.az
		.clk    (clk),           //   input,   width = 1,    clk.clk
		.clr    (rst),           //   input,   width = 2,    clr.clr
		.ena    (level1_stage1_en),     //   input,   width = 1,    ena.ena
		.result (r14_result_stage1)     //   output,  width = 32, result.result
	);
	
	// Get r3 term final = (c2 * r2 + c1) * r2 + c0
	FP_MUL_ADD FP_MUL_r3_term_stage2 (
		.ax     (terms0_r3),     //   input,  width = 32,     ax.ax
		.ay     (r3_result_stage1),     //   input,  width = 32,     ay.ay
		.az     (r2_delay_stage2),      //   input,  width = 32,     az.az
		.clk    (clk),           //   input,   width = 1,    clk.clk
		.clr    (rst),           //   input,   width = 2,    clr.clr
		.ena    (level1_en),     //   input,   width = 1,    ena.ena
		.result (r3_result)      //   output,  width = 32, result.result
	);
	
	// Get r8 term final = (c2 * r2 + c1) * r2 + c0
	FP_MUL_ADD FP_MUL_r8_term_stage2 (
		.ax     (terms0_r8),     //   input,  width = 32,     ax.ax
		.ay     (r8_result_stage1),     //   input,  width = 32,     ay.ay
		.az     (r2_delay_stage2),      //   input,  width = 32,     az.az
		.clk    (clk),           //   input,   width = 1,    clk.clk
		.clr    (rst),           //   input,   width = 2,    clr.clr
		.ena    (level1_en),     //   input,   width = 1,    ena.ena
		.result (r8_result)      //   output,  width = 32, result.result
	);
	
	// Get r14 term final = (c2 * r2 + c1) * r2 + c0
	FP_MUL_ADD FP_MUL_r14_term_stage2 (
		.ax     (terms0_r14),    //   input,  width = 32,     ax.ax
		.ay     (r14_result_stage1),    //   input,  width = 32,     ay.ay
		.az     (r2_delay_stage2),      //   input,  width = 32,     az.az
		.clk    (clk),           //   input,   width = 1,    clk.clk
		.clr    (rst),           //   input,   width = 2,    clr.clr
		.ena    (level1_en),     //   input,   width = 1,    ena.ena
		.result (r14_result)     //   output,  width = 32, result.result
	);
	
	// Calculate: Coulomb_Force = QQ * r3
	FP_MUL FP_MUL_Coulomb_Force (
		.ay(r3_result),     		//     ay.ay
		.az(p_qq),     			//     az.az
		.clk(clk),    				//    clk.clk
		.clr(rst),    				//    clr.clr
		.ena(level2_en),    		//    ena.ena
		.result(coulomb_force)  // result.result
	);
	
	// Get intermediate force Coulomb_Force + r8 * B
	FP_MUL_ADD FP_MUL_ADD_Partial_Force (
		.ax     (coulomb_force), //   input,  width = 32,     ax.ax
		.ay     (r8_result_delay),     //   input,  width = 32,     ay.ay
		.az     (p_b),     		 //   input,  width = 32,     az.az
		.clk    (clk),           //   input,   width = 1,    clk.clk
		.clr    (rst),           //   input,   width = 2,    clr.clr
		.ena    (level3_en),     //   input,   width = 1,    ena.ena
		.result (partial_force)  //   output,  width = 32, result.result
	);
	
	// Get total force Coulomb_Force + r8 * B + r14 * A
	FP_MUL_ADD FP_MUL_ADD_Total_Force (
		.ax     (partial_force), //   input,  width = 32,     ax.ax
		.ay     (r14_result_delay),    //   input,  width = 32,     ay.ay
		.az     (p_a),     		 //   input,  width = 32,     az.az
		.clk    (clk),           //   input,   width = 1,    clk.clk
		.clr    (rst),           //   input,   width = 2,    clr.clr
		.ena    (level4_en),     //   input,   width = 1,    ena.ena
		.result (RL_force)       //   output,  width = 32, result.result
	);
	


	
endmodule

