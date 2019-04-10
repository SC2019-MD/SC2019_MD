/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: Filter_Logic_no_DSP.v
//
//	Function: 
//					Process the data in fixed point
//					Converting Floating-point to fixed point first, then process by dx+dy+dz < sqrt(3)*r
//					Filter logic, send only particle pairs that within cutoff radius to force pipeline
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
//				Filter_Bank_no_DSP.v
//
// Dependency:
//				Filter_Buffer.v
//
// Latency: total: 4 cycles
//				getting sum_dx_dy_dz:			3 cycles
//
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module Filter_Logic_no_DSP
#(
	parameter DATA_WIDTH 					= 32,
	parameter PARTICLE_ID_WIDTH			= 20,									// # of bit used to represent particle ID, 9*9*7 cells, each 4-bit, each cell have max of 200 particles, 8-bit
	parameter FILTER_BUFFER_DEPTH 		= 16,
	parameter FILTER_BUFFER_ADDR_WIDTH	= 4,
	parameter CUTOFF_TIMES_SQRT_3			= 32'h41A646DC,					// sqrt(3) * CUTOFF
	parameter FIXED_POINT_WIDTH 			= 32,
	parameter FILTER_IN_PATCH_0_BITS		= 8'b0,								// Width = FIXED_POINT_WIDTH - 1 - 23
	parameter BOUNDING_BOX_X				= 32'h42D80000,					// 12*9 = 108 in IEEE floating point
	parameter BOUNDING_BOX_Y				= 32'h42D80000,					// 12*9 = 108 in IEEE floating point
	parameter BOUNDING_BOX_Z				= 32'h42A80000						// 12*7 = 84 in IEEE floating point
)
(
	input clk,
	input rst,
	input input_valid,
	input [PARTICLE_ID_WIDTH-1:0] in_ref_particle_id,
	input [PARTICLE_ID_WIDTH-1:0] in_neighbor_particle_id,
	input [DATA_WIDTH-1:0] in_refx,
	input [DATA_WIDTH-1:0] in_refy,
	input [DATA_WIDTH-1:0] in_refz,
	input [DATA_WIDTH-1:0] in_neighborx,
	input [DATA_WIDTH-1:0] in_neighbory,
	input [DATA_WIDTH-1:0] in_neighborz,
	output [PARTICLE_ID_WIDTH-1:0] out_ref_particle_id,
	output [PARTICLE_ID_WIDTH-1:0] out_neighbor_particle_id,
	output [DATA_WIDTH-1:0] out_refx,
	output [DATA_WIDTH-1:0] out_refy,
	output [DATA_WIDTH-1:0] out_refz,
	output [DATA_WIDTH-1:0] out_neighborx,
	output [DATA_WIDTH-1:0] out_neighbory,
	output [DATA_WIDTH-1:0] out_neighborz,
	// Connect to filter arbiter
	input sel,
	output particle_pair_available,
	// Connect to input generator
	output filter_back_pressure								// Buffer should have enough space to store 17 pairs after the input stop coming
);


	// The exponential value
	wire [7:0] exp_box_x, exp_box_y, exp_box_z;
	assign exp_box_x = BOUNDING_BOX_X[30:23];
	assign exp_box_y = BOUNDING_BOX_Y[30:23];
	assign exp_box_z = BOUNDING_BOX_Z[30:23];
	wire [7:0] exp_refx, exp_refy, exp_refz, exp_neighborx, exp_neighbory, exp_neighborz;
	assign exp_refx = in_refx[30:23];
	assign exp_refy = in_refy[30:23];
	assign exp_refz = in_refz[30:23];
	assign exp_neighborx = in_neighborx[30:23];
	assign exp_neighbory = in_neighbory[30:23];
	assign exp_neighborz = in_neighborz[30:23];
	// Shift value
	wire [7:0] shift_value_refx, shift_value_refy, shift_value_refz;
	wire [7:0] shift_value_neighborx, shift_value_neighbory, shift_value_neighborz;
	assign shift_value_refx = exp_box_x - exp_refx;
	assign shift_value_refy = exp_box_y - exp_refy;
	assign shift_value_refz = exp_box_z - exp_refz;
	assign shift_value_neighborx = exp_box_x - exp_neighborx;
	assign shift_value_neighbory = exp_box_y - exp_neighbory;
	assign shift_value_neighborz = exp_box_z - exp_neighborz;
	
	// Converting from IEEE floating point to Fixed point
	// The fixed point value
	reg [FIXED_POINT_WIDTH-1:0] fixed_refx, fixed_refy, fixed_refz;
	reg [FIXED_POINT_WIDTH-1:0] fixed_neighborx, fixed_neighbory, fixed_neighborz;
	always@(posedge clk)
		begin
		fixed_refx <= {1'b1, in_refx[22:0], FILTER_IN_PATCH_0_BITS} >> shift_value_refx;
		fixed_refy <= {1'b1, in_refy[22:0], FILTER_IN_PATCH_0_BITS} >> shift_value_refy;
		fixed_refz <= {1'b1, in_refz[22:0], FILTER_IN_PATCH_0_BITS} >> shift_value_refz;
		fixed_neighborx <= {1'b1, in_neighborx[22:0], FILTER_IN_PATCH_0_BITS} >> shift_value_neighborx;
		fixed_neighbory <= {1'b1, in_neighbory[22:0], FILTER_IN_PATCH_0_BITS} >> shift_value_neighbory;
		fixed_neighborz <= {1'b1, in_neighborz[22:0], FILTER_IN_PATCH_0_BITS} >> shift_value_neighborz;
		end
	
	// dx, dy, dz
	reg [FIXED_POINT_WIDTH-1:0] dx, dy, dz;
	reg [FIXED_POINT_WIDTH-1:0] sum_dx_dy_dz;
	always@(posedge clk)
		begin
		if(rst)
			begin
			dx <= 0;
			dy <= 0;
			dz <= 0;
			sum_dx_dy_dz <= 0;
			end
		else
			begin
			// Sum the dx value
			sum_dx_dy_dz <= dx + dy + dz;
			// Get the absolute value of dx
			if(fixed_refx >= fixed_neighborx)
				dx <= fixed_refx - fixed_neighborx;
			else
				dx <= fixed_neighborx - fixed_refx;
			// Get the absolute value of dy
			if(fixed_refy >= fixed_neighbory)
				dy <= fixed_refy - fixed_neighbory;
			else
				dy <= fixed_neighbory - fixed_refy;
			// Get the absolute value of dz
			if(fixed_refz >= fixed_neighborz)
				dz <= fixed_refz - fixed_neighborz;
			else
				dz <= fixed_neighborz - fixed_refz;
			end
		end
	
	// Assign Output: backpressure
	// 3 is the latency in getting sum_dx_dy_dz
	// *** if sum_dx_dy_dz latency changed, need to change the threshold value to the new latency
	wire [FILTER_BUFFER_ADDR_WIDTH-1:0] buffer_usedw;
	assign filter_back_pressure = (FILTER_BUFFER_DEPTH - buffer_usedw < 5) ? 1'b1 : 1'b0;
	
	// Assign Output: particle_pair_available
	wire buffer_empty;
	assign particle_pair_available = ~buffer_empty;
	
	// Delay registers for input particle IDs & positions
	// Delay for 3 (sum_dx_dy_dz) cycles
	reg [PARTICLE_ID_WIDTH-1:0] ref_particle_id_reg0;
	reg [PARTICLE_ID_WIDTH-1:0] ref_particle_id_reg1;
	reg [PARTICLE_ID_WIDTH-1:0] ref_particle_id_delayed;
	reg [PARTICLE_ID_WIDTH-1:0] neighbor_particle_id_reg0;
	reg [PARTICLE_ID_WIDTH-1:0] neighbor_particle_id_reg1;
	reg [PARTICLE_ID_WIDTH-1:0] neighbor_particle_id_delayed;
	reg [3*FIXED_POINT_WIDTH-1:0] ref_reg0;						// {refz, refy, refx}
	reg [3*FIXED_POINT_WIDTH-1:0] ref_reg1;
	reg [3*FIXED_POINT_WIDTH-1:0] ref_delayed;
	reg [3*FIXED_POINT_WIDTH-1:0] neighbor_reg0;					// {neighborz, neighbory, neighborx}
	reg [3*FIXED_POINT_WIDTH-1:0] neighbor_reg1;
	reg [3*FIXED_POINT_WIDTH-1:0] neighbor_delayed;
	reg input_valid_reg0;
	reg input_valid_reg1;
	reg input_valid_delayed;
	
	always@(posedge clk)
		begin
		if(rst)
			begin
			ref_particle_id_reg0 <= 0;
			ref_particle_id_reg1 <= 0;
			ref_particle_id_delayed <= 0;
			neighbor_particle_id_reg0 <= 0;
			neighbor_particle_id_reg1 <= 0;
			neighbor_particle_id_delayed <= 0;
			ref_reg0 <= 0;
			ref_reg1 <= 0;
			ref_delayed <= 0;
			neighbor_reg0 <= 0;
			neighbor_reg1 <= 0;
			neighbor_delayed <= 0;
			input_valid_reg0 <= 1'b0;
			input_valid_reg1 <= 1'b0;
			input_valid_delayed <= 1'b0;
			end
		else
			begin
			ref_particle_id_reg0 <= in_ref_particle_id;
			ref_particle_id_reg1 <= ref_particle_id_reg0;
			ref_particle_id_delayed <= ref_particle_id_reg1;
			neighbor_particle_id_reg0 <= in_neighbor_particle_id;
			neighbor_particle_id_reg1 <= neighbor_particle_id_reg0;
			neighbor_particle_id_delayed <= neighbor_particle_id_reg1;
			ref_reg0 <= {in_refz, in_refy, in_refx};
			ref_reg1 <= ref_reg0;
			ref_delayed <= ref_reg1;
			neighbor_reg0 <= {in_neighborz, in_neighbory, in_neighborx};
			neighbor_reg1 <= neighbor_reg0;
			neighbor_delayed <= neighbor_reg1;
			input_valid_reg0 <= input_valid;
			input_valid_reg1 <= input_valid_reg0;
			input_valid_delayed <= input_valid_reg1;
			end
		end

	
	/////////////////////////////////////////////////////////////////////////////
	// Filter Logic
	/////////////////////////////////////////////////////////////////////////////
	reg buffer_wr;
	// MSB-LSB: {ref_particle_id, neighbor_particle_id, refz, refy, refx, neighborz, neighbory, neighbor_x}
	reg [PARTICLE_ID_WIDTH*2+FIXED_POINT_WIDTH*6-1:0] buffer_wr_data;
	always@(posedge clk)
		begin
		if(rst)
			begin
			buffer_wr_data <= 0;
			buffer_wr <= 1'b0;
			end
		else if(input_valid_delayed && sum_dx_dy_dz <= CUTOFF_TIMES_SQRT_3 && sum_dx_dy_dz > 0)
			begin
			buffer_wr_data <= {ref_particle_id_delayed, neighbor_particle_id_delayed, ref_delayed, neighbor_delayed};
			buffer_wr <= 1'b1;
			end
		else
			begin
			buffer_wr_data <= 0;
			buffer_wr <= 1'b0;
			end
		end

	
	// Buffer for pairs passed the filter logic
	// Data organization in buffer: MSB-LSB: {ref_particle_id, neighbor_particle_id, refz, refy, refx, neighborz, neighbory, neighbor_x}
	Filter_Buffer
	#(
		.DATA_WIDTH(2*PARTICLE_ID_WIDTH+6*DATA_WIDTH),							// hold r2, refz, refy, refx, neighborz, neighbory, neighbor_x
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
		 .q({out_ref_particle_id, out_neighbor_particle_id, out_refz, out_refy, out_refx, out_neighborz, out_neighbory, out_neighborx}),
		 .usedw(buffer_usedw)
	);


endmodule