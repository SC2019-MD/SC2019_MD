/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: r2_compute.v
//
//	Function: Evaluate the r2 value between the reference particle and neighbor particle based on the input coordinate
//					ref - neighbor
//
// Used by:
//				RL_LJ_Pipeline_1st_Order_no_filter.v
//				Filter_Logic.v
//
// Dependency:
// 			FP_MUL.v
//				FP_SUB.v
//			   FP_MUL_ADD.v
//
// FP IP timing:
//				FP_SUB: ay - ax = result				latency: 3
//				FP_MUL: ay * az = result				latency: 4
//				FP_MUL_ADD: ay * az + ax  = result	latency: 5
//
// Latency: total: 17 cycles
//				Level 1: calculate dx, dy, dz (SUB)								3 cycles
//				Level 2: calculate x2 = dx * dx (MUL)							4 cycles
//				Level 3: calculate (x2 + y2) = (x2) + dy * dy (MUL_ADD)	5 cycles
//				Level 4: calculate (x2 + y2) + dz * dz (MUL_ADD)			5 cycles
//
// Update log: 
//			Chen Yang 10/01/18: add dx, dy, dz to output
//			Chen Yang 10/03/18: remove the bug when only few sets of input are valid, the FP IP enable signal is not holding long enough
//
// Created by:
//				Chen Yang 07/15/18
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module r2_compute
#(
	parameter DATA_WIDTH = 32,
	parameter BOUNDING_BOX_X = 32'h426E0000,							// 8.5*7 = 59.5 in IEEE floating point
	parameter BOUNDING_BOX_Y = 32'h424C0000,							// 8.5*6 = 51 in IEEE floating point
	parameter BOUNDING_BOX_Z = 32'h424C0000,							// 8.5*6 = 51 in IEEE floating point
	parameter HALF_BOUNDING_BOX_X_POS = 32'h41EE0000,				// 59.5/2 = 29.75 in IEEE floating point
	parameter HALF_BOUNDING_BOX_Y_POS = 32'h41CC0000,				// 51/2 = 25.5 in IEEE floating point
	parameter HALF_BOUNDING_BOX_Z_POS = 32'h41CC0000,				// 51/2 = 25.5 in IEEE floating point
	parameter HALF_BOUNDING_BOX_X_NEG = 32'hC1EE0000,				// -59.5/2 = -29.75 in IEEE floating point
	parameter HALF_BOUNDING_BOX_Y_NEG = 32'hC1CC0000,				// -51/2 = -25.5 in IEEE floating point
	parameter HALF_BOUNDING_BOX_Z_NEG = 32'hC1CC0000				// -51/2 = -25.5 in IEEE floating point
)
(
	input clk,
	input rst,
	input enable,
	input [DATA_WIDTH-1:0] refx,
	input [DATA_WIDTH-1:0] refy,
	input [DATA_WIDTH-1:0] refz,
	input [DATA_WIDTH-1:0] neighborx,
	input [DATA_WIDTH-1:0] neighbory,
	input [DATA_WIDTH-1:0] neighborz,
	output [DATA_WIDTH-1:0] r2,
	output reg [DATA_WIDTH-1:0] dx_out,
	output reg [DATA_WIDTH-1:0] dy_out,
	output reg [DATA_WIDTH-1:0] dz_out,
	output reg r2_valid
);
	
	wire [DATA_WIDTH-1:0] dx;
	wire [DATA_WIDTH-1:0] dy;
	wire [DATA_WIDTH-1:0] dz;
	wire [DATA_WIDTH-1:0] dx2;
	wire [DATA_WIDTH-1:0] r2_partial;
	
	// Delay the dx input to arrive at the output along with r2 (14 cycles between dx,dy,dz and r2)
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
	reg [DATA_WIDTH-1:0] dx_reg13;
	
	// Delay the dy input before the x2 is calculated (4 cycles)
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
	reg [DATA_WIDTH-1:0] dy_reg13;
	reg [DATA_WIDTH-1:0] dy_delay;
	
	// Delay the dz input before the x2+y2 is calculated (4+5 cycles)
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
	reg [DATA_WIDTH-1:0] dz_reg13;
	reg [DATA_WIDTH-1:0] dz_delay;
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// !!!!!!!!Attention!!!!!!!!
	// The enable singal for FP IPs should kept high until the operation is finished!!!!!!!!
	// When connect the stage enable signal to the IP enable signal, always do logical OR with the next stage enable signal to make sure the calculation is finished
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	wire level1_en;			// Calculate dx, dy, dz
	reg level2_en;				// Calculate dx2
	reg level3_en;				// Calculate dx2 + dy2
	reg level4_en;				// Calculate r2 = dx2 + dy2 + dz2
	reg level1_en_reg1;
	reg level1_en_reg2;
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
	
	assign level1_en = enable;
	
	always@(posedge clk)
		begin
		if(rst)
			begin
			level2_en <= 1'b0;
			level3_en <= 1'b0;
			level4_en <= 1'b0;
			r2_valid <= 1'b0;
			// delay registers to propagate the enable signal of FP IP units
			level1_en_reg1 <= 1'b0;
			level1_en_reg2 <= 1'b0;
			level2_en_reg1 <= 1'b0;
			level2_en_reg2 <= 1'b0;
			level2_en_reg3 <= 1'b0;
			level3_en_reg1 <= 1'b0;
			level3_en_reg2 <= 1'b0;
			level3_en_reg3 <= 1'b0;
			level3_en_reg4 <= 1'b0;
			level4_en_reg1 <= 1'b0;
			level4_en_reg2 <= 1'b0;
			level4_en_reg3 <= 1'b0;
			level4_en_reg4 <= 1'b0;
			// delay registers to propage the dx value to output along with r2
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
			dx_reg13 <= 0;
			dx_out <= 0;							// Output port
			// delay registers to propage the dy value to output along with r2
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
			dy_reg13 <= 0;
			dy_delay <= 0;
			dy_out <= 0;							// Output port
			// delay registers to propage the dz value to output along with r2
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
			dz_reg13 <= 0;
			dz_delay <= 0;
			dz_out <= 0;							// Output port
			end
		else
			begin	
			level1_en_reg1 <= level1_en;
			level1_en_reg2 <= level1_en_reg1;
			
			level2_en <= level1_en_reg2;
			level2_en_reg1 <= level2_en;
			level2_en_reg2 <= level2_en_reg1;
			level2_en_reg3 <= level2_en_reg2;
			
			level3_en <= level2_en_reg3;
			level3_en_reg1 <= level3_en;
			level3_en_reg2 <= level3_en_reg1;
			level3_en_reg3 <= level3_en_reg2;
			level3_en_reg4 <= level3_en_reg3;
			
			level4_en <= level3_en_reg4;
			level4_en_reg1 <= level4_en;
			level4_en_reg2 <= level4_en_reg1;
			level4_en_reg3 <= level4_en_reg2;
			level4_en_reg4 <= level4_en_reg3;
			
			r2_valid <= level4_en_reg4;
			
			// delay registers to propage the dx value to output along with r2
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
			dx_reg13 <= dx_reg12;
			dx_out <= dx_reg13;								// Output port
			// delay registers to propage the dy value to output along with r2
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
			dy_reg13 <= dy_reg12;
			dy_out <= dy_reg13;								// Output port
			dy_delay <= dy_reg3;
			// delay registers to propage the dz value to output along with r2
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
			dz_reg13 <= dz_reg12;
			dz_out <= dz_reg13;								// Output port
			dz_delay <= dz_reg8;
			end
		end

	
	///////////////////////////////////////////////////////////////////////////////////
	// Evaluate raw dx, dy, dz
	///////////////////////////////////////////////////////////////////////////////////
	// dx = refx - neighborx
	// 3 cycles delay
	FP_SUB FP_SUB_diff_x (
		.ax     (neighborx),     		//   input,  width = 32,     ax.ax
		.ay     (refx),     		//   input,  width = 32,     ay.ay
		.clk    (clk),    		//   input,   width = 1,    clk.clk
		.clr    (rst),    		//   input,   width = 2,    clr.clr
		.ena    (level1_en || level2_en || level1_en_reg1 || level1_en_reg2),    //   input,   width = 1,    ena.ena
		.result (dx)  				//  output,  width = 32, result.result
	);
	
	// dy = refy - neighbory
	// 3 cycles delay
	FP_SUB FP_SUB_diff_y (
		.ax     (neighbory),     		//   input,  width = 32,     ax.ax
		.ay     (refy),     		//   input,  width = 32,     ay.ay
		.clk    (clk),    		//   input,   width = 1,    clk.clk
		.clr    (rst),    		//   input,   width = 2,    clr.clr
		.ena    (level1_en || level2_en || level1_en_reg1 || level1_en_reg2),    //   input,   width = 1,    ena.ena
		.result (dy)  				//  output,  width = 32, result.result
	);
	
	// dz = refz - neighborz
	// 3 cycles delay
	FP_SUB FP_SUB_diff_z (
		.ax     (neighborz),     		//   input,  width = 32,     ax.ax
		.ay     (refz),     		//   input,  width = 32,     ay.ay
		.clk    (clk),    		//   input,   width = 1,    clk.clk
		.clr    (rst),    		//   input,   width = 2,    clr.clr
		.ena    (level1_en || level2_en || level1_en_reg1 || level1_en_reg2),    //   input,   width = 1,    ena.ena
		.result (dz)  				//  output,  width = 32, result.result
	);
	
	///////////////////////////////////////////////////////////////////////////////////
	// Evaluate r2
	///////////////////////////////////////////////////////////////////////////////////
	// dx2 = dx * dx
	// 4 cycles delay
	FP_MUL FP_MUL_x2 (
		.ay(dx),     				//     ay.ay
		.az(dx),     				//     az.az
		.clk(clk),    				//    clk.clk
		.clr(rst),    				//    clr.clr
		.ena(level2_en || level3_en || level2_en_reg1 || level2_en_reg2 || level2_en_reg3),    		//    ena.ena
		.result(dx2)  				// result.result
	);
	
	// partial = dx2 + dy2
	// 5 cycles delay
	FP_MUL_ADD FP_MUL_ADD_Partial_r2 (
		.ax     (dx2), 			//   input,  width = 32,     ax.ax
		.ay     (dy_delay),     	//   input,  width = 32,     ay.ay
		.az     (dy_delay),     	//   input,  width = 32,     az.az
		.clk    (clk),          //   input,   width = 1,    clk.clk
		.clr    (rst),          //   input,   width = 2,    clr.clr
		.ena    (level3_en || level4_en || level3_en_reg1 || level3_en_reg2 || level3_en_reg3 || level3_en_reg4),    //   input,   width = 1,    ena.ena
		.result (r2_partial)  	//   output,  width = 32, result.result
	);
	
	// r2 = dx2 + dy2 + dz2
	// 5 cycles delay
	FP_MUL_ADD FP_MUL_ADD_final_r2 (
		.ax     (r2_partial), 	//   input,  width = 32,     ax.ax
		.ay     (dz_delay),     	//   input,  width = 32,     ay.ay
		.az     (dz_delay),     	//   input,  width = 32,     az.az
		.clk    (clk),          //   input,   width = 1,    clk.clk
		.clr    (rst),          //   input,   width = 2,    clr.clr
		.ena    (level4_en || r2_valid || level4_en_reg1 || level4_en_reg2 || level4_en_reg3 || level4_en_reg4),    //   input,   width = 1,    ena.ena
		.result (r2)  				//   output,  width = 32, result.result
	);
 

endmodule

