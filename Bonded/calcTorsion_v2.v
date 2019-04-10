/**************************************
**************************************/
// Torsion packet
// 572 bits
// higheset three bits :  0011 Torsion term
// [567:184] 
// lower 184 bits: Atom1:14bits Atom2:14bits Atom3:14bits Atom4:14bits multiplicity forceConstant periodicity phaseShift

module calcTorsion_v2
#(
	parameter PARTICLE_GLOBAL_ID_WIDTH 		= 15
)
(
input clk,
input rst,
input [95:0] in_Particle_Pos_1,
input [95:0] in_Particle_Pos_2,
input [95:0] in_Particle_Pos_3,
input [95:0] in_Particle_Pos_4,
input [PARTICLE_GLOBAL_ID_WIDTH-1:0] in_Particle_ID_1,
input [PARTICLE_GLOBAL_ID_WIDTH-1:0] in_Particle_ID_2,
input [PARTICLE_GLOBAL_ID_WIDTH-1:0] in_Particle_ID_3,
input [PARTICLE_GLOBAL_ID_WIDTH-1:0] in_Particle_ID_4,
input [127:0] in_Torsion_Param,
output [95:0] out_Torsion_Force_1,
output [95:0] out_Torsion_Force_2,
output [95:0] out_Torsion_Force_3,
output [95:0] out_Torsion_Force_4,
output [PARTICLE_GLOBAL_ID_WIDTH-1:0] out_Particle_ID_1,//address of the forces
output [PARTICLE_GLOBAL_ID_WIDTH-1:0] out_Particle_ID_2,
output [PARTICLE_GLOBAL_ID_WIDTH-1:0] out_Particle_ID_3,
output [PARTICLE_GLOBAL_ID_WIDTH-1:0] out_Particle_ID_4
);

/*
    int a1 = currTorsion.atom1;
    int a2 = currTorsion.atom2;
    int a3 = currTorsion.atom3;
    int a4 = currTorsion.atom4;
    Vector pos_1 =  (*positions)[a1];
    Vector pos_2 =  (*positions)[a2];
    Vector pos_3 =  (*positions)[a3];
    Vector pos_4 =  (*positions)[a4];
*/ 
	 
	 
	assign out_Particle_ID_1 = in_Particle_ID_1;
	assign out_Particle_ID_2 = in_Particle_ID_2;
	assign out_Particle_ID_3 = in_Particle_ID_3;
	assign out_Particle_ID_4 = in_Particle_ID_4;
	
	wire [31: 0] multiplicity;
	wire [31: 0] forceConstant;
	wire [31: 0] periodicity;
	wire [31: 0] phaseShift;
	wire [95: 0] atom1_p;
	wire [95: 0] atom2_p;
	wire [95: 0] atom3_p;
	wire [95: 0] atom4_p;
	
	assign multiplicity = in_Torsion_Param[127:96];
	assign forceConstant = in_Torsion_Param[95:64];
	assign periodicity = in_Torsion_Param[63:32];
	assign phaseShift = in_Torsion_Param[31:0];
	assign atom1_p = in_Particle_Pos_1;
	assign atom2_p = in_Particle_Pos_1;
	assign atom3_p = in_Particle_Pos_1;
	assign atom4_p = in_Particle_Pos_1;
	
	//float energy = 0;
    //Vector3D r12((*positions)[a1] - (*positions)[a2]);       // Vector from atom 1 to atom 2
    //Vector r12 = pos_2 - pos_1;
	 wire [95:0] r12;
	 vec_fp_sub vec_sub1(clk,rst, atom1_p,atom2_p,r12);
    //Vector3D r23((*positions)[a2] - (*positions)[a3]);       // Vector from atom 2 to atom 3
    //Vector r23 = pos_3 -pos_2 ;
	 wire [95:0] r23;
	 vec_fp_sub vec_sub2(clk,rst, atom2_p,atom3_p,r23);
    //Vector3D r34((*positions)[a3] - (*positions)[a4]);       // Vector from atom 3 to atom 4
    //Vector r34 = pos_4 - pos_3 ;
	 wire [95:0] r34;
	 vec_fp_sub vec_sub3(clk,rst, atom3_p,atom4_p,r34);

    // Cross product of r12 and r23, represents the plane shared by these two vectors
    //Vector a = cross(r12, r23);
	 wire [95:0] a;
	 cross cross2(clk, rst, r12, r23, a);
	 
    // Cross product of r23 and r34, represents the plane shared by these two vectors
    //Vector b = cross(r23, r34);
	 wire [95:0] b;
	 cross cross3(clk, rst, r23, r34, b);
	 
    // Cross product of r23 and A, represents the plane shared by these two vectors
    //Vector c = cross(r23, a);
	 wire [95:0] r23_r;
	 syn_fifo #(96, 25) sf1(clk, rst, r23, r23_r);
	 
	 wire [95:0] c;
	 cross cross4(clk, rst, r23_r, a, c);
	 
    // 1/length of Vector A, B and C
    //float ra = 1.0/a.length();
    //float rb = 1.0/b.length();
    //float rc = 1.0/c.length();
	 wire [31:0] ra_rv, rb_rv, rc_rv, ra, rb, rc;
	 get_len get_len1(clk, rst, a, ra_rv);
	 get_len get_len2(clk, rst, b, rb_rv);
	 get_len get_len3(clk, rst, c, rc_rv);
	 
	 fp_div div1(clk, 32'h3f800000, ra_rv, ra);
	 fp_div div2(clk, 32'h3f800000, rb_rv, rb);
	 fp_div div3(clk, 32'h3f800000, rc_rv, rc);
    // Normalize A,B and C
    //a = a *ra;
    //b = b *rb;
    //c = c *rc;
	 wire [95:0] a_n, b_n, c_n;
	 
	 wire [95:0] a_r;
	 syn_fifo #(96, 67) sf2(clk, rst, a, a_r);
	 
	 wire [95:0] b_r;
	 syn_fifo #(96, 67) sf3(clk, rst, b, b_r);
	 wire [95:0] c_r;
	 syn_fifo #(96, 67) sf4(clk, rst, c, c_r);
	 
	 vec_fp_div vec_div1(clk, a_r, ra_rv, a_n);
	 vec_fp_div vec_div2(clk, b_r, rb_rv, b_n);
	 
	 wire [95:0] b_n_r;
	 syn_fifo #(96, 25) sf11(clk, rst, b_n, b_n_r);
	 
	 vec_fp_div vec_div3(clk, c_r, rc_rv, c_n);
    // Calculate phi
    //float cosPhi = a *b;
	 //float sinPhi = c*b;
	 wire [31:0] cosPhi, sinPhi, phi_neg, phi;
	 dot dot1(clk, rst, a_n, b_n, cosPhi);
	 dot dot2(clk, rst, c_n, b_n_r, sinPhi);
	 
    
    //float phi    = -atan2(sinPhi,cosPhi);
	 wire [31:0] cosPhi_r;
	 syn_fifo #(32, 25) sf12(clk, rst, cosPhi, cosPhi_r);
	 fp_atan2 atan2_1(clk, rst, sinPhi, cosPhi_r, phi_neg);
	 //fp_mult mult1(clk, phi_neg, 32'hbf800000, phi);
	 assign phi={~phi_neg[31], phi_neg[30:0]};
    //float dpotdphi = 0.;
	 reg [31:0] dpotdphi;
	 
	 
	 
	 
	 
	 
	 //assume multiplicity is one!!!
	 

    //for( int i = 0; i < currTorsion.multiplicity; i++ ) {

	 integer p;
	 always @ (periodicity) 
		p = periodicity;
		
	
	 
      //if( currTorsion.periodicity[i] > 0 ) {

	//dpotdphi -= currTorsion.periodicity[i]	  * currTorsion.forceConstant[i]	  * sin( currTorsion.periodicity[i] * phi		 + currTorsion.phaseShift[i] );
	 wire [31:0] p_f;  
	 fp_mult mult2(clk, periodicity, forceConstant, p_f);
	 wire [31:0] p_phi;
	 fp_mult mult3(clk, periodicity, phi, p_phi);
	 wire [31:0] p_phi_ph;
	 fp_add add1(clk, rst, p_phi, phaseShift, p_phi_ph);
	 wire [31:0] sin_p_phi_ph;
	 fp_sin sin1(clk, rst, p_phi_ph, sin_p_phi_ph);
	 //wire [31:0] cos_p_phi_ph;
	 //cos cos1(clk, p_phi_ph, cos_p_phi_ph);
	 //wire [31:0] one_cos_p_phi_ph;
	 //fp_add_2 add2(clk, rst,cos_p_phi_ph, 32'h3f800000, one_cos_p_phi_ph);
	 wire [31:0] p_f_sin;
	 fp_mult mult4(clk, p_f, sin_p_phi_ph, p_f_sin);
	 wire [31:0] neg_p_f_sin;
	 assign neg_p_f_sin={~p_f_sin[31], p_f_sin[30:0]};
	 wire [31:0] f_one_cos_p_phi_ph;
	 //fp_mult mult5(clk, forceConstant, one_cos_p_phi_ph, f_one_cos_p_phi_ph);
	 
	 wire [31:0] diff_t;
	 fp_sub sub2(clk, rst,phi, phaseShift, diff_t);
	 wire diff_pi_aeb, diff_pi_agb, diff_pi_alb,diff_negpi_aeb, diff_negpi_agb, diff_negpi_alb; 
	 fp_comp comp1(clk,diff_t, 32'h40490fdb,diff_pi_aeb,diff_pi_agb,diff_pi_alb);
	 fp_comp comp2(clk,diff_t, 32'hc0490fdb,diff_negpi_aeb,diff_negpi_agb,diff_negpi_alb);
	 wire [31:0] diff_plus_2pi;
	 wire [31:0] diff_minus_2pi;
	 
	 fp_add add3(clk, rst,diff_t, 32'h40c90fdb,diff_plus_2pi);
	 fp_add add4(clk, rst,diff_t, 32'h40c90fdb,diff_minus_2pi);
	 wire [31:0] diff_plus_f_2, diff_minus_f_2, diff_t_f, diff_t_f_2;
	 
	 //wire [31:0] energy1, energy2, energy3;
	 wire [31:0] forceConstant2;
	 assign forceConstant2 = 32'h400ccccd;
	 fp_mult mult6(clk, forceConstant2, diff_plus_2pi, diff_plus_f_2);
	 fp_mult mult7(clk, forceConstant2, diff_minus_2pi, diff_minus_f_2);
	 
	 
	 
	 
	 fp_mult mult8(clk, diff_t, forceConstant2, diff_t_f_2);
	 
	  always @ (posedge clk)
	 begin 
		if (p > 0) begin
			dpotdphi <= neg_p_f_sin;		
		end 
		
		else begin
			if (diff_negpi_alb == 1) begin
				dpotdphi <= diff_plus_f_2;
			end
			else if (diff_pi_agb == 1) begin
				dpotdphi <= diff_minus_f_2;
			end else begin
				dpotdphi <= diff_t_f_2;
			end
		end 
		
	 end
	//***************************************************************energy part*************
	 /*
	 fp_mult mult12(clk, diff_plus_f, diff_plus_f, energy1);
	 fp_mult mult13(clk, diff_minus_f, diff_minus_f, energy2);
	 fp_mult mult14(clk, diff_t_f, diff_t_f, energy3);
	 reg [31:0] energy; 
	 
	 always @ (posedge clk)
	 begin 
		if (p > 0) begin	
	// Add energy
	//(*energies)[2] += currTorsion.forceConstant[i] * ( 1.0 + cos(currTorsion.periodicity[i] * phi+ currTorsion.phaseShift[i] ) );}

			dpotdphi <= neg_p_f_sin;
			energy <= hardware_b_f.energy_t + f_one_cos_p_phi_ph;
			
		end 
		
		else begin
			if (diff_negpi_alb == 1) begin
				dpotdphi <= diff_plus_f_2;
				energy <= energy1;
			end
			else if (diff_pi_agb == 1) begin
				dpotdphi <= diff_minus_f_2;
				energy <= energy2;
			end else begin
				dpotdphi <= diff_t_f_2;
				energy <= energy2;
			end
		end 
		
		
	end 
	
	
	*/
	
      //else {

	//float diff = phi - currTorsion.phaseShift[i];

	//if( diff < -M_PI )
	 // diff += 2 * M_PI;
	//else if( diff > M_PI )
	//  diff -= 2 * M_PI;

	//dpotdphi += 2.0 * currTorsion.forceConstant[i] * diff;

	// Add energy
	//(*energies)[2] += currTorsion.forceConstant[i] * diff * diff;

    //  }

    //}
/*************************************************************************************************************/ 

    // To prevent potential singularities, if abs(sinPhi) <= 0.1, then
    // use another method of calculating the gradient.
    //Vector f1(0);
	//Vector f2(0);
	//Vector f3(0);
    wire [31:0] sinPhi_abs;
	 wire abs_agb, abs_aeb, abs_alb;
	 fp_abs abs1(sinPhi, sinPhi_abs);
	 fp_comp comp3(clk, sinPhi_abs, 32'h3dcccccd, abs_aeb, abs_agb, abs_alb);
	 
	 wire [95:0] acos, bcos, acos_b, bcos_a;
	 wire [95:0] a_r_r;
	 wire [95:0] b_r_r;
	 syn_fifo #(96, 45) sf5(clk, rst, a_r, a_r_r);
	 vec_fp_mult vec_mult1(clk, rst, a_r_r, cosPhi, acos);
    vec_fp_mult vec_mult2(clk, rst, b_r_r, cosPhi, bcos);
	 syn_fifo #(96, 45) sf6(clk, rst, b_r, b_r_r);

	 wire [95:0] a_r_r_r,b_r_r_r;
	 syn_fifo #(96, 11) sf7(clk, rst, b_r_r, b_r_r_r);
	 
	 vec_fp_sub  vec_sub4(clk, rst,acos, b_r_r_r, acos_b);
	 
	 
	 syn_fifo #(96, 11) sf9(clk, rst, a_r_r, a_r_r_r);
	 
	 vec_fp_sub  vec_sub5(clk, rst,bcos, a_r_r_r, bcos_a);
	 
	 wire [95:0] dcosdA, dcosdB;

	 wire [31:0] ra_r;
	 syn_fifo #(32, 64) sf8(clk, rst, ra, ra_r);
	 
	 vec_fp_mult vec_mult3(clk, rst, acos_b, ra_r, dcosdA);
	 
	 wire [31:0] rb_r;
	 syn_fifo #(32, 64) sf10(clk, rst, rb, rb_r);
	 
	 vec_fp_mult vec_mult4(clk, rst, bcos_a, rb_r, dcosdB);
	 
	 wire [31:0] k1;
	 fp_div div4(clk, dpotdphi, sinPhi, k1);
	 
	 reg [95:0] f1, f2, f3;
	 wire [31:0] r231da2, r232da1, aa_t, aa, f11_t, f12_t, f30_t, f31_t, f32_t, f20_t, f21_t, f22_t;
	 fp_mult mult15(clk, r23[63:32], dcosdA[95:64],r231da2);
	 fp_mult mult16(clk, r23[95:64], dcosdA[31:0], r232da1);
	 fp_sub sub3(clk, rst,r231da2, r232da1, aa_t);
	 fp_mult mult17(clk, aa_t, k1, aa);
	 wire [31:0] r232da0, r230da2, f11;
	 fp_mult mult17_2(clk, r23[95:64], dcosdA[31:0], r232da0);
	 fp_mult mult18(clk, r23[31:0], dcosdA[95:64], r230da2);
	 fp_sub  sub4(clk, rst,r232da0, r230da2, f11_t);
	 fp_mult mult19(clk, f11_t, k1, f11);
	 wire [31:0] r230da1, r231da0,f12;
	 fp_mult mult20(clk, r23[31:0], dcosdA[63:32], r230da1);
	 fp_mult mult21(clk, r23[63:32], dcosdA[31:0], r231da0);
	 fp_sub  sub5(clk, rst,r230da1, r231da0, f12_t);
	 fp_mult mult22(clk, f12_t, k1, f12);
	 
	 wire [31:0] r232db1, r231db2,f30;
	 fp_mult mult20_2(clk, r23[95:64], dcosdB[63:32], r232db1);
	 fp_mult mult21_2(clk, r23[63:32], dcosdB[95:64], r231db2);
	 fp_sub  sub5_2(clk, rst,r232db1, r231db2, f30_t);
	 fp_mult mult22_2(clk, f30_t, k1, f30);
	 
	 wire [31:0] r230db2, r232db0,f31;
	 fp_mult mult23(clk, r23[31:0], dcosdB[95:64], r230db2);
	 fp_mult mult24(clk, r23[95:64], dcosdB[31:0], r232db0);
	 fp_sub  sub6(clk, rst,r230db2, r232db0, f31_t);
	 fp_mult mult25(clk, f31_t, k1, f31);
	 
	 wire [31:0] r231db0, r230db1,f32;
	 fp_mult mult26(clk, r23[63:32], dcosdB[31:0], r231db0);
	 fp_mult mult27(clk, r23[31:0], dcosdB[63:32], r230db1);
	 fp_sub  sub7(clk, rst,r231db0, r230db1, f32_t);
	 fp_mult mult28(clk, f32_t, k1, f32);
	 
	 
	 wire [31:0] r122da1, r121da2, r341db2, r342db1, f20_a, f20_b, f20;
	 fp_mult mult29(clk, r12[95:64], dcosdA[63:32], r122da1);
	 fp_mult mult30(clk, r23[63:32], dcosdA[95:64], r121da2);
	 
	 fp_mult mult31(clk, r34[63:32], dcosdB[95:64], r341db2);
	 fp_mult mult32(clk, r34[95:64], dcosdB[63:32], r342db1);
	 
	 fp_sub  sub8(clk, rst,r122da1, r121da2, f20_a);
	 
	 fp_sub  sub9(clk, rst,r341db2, r342db1, f20_b);
	 
	 fp_add  add5(clk, rst,f20_a, f20_b, f20_t);
	 
	 
	 fp_mult mult33(clk, f20_t, k1, f20);
	 
	 
	 wire [31:0] r120da2, r122da0, r342db0, r340db2, f21_a, f21_b, f21;
	 fp_mult mult34(clk, r12[31:0], dcosdA[95:64], r120da2);
	 fp_mult mult35(clk, r23[95:64], dcosdA[31:0], r122da0);
	
	 fp_mult mult36(clk, r34[95:64], dcosdB[31:0], r342db0);
	 fp_mult mult37(clk, r34[31:0], dcosdB[95:64], r340db2);
	 
	 fp_sub  sub10(clk, rst,r120da2, r122da0, f21_a);
	 
	 fp_sub  sub11(clk,rst, r342db0, r340db2, f21_b);
	 
	 fp_add  add6(clk, rst,f21_a, f21_b, f21_t);
	 
	 
	 fp_mult mult38(clk, f21_t, k1, f21);
	 
	 wire [31:0] r121da0, r120da1, r340db1, r341db0, f22_a, f22_b, f22;
	 fp_mult mult39(clk, r12[63:32], dcosdA[31:0], r121da0);
	 fp_mult mult40(clk, r23[31:0], dcosdA[63:32], r120da1);
	 
	 fp_mult mult41(clk, r34[31:0], dcosdB[63:32], r340db1);
	 fp_mult mult42(clk, r34[63:32], dcosdB[31:0], r341db0);
	 
	 fp_sub  sub12(clk, rst,r121da0, r120da1, f22_a);
	 
	 fp_sub  sub13(clk, rst,r340db1, r341db0, f22_b);
	 
	 fp_add  add7(clk, rst,f22_a, f22_b, f22_t);
	 
	 
	 fp_mult mult43(clk, f22_t, k1, f22);
	 
	 
	 always @ (posedge clk) begin
//	   if (abs_agb == 1) begin
			f1[31:0] <= aa;
			f1[63:32] <= f11;
			f1[95:64] <= f12;
			f3[31:0] <= f30;
			f3[63:32] <= f31;
			f3[95:64] <= f32;
			f2[31:0] <= f20;
			f2[63:32] <= f21;
			f2[95:64] <= f22;
		end

////////////////////////////////////////////////////////////////////////////////////fake output for test resource utilization 
assign out_Torsion_Force_1 = f1;
vec_fp_sub  vec_sub6(clk,rst, f2, f1, out_Torsion_Force_2);
vec_fp_sub  vec_sub7(clk,rst, f3, f2, out_Torsion_Force_3);

vec_fp_mult  vec_mult_t(clk, rst, f3, 32'hbf800000, out_Torsion_Force_4);


//assign energy_out = energy;
    // Add virial


 
  
endmodule 