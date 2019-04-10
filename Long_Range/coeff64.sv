module coeff64(
clk,
rst,
wen_in,
forceValid_in, // after cycle delay like wen_in
CA_BI,
wen_out,
forceValid_out, //
selx,
sely,
selz,
user_buffer_data,
coeff
);

parameter HIGHPOWER = 3;
parameter NUMEQU    = 4;
parameter NUMCOEFF = NUMEQU*NUMEQU*NUMEQU;
parameter TOFPDELAY = 4;
parameter MULDELAY = 3;
parameter ADDDELAY = 2;
localparam FPONE = 32'b00111111100000000000000000000000;

input  logic clk;
input  logic rst;
input  logic wen_in;
input  logic forceValid_in; // after cycle delay like wen_in
input  logic [1:0] CA_BI;
output logic wen_out;
output logic forceValid_out; //
output logic [3:0] selx;
output logic [3:0] sely;
output logic [3:0] selz;
input  logic [127:0] user_buffer_data;
output logic [31:0] coeff [0:NUMEQU-1] [0:NUMEQU-1] [0:NUMEQU-1];

// For the third order basis function we only need 64 outputs to describe the 4x4x4 grid
// Now we are using the fifth order basis function which needs 216 outputs to describe the 6x6x6 grid

// stage 1
wire [26:0] oix_s1;
wire [26:0] oiy_s1;
wire [26:0] oiz_s1;
wire [31:0] q_s1;
wire [8:0] mem_Addr_s1;
wire [5:0] sel_s1;
wire [31:0] ctrl_s1;
wire wen_s1;

// Convert input memory bus to X, Y, Z and memory locations information
assign {mem_Addr_s1[8:6],sel_s1[5:4],oiz_s1,mem_Addr_s1[5:3],sel_s1[3:2],oiy_s1,mem_Addr_s1[2:0],sel_s1[1:0],oix_s1,q_s1} = user_buffer_data;

// Through testbench looks like the wen_in signal is passed through one clock late
assign ctrl_s1 = (rst == 1) ? 0 : {15'b01111111000000,forceValid_in,wen_in, mem_Addr_s1, sel_s1};

// stage 2-- convert to floating points
wire [31:0] oix_fp_s2;
wire [31:0] oiy_fp_s2;
wire [31:0] oiz_fp_s2;
wire [31:0] q_fp_s2;
reg [31:0] ctrl_s2_d0;
reg [31:0] ctrl_s2_d1;
reg [31:0] ctrl_s2_d2;
reg [31:0] ctrl_s2;
toFp x(.clk(clk),.areset(rst),.a({5'd0,oix_s1}),.q(oix_fp_s2));
toFp y(.clk(clk),.areset(rst),.a({5'd0,oiy_s1}),.q(oiy_fp_s2));
toFp z(.clk(clk),.areset(rst),.a({5'd0,oiz_s1}),.q(oiz_fp_s2));
toFp q2(.clk(clk),.areset(rst),.a(q_s1),.q(q_fp_s2));

customdelay #(.DELAY(TOFPDELAY)) tofp_ctrl(.clk(clk), .rst(rst), .x(ctrl_s1), .y(ctrl_s2));

// generate powers of input:
//   ex: x, x^2, x^3, x^4, ...
// stage 3 -- generate oi2
wire [31:0] oix_fp_s3;
wire [31:0] oiy_fp_s3;
wire [31:0] oiz_fp_s3;
wire [31:0] oix2_fp_s3;
wire [31:0] oiy2_fp_s3;
wire [31:0] oiz2_fp_s3;
wire [31:0] q_fp_s3;
wire [31:0] ctrl_s3;

FpMul oix2s3(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ay(oix_fp_s2), .az(oix_fp_s2), .result(oix2_fp_s3));
FpMul oiy2s3(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ay(oiy_fp_s2), .az(oiy_fp_s2), .result(oiy2_fp_s3));
FpMul oiz2s3(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ay(oiz_fp_s2), .az(oiz_fp_s2), .result(oiz2_fp_s3));

// Delay oi to match timing with oi^2
// Redo delay using parameter for clock cycles of FpMul
customdelay #(.DELAY(MULDELAY)) oixs3(.clk(clk), .rst(rst), .x(oix_fp_s2), .y(oix_fp_s3));
customdelay #(.DELAY(MULDELAY)) oiys3(.clk(clk), .rst(rst), .x(oiy_fp_s2), .y(oiy_fp_s3));
customdelay #(.DELAY(MULDELAY)) oizs3(.clk(clk), .rst(rst), .x(oiz_fp_s2), .y(oiz_fp_s3));

customdelay #(.DELAY(MULDELAY)) ctrls3(.clk(clk), .rst(rst), .x(ctrl_s2), .y(ctrl_s3));
customdelay #(.DELAY(MULDELAY)) qs3(.clk(clk), .rst(rst), .x(q_fp_s2), .y(q_fp_s3));

// stage 4 -- generate oi3 and oi4

wire [31:0] oix_fp_s4;
wire [31:0] oiy_fp_s4;
wire [31:0] oiz_fp_s4;
wire [31:0] oix2_fp_s4;
wire [31:0] oiy2_fp_s4;
wire [31:0] oiz2_fp_s4;
wire [31:0] oix3_fp_s4;
wire [31:0] oiy3_fp_s4;
wire [31:0] oiz3_fp_s4;
wire [31:0] q_fp_s4;
wire [31:0] ctrl_s4;


FpMul oix3s4(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ay(oix_fp_s3), .az(oix2_fp_s3), .result(oix3_fp_s4));
FpMul oiy3s4(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ay(oiy_fp_s3), .az(oiy2_fp_s3), .result(oiy3_fp_s4));
FpMul oiz3s4(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ay(oiz_fp_s3), .az(oiz2_fp_s3), .result(oiz3_fp_s4));

customdelay #(.DELAY(MULDELAY)) oix2s4(.clk(clk), .rst(rst), .x(oix2_fp_s3), .y(oix2_fp_s4));
customdelay #(.DELAY(MULDELAY)) oiy2s4(.clk(clk), .rst(rst), .x(oiy2_fp_s3), .y(oiy2_fp_s4));
customdelay #(.DELAY(MULDELAY)) oiz2s4(.clk(clk), .rst(rst), .x(oiz2_fp_s3), .y(oiz2_fp_s4));

customdelay #(.DELAY(MULDELAY)) oixs4 (.clk(clk), .rst(rst), .x(oix_fp_s3), .y(oix_fp_s4));
customdelay #(.DELAY(MULDELAY)) oiys4 (.clk(clk), .rst(rst), .x(oiy_fp_s3), .y(oiy_fp_s4));
customdelay #(.DELAY(MULDELAY)) oizs4 (.clk(clk), .rst(rst), .x(oiz_fp_s3), .y(oiz_fp_s4));

customdelay #(.DELAY(MULDELAY)) ctrls4(.clk(clk), .rst(rst), .x(ctrl_s3), .y(ctrl_s4));
customdelay #(.DELAY(MULDELAY)) qs4   (.clk(clk), .rst(rst), .x(q_fp_s3), .y(q_fp_s4));


// stage 5 -- generate 48 initial values - 14 each for each dimension

// define CM phi coefficients

// pphi ersion --- power of oi
	wire [31:0] phi [0:NUMEQU-1][0:HIGHPOWER];
	wire [31:0] dphi [0:NUMEQU-1][0:HIGHPOWER];

	// Generic basis polynomial. change coeff for gausian
	assign phi[0][3] = 32'b10111111000000000000000000000000 ;  //-0.5
	assign phi[0][2] = 32'b00111111100000000000000000000000 ; // 1
	assign phi[0][1] = 32'b10111111000000000000000000000000 ; // -0.5
	assign phi[0][0] = 32'b00000000000000000000000000000000 ; // 0
	assign phi[1][3] = 32'b00111111110000000000000000000000 ; // 1.5
	assign phi[1][2] = 32'b01000000001000000000000000000000 ; // -2.5  
	assign phi[1][1] = 32'b00000000000000000000000000000000 ; // 0
	assign phi[1][0] = 32'b00111111100000000000000000000000 ; // 1
	assign phi[2][3] = 32'b10111111110000000000000000000000 ; // -1.5
	assign phi[2][2] = 32'b01000000000000000000000000000000 ; // 2
	assign phi[2][1] = 32'b00111111000000000000000000000000 ; // 0.5
	assign phi[2][0] = 32'b00000000000000000000000000000000 ; // 0
	assign phi[3][3] = 32'b00111111000000000000000000000000 ; // 0.5
	assign phi[3][2] = 32'b10111111100000000000000000000000 ; // -0.5  
	assign phi[3][1] = 32'b00000000000000000000000000000000 ; // 0
	assign phi[3][0] = 32'b00000000000000000000000000000000 ; // 0

	assign dphi[0][3] = 32'b00000000000000000000000000000000 ; // 0
	assign dphi[0][2] = 32'b10111111110000000000000000000000 ; // -1.5
	assign dphi[0][1] = 32'b01000000000000000000000000000000 ; // 2
	assign dphi[0][0] = 32'b10111111000000000000000000000000 ; // -0.5
	assign dphi[1][3] = 32'b00000000000000000000000000000000 ; // 0
	assign dphi[1][2] = 32'b01000000100100000000000000000000 ; //4.5
	assign dphi[1][1] = 32'b11000000101000000000000000000000 ; // -5
	assign dphi[1][0] = 32'b00000000000000000000000000000000 ; // 0
	assign dphi[2][3] = 32'b00000000000000000000000000000000 ; // 0
	assign dphi[2][2] = 32'b11000000100100000000000000000000 ; // -4.5
	assign dphi[2][1] = 32'b01000000100000000000000000000000 ; // 4
	assign dphi[2][0] = 32'b00111111000000000000000000000000 ; // 0.5
	assign dphi[3][3] = 32'b00000000000000000000000000000000 ; // 0
	assign dphi[3][2] = 32'b00111111110000000000000000000000 ; // 1.5
	assign dphi[3][1] = 32'b10111111100000000000000000000000 ; // -1
	assign dphi[3][0] = 32'b00000000000000000000000000000000 ; // 0
	
	
	wire [31:0] ppx_s5 [0:NUMEQU-1] [0:HIGHPOWER];

	logic [31:0] mul_inputx_fp_s4 [0:HIGHPOWER];
	assign mul_inputx_fp_s4[0] = FPONE;
	assign mul_inputx_fp_s4[1] = oix_fp_s4;
	assign mul_inputx_fp_s4[2] = oix2_fp_s4;
	assign mul_inputx_fp_s4[3] = oix3_fp_s4;

	genvar stage5xequ_i, stage5x_i;
	generate 
	for (stage5xequ_i = 0; stage5xequ_i < NUMEQU; stage5xequ_i = stage5xequ_i + 1)
	begin : gunmulxequ_fp_s5
		for (stage5x_i = 0; stage5x_i < HIGHPOWER+1; stage5x_i = stage5x_i + 1) 
		begin : genmulx_fp_s5
			FpMul phixs5(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ay(mul_inputx_fp_s4[stage5x_i]), .az((CA_BI==2'b01)?dphi[stage5xequ_i][stage5x_i] : phi[stage5xequ_i][stage5x_i] ), .result( ppx_s5[stage5xequ_i][stage5x_i] ));
		end
	end
	endgenerate
	
	wire [31:0] ppy_s5 [0:NUMEQU-1][0:HIGHPOWER];

	logic [31:0] mul_inputy_fp_s4 [0:HIGHPOWER];
	assign mul_inputy_fp_s4[0] = FPONE;
	assign mul_inputy_fp_s4[1] = oiy_fp_s4;
	assign mul_inputy_fp_s4[2] = oiy2_fp_s4;
	assign mul_inputy_fp_s4[3] = oiy3_fp_s4;

	genvar stage5yequ_i, stage5y_i;
	generate 
	for (stage5yequ_i = 0; stage5yequ_i < NUMEQU; stage5yequ_i = stage5yequ_i + 1) 
	begin : genmulyequ_fp_s5
		for (stage5y_i = 0; stage5y_i < HIGHPOWER+1; stage5y_i = stage5y_i + 1) 
		begin : genmuly_fp_s5
			FpMul phiys5(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ay(mul_inputy_fp_s4[stage5y_i]), .az((CA_BI==2'b10)?dphi[stage5yequ_i][stage5y_i] : phi[stage5yequ_i][stage5y_i] ), .result( ppy_s5[stage5yequ_i][stage5y_i] ));
		end
	end
	endgenerate

	wire [31:0] ppz_s5 [0:NUMEQU-1][0:HIGHPOWER];

	logic [31:0] mul_inputz_fp_s4 [0:HIGHPOWER];
	assign mul_inputz_fp_s4[0] = FPONE;
	assign mul_inputz_fp_s4[1] = oiz_fp_s4;
	assign mul_inputz_fp_s4[2] = oiz2_fp_s4;
	assign mul_inputz_fp_s4[3] = oiz3_fp_s4;

	genvar stage5zequ_i, stage5z_i;
	generate 
	for (stage5zequ_i = 0; stage5zequ_i < NUMEQU; stage5zequ_i = stage5zequ_i + 1) 
	begin : genmulzequ_fp_s5
		for (stage5z_i = 0; stage5z_i < HIGHPOWER+1; stage5z_i = stage5z_i + 1) 
		begin : genmulz_fp_s5
			FpMul phizs5(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ay(mul_inputz_fp_s4[stage5z_i]), .az((CA_BI==2'b11)?dphi[stage5zequ_i][stage5z_i] : phi[stage5zequ_i][stage5z_i] ), .result( ppz_s5[stage5zequ_i][stage5z_i] ));
		end
	end
	endgenerate

	wire [31:0]ctrl_s5;
	wire [31:0]q_fp_s5; 
	customdelay #(.DELAY(MULDELAY)) ctrls5(.clk(clk), .rst(rst), .x(ctrl_s4), .y(ctrl_s5));
	customdelay #(.DELAY(MULDELAY)) qs5   (.clk(clk), .rst(rst), .x(q_fp_s4), .y(q_fp_s5));

// ---------------------- END STAGE 5 ---------------------

	// stage 6 - first stage of summation - 24 results
	
	wire [31:0] ppx_s6 [0:NUMEQU-1][0:HIGHPOWER/2];

	genvar stage6xequ_i, stage6x_i;
	generate 
	for (stage6xequ_i = 0; stage6xequ_i < NUMEQU; stage6xequ_i = stage6xequ_i + 1) 
	begin : genmulxequ_fp_s6
		for (stage6x_i = 0; stage6x_i < (HIGHPOWER+1)/2; stage6x_i = stage6x_i + 1) 
		begin : genmulx_fp_s6
			FpAdd phixs6(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(ppx_s5[stage6xequ_i][(stage6x_i*2)+1]), .ay(ppx_s5[stage6xequ_i][(stage6x_i*2)]), .result(ppx_s6[stage6xequ_i][stage6x_i]));
		end
	end
	endgenerate

	wire [31:0] ppy_s6 [0:NUMEQU-1][0:HIGHPOWER/2];

	genvar stage6yequ_i, stage6y_i;
	generate 
	for (stage6yequ_i = 0; stage6yequ_i < NUMEQU; stage6yequ_i = stage6yequ_i + 1) 
	begin : genmulyequ_fp_s6
		for (stage6y_i = 0; stage6y_i < (HIGHPOWER+1)/2; stage6y_i = stage6y_i + 1) 
		begin : genmuly_fp_s6
			FpAdd phiys6(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(ppy_s5[stage6yequ_i][(stage6y_i*2)+1]), .ay(ppy_s5[stage6yequ_i][(stage6y_i*2)]), .result(ppy_s6[stage6yequ_i][stage6y_i]));
		end
	end
	endgenerate
	
	wire [31:0] ppz_s6 [0:NUMEQU-1][0:HIGHPOWER/2];

	genvar stage6zequ_i, stage6z_i;
	generate 
	for (stage6zequ_i = 0; stage6zequ_i < NUMEQU; stage6zequ_i = stage6zequ_i + 1) 
	begin : genmulzequ_fp_s6
		for (stage6z_i = 0; stage6z_i < (HIGHPOWER+1)/2; stage6z_i = stage6z_i + 1) 
		begin : genmulz_fp_s6
			FpAdd phizs6(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(ppz_s5[stage6zequ_i][(stage6z_i*2)+1]), .ay(ppz_s5[stage6zequ_i][(stage6z_i*2)]), .result(ppz_s6[stage6zequ_i][stage6z_i]));
		end
	end
	endgenerate
	
	wire [31:0] ctrl_s6;
	wire [31:0] q_fp_s6;
	customdelay #(.DELAY(ADDDELAY)) ctrls6(.clk(clk), .rst(rst), .x(ctrl_s5), .y(ctrl_s6));
	customdelay #(.DELAY(ADDDELAY)) qs6   (.clk(clk), .rst(rst), .x(q_fp_s5), .y(q_fp_s6));
	
// ---------------------- END STAGE 6 ---------------------

	// Stage 7 PART 1-- 12 partial products
	
	wire [31:0] ppx_s7 [0:NUMEQU-1];
	FpAdd phi0xs71(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(ppx_s6[0][0]), .ay(ppx_s6[0][1]), .result(ppx_s7[0]));
	FpAdd phi1xs71(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(ppx_s6[1][0]), .ay(ppx_s6[1][1]), .result(ppx_s7[1]));
	FpAdd phi2xs71(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(ppx_s6[2][0]), .ay(ppx_s6[2][1]), .result(ppx_s7[2]));
	FpAdd phi3xs71(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(ppx_s6[3][0]), .ay(ppx_s6[3][1]), .result(ppx_s7[3]));

	wire [31:0] ppy_s7 [0:NUMEQU-1];
	FpAdd phi0ys71(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(ppy_s6[0][0]), .ay(ppy_s6[0][1]), .result(ppy_s7[0]));
	FpAdd phi1ys71(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(ppy_s6[1][0]), .ay(ppy_s6[1][1]), .result(ppy_s7[1]));
	FpAdd phi2ys71(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(ppy_s6[2][0]), .ay(ppy_s6[2][1]), .result(ppy_s7[2]));
	FpAdd phi3ys71(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(ppy_s6[3][0]), .ay(ppy_s6[3][1]), .result(ppy_s7[3]));
	
	wire [31:0] ppz_s7 [0:NUMEQU-1];
	FpAdd phi0zs71(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(ppz_s6[0][0]), .ay(ppz_s6[0][1]), .result(ppz_s7[0]));
	FpAdd phi1zs71(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(ppz_s6[1][0]), .ay(ppz_s6[1][1]), .result(ppz_s7[1]));
	FpAdd phi2zs71(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(ppz_s6[2][0]), .ay(ppz_s6[2][1]), .result(ppz_s7[2]));
	FpAdd phi3zs71(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ax(ppz_s6[3][0]), .ay(ppz_s6[3][1]), .result(ppz_s7[3]));
	
	
	wire [31:0] ctrl_s7;
	wire [31:0] q_fp_s7;
	customdelay #(.DELAY(ADDDELAY)) ctrls71(.clk(clk), .rst(rst), .x(ctrl_s6), .y(ctrl_s7));
	customdelay #(.DELAY(ADDDELAY)) qs71 (.clk(clk), .rst(rst), .x(q_fp_s6), .y(q_fp_s7));
	

// ---------------------- END STAGE 7 ---------------------
	
	// stage 8  - generate 16 x,y combinations and 4 z,q combinations. select q if charge mapping
	
	wire [31:0] pzq_s8 [0:NUMEQU-1];
	
	wire [31:0] pxy_s8 [0:NUMEQU-1][0:NUMEQU-1];
	
	genvar stage8z_i;
	generate
		for (stage8z_i = 0; stage8z_i < NUMEQU; stage8z_i = stage8z_i + 1)
		begin : genpzqs8
			FpMul pzq0s8 (.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ay(ppz_s7[stage8z_i]), .az((CA_BI==2'b00)?q_fp_s7:FPONE), .result(pzq_s8[stage8z_i]));
		end
	endgenerate
	
	genvar stage8x_i,stage8y_i;
	generate
		for (stage8x_i = 0; stage8x_i < NUMEQU; stage8x_i = stage8x_i + 1)
		begin : genpxs8
			for (stage8y_i = 0; stage8y_i < NUMEQU; stage8y_i = stage8y_i + 1)
			begin : genpys8
				FpMul pxys8 (.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ay(ppx_s7[stage8x_i]), .az(ppy_s7[stage8y_i]), .result(pxy_s8[stage8y_i][stage8x_i]));
			end
		end
	endgenerate
	
	wire [31:0]ctrl_s8;
	customdelay #(.DELAY(MULDELAY)) ctrls8(.clk(clk), .rst(rst), .x(ctrl_s7), .y(ctrl_s8));

// ---------------------- END STAGE 8 ---------------------
	
	
	// stage 9 - generate 64 coefficients

	genvar stage9x_i, stage9y_i, stage9z_i;
	generate
		for (stage9z_i = 0; stage9z_i < NUMEQU; stage9z_i = stage9z_i + 1)
		begin : gencoefflistz
			for (stage9y_i = 0; stage9y_i < NUMEQU; stage9y_i = stage9y_i + 1)
			begin : gencoefflisty
				for (stage9x_i = 0; stage9x_i < NUMEQU; stage9x_i = stage9x_i + 1)
				begin : gencoefflistx
					//FpMul coeffM(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ay(pxy_s8[stage9y_i][stage9x_i]), .az(pzq_s8[stage9z_i]), .result(coeff[(stage9x_i) + (NUMEQU*stage9y_i) + (NUMEQU*NUMEQU*stage9z_i)]));
					FpMul coeffM(.clk0(clk), .clr0(rst), .clr1(rst), .ena(1'd1), .ay(pxy_s8[stage9y_i][stage9x_i]), .az(pzq_s8[stage9z_i]), .result(coeff[stage9x_i][stage9y_i][stage9z_i]));
				end
			end
		end
	endgenerate
	
	wire [31:0] ctrl_s9;
	customdelay #(.DELAY(MULDELAY)) ctrls9(.clk(clk), .rst(rst), .x(ctrl_s8), .y(ctrl_s9));
	assign wen_out = ctrl_s9[15:15];
	assign forceValid_out = ctrl_s9[16:16];
	//assign MemAddress = ctrl_s9[14:6];
	assign selz = {ctrl_s9[14:12], ctrl_s9[5:4]};
	assign sely = {ctrl_s9[11:9], ctrl_s9[3:2]};
	assign selx = {ctrl_s9[8:6], ctrl_s9[1:0]};
	
	endmodule
