module Reduction_Tree(clk, rst, out_port, in_port1, in_port2);

input clk;
input rst;
output [31:0] out_port;
input [31:0] in_port1 [0:3][0:3][0:3];
input [31:0] in_port2 [0:3][0:3][0:3];

logic [31:0] stage1 [1:0];
logic [31:0] stage2 [3:0];
logic [31:0] stage3 [7:0];
logic [31:0] stage4 [15:0];
logic [31:0] stage5 [31:0];
logic [31:0] stage6 [63:0];

genvar i;
generate
	for (i = 0; i < 64; i = i + 1) begin: init_add_inputs
		FpAdd reduce6(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(in_port1[i[5:4]][i[3:2]][i[1:0]]), .ay(in_port2[i[5:4]][i[3:2]][i[1:0]]), .result(stage6[i]));
	end
endgenerate

FpAdd reduce5_31(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage6[63]), .ay(stage6[62]), .result(stage5[31]));
FpAdd reduce5_30(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage6[61]), .ay(stage6[60]), .result(stage5[30]));
FpAdd reduce5_29(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage6[59]), .ay(stage6[58]), .result(stage5[29]));
FpAdd reduce5_28(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage6[57]), .ay(stage6[56]), .result(stage5[28]));
FpAdd reduce5_27(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage6[55]), .ay(stage6[54]), .result(stage5[27]));
FpAdd reduce5_26(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage6[53]), .ay(stage6[52]), .result(stage5[26]));
FpAdd reduce5_25(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage6[51]), .ay(stage6[50]), .result(stage5[25]));
FpAdd reduce5_24(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage6[49]), .ay(stage6[48]), .result(stage5[24]));
FpAdd reduce5_23(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage6[47]), .ay(stage6[46]), .result(stage5[23]));
FpAdd reduce5_22(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage6[45]), .ay(stage6[44]), .result(stage5[22]));
FpAdd reduce5_21(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage6[43]), .ay(stage6[42]), .result(stage5[21]));
FpAdd reduce5_20(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage6[41]), .ay(stage6[40]), .result(stage5[20]));
FpAdd reduce5_19(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage6[39]), .ay(stage6[38]), .result(stage5[19]));
FpAdd reduce5_18(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage6[37]), .ay(stage6[36]), .result(stage5[18]));
FpAdd reduce5_17(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage6[35]), .ay(stage6[34]), .result(stage5[17]));
FpAdd reduce5_16(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage6[33]), .ay(stage6[32]), .result(stage5[16]));
FpAdd reduce5_15(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage6[31]), .ay(stage6[30]), .result(stage5[15]));
FpAdd reduce5_14(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage6[29]), .ay(stage6[28]), .result(stage5[14]));
FpAdd reduce5_13(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage6[27]), .ay(stage6[26]), .result(stage5[13]));
FpAdd reduce5_12(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage6[25]), .ay(stage6[24]), .result(stage5[12]));
FpAdd reduce5_11(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage6[23]), .ay(stage6[22]), .result(stage5[11]));
FpAdd reduce5_10(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage6[21]), .ay(stage6[20]), .result(stage5[10]));
FpAdd reduce5_9(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage6[19]), .ay(stage6[18]), .result(stage5[9]));
FpAdd reduce5_8(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage6[17]), .ay(stage6[16]), .result(stage5[8]));
FpAdd reduce5_7(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage6[15]), .ay(stage6[14]), .result(stage5[7]));
FpAdd reduce5_6(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage6[13]), .ay(stage6[12]), .result(stage5[6]));
FpAdd reduce5_5(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage6[11]), .ay(stage6[10]), .result(stage5[5]));
FpAdd reduce5_4(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage6[9]), .ay(stage6[8]), .result(stage5[4]));
FpAdd reduce5_3(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage6[7]), .ay(stage6[6]), .result(stage5[3]));
FpAdd reduce5_2(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage6[5]), .ay(stage6[4]), .result(stage5[2]));
FpAdd reduce5_1(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage6[3]), .ay(stage6[2]), .result(stage5[1]));
FpAdd reduce5_0(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage6[1]), .ay(stage6[0]), .result(stage5[0]));

FpAdd reduce4_15(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage5[31]), .ay(stage5[30]), .result(stage4[15]));
FpAdd reduce4_14(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage5[29]), .ay(stage5[28]), .result(stage4[14]));
FpAdd reduce4_13(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage5[27]), .ay(stage5[26]), .result(stage4[13]));
FpAdd reduce4_12(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage5[25]), .ay(stage5[24]), .result(stage4[12]));
FpAdd reduce4_11(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage5[23]), .ay(stage5[22]), .result(stage4[11]));
FpAdd reduce4_10(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage5[21]), .ay(stage5[20]), .result(stage4[10]));
FpAdd reduce4_9(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage5[19]), .ay(stage5[18]), .result(stage4[9]));
FpAdd reduce4_8(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage5[17]), .ay(stage5[16]), .result(stage4[8]));
FpAdd reduce4_7(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage5[15]), .ay(stage5[14]), .result(stage4[7]));
FpAdd reduce4_6(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage5[13]), .ay(stage5[12]), .result(stage4[6]));
FpAdd reduce4_5(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage5[11]), .ay(stage5[10]), .result(stage4[5]));
FpAdd reduce4_4(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage5[9]), .ay(stage5[8]), .result(stage4[4]));
FpAdd reduce4_3(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage5[7]), .ay(stage5[6]), .result(stage4[3]));
FpAdd reduce4_2(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage5[5]), .ay(stage5[4]), .result(stage4[2]));
FpAdd reduce4_1(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage5[3]), .ay(stage5[2]), .result(stage4[1]));
FpAdd reduce4_0(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage5[1]), .ay(stage5[0]), .result(stage4[0]));

FpAdd reduce3_7(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage4[15]), .ay(stage4[14]), .result(stage3[7]));
FpAdd reduce3_6(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage4[13]), .ay(stage4[12]), .result(stage3[6]));
FpAdd reduce3_5(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage4[11]), .ay(stage4[10]), .result(stage3[5]));
FpAdd reduce3_4(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage4[9]), .ay(stage4[8]), .result(stage3[4]));
FpAdd reduce3_3(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage4[7]), .ay(stage4[6]), .result(stage3[3]));
FpAdd reduce3_2(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage4[5]), .ay(stage4[4]), .result(stage3[2]));
FpAdd reduce3_1(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage4[3]), .ay(stage4[2]), .result(stage3[1]));
FpAdd reduce3_0(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage4[1]), .ay(stage4[0]), .result(stage3[0]));

FpAdd reduce2_3(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage3[7]), .ay(stage3[6]), .result(stage2[3]));
FpAdd reduce2_2(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage3[5]), .ay(stage3[4]), .result(stage2[2]));
FpAdd reduce2_1(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage3[3]), .ay(stage3[2]), .result(stage2[1]));
FpAdd reduce2_0(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage3[1]), .ay(stage3[0]), .result(stage2[0]));

FpAdd reduce1_0(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage2[1]), .ay(stage2[0]), .result(stage1[0]));
FpAdd reduce1_1(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage2[3]), .ay(stage2[2]), .result(stage1[1]));

FpAdd reduce0_0(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(stage1[1]), .ay(stage1[0]), .result(out_port));

endmodule
