/**************************************

**************************************/

module atan2
(
input clk,
input [31:0] a,
input [31:0] b,
output [31:0] r

);

wire [31:0] data;
wire [31:0] result;
wire aeb_a, agb_a, alb_a, aeb_b, agb_b, alb_b;

fp_div div2(clk, a, b, data);

fp_comp comp1(
	clk,
	a,
	'h0,
	aeb_a,
	agb_a,
	alb_a);

fp_comp comp2(
	clk,
	b,
	'h0,
	aeb_b,
	agb_b,
	alb_b);
wire aeb_a_r, alb_a_r, aeb_b_r, agb_b_r, alb_b_r;
syn_fifo #(1, 78) f1(clk, rst, aeb_a, aeb_a_r);
syn_fifo #(1, 78) f2(clk, rst, alb_a, alb_a_r);
syn_fifo #(1, 78) f3(clk, rst, aeb_b, aeb_b_r);
syn_fifo #(1, 78) f4(clk, rst, agb_b, agb_b_r);
syn_fifo #(1, 78) f5(clk, rst, alb_b, alb_b_r);
atan atan1(
	clk,
	data,
	result);
wire [31:0] result_r;
syn_fifo #(32, 14) f6(clk, rst, result, result_r);
//pi:  40490fdb
//pi/2: 0x3fc90fdb
//-pi/2: bfc90fdb

wire [31:0] add_res;
wire [31:0] sub_res_2;

fp_add add1(clk, 32'h40490fdb, result, add_res);
fp_sub sub2(clk, result, 32'h40490fdb, sub_res_2);
reg [31:0] r_t;
always @ (posedge clk) begin 
	if(agb_a == 1) begin
		r_t = result_r;
	end else if (alb_a == 1 && (agb_b == 1 || aeb_b == 1)) begin 
		r_t = add_res;
	end else if (alb_a == 1 && alb_b == 1) begin
		r_t = sub_res_2;
	end else if (aeb_a == 1 && agb_b == 1) begin
		r_t = 32'h3fc90fdb;
	end else if (aeb_a == 1 && alb_b == 1) begin
		r_t = 32'hbfc90fdb;
	end else begin
		r_t = 0;
	end
end

assign r= r_t;


	
endmodule