/**************************************

**************************************/

// Angle packet
// 458 bits
// [457:170] atom1 position: 32bits*3, atom2 position: 32:bits*3, atom3 position: 32:bits*3
// higheset four bits :  0010 Angle term
// lower 170 bits: Atom1:14bits Atom2:14bits Atom3:14bits 32'h40f51eb8 32 32'h402ef9db 32 32'h3f4ccccd 32 32'h3f4ccccd 32
// 
module calcAngle_v2
#(
	parameter PARTICLE_GLOBAL_ID_WIDTH 		= 15
)
(
	input [457: 0] currentangle,

	//output [95:0] force1,
	//output [95:0] force2,
	//output vector<float>* energies,
	input rst,
	input clk,
	input [95:0] in_Particle_Pos_1,
	input [95:0] in_Particle_Pos_2,
	input [95:0] in_Particle_Pos_3,
	input [PARTICLE_GLOBAL_ID_WIDTH-1:0] in_Particle_ID_1,
	input [PARTICLE_GLOBAL_ID_WIDTH-1:0] in_Particle_ID_2,
	input [PARTICLE_GLOBAL_ID_WIDTH-1:0] in_Particle_ID_3,
	output [95:0] out_Angle_Force_1,
	output [95:0] out_Angle_Force_2,
	output [95:0] out_Angle_Force_3,
	output [PARTICLE_GLOBAL_ID_WIDTH-1:0] out_Particle_ID_1,//address of the forces
	output [PARTICLE_GLOBAL_ID_WIDTH-1:0] out_Particle_ID_2,
	output [PARTICLE_GLOBAL_ID_WIDTH-1:0] out_Particle_ID_3
	//output [16:0] address,//address of the forces
	//output oe_b,
);

	
	
	//int a1 = currentBond.atom1;	
	//int a2 = currentBond.atom2;
	//float restLength = currentBond.restLength;
	//float springConstant = currentBond.springConstant;
	//Vector atom1_p = (*positions)[a1];
	//Vector atom2_p = (*positions)[a2];
	
	assign out_Particle_ID_1 = in_Particle_ID_1;
	assign out_Particle_ID_2 = in_Particle_ID_2;
	assign out_Particle_ID_3 = in_Particle_ID_3;
	
	wire [95: 0] atom1_p;
	wire [95: 0] atom2_p;
	wire [95: 0] atom3_p;

	//assign 32'h40f51eb8 = currentangle[127:96];
	//assign 32'h402ef9db = currentangle[95:64];
	//assign 32'h3f4ccccd = currentangle[63:32];
	//assign 32'h3f4ccccd = currentangle[31:0];
	assign atom1_p = in_Particle_Pos_1;
	assign atom2_p = in_Particle_Pos_2;
	assign atom3_p = in_Particle_Pos_3;
	
	
	//Vector3D r12 = atom1 - atom2;                     // Vector from atom 1 to atom 2.
   // Vector r12 = atom1_p- atom2_p;
	
	wire [95:0] r12;
	vec_fp_sub vec_sub1(clk, rst,atom1_p,atom2_p,r12);
	wire [95:0] r12_r;
	 syn_fifo #(96, 13) f2(clk, rst, r12, r12_r);
    //Vector3D r32 = atom3 - atom2;                     // Vector from atom 3 to atom 2.
    //Vector r32 = atom3_p-atom2_p;
	wire [95:0] r32;
	vec_fp_sub vec_sub2(clk, rst,atom3_p,atom2_p,r32);
	wire [95:0] r32_r;
	syn_fifo #(96, 13) f3(clk, rst, r32, r32_r);
    //Vector3D r13 = atom1 - atom3;                     // Vector from atom 1 to atom 3.
    //Vector r13 = atom1_p-atom3_p;
	 
	wire [95:0] r13;
	vec_fp_sub vec_sub3(clk,rst, atom1_p,atom3_p,r13);
	wire [95:0] r13_r;
	syn_fifo #(96, 13) f4(clk, rst, r13, r13_r);
    
	 //float d12 = r12.length();                        // Distance between atom 1 and 2.
    //float d32 = r32.length();                        // Distance between atom 3 and 2.
    //float d13 = r13.length();                        // Distance between atom 1 and 3.
	
	
	wire [31:0] d12;
	wire [31:0] d32;
	wire [31:0] d13;
	get_len get_len1(
	clk,
	rst,
	r12,
	d12
	);
	
	get_len get_len2(
	clk,
	rst,
	r32,
	d32
	);
	get_len get_len3(
	clk,
	rst,
	r13,
	d13
	);
	//*****************************
    // Calculate theta.
	 //float y= (cross(r12, r32)).length();
	 wire [95:0] cross_y;
	 wire [31:0] y;
	 cross cross1(clk, rst, r12, r32, cross_y);
	 get_len get_len4(
	 clk,
	 rst,
	 cross_y,
	 y
	 );
	 
	 
    //float theta = atan2(y,(r12*r32));
	 wire [31:0] dot_12_32;
	 dot dot1(clk, rst, r12, r32, dot_12_32);
	 
	 wire [31:0] dot_12_32_r;
	 syn_fifo #(32, 53) f1(clk, rst, dot_12_32, dot_12_32_r);
	 wire [31:0] theta;
	 //reg [31:0] theta_t;
	 fp_atan2 atan2_1(clk, rst, y, dot_12_32_r, theta);

    //float sinTheta = sin(theta);
    //float cosTheta = cos(theta);
	 wire [31:0] sinTheta;
	 wire [31:0] cosTheta;
	 fp_sin sin1(clk, rst, theta, sinTheta);
	 fp_cos cos1(clk, rst, theta, cosTheta);
	 
	 
	
    // Calculate dpot/dtheta
    //float dpotdtheta = 2.0 * 32'h402ef9db * ( theta - 32'h40f51eb8);   
	 wire [31:0] theta_diff;

	 wire [31:0] neg_dpotdtheta; 
		
	 fp_sub sub1(clk, rst,theta, 32'h40f51eb8, theta_diff);
	 fp_mult mult1(clk, 32'hc02ef9db, theta_diff, neg_dpotdtheta); //change from two multipliers to one (times -2 instead of *2 and *-1)
	 
    // Calculate dr/dx, dr/dy, dr/dz.
    //Vector dr12 = r12/d12;
    //Vector dr32 = r32/d32;
    //Vector dr13 = r13/d13;
	 wire [95:0] dr12;
	 wire [95:0] dr32;
	 wire [95:0] dr13;
	 
	 vec_fp_div vdiv_1(clk, r12_r, d12, dr12);
	 vec_fp_div vdiv_2(clk, r32_r, d32, dr32);
	 vec_fp_div vdiv_3(clk, r13_r, d13, dr13);

    // Calulate dtheta/dx, dtheta/dy, dtheta/dz.
    //Vector dtheta1 = ((dr12*cosTheta) -dr32)/(sinTheta*d12);     // atom1
    //Vector dtheta3 = ((dr32*cosTheta)-dr12)/(sinTheta*d32);     // atom3
	 wire [31:0] dtheta1;
	 wire [31:0] dtheta3;
	 wire [31:0] sintheta_d12;
	 wire [31:0] sintheta_d32;
	 wire [95:0] dr12_costheta;
	 wire [95:0] dr32_costheta;
	 wire [95:0] dr_diff_13;
	 wire [95:0] dr_diff_31;
	 
	 wire [31:0] d12_r, d32_r;
	 wire [95:0] dr12_r, dr32_r, dr13_r, dr12_r_r, dr32_r_r;
	 syn_fifo #(32,65) f5(clk, rst, d12, d12_r);
	 syn_fifo #(32,65) f6(clk, rst, d32, d32_r);
	 syn_fifo #(96,32) f7(clk, rst, dr12, dr12_r);
	 syn_fifo #(96,32) f8(clk, rst, dr32, dr32_r);
	 syn_fifo #(96,11) f9(clk, rst, dr12_r, dr12_r_r);
	 syn_fifo #(96,11) f10(clk, rst, dr32_r, dr32_r_r);
	 syn_fifo #(96,19) f14(clk, rst, dr13, dr13_r); //!!!!!
	 
	 fp_mult mult3(clk, sinTheta, d12_r, sintheta_d12);
	 wire [31:0] sintheta_d12_r, sintheta_d32_r;
	 
	 
	 fp_mult mult4(clk, sinTheta, d32_r, sintheta_d32);
	 syn_fifo #(32,14) f11(clk, rst, sintheta_d12, sintheta_d12_r);
	 syn_fifo #(32,14) f12(clk, rst, sintheta_d32, sintheta_d32_r);
	 
	 vec_fp_mult vmult1(clk, rst, dr12_r, cosTheta, dr12_costheta);
	 vec_fp_mult vmult2(clk, rst, dr32_r, cosTheta, dr32_costheta); 
	 vec_fp_sub  vec_sub4(clk,rst, dr12_costheta, dr32_r_r, dr_diff_13);
	 vec_fp_sub  vec_sub5(clk, rst,dr32_costheta, dr12_r_r, dr_diff_31);
	 /////////////////////////////////
	 wire [95:0]  dtheta1_dpot, dtheta3_dpot;
	 fp_div div_new1(clk, neg_dpotdtheta, sintheta_d12, dtheta1);
	 vec_fp_mult vm_new1(clk, rst, dr_diff_13, dtheta1, dtheta1_dpot);
	 fp_div div_new2(clk, neg_dpotdtheta, sintheta_d32, dtheta3);
	 vec_fp_mult vm_new2(clk, rst, dr_diff_31, dtheta3, dtheta3_dpot);
	 //vec_fp_div vec_div1(clk, dr_diff_13, sintheta_d12_r, dtheta1);
	 //vec_fp_div vec_div2(clk, dr_diff_31, sintheta_d32_r, dtheta3);
	 
	 
	 
    // Calculate Urey Bradley force.
    //Vector ureyBradleyforce1 = dr13* (2.0 * 32'h3f4ccccd * (d13 - 32'h3f4ccccd));
    //Vector ureyBradleyforce3 = ureyBradleyforce1*(-1);
	 
	 wire [31:0] d13_u;
	 wire [31:0] d13_u_u;
	 wire [31:0] d13_u_u_2;
	 wire [95:0] ureyBradleyforce1, ureyBradleyforce1_r;
	 wire [95:0] ureyBradleyforce3, ureyBradleyforce3_r;
	 
	 wire [31:0] k2 =32'h3f4ccccd;
	 fp_sub sub2(clk, rst,d13, 32'h3f4ccccd, d13_u);
	 fp_mult mult5(clk, d13_u, k2, d13_u_u_2); 
	 //fp_mult mult6(clk, d13_u_u, 32'h40000000, d13_u_u_2);
	 vec_fp_mult vmult3(clk, rst, dr13_r, d13_u_u_2, ureyBradleyforce1);
	 assign ureyBradleyforce3={~ureyBradleyforce1[95], ureyBradleyforce1[94:64], ~ureyBradleyforce1[63], ureyBradleyforce1[62:32], ~ureyBradleyforce1[31], ureyBradleyforce1[30:0]};
	 
	 syn_fifo #(96,76) f15(clk, rst, ureyBradleyforce3, ureyBradleyforce3_r);
	 syn_fifo #(96,87) f16(clk, rst, ureyBradleyforce1, ureyBradleyforce1_r);
    // Calculate force on atom1 due to atom 2 and 3.
    //Vector force1 = (dtheta1*(-dpotdtheta))-ureyBradleyforce1;
	  
	  
	 wire [95:0]  force1, force2, force3;
	 //fp_mult mult7(clk, dpotdtheta, 32'hbf800000, neg_dpotdtheta);
	  
	 //wire [31:0] neg_dpotdtheta_r;
	 //syn_fifo #(32,58) f13(clk, rst, neg_dpotdtheta, neg_dpotdtheta_r);

	  
	 
	 vec_fp_sub  vec_sub6(clk,rst, dtheta1_dpot, ureyBradleyforce1_r, force1);
	  
	 wire [95:0] force1_r;
	 syn_fifo #(96,25) f19(clk, rst, force1, force1_r);
    // Calculate force on atom3 due to atom 1 and 2.
    //Vector force3 = (dtheta3*(-dpotdtheta))- ureyBradleyforce3;
	 
	 
	 
	 
	 
	 vec_fp_sub  vec_sub7(clk, rst,dtheta3_dpot, ureyBradleyforce3_r, force3);
	 wire [95:0] force3_r;
	 syn_fifo #(96,11) f17(clk, rst, force3, force3_r);
	 wire [95:0] force3_r_r;
	 syn_fifo #(96,14) f18(clk, rst, force3_r, force3_r_r);
    // Calculate force on atom2 due to atom 1 and 3.
    //Vector force2 = force1*(-1)-force3;
	 wire [95:0] neg_force1;
	 assign neg_force1={~force1[95], force1[94:64], ~force1[63], force1[62:32], ~force1[31], force1[30:0]};
	 vec_fp_sub vec_sub8(clk,rst, neg_force1, force3_r, force2);
	 
	 
    // Add to the total force.

    //(*forces)[a1] = (*forces)[a1]+force1;
    //(*forces)[a2] = (*forces)[a2]+force2;
    //(*forces)[a3] = (*forces)[a3]+force3;
	 

	assign out_Angle_Force_1 = force1_r; 
	
	assign out_Angle_Force_2 = force2; 
	
	assign out_Angle_Force_3 = force3_r_r; 
	
	
	
	/**********************************FSM*******************************************************/
	
	
	
	
	
	
	/*
	reg [95:0] force_t_r;
	
	always @ (force_t)  force_t_r <= force_t; 
	
	
	vec_fp_add vec_add1(clk,rst, hardware_b_f.forces[a1_i], force_t_r, force_a1);
	vec_fp_add vec_sub2(clk, rst,hardware_b_f.forces[a1_i], force_t_r, force_a2);

	 always @ (posedge clk) begin
		hardware_b_f.forces[a1_i] <= force_a1;
		hardware_b_f.forces[a2_i] <= force_a2;
	end
	 
	 */
 	 // Calculate Energy.
	 
	 
   // float eHarmonic = 32'h402ef9db * (theta - 32'h40f51eb8)*(theta - 32'h40f51eb8);
  //  float eUreyBradley = 32'h3f4ccccd * (d13 - 32'h3f4ccccd)*(d13 - 32'h3f4ccccd);
    // Add Energy
   // (*energies)[1] += eHarmonic + eUreyBradley;
	
	
	endmodule 