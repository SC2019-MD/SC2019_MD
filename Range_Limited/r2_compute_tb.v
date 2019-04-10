/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: r2_compute_tb.v
//
//	Function: Testbench for r2_compute
//
// Dependency:
// 			r2_compute.v
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
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ns

module r2_compute_tb;

	parameter DATA_WIDTH = 32;

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
		// r2 = 32'h426C0000 (32'd59)
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
		
		
		#100
		r2_enable <= 1;
		
		#2									// r2 = 32'h426C0000 (32'd59)
		neighborx <= 32'h3F800000;				// 1.0
		neighbory <= 32'h3F800000;				// 1.0
		neighborz <= 32'h3F800000;				// 1.0
		refx <= 32'h40000000;				// 2.0
		refy <= 32'h40800000;				// 4.0
		refz <= 32'h41000000;				// 8.0
		
		#2									// r2 = 32'h40400000 (32'd3)
		neighborx <= 32'h3F800000;				// 1.0
		neighbory <= 32'h3F800000;				// 1.0
		neighborz <= 32'h3F800000;				// 1.0
		refx <= 32'h40000000;				// 2.0
		refy <= 32'h40000000;				// 2.0
		refz <= 32'h40000000;				// 2.0
		
		#2									// r2 = 32'd426C0000(32'd59)
		neighborx <= 32'h40000000;				// 2.0
		neighbory <= 32'h40800000;				// 4.0
		neighborz <= 32'h41000000;				// 8.0
		refx <= 32'h3F800000;				// 1.0
		refy <= 32'h3F800000;				// 1.0
		refz <= 32'h3F800000;				// 1.0
	
	end

	r2_compute #(
		.DATA_WIDTH(DATA_WIDTH)
	)
	r2_evaluate(
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