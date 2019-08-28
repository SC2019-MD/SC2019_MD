/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: r2_compute_with_pbc_tb.v
//
//	Function: Testbench for r2_compute_with_pbc
//
// Dependency:
// 			r2_compute_with_pbc.v
//
// FP IP timing:
//				FP_SUB: ay - ax = result				latency: 3
//				FP_MUL: ay * az = result				latency: 4
//				FP_MUL_ADD: ay * az + ax  = result	latency: 5
//
// Latency: total: 20 cycles
//				Level 1: calculate dx, dy, dz (SUB)								3 cycles
//				Level pbc: calculate dx_pbc, dy_pbc, dz_pbc (SUB)			3 cycles
//				Level 2: calculate x2 = dx * dx (MUL)							4 cycles
//				Level 3: calculate (x2 + y2) = (x2) + dy * dy (MUL_ADD)	5 cycles
//				Level 4: calculate (x2 + y2) + dz * dz (MUL_ADD)			5 cycles
//
//
// Created by:
//				Chen Yang 03/13/19
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ns

module r2_compute_with_pbc_tb;

	parameter DATA_WIDTH = 32;
	parameter BOUNDING_BOX_X = 32'h426E0000;							// 8.5*7 = 59.5 in IEEE floating point
	parameter BOUNDING_BOX_Y = 32'h424C0000;							// 8.5*6 = 51 in IEEE floating point
	parameter BOUNDING_BOX_Z = 32'h424C0000;							// 8.5*6 = 51 in IEEE floating point
	parameter HALF_BOUNDING_BOX_X_POS = 32'h41EE0000;				// 59.5/2 = 29.75 in IEEE floating point
	parameter HALF_BOUNDING_BOX_Y_POS = 32'h41CC0000;				// 51/2 = 25.5 in IEEE floating point
	parameter HALF_BOUNDING_BOX_Z_POS = 32'h41CC0000;				// 51/2 = 25.5 in IEEE floating point
	parameter HALF_BOUNDING_BOX_X_NEG = 32'hC1EE0000;				// -59.5/2 = -29.75 in IEEE floating point
	parameter HALF_BOUNDING_BOX_Y_NEG = 32'hC1CC0000;				// -51/2 = -25.5 in IEEE floating point
	parameter HALF_BOUNDING_BOX_Z_NEG = 32'hC1CC0000;				// -51/2 = -25.5 in IEEE floating point

	reg clk;
	reg rst;
	reg r2_enable;
	reg [DATA_WIDTH-1:0] refx, refy, refz, neighborx, neighbory, neighborz;
	
	wire [DATA_WIDTH-1:0] r2;
	wire [DATA_WIDTH-1:0] dx;
	wire [DATA_WIDTH-1:0] dy;
	wire [DATA_WIDTH-1:0] dz;
	wire r2_valid;
	
	always#1 clk <= ~clk;
	
	initial begin
		clk <= 1;
		rst <= 1;
		r2_enable <= 0;
		refx <= 0;
		refy <= 0;
		refz <= 0;
		neighborx <= 0;
		neighbory <= 0;
		neighborz <= 0;
		
		#10
		rst <= 0;
		
		#2
		r2_enable <= 1'b1;
		// dx = 1.0; 32'h3F800000
		// dy = 3.0; 32'h40400000
		// dz = 7.0; 32'h40E00000
		// r2 = 59;  32'h426C0000
		neighborx <= 32'h3F800000;				// 1.0
		neighbory <= 32'h3F800000;				// 1.0
		neighborz <= 32'h3F800000;				// 1.0
		refx <= 32'h40000000;				// 2.0
		refy <= 32'h40800000;				// 4.0
		refz <= 32'h41000000;				// 8.0
		
		#2
		r2_enable <= 1'b0;
		refx <= 0;
		refy <= 0;
		refz <= 0;
		neighborx <= 0;
		neighbory <= 0;
		neighborz <= 0;
		
		
		#10
		r2_enable <= 1;
		
		#2
		// dx = 1.0; 32'h3F800000
		// dy = 3.0; 32'h40400000
		// dz = 7.0; 32'h40E00000
		// r2 = 59;  32'h426C0000
		neighborx <= 32'h3F800000;				// 1.0
		neighbory <= 32'h3F800000;				// 1.0
		neighborz <= 32'h3F800000;				// 1.0
		refx <= 32'h40000000;				// 2.0
		refy <= 32'h40800000;				// 4.0
		refz <= 32'h41000000;				// 8.0
		
		#2
		// dx = 1.0; 32'h3F800000
		// dy = 1.0; 32'h3F800000
		// dz = 1.0; 32'h3F800000
		// r2 = 3;  32'h40400000
		neighborx <= 32'h3F800000;				// 1.0
		neighbory <= 32'h3F800000;				// 1.0
		neighborz <= 32'h3F800000;				// 1.0
		refx <= 32'h40000000;				// 2.0
		refy <= 32'h40000000;				// 2.0
		refz <= 32'h40000000;				// 2.0
		
		#2
		// dx = -1.0; 32'hBF800000
		// dy = -3.0; 32'hC0400000
		// dz = -7.0; 32'hC0E00000
		// r2 = 59;  32'h426C0000
		neighborx <= 32'h40000000;				// 2.0
		neighbory <= 32'h40800000;				// 4.0
		neighborz <= 32'h41000000;				// 8.0
		refx <= 32'h3F800000;				// 1.0
		refy <= 32'h3F800000;				// 1.0
		refz <= 32'h3F800000;				// 1.0
		
		#2
		// dx = -0.5, 32'hBF000000
		// dy = -0.5, 32'hBF000000
		// dz = -0.5, 32'hBF000000
		// r2 = 0.75, 32'h3F400000
		neighborx <= 32'h00000000;				// 0.0
		neighbory <= 32'h00000000;				// 0.0
		neighborz <= 32'h00000000;				// 0.0
		refx <= 32'h426C0000;				// 59.0
		refy <= 32'h424A0000;				// 50.5
		refz <= 32'h424A0000;				// 50.5
		
		#2
		// dx = 0.5, 32'h3F000000
		// dy = 0.5, 32'h3F000000
		// dz = 0.5, 32'h3F000000
		// r2 = 0.75, 32'h3F400000
		refx <= 32'h00000000;				// 0.0
		refy <= 32'h00000000;				// 0.0
		refz <= 32'h00000000;				// 0.0
		neighborx <= 32'h426C0000;				// 59.0
		neighbory <= 32'h424A0000;				// 50.5
		neighborz <= 32'h424A0000;				// 50.5
	
		#2
		r2_enable <= 0;
		
	end

	r2_compute_with_pbc #(
		.DATA_WIDTH(DATA_WIDTH),
		.BOUNDING_BOX_X(BOUNDING_BOX_X),
		.BOUNDING_BOX_Y(BOUNDING_BOX_Y),
		.BOUNDING_BOX_Z(BOUNDING_BOX_Z),
		.HALF_BOUNDING_BOX_X_POS(HALF_BOUNDING_BOX_X_POS),
		.HALF_BOUNDING_BOX_Y_POS(HALF_BOUNDING_BOX_Y_POS),
		.HALF_BOUNDING_BOX_Z_POS(HALF_BOUNDING_BOX_Z_POS),
		.HALF_BOUNDING_BOX_X_NEG(HALF_BOUNDING_BOX_X_NEG),
		.HALF_BOUNDING_BOX_Y_NEG(HALF_BOUNDING_BOX_Y_NEG),
		.HALF_BOUNDING_BOX_Z_NEG(HALF_BOUNDING_BOX_Z_NEG)
	)
	UUT(
		.clk(clk),
		.rst(rst),
		.enable(r2_enable),
		.refx(refx),
		.refy(refy),
		.refz(refz),
		.neighborx(neighborx),
		.neighbory(neighbory),
		.neighborz(neighborz),
		.r2(r2),
		.dx_out(dx),
		.dy_out(dy),
		.dz_out(dz),
		.r2_valid(r2_valid)
	);


endmodule