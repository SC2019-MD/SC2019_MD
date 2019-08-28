/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: Filter_Logic.v
//
//	Function: Filter logic, send only particle pairs that within cutoff radius to force pipeline
//					Multiple filters are corresponding to a single force pipleine
//					Buffer to store the filtered particle pairs -> Backpressure needed when buffer is full
//					The module contains the delay register chain to pass the particle ID from input along with the distance value all the way into buffer
//					An arbitration will be needed when implement multiple filters (Filter_Bank) to select from one of the available ones
//					The data valid signal should be assigned in the Filter_Bank module
//
// Data Organization:
//				Data organization in buffer: MSB-LSB: {ref_particle_id, neighbor_particle_id, r2, dz, dy, dx}
//
// Used by:
//				Filter_Bank.v
//
// Dependency:
// 			r2_compute_with_pbc.v
//				Filter_Buffer.v
//
// Latency: total: 22 cycles
//				r2_compute_with_pbc													20 cycles
//				filteration																1 cycle
//				write to buffer														1 cycle
//
// Created by: Chen Yang 10/10/18
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module Filter_Logic
#(
	parameter DATA_WIDTH 					= 32,
	parameter PARTICLE_ID_WIDTH			= 20,									// # of bit used to represent particle ID, 9*9*7 cells, each 4-bit, each cell have max of 200 particles, 8-bit
	parameter FILTER_BUFFER_DEPTH 		= 32,
	parameter FILTER_BUFFER_ADDR_WIDTH	= 5,
	parameter CUTOFF_2 						= 32'h43100000,					// (12^2=144 in IEEE floating point)
	// Bounding box size, used when applying PBC
	parameter BOUNDING_BOX_X 				= 32'h426E0000,					// 8.5*7 = 59.5 in IEEE floating point
	parameter BOUNDING_BOX_Y 				= 32'h424C0000,					// 8.5*6 = 51 in IEEE floating point
	parameter BOUNDING_BOX_Z 				= 32'h424C0000,					// 8.5*6 = 51 in IEEE floating point
	parameter HALF_BOUNDING_BOX_X_POS 	= 32'h41EE0000,					// 59.5/2 = 29.75 in IEEE floating point
	parameter HALF_BOUNDING_BOX_Y_POS 	= 32'h41CC0000,					// 51/2 = 25.5 in IEEE floating point
	parameter HALF_BOUNDING_BOX_Z_POS 	= 32'h41CC0000,					// 51/2 = 25.5 in IEEE floating point
	parameter HALF_BOUNDING_BOX_X_NEG 	= 32'hC1EE0000,					// -59.5/2 = -29.75 in IEEE floating point
	parameter HALF_BOUNDING_BOX_Y_NEG 	= 32'hC1CC0000,					// -51/2 = -25.5 in IEEE floating point
	parameter HALF_BOUNDING_BOX_Z_NEG 	= 32'hC1CC0000						// -51/2 = -25.5 in IEEE floating point
)
(
	input clk,
	input rst,
	input input_valid,
	input [PARTICLE_ID_WIDTH-1:0] ref_particle_id,
	input [PARTICLE_ID_WIDTH-1:0] neighbor_particle_id,
	input [DATA_WIDTH-1:0] refx,
	input [DATA_WIDTH-1:0] refy,
	input [DATA_WIDTH-1:0] refz,
	input [DATA_WIDTH-1:0] neighborx,
	input [DATA_WIDTH-1:0] neighbory,
	input [DATA_WIDTH-1:0] neighborz,
	output [PARTICLE_ID_WIDTH-1:0] ref_particle_id_out,
	output [PARTICLE_ID_WIDTH-1:0] neighbor_particle_id_out,
	output [DATA_WIDTH-1:0] r2,
	output [DATA_WIDTH-1:0] dx,
	output [DATA_WIDTH-1:0] dy,
	output [DATA_WIDTH-1:0] dz,
	// Connect to filter arbiter
	input sel,
	output particle_pair_available,
	// Connect to input generator
	output filter_back_pressure								// Buffer should have enough space to store 17 pairs after the input stop coming
);


	// Wires connect r2_compute and Filter_Buffer
	wire [DATA_WIDTH-1:0] r2_wire, dx_wire, dy_wire, dz_wire;
	wire r2_valid;
	
	// Assign Output: backpressure
	// 20 is the latency in r2_compute_with_pbc
	// *** if r2_compute latency changed, need to change the threshold value to the new latency
	// Threshold is approximate: r2_latency + 4 cycle latency in propagating the backpressure signal = 20+4 = 24
	wire [FILTER_BUFFER_ADDR_WIDTH-1:0] buffer_usedw;
	assign filter_back_pressure = (FILTER_BUFFER_DEPTH - buffer_usedw < 24) ? 1'b1 : 1'b0;
	
	// Assign Output: particle_pair_available
	wire buffer_empty;
	assign particle_pair_available = ~buffer_empty;
	
	// Delay registers for input particle IDs
	// Delay for 20 (r2_compute_with_pbc) cycles
	reg [PARTICLE_ID_WIDTH-1:0] ref_particle_id_reg0;
	reg [PARTICLE_ID_WIDTH-1:0] ref_particle_id_reg1;
	reg [PARTICLE_ID_WIDTH-1:0] ref_particle_id_reg2;
	reg [PARTICLE_ID_WIDTH-1:0] ref_particle_id_reg3;
	reg [PARTICLE_ID_WIDTH-1:0] ref_particle_id_reg4;
	reg [PARTICLE_ID_WIDTH-1:0] ref_particle_id_reg5;
	reg [PARTICLE_ID_WIDTH-1:0] ref_particle_id_reg6;
	reg [PARTICLE_ID_WIDTH-1:0] ref_particle_id_reg7;
	reg [PARTICLE_ID_WIDTH-1:0] ref_particle_id_reg8;
	reg [PARTICLE_ID_WIDTH-1:0] ref_particle_id_reg9;
	reg [PARTICLE_ID_WIDTH-1:0] ref_particle_id_reg10;
	reg [PARTICLE_ID_WIDTH-1:0] ref_particle_id_reg11;
	reg [PARTICLE_ID_WIDTH-1:0] ref_particle_id_reg12;
	reg [PARTICLE_ID_WIDTH-1:0] ref_particle_id_reg13;
	reg [PARTICLE_ID_WIDTH-1:0] ref_particle_id_reg14;
	reg [PARTICLE_ID_WIDTH-1:0] ref_particle_id_reg15;
	reg [PARTICLE_ID_WIDTH-1:0] ref_particle_id_reg16;
	reg [PARTICLE_ID_WIDTH-1:0] ref_particle_id_reg17;
	reg [PARTICLE_ID_WIDTH-1:0] ref_particle_id_reg18;
	reg [PARTICLE_ID_WIDTH-1:0] ref_particle_id_delayed;
	reg [PARTICLE_ID_WIDTH-1:0] neighbor_particle_id_reg0;
	reg [PARTICLE_ID_WIDTH-1:0] neighbor_particle_id_reg1;
	reg [PARTICLE_ID_WIDTH-1:0] neighbor_particle_id_reg2;
	reg [PARTICLE_ID_WIDTH-1:0] neighbor_particle_id_reg3;
	reg [PARTICLE_ID_WIDTH-1:0] neighbor_particle_id_reg4;
	reg [PARTICLE_ID_WIDTH-1:0] neighbor_particle_id_reg5;
	reg [PARTICLE_ID_WIDTH-1:0] neighbor_particle_id_reg6;
	reg [PARTICLE_ID_WIDTH-1:0] neighbor_particle_id_reg7;
	reg [PARTICLE_ID_WIDTH-1:0] neighbor_particle_id_reg8;
	reg [PARTICLE_ID_WIDTH-1:0] neighbor_particle_id_reg9;
	reg [PARTICLE_ID_WIDTH-1:0] neighbor_particle_id_reg10;
	reg [PARTICLE_ID_WIDTH-1:0] neighbor_particle_id_reg11;
	reg [PARTICLE_ID_WIDTH-1:0] neighbor_particle_id_reg12;
	reg [PARTICLE_ID_WIDTH-1:0] neighbor_particle_id_reg13;
	reg [PARTICLE_ID_WIDTH-1:0] neighbor_particle_id_reg14;
	reg [PARTICLE_ID_WIDTH-1:0] neighbor_particle_id_reg15;
	reg [PARTICLE_ID_WIDTH-1:0] neighbor_particle_id_reg16;
	reg [PARTICLE_ID_WIDTH-1:0] neighbor_particle_id_reg17;
	reg [PARTICLE_ID_WIDTH-1:0] neighbor_particle_id_reg18;
	reg [PARTICLE_ID_WIDTH-1:0] neighbor_particle_id_delayed;
	
	always@(posedge clk)
		begin
		if(rst)
			begin
			ref_particle_id_reg0 <= 0;
			ref_particle_id_reg1 <= 0;
			ref_particle_id_reg2 <= 0;
			ref_particle_id_reg3 <= 0;
			ref_particle_id_reg4 <= 0;
			ref_particle_id_reg5 <= 0;
			ref_particle_id_reg6 <= 0;
			ref_particle_id_reg7 <= 0;
			ref_particle_id_reg8 <= 0;
			ref_particle_id_reg9 <= 0;
			ref_particle_id_reg10 <= 0;
			ref_particle_id_reg11 <= 0;
			ref_particle_id_reg12 <= 0;
			ref_particle_id_reg13 <= 0;
			ref_particle_id_reg14 <= 0;
			ref_particle_id_reg15 <= 0;
			ref_particle_id_reg16 <= 0;
			ref_particle_id_reg17 <= 0;
			ref_particle_id_reg18 <= 0;
			ref_particle_id_delayed <= 0;
			neighbor_particle_id_reg0 <= 0;
			neighbor_particle_id_reg1 <= 0;
			neighbor_particle_id_reg2 <= 0;
			neighbor_particle_id_reg3 <= 0;
			neighbor_particle_id_reg4 <= 0;
			neighbor_particle_id_reg5 <= 0;
			neighbor_particle_id_reg6 <= 0;
			neighbor_particle_id_reg7 <= 0;
			neighbor_particle_id_reg8 <= 0;
			neighbor_particle_id_reg9 <= 0;
			neighbor_particle_id_reg10 <= 0;
			neighbor_particle_id_reg11 <= 0;
			neighbor_particle_id_reg12 <= 0;
			neighbor_particle_id_reg13 <= 0;
			neighbor_particle_id_reg14 <= 0;
			neighbor_particle_id_reg15 <= 0;
			neighbor_particle_id_reg16 <= 0;
			neighbor_particle_id_reg17 <= 0;
			neighbor_particle_id_reg18 <= 0;
			neighbor_particle_id_delayed <= 0;
			end
		else
			begin
			ref_particle_id_reg0 <= ref_particle_id;
			ref_particle_id_reg1 <= ref_particle_id_reg0;
			ref_particle_id_reg2 <= ref_particle_id_reg1;
			ref_particle_id_reg3 <= ref_particle_id_reg2;
			ref_particle_id_reg4 <= ref_particle_id_reg3;
			ref_particle_id_reg5 <= ref_particle_id_reg4;
			ref_particle_id_reg6 <= ref_particle_id_reg5;
			ref_particle_id_reg7 <= ref_particle_id_reg6;
			ref_particle_id_reg8 <= ref_particle_id_reg7;
			ref_particle_id_reg9 <= ref_particle_id_reg8;
			ref_particle_id_reg10 <= ref_particle_id_reg9;
			ref_particle_id_reg11 <= ref_particle_id_reg10;
			ref_particle_id_reg12 <= ref_particle_id_reg11;
			ref_particle_id_reg13 <= ref_particle_id_reg12;
			ref_particle_id_reg14 <= ref_particle_id_reg13;
			ref_particle_id_reg15 <= ref_particle_id_reg14;
			ref_particle_id_reg16 <= ref_particle_id_reg15;
			ref_particle_id_reg17 <= ref_particle_id_reg16;
			ref_particle_id_reg18 <= ref_particle_id_reg17;
			ref_particle_id_delayed <= ref_particle_id_reg18;
			neighbor_particle_id_reg0 <= neighbor_particle_id;
			neighbor_particle_id_reg1 <= neighbor_particle_id_reg0;
			neighbor_particle_id_reg2 <= neighbor_particle_id_reg1;
			neighbor_particle_id_reg3 <= neighbor_particle_id_reg2;
			neighbor_particle_id_reg4 <= neighbor_particle_id_reg3;
			neighbor_particle_id_reg5 <= neighbor_particle_id_reg4;
			neighbor_particle_id_reg6 <= neighbor_particle_id_reg5;
			neighbor_particle_id_reg7 <= neighbor_particle_id_reg6;
			neighbor_particle_id_reg8 <= neighbor_particle_id_reg7;
			neighbor_particle_id_reg9 <= neighbor_particle_id_reg8;
			neighbor_particle_id_reg10 <= neighbor_particle_id_reg9;
			neighbor_particle_id_reg11 <= neighbor_particle_id_reg10;
			neighbor_particle_id_reg12 <= neighbor_particle_id_reg11;
			neighbor_particle_id_reg13 <= neighbor_particle_id_reg12;
			neighbor_particle_id_reg14 <= neighbor_particle_id_reg13;
			neighbor_particle_id_reg15 <= neighbor_particle_id_reg14;
			neighbor_particle_id_reg16 <= neighbor_particle_id_reg15;
			neighbor_particle_id_reg17 <= neighbor_particle_id_reg16;
			neighbor_particle_id_reg18 <= neighbor_particle_id_reg17;
			neighbor_particle_id_delayed <= neighbor_particle_id_reg18;
			end
		end

	
	/////////////////////////////////////////////////////////////////////////////
	// Filter Logic
	/////////////////////////////////////////////////////////////////////////////
	reg buffer_wr;
	reg [PARTICLE_ID_WIDTH*2+DATA_WIDTH*4-1:0] buffer_wr_data;
	always@(posedge clk)
		begin
		if(rst)
			begin
			buffer_wr_data <= 0;
			buffer_wr <= 1'b0;
			end
		else if(r2_valid && r2_wire <= CUTOFF_2 && r2_wire > 0)
			begin
			buffer_wr_data <= {ref_particle_id_delayed, neighbor_particle_id_delayed, r2_wire, dz_wire, dy_wire, dx_wire};
			buffer_wr <= 1'b1;
			end
		else
			begin
			buffer_wr_data <= 0;
			buffer_wr <= 1'b0;
			end
		end
	
	// Evaluate r2 between particle pairs
	r2_compute_with_pbc #(
		.DATA_WIDTH(DATA_WIDTH),
		// Bounding box size, used when applying PBC
		.BOUNDING_BOX_X(BOUNDING_BOX_X),
		.BOUNDING_BOX_Y(BOUNDING_BOX_Y),
		.BOUNDING_BOX_Z(BOUNDING_BOX_Z),
		.HALF_BOUNDING_BOX_X_POS(HALF_BOUNDING_BOX_X_POS),
		.HALF_BOUNDING_BOX_Y_POS(HALF_BOUNDING_BOX_Y_POS),
		.HALF_BOUNDING_BOX_Z_POS(HALF_BOUNDING_BOX_Z_POS),
		.HALF_BOUNDING_BOX_X_NEG(HALF_BOUNDING_BOX_X_NEG),
		.HALF_BOUNDING_BOX_Y_NEG(HALF_BOUNDING_BOX_Y_NEG),
		.HALF_BOUNDING_BOX_Z_NEG(HALF_BOUNDING_BOX_Z_NEG)
	)
	r2_evaluate(
		.clk(clk),
		.rst(rst),
		.enable(input_valid),
		.refx(refx),
		.refy(refy),
		.refz(refz),
		.neighborx(neighborx),
		.neighbory(neighbory),
		.neighborz(neighborz),
		.r2(r2_wire),
		.dx_out(dx_wire),
		.dy_out(dy_wire),
		.dz_out(dz_wire),
		.r2_valid(r2_valid)
	);
/*
	r2_compute #(
		.DATA_WIDTH(DATA_WIDTH),
		.BOUNDING_BOX_X(BOUNDING_BOX_X),
		.BOUNDING_BOX_Y(BOUNDING_BOX_Y),
		.BOUNDING_BOX_Z(BOUNDING_BOX_Z)
	)
	r2_evaluate(
		.clk(clk),
		.rst(rst),
		.enable(input_valid),
		.refx(refx),
		.refy(refy),
		.refz(refz),
		.neighborx(neighborx),
		.neighbory(neighbory),
		.neighborz(neighborz),
		.r2(r2_wire),
		.dx_out(dx_wire),
		.dy_out(dy_wire),
		.dz_out(dz_wire),
		.r2_valid(r2_valid)
	);
*/	
	// Buffer for pairs passed the filter logic
	// Data organization in buffer: MSB-LSB: {ref_particle_id, neighbor_particle_id, r2, dz, dy, dx}
	Filter_Buffer
	#(
		.DATA_WIDTH(2*PARTICLE_ID_WIDTH+4*DATA_WIDTH),							// hold r2, dx, dy, dz
		.FILTER_BUFFER_DEPTH(FILTER_BUFFER_DEPTH),
		.FILTER_BUFFER_ADDR_WIDTH(FILTER_BUFFER_ADDR_WIDTH)					// log(FILTER_BUFFER_DEPTH) / log 2
	)
	Filter_Buffer
	(
		 .clock(clk),
		 .data(buffer_wr_data),
		 .rdreq(sel),
		 .wrreq(buffer_wr),
		 .empty(buffer_empty),
		 .full(),
		 .q({ref_particle_id_out, neighbor_particle_id_out, r2, dz, dy, dx}),
		 .usedw(buffer_usedw)
	);


endmodule