`timescale 1 ps / 1 ps

module vec_fp_sub_tb();

reg [95:0] a;
reg [95:0] b;
reg clk;
wire [95:0] r;


vec_fp_sub
fp(
	a,
	b,
	r,
	clk
);

initial begin
	a = 'h3f8ccccd_3f8ccccd_3f8ccccd;
	b = 'h4159999a_4159999a_4159999a;
	
	#200;
	a = 'h3f8ccccd_41e770a4_3f8ccccd;
	b = 'h4159999a_40ec28f6_4159999a;
	
	
	#200;
	a = 'h3f8ccccd_41e770a4_4602db54;
	b = 'h4159999a_40ec28f6_42f68f5c;

	
end 

always begin
#5
clk=~clk;
end


endmodule