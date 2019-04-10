/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: RL_Evaluate_Pairs_1st_Order_v2.v
//
//	Function:
//				There is another module: RL_Evaluate_Pairs_1st_Order, but only evaluate total RL force
//				Evaluate the piarwise non-bonded force (LJ and Coulomb force) between the intput particle pair using 1st order interpolation (interpolation index is generated in Matlab)
// 			Taking the square distance as input
//				Based on the sqaure distance, evaluate the table look-up entry
//
//	Used by:
//				RL_Force_Evaluation_Unit.v
//
// Force Model:
//				R14_term = 48 * eps * sigma^12 * inv_r14
//				R8_term  = 24 * eps * sigma^8 * inv_r8
//				R3_term  = q0 * q1 / (4*pi*eps) * inv_r3
//				Force_LJ = R14_term - R8_term			(R14_term and R8_term come directly from table lookup)
//				Force_C  = R3_term
//				Force_RL = Force_LJ + Force_C
//				Force_RL_x = Force_RL * dx;
//				Force_RL_y = Force_RL * dy;
//				Force_RL_z = Force_RL * dz;
//
// Dependency:
// 			Table lookup memory modules
//					lut0_14.v
//					lut1_14.v
//					lut0_8.v
//					lut1_8.v
//					lut0_3.v
//					lut1_3.v
//				multiply and summation IPs
//					FP_ADD.v
//					FP_SUB.v
//					FP_MUL.v
//					FP_MUL_ADD.v
//
// Testbench:
//				RL_Evaluate_Pairs_1st_Order_v2_tb.v
//
// FP IP timing:
//				FP_ADD: ay - ax = result				latency: 3
//				FP_SUB: ay - ax = result				latency: 3
//				FP_MUL: ay * az = result				latency: 4
//				FP_MUL_ADD: ay * az + ax  = result	latency: 5
//
// Latency: total: 17 cycles
//				Input level: wait for table lookup to finish							2 cycle
//				Level 1: calculate r3, r8, r14 terms (MUL_ADD)						5 cycles
//				Level 2: calculate LJ Force (SUB)										3 cycles
//				Level 3: calculate RL Force (ADD)										3 cycles
//				Level 4: calculate Force components in each direction (MUL)		4 cycles
// 
// DataSet:
//				ApoA1: Segment 14, Bin 256, range: 2^-6 ~ 2^8
//				LJArgon: Segment 9, Bin 256, range: 2^-2 ~ 2^7
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module RL_Evaluate_Pairs_1st_Order_v2
#(
	parameter DATA_WIDTH 				= 32,
	parameter SEGMENT_NUM				= 9,
	parameter SEGMENT_WIDTH				= 4,
	parameter BIN_NUM						= 256,
	parameter BIN_WIDTH					= 8,
	parameter CUTOFF_2					= 32'h43100000,						// (12^2=144 in IEEE floating point)
	parameter LOOKUP_NUM					= SEGMENT_NUM * BIN_NUM,			// SEGMENT_NUM * BIN_NUM
	parameter LOOKUP_ADDR_WIDTH		= SEGMENT_WIDTH + BIN_WIDTH		// log LOOKUP_NUM / log 2
)
(
	input  clk,
	input  rst,
	input  r2_valid,
	input  [DATA_WIDTH-1:0] r2,										// in IEEE floating point
	input  [DATA_WIDTH-1:0] dx,										// in IEEE floating point
	input  [DATA_WIDTH-1:0] dy,										// in IEEE floating point
	input  [DATA_WIDTH-1:0] dz,										// in IEEE floating point
	input  [DATA_WIDTH-1:0] p_a,										// in IEEE floating point
	input  [DATA_WIDTH-1:0] p_b,										// in IEEE floating point
	input  [DATA_WIDTH-1:0] p_qq,										// in IEEE floating point
	output [DATA_WIDTH-1:0] RL_Force_X,								// in IEEE floating point
	output [DATA_WIDTH-1:0] RL_Force_Y,								// in IEEE floating point
	output [DATA_WIDTH-1:0] RL_Force_Z,								// in IEEE floating point
	output reg RL_force_valid
);

	wire table_rden;														// Table lookup enable
	wire [LOOKUP_ADDR_WIDTH - 1:0] rdaddr;							// Table lookup address
	
	// Create a 2 cycles delay of the input R2 value, thus allow the table lookup entry to be readout from RAM
	reg [DATA_WIDTH-1:0] r2_delay;
	reg [DATA_WIDTH-1:0] r2_reg1;
/*	reg [DATA_WIDTH-1:0] r2_reg2;
	reg [DATA_WIDTH-1:0] r2_reg3;
	reg [DATA_WIDTH-1:0] r2_reg4;
	reg [DATA_WIDTH-1:0] r2_reg5;
	reg [DATA_WIDTH-1:0] r2_reg6;
	reg [DATA_WIDTH-1:0] r2_reg7;
	reg [DATA_WIDTH-1:0] r2_reg8;
	reg [DATA_WIDTH-1:0] r2_reg9;
	reg [DATA_WIDTH-1:0] r2_reg10;
	reg [DATA_WIDTH-1:0] r2_reg11;
	reg [DATA_WIDTH-1:0] r2_reg12;
	reg [DATA_WIDTH-1:0] r2_reg13;
	reg [DATA_WIDTH-1:0] r2_final;									// The r2 value related to the current output force
*/	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// !!!!!!!!Attention!!!!!!!!
	// The enable singal for FP IPs should kept high until the operation is finished!!!!!!!!
	// When connect the stage enable signal to the IP enable signal, always do logical OR with the next stage enable signal to make sure the calculation is finished
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	reg level1_en;															// Mul-Add enable: Calculate r8, r14 using interpolation
	reg level2_en;															// Sub enable: Calculate LJ Force
	reg level3_en;															// Add enable: Calculate RL Force (LJ Force + Coulomb Force)
	reg level4_en;															// Mul enable: Calculate LJ Force component in each direction
	reg table_rden_reg;
	reg level1_en_reg1;
	reg level1_en_reg2;
	reg level1_en_reg3;
	reg level1_en_reg4;
	reg level2_en_reg1;
	reg level2_en_reg2;
	reg level3_en_reg1;
	reg level3_en_reg2;
	reg level4_en_reg1;
	reg level4_en_reg2;
	reg level4_en_reg3;
	
	// Delay register to propogate dx, dy, dz, delay for 2+5+3+3=13 cycles
	reg [DATA_WIDTH-1:0] dx_reg1;
	reg [DATA_WIDTH-1:0] dx_reg2;
	reg [DATA_WIDTH-1:0] dx_reg3;
	reg [DATA_WIDTH-1:0] dx_reg4;
	reg [DATA_WIDTH-1:0] dx_reg5;
	reg [DATA_WIDTH-1:0] dx_reg6;
	reg [DATA_WIDTH-1:0] dx_reg7;
	reg [DATA_WIDTH-1:0] dx_reg8;
	reg [DATA_WIDTH-1:0] dx_reg9;
	reg [DATA_WIDTH-1:0] dx_reg10;
	reg [DATA_WIDTH-1:0] dx_reg11;
	reg [DATA_WIDTH-1:0] dx_reg12;
	reg [DATA_WIDTH-1:0] dx_delay;
	
	reg [DATA_WIDTH-1:0] dy_reg1;
	reg [DATA_WIDTH-1:0] dy_reg2;
	reg [DATA_WIDTH-1:0] dy_reg3;
	reg [DATA_WIDTH-1:0] dy_reg4;
	reg [DATA_WIDTH-1:0] dy_reg5;
	reg [DATA_WIDTH-1:0] dy_reg6;
	reg [DATA_WIDTH-1:0] dy_reg7;
	reg [DATA_WIDTH-1:0] dy_reg8;
	reg [DATA_WIDTH-1:0] dy_reg9;
	reg [DATA_WIDTH-1:0] dy_reg10;
	reg [DATA_WIDTH-1:0] dy_reg11;
	reg [DATA_WIDTH-1:0] dy_reg12;
	reg [DATA_WIDTH-1:0] dy_delay;
	
	reg [DATA_WIDTH-1:0] dz_reg1;
	reg [DATA_WIDTH-1:0] dz_reg2;
	reg [DATA_WIDTH-1:0] dz_reg3;
	reg [DATA_WIDTH-1:0] dz_reg4;
	reg [DATA_WIDTH-1:0] dz_reg5;
	reg [DATA_WIDTH-1:0] dz_reg6;
	reg [DATA_WIDTH-1:0] dz_reg7;
	reg [DATA_WIDTH-1:0] dz_reg8;
	reg [DATA_WIDTH-1:0] dz_reg9;
	reg [DATA_WIDTH-1:0] dz_reg10;
	reg [DATA_WIDTH-1:0] dz_reg11;
	reg [DATA_WIDTH-1:0] dz_reg12;
	reg [DATA_WIDTH-1:0] dz_delay;
	
	// Table lookup variables
	reg [SEGMENT_WIDTH - 1:0] segment_id;							// Segment id, determined by r2 exponential part
	reg [BIN_WIDTH - 1:0] bin_id;										// Bin id, determined by r2 mantissa high order bits
	wire [DATA_WIDTH-1:0] terms0_r3, terms0_r8, terms0_r14, terms1_r3, terms1_r8, terms1_r14;
	wire [DATA_WIDTH-1:0] r3_result, r14_result, r8_result;	// final result for r3, r8, r14
	
	// Delay register to propagate r3_result by 3 cycles to match the latency to evaluate LJ Force
	reg [DATA_WIDTH-1:0] r3_result_reg1;
	reg [DATA_WIDTH-1:0] r3_result_reg2;
	reg [DATA_WIDTH-1:0] r3_result_delay;
	
	// Force variables
	wire [DATA_WIDTH-1:0] LJ_Force;									// LJ Force
	wire [DATA_WIDTH-1:0] RL_Force;									// Total Force
	//wire [DATA_WIDTH-1:0] RL_Force_X_wire;
	//wire [DATA_WIDTH-1:0] RL_Force_Y_wire;
	//wire [DATA_WIDTH-1:0] RL_Force_Z_wire;
	
	// Table lookup enable
	assign table_rden = r2_valid;
/*	
	// Simple filter based on the r2_value, but the force is still evaluated whether within cutoff or not
	// assign output force (if exceed cutoff, then set as 0)
	assign LJ_Force_X = (r2_final > CUTOFF_2 || r2_final == 0) ? 0 : LJ_Force_X_wire;
	assign LJ_Force_Y = (r2_final > CUTOFF_2 || r2_final == 0) ? 0 : LJ_Force_Y_wire;
	assign LJ_Force_Z = (r2_final > CUTOFF_2 || r2_final == 0) ? 0 : LJ_Force_Z_wire;
*/	
	// Generate table lookup address
	assign rdaddr = {segment_id, bin_id};							// asssign the table lookup address
	wire [7:0] segment_id_temp;
	// DataSet: LJArgon
	assign segment_id_temp = r2[30:23] - 8'd125;
	// DataSet: ApoA1
	//assign segment_id_temp = r2[30:23] - 8'd121;
	always@(*)
		if(rst)
			begin		
			segment_id <= 0;
			bin_id <= 0;
			end
		else
			begin
				// ApoA1: Table lookup starting from 0.015625 = 2^-6
				// LJArgon: Table lookup starting from 0.25 = 2^-2
				// assign bin_id
				bin_id = r2[22:22-BIN_WIDTH+1];
				// assign segment_id
				if(segment_id_temp < SEGMENT_NUM && segment_id_temp >= 0)
					segment_id = segment_id_temp[SEGMENT_WIDTH-1:0];
				else
					segment_id = 0;
			end
	
	// Force evaluation controller
	always@(posedge clk)
		begin
		if(rst)
			begin
			
			// delay the input r2 value by 2 cycle to wait for table lookup to finish
			r2_delay <= 0;
			r2_reg1 <= 0;
/*			r2_reg2 <= 0;
			r2_reg3 <= 0;
			r2_reg4 <= 0;
			r2_reg5 <= 0;
			r2_reg6 <= 0;
			r2_reg7 <= 0;
			r2_reg8 <= 0;
			r2_reg9 <= 0;
			r2_reg10 <= 0;
			r2_reg11 <= 0;
			r2_reg12 <= 0;
			r2_reg13 <= 0;
			r2_final <= 0;
*/
			// delay registers to propagate the enable signal of FP IP units
			table_rden_reg <= 1'b0;
			level1_en <= 1'b0;
			level1_en_reg1 <= 1'b0;
			level1_en_reg2 <= 1'b0;
			level1_en_reg3 <= 1'b0;
			level1_en_reg4 <= 1'b0;
			level2_en <= 1'b0;
			level2_en_reg1 <= 1'b0;
			level2_en_reg2 <= 1'b0;
			level3_en <= 1'b0;
			level3_en_reg1 <= 1'b0;
			level3_en_reg2 <= 1'b0;
			level4_en <= 1'b0;
			level4_en_reg1 <= 1'b0;
			level4_en_reg2 <= 1'b0;
			level4_en_reg3 <= 1'b0;
			RL_force_valid <= 1'b0;
			// Delay register to propagate r3_result by 3 cycles to match the latency to evaluate LJ Force
			r3_result_reg1 <= 0;
			r3_result_reg2 <= 0;
			r3_result_delay <= 0;
			// Delay registers to propogate the dx, dy, dz input
			dx_reg1 <= 0;
			dx_reg2 <= 0;
			dx_reg3 <= 0;
			dx_reg4 <= 0;
			dx_reg5 <= 0;
			dx_reg6 <= 0;
			dx_reg7 <= 0;
			dx_reg8 <= 0;
			dx_reg9 <= 0;
			dx_reg10 <= 0;
			dx_reg11 <= 0;
			dx_reg12 <= 0;
			dx_delay <= 0;
			
			dy_reg1 <= 0;
			dy_reg2 <= 0;
			dy_reg3 <= 0;
			dy_reg4 <= 0;
			dy_reg5 <= 0;
			dy_reg6 <= 0;
			dy_reg7 <= 0;
			dy_reg8 <= 0;
			dy_reg9 <= 0;
			dy_reg10 <= 0;
			dy_reg11 <= 0;
			dy_reg12 <= 0;
			dy_delay <= 0;
			
			dz_reg1 <= 0;
			dz_reg2 <= 0;
			dz_reg3 <= 0;
			dz_reg4 <= 0;
			dz_reg5 <= 0;
			dz_reg6 <= 0;
			dz_reg7 <= 0;
			dz_reg8 <= 0;
			dz_reg9 <= 0;
			dz_reg10 <= 0;
			dz_reg11 <= 0;
			dz_reg12 <= 0;
			dz_delay <= 0;
			end
		else
			begin
			// delay the input r2 value by 1 cycle to wait for table lookup to finish
			r2_reg1 <= r2;
			r2_delay <= r2_reg1;
/*			r2_reg2 <= r2_reg1;
			r2_reg3 <= r2_reg2;
			r2_reg4 <= r2_reg3;
			r2_reg5 <= r2_reg4;
			r2_reg6 <= r2_reg5;
			r2_reg7 <= r2_reg6;
			r2_reg8 <= r2_reg7;
			r2_reg9 <= r2_reg8;
			r2_reg10 <= r2_reg9;
			r2_reg11 <= r2_reg10;
			r2_reg12 <= r2_reg11;
			r2_reg13 <= r2_reg12;
			r2_final <= r2_reg13;
*/
			// 2 cycles delay between table lookup enable and polynomial calculation
			table_rden_reg <= table_rden;
			level1_en <= table_rden_reg;
			// 5 cycles delay between the starting of polynomical calculation and LJ force calculation
			level1_en_reg1 <= level1_en;
			level1_en_reg2 <= level1_en_reg1;
			level1_en_reg3 <= level1_en_reg2;
			level1_en_reg4 <= level1_en_reg3;			
			level2_en <= level1_en_reg4;
			// 3 cycles delay between the starting of LJ force calculation and LJ force component evaluation
			level2_en_reg1 <= level2_en;
			level2_en_reg2 <= level2_en_reg1;
			level3_en <= level2_en_reg2;
			// 3 cycles delay between the starting of RL force calculation and LJ force calculation
			level3_en_reg1 <= level3_en;
			level3_en_reg2 <= level3_en_reg1;
			level4_en <= level3_en_reg2;
			// 4 cycles delay between the starting of LJ force component evaluation and final output LJ force
			level4_en_reg1 <= level4_en;
			level4_en_reg2 <= level4_en_reg1;
			level4_en_reg3 <= level4_en_reg2;
			RL_force_valid <= level4_en_reg3;
			// 3 cycles delay between r3_term is evaluated and used for RL_Force evaluation
			r3_result_reg1 <= r3_result;
			r3_result_reg2 <= r3_result_reg1;
			r3_result_delay <= r3_result_reg2;
			// 13 cycles delay between the input of dx, dy, dz before it used for calculate LJ force components
			dx_reg1 <= dx;
			dx_reg2 <= dx_reg1;
			dx_reg3 <= dx_reg2;
			dx_reg4 <= dx_reg3;
			dx_reg5 <= dx_reg4;
			dx_reg6 <= dx_reg5;
			dx_reg7 <= dx_reg6;
			dx_reg8 <= dx_reg7;
			dx_reg9 <= dx_reg8;
			dx_reg10 <= dx_reg9;
			dx_reg11 <= dx_reg10;
			dx_reg12 <= dx_reg11;
			dx_delay <= dx_reg12;
			
			dy_reg1 <= dy;
			dy_reg2 <= dy_reg1;
			dy_reg3 <= dy_reg2;
			dy_reg4 <= dy_reg3;
			dy_reg5 <= dy_reg4;
			dy_reg6 <= dy_reg5;
			dy_reg7 <= dy_reg6;
			dy_reg8 <= dy_reg7;
			dy_reg9 <= dy_reg8;
			dy_reg10 <= dy_reg9;
			dy_reg11 <= dy_reg10;
			dy_reg12 <= dy_reg11;
			dy_delay <= dy_reg12;
			
			dz_reg1 <= dz;
			dz_reg2 <= dz_reg1;
			dz_reg3 <= dz_reg2;
			dz_reg4 <= dz_reg3;
			dz_reg5 <= dz_reg4;
			dz_reg6 <= dz_reg5;
			dz_reg7 <= dz_reg6;
			dz_reg8 <= dz_reg7;
			dz_reg9 <= dz_reg8;
			dz_reg10 <= dz_reg9;
			dz_reg11 <= dz_reg10;
			dz_reg12 <= dz_reg11;
			dz_delay <= dz_reg12;
			end
		end

	//////////////////////////////////////////////////////////////////////
	// Interpolation index ROM
	//////////////////////////////////////////////////////////////////////
	lut0_14
	#(
		.DEPTH(LOOKUP_NUM),
		.ADDR_WIDTH(LOOKUP_ADDR_WIDTH)
	)
	Index_Mem_0_R14
	(
		.data(32'd0),
		.address(rdaddr),
		.wren(1'd0),
		.clock(clk),
		.rden(table_rden || table_rden_reg),
		.q(terms0_r14)
	);

	lut1_14
	#(
		.DEPTH(LOOKUP_NUM),
		.ADDR_WIDTH(LOOKUP_ADDR_WIDTH)
	)
	Index_Mem_1_R14
	(
		.data(32'd0),
		.address(rdaddr),
		.wren(1'd0),
		.clock(clk),
		.rden(table_rden || table_rden_reg),
		.q(terms1_r14)
	);

	lut0_8
	#(
		.DEPTH(LOOKUP_NUM),
		.ADDR_WIDTH(LOOKUP_ADDR_WIDTH)
	)
	Index_Mem_0_R8
	(
		.data(32'd0),
		.address(rdaddr),
		.wren(1'd0),
		.clock(clk),
		.rden(table_rden || table_rden_reg),
		.q(terms0_r8)
	);

	lut1_8
	#(
		.DEPTH(LOOKUP_NUM),
		.ADDR_WIDTH(LOOKUP_ADDR_WIDTH)
	)
	Index_Mem_1_R8
	(
		.data(32'd0),
		.address(rdaddr),
		.wren(1'd0),
		.clock(clk),
		.rden(table_rden || table_rden_reg),
		.q(terms1_r8)
	);
	
	lut0_3
	#(
		.DEPTH(LOOKUP_NUM),
		.ADDR_WIDTH(LOOKUP_ADDR_WIDTH)
	)
	Index_Mem_0_R3
	(
		.data(32'd0),
		.address(rdaddr),
		.wren(1'd0),
		.clock(clk),
		.rden(table_rden || table_rden_reg),
		.q(terms0_r3)
	);
	
	lut1_3
	#(
		.DEPTH(LOOKUP_NUM),
		.ADDR_WIDTH(LOOKUP_ADDR_WIDTH)
	)
	Index_Mem_1_R3
	(
		.data(32'd0),
		.address(rdaddr),
		.wren(1'd0),
		.clock(clk),
		.rden(table_rden || table_rden_reg),
		.q(terms1_r3)
	);
	
	//////////////////////////////////////////////////////////////////////
	// FP instances for force evaluation
	//////////////////////////////////////////////////////////////////////
	// ********** Level 1 ********** //
	// Get r8 term = c1 * r2 + c0 (The coefficient of 24 is already included when generating the table
	// 5 cycles delay
	FP_MUL_ADD FP_MUL_r8_term (
		.ax     (terms0_r8),     //   input,  width = 32,     ax.ax
		.ay     (terms1_r8),     //   input,  width = 32,     ay.ay
		.az     (r2_delay),      //   input,  width = 32,     az.az
		.clk    (clk),           //   input,   width = 1,    clk.clk
		.clr    (rst),           //   input,   width = 2,    clr.clr
		.ena    (level1_en || level2_en || level1_en_reg1 || level1_en_reg2 || level1_en_reg3 || level1_en_reg4),     //   input,   width = 1,    ena.ena
		.result (r8_result)      //   output,  width = 32, result.result
	);
	
	// Get r14 term = c1 * r2 + c0 (The coefficient of 48 is already included when generating the table)
	// 5 cycles delay
	FP_MUL_ADD FP_MUL_r14_term (
		.ax     (terms0_r14),    //   input,  width = 32,     ax.ax
		.ay     (terms1_r14),    //   input,  width = 32,     ay.ay
		.az     (r2_delay),      //   input,  width = 32,     az.az
		.clk    (clk),           //   input,   width = 1,    clk.clk
		.clr    (rst),           //   input,   width = 2,    clr.clr
		.ena    (level1_en || level2_en || level1_en_reg1 || level1_en_reg2 || level1_en_reg3 || level1_en_reg4),     //   input,   width = 1,    ena.ena
		.result (r14_result)     //   output,  width = 32, result.result
	);
	
	// Get r3 term = c1 * r2 + c0 (The coefficient of q0*q1/(4*pi*eps) is already included when generating the table)
	// 5 cycles delay
	FP_MUL_ADD FP_MUL_r3_term (
		.ax     (terms0_r3),     //   input,  width = 32,     ax.ax
		.ay     (terms1_r3),     //   input,  width = 32,     ay.ay
		.az     (r2_delay),      //   input,  width = 32,     az.az
		.clk    (clk),           //   input,   width = 1,    clk.clk
		.clr    (rst),           //   input,   width = 2,    clr.clr
		.ena    (level1_en || level2_en || level1_en_reg1 || level1_en_reg2 || level1_en_reg3 || level1_en_reg4),     //   input,   width = 1,    ena.ena
		.result (r3_result)     //   output,  width = 32, result.result
	);
	
	// ********** Level 2 ********** //
	// Get Force_LJ/J = R14_term - R8_term
	// 3 cycles delay
	FP_SUB FP_SUB_LJ_Force (
		.ax     (r8_result),     //   input,  width = 32,     ax.ax
		.ay     (r14_result),    //   input,  width = 32,     ay.ay
		.clk    (clk),           //   input,   width = 1,    clk.clk
		.clr    (rst),           //   input,   width = 2,    clr.clr
		.ena    (level2_en || level3_en || level2_en_reg1 || level2_en_reg2),     //   input,   width = 1,    ena.ena
		.result (LJ_Force)       //   output,  width = 32, result.result
	);
	
	// ********** Level 3 ********** //
	// Get Force_RL/J = R14_term - R8_term + R3_term
	// 3 cycles delay
	FP_ADD FP_ADD_Total_Force (
		.ax     (LJ_Force),      //   input,  width = 32,     ax.ax
		.ay     (r3_result_delay),     //   input,  width = 32,     ay.ay
		.clk    (clk),           //   input,   width = 1,    clk.clk
		.clr    (rst),           //   input,   width = 2,    clr.clr
		.ena    (level3_en || level4_en || level3_en_reg1 || level3_en_reg2),     //   input,   width = 1,    ena.ena
		.result (RL_Force)       //   output,  width = 32, result.result
	);
	
	// ********** Level 4 ********** //
	// Get Force component on X direction: Fx = (Force_RL/J) * dx
	// 4 cycles delay
	FP_MUL FP_MUL_FX (
		.ay(RL_Force),     			//     ay.ay
		.az(dx_delay),   				//     az.az
		.clk(clk),    					//    clk.clk
		.clr(rst),    					//    clr.clr
		.ena(level4_en || RL_force_valid || level4_en_reg1 || level4_en_reg2 || level4_en_reg3),    			//    ena.ena
		.result(RL_Force_X)  		// result.result
	);
	
	// Get Force component on Y direction: Fy = (Force_RL/J) * dy
	// 4 cycles delay
	FP_MUL FP_MUL_FY (
		.ay(RL_Force),     			//     ay.ay
		.az(dy_delay),   				//     az.az
		.clk(clk),    					//    clk.clk
		.clr(rst),    					//    clr.clr
		.ena(level4_en || RL_force_valid || level4_en_reg1 || level4_en_reg2 || level4_en_reg3),    			//    ena.ena
		.result(RL_Force_Y)  		// result.result
	);
	
	// Get Force component on Z direction: Fz = (Force_RL/J) * dz
	// 4 cycles delay
	FP_MUL FP_MUL_FZ (
		.ay(RL_Force),     			//     ay.ay
		.az(dz_delay),   				//     az.az
		.clk(clk),    					//    clk.clk
		.clr(rst),    					//    clr.clr
		.ena(level4_en || RL_force_valid || level4_en_reg1 || level4_en_reg2 || level4_en_reg3),    			//    ena.ena
		.result(RL_Force_Z)  		// result.result
	);
	
endmodule

