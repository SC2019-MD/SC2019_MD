/**************************************
**************************************/

module vec_fp_div
(
	input clk,
	input [95:0] a,
	input [31:0] b,
	output [95:0] r
	
);

	fp_div div1(
	clk,
	a[31:0],
	b[31:0],
	r[31:0]
	);

	fp_div div2(
	clk,
	a[63:32],
	b[31:0],
	r[63:32]
	);

	fp_div div3(
	clk,
	a[95:64],
	b[31:0],
	r[95:64]
	);

endmodule 