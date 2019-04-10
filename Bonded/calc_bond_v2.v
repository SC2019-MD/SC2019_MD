/**************************************
*
**************************************/

// Bond packet 
// 284 bits
// higheset four bits :  0001 Bond term
// [283:92] then atom1 position: 32bits*3, atom2 position: 32:bits*3
// lower 92 bits: Atom1:14bits Atom2:14bits restLength 32 springConstant 32


////////////////////////////////////8 stages of calculation  the last stage has three parallel components
`timescale 1 ps/ 1 ps
module calcBond_v2
#(
	parameter PARTICLE_GLOBAL_ID_WIDTH 		= 15
)
(
	input clk,
	input rst,
	input [95:0] in_Particle_Pos_1,
	input [95:0] in_Particle_Pos_2,
	input [PARTICLE_GLOBAL_ID_WIDTH-1:0] in_Particle_ID_1,
	input [PARTICLE_GLOBAL_ID_WIDTH-1:0] in_Particle_ID_2,
	//input one_bond_start,
	//output [95:0] force1,
	//output [95:0] force2,
	//output vector<float>* energies,
	output [95:0] out_Bond_Force_out_1,// force_t, for accumulation 
	output [95:0] out_Bond_Force_out_2,
	output [PARTICLE_GLOBAL_ID_WIDTH-1:0] out_Particle_ID_1,//address of the forces
	output [PARTICLE_GLOBAL_ID_WIDTH-1:0] out_Particle_ID_2 
	//output we_b
	//output [95:0] display
);

	
	
	//int a1 = currentBond.atom1;	
	//int a2 = currentBond.atom2;
	//float restLength = currentBond.restLength;
	//float springConstant = currentBond.springConstant;
	//Vector atom1_p = (*positions)[a1];
	//Vector atom2_p = (*positions)[a2];
	
	reg [31: 0] restLength;
	reg [31: 0] springConstant;
	wire [95: 0] atom1_p;
	wire [95: 0] atom2_p;
	
	//assign restLength = currentBond[63:32];
	//assign springConstant = currentBond[31:0];
	assign atom1_p = in_Particle_Pos_1;
	assign atom2_p = in_Particle_Pos_2;
	


	//Vector3D r12 = atom1 - atom2;                       // Vector from atom 1 to atom 2.
	//Vector r12 = atom1_p-atom2_p; // Vector from atom 1 to atom 2.
	wire [95: 0] r12;
	
	vec_fp_sub vec_sub1(
	.clk(clk),
	.rst(rst),
	.a(atom1_p),
	.b(atom2_p),
	.r(r12)
	);
	
	
	//float r = r12.length();                            // Distance between atom 1 and 2.
	
	wire [31:0] r;
	get_len get_len1(     //3 multipliers and two adders and one sqrt
	clk,
	rst,
	r12,
	r
	);
	wire [95:0] r12_r;
	syn_fifo #(96, 98) f1(clk, rst, r12, r12_r);
	
	//float dpotdr = 2.0 * springConstant * (r - restLength);   // Calculate dpot/dr
	wire [31:0] r_dist, r_r;
	syn_fifo #(32, 25) f2(clk, rst, r, r_r);
	
	fp_sub sub2(
	clk,rst,r,32'h3f000000,//restLength),
	r_dist
	);

	
	wire [31:0]  const, r_dist_const;
	assign const = 32'hbf000000;  //   !!!!!!!!!!!-0.5 as -2*springConstant

	// Calculate force on atom1 due to atom2.
	//Vector force_t = (-dpotdr / r) *r12;
	
	wire [31:0] dpotdr_1;
	fp_mult mult1(clk, r_dist, const, r_dist_const);
	
	fp_div div1(clk,r_dist_const,r_r,dpotdr_1);

	
	
	vec_fp_mult vec_mult1(clk, rst, r12_r, dpotdr_1, out_Bond_Force_out_1);//store for 103 cycles

	assign out_Bond_Force_out_2[31:0] = {~out_Bond_Force_out_1[31],out_Bond_Force_out_1[30:0]};
	assign out_Bond_Force_out_2[63:32]= {~out_Bond_Force_out_1[63],out_Bond_Force_out_1[62:32]};
	assign out_Bond_Force_out_2[95:64]= {~out_Bond_Force_out_1[95],out_Bond_Force_out_1[94:64]};

	
	
	

	
	//wire [95:64] force_t_2;
	//vec_fp_mult mult10(clk, force_t, 32'hbf800000, force_out_2);
	//assign force_out_1 = force_t;
	assign out_Particle_ID_1 = in_Particle_ID_1;
	assign out_Particle_ID_2 = in_Particle_ID_1; 


	
	

	
endmodule