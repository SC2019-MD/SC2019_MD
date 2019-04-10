/**************************************
**************************************/

module get_len
(
	input clock,
	input rst,
	input [95:0] data,
	output [31:0] result
);


 get_len_2 get_len_2(
		clock,    //    clk.clk
		rst, // areset.reset
		data[95:64],      //      a.a
		data[63:32],      //      b.b
		data[31:0],      //      c.c
		result     //      q.q
	);

	
/*

wire [31:0] rest1;
wire [31:0] rest2;
wire [31:0] rest3;
wire [31:0] add1;
wire [31:0] add2;


fp_mult mult1(
	.clock(clock),
	.dataa(data[95:64]),
	.datab(data[95:64]),
	.result(rest1)
	
);

fp_mult mult2(
	.clock(clock),
	.dataa(data[63:32]),
	.datab(data[63:32]),
	.result(rest2)
	
);

fp_mult mult3(
	.clock(clock),
	.dataa(data[31:0]),
	.datab(data[31:0]),
	.result(rest3)
	
);

wire [31:0] rest3_r;
syn_fifo #(32, 14) f3(clock, rst, rest3, rest3_r);
	
	
fp_add adder1(
	clock,
	rest1,
	rest2,
	add1);
	
fp_add adder2(
	clock,
	rest3_r,
	add1,
	add2);

fp_sqrt sqrt1(
	clock,
	add2,
	result);	
*/
endmodule 