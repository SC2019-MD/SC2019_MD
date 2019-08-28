/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: Filter_Bank.v
//
//	Function: 
//					Holding multiple filter, perform arbitration to read from multiple available filter buffers
//					Sending selected data to force evaluation pipeline
//
// Used by:
//				RL_LJ_Force_Evaluation_Unit.v
//
// Dependency:
// 			Filter_Logic.v
//				Filter_Arbiter.v
//
// Testbench:
//				RL_LJ_Top_tb.v
//
// Created by:
//				Chen Yang 10/10/18
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module Filter_Bank
#(
	parameter DATA_WIDTH 					= 32,
	parameter NUM_FILTER						= 4,	// 8
	parameter ARBITER_MSB 					= 8,	//128							// 2^(NUM_FILTER-1)
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
	input [NUM_FILTER-1:0] input_valid,
	input [NUM_FILTER*PARTICLE_ID_WIDTH-1:0] ref_particle_id,
	input [NUM_FILTER*PARTICLE_ID_WIDTH-1:0] neighbor_particle_id,
	input [NUM_FILTER*DATA_WIDTH-1:0] refx,
	input [NUM_FILTER*DATA_WIDTH-1:0] refy,
	input [NUM_FILTER*DATA_WIDTH-1:0] refz,
	input [NUM_FILTER*DATA_WIDTH-1:0] neighborx,
	input [NUM_FILTER*DATA_WIDTH-1:0] neighbory,
	input [NUM_FILTER*DATA_WIDTH-1:0] neighborz,
	output reg [PARTICLE_ID_WIDTH-1:0] ref_particle_id_out,
	output reg [PARTICLE_ID_WIDTH-1:0] neighbor_particle_id_out,
	output reg [DATA_WIDTH-1:0] r2,
	output reg [DATA_WIDTH-1:0] dx,
	output reg [DATA_WIDTH-1:0] dy,
	output reg [DATA_WIDTH-1:0] dz,
	output reg out_valid,
	
	output [NUM_FILTER-1:0] out_back_pressure_to_input,				// If one of the FIFO is full, then set the back_pressure flag to stop more incoming particle pairs
	output out_all_buffer_empty												// Output to FSM that generate particle pairs. Only when all the filter buffers are empty, then the FSM will move on to the next reference particle
																						// Avoid the cases when the force pipelines are evaluating for 2 different reference particles when switching after one reference particle, this will lead to the accumulation error for the reference particle
);

	// Wires between Filter_Logic and Arbiter
	wire [NUM_FILTER*DATA_WIDTH-1:0] r2_wire, dx_wire, dy_wire, dz_wire;
	wire [NUM_FILTER*PARTICLE_ID_WIDTH-1:0] ref_particle_id_out_wire, neighbor_particle_id_out_wire;
	wire [NUM_FILTER-1:0] filter_data_available;							// Filter -> Arbitor
	wire [NUM_FILTER-1:0] arbitration_result;								// Arbitor -> Filter
	// The arbitration_result is directly used as read request signal for the selected filter buffer
	// Since there is a one cycle delay between the read request is assigned and the data readout from the FIFO, thus implement a one cycle delay for the arbitration_result when assigning the output port of particle pairs information
	reg  [NUM_FILTER-1:0] prev_arbitration_result;	
	always@(posedge clk)
		begin
		prev_arbitration_result <= arbitration_result;
		end
	
	/////////////////////////////////////////////////////////////////////////////////
	// Assign the output ports
	/////////////////////////////////////////////////////////////////////////////////
	// Assign buffer empty signal
	assign out_all_buffer_empty = (filter_data_available == 0) ? 1'b1 : 1'b0;
	
	// Need to change this if # of filters changed
	generate
		// Filter_num = 4
		if(NUM_FILTER == 4)
			begin
			always@(posedge clk)
				begin
				case(prev_arbitration_result)
					4'b0001:
						begin
						ref_particle_id_out <= ref_particle_id_out_wire[PARTICLE_ID_WIDTH-1:0];
						neighbor_particle_id_out <= neighbor_particle_id_out_wire[PARTICLE_ID_WIDTH-1:0];
						r2 <= r2_wire[DATA_WIDTH-1:0];
						dx <= dx_wire[DATA_WIDTH-1:0];
						dy <= dy_wire[DATA_WIDTH-1:0];
						dz <= dz_wire[DATA_WIDTH-1:0];
						out_valid <= 1'b1;
						end
					4'b0010:
						begin
						ref_particle_id_out <= ref_particle_id_out_wire[2*PARTICLE_ID_WIDTH-1:1*PARTICLE_ID_WIDTH];
						neighbor_particle_id_out <= neighbor_particle_id_out_wire[2*PARTICLE_ID_WIDTH-1:1*PARTICLE_ID_WIDTH];
						r2 <= r2_wire[2*DATA_WIDTH-1:1*DATA_WIDTH];
						dx <= dx_wire[2*DATA_WIDTH-1:1*DATA_WIDTH];
						dy <= dy_wire[2*DATA_WIDTH-1:1*DATA_WIDTH];
						dz <= dz_wire[2*DATA_WIDTH-1:1*DATA_WIDTH];
						out_valid <= 1'b1;
						end
					4'b0100:
						begin
						ref_particle_id_out <= ref_particle_id_out_wire[3*PARTICLE_ID_WIDTH-1:2*PARTICLE_ID_WIDTH];
						neighbor_particle_id_out <= neighbor_particle_id_out_wire[3*PARTICLE_ID_WIDTH-1:2*PARTICLE_ID_WIDTH];
						r2 <= r2_wire[3*DATA_WIDTH-1:2*DATA_WIDTH];
						dx <= dx_wire[3*DATA_WIDTH-1:2*DATA_WIDTH];
						dy <= dy_wire[3*DATA_WIDTH-1:2*DATA_WIDTH];
						dz <= dz_wire[3*DATA_WIDTH-1:2*DATA_WIDTH];
						out_valid <= 1'b1;
						end
					4'b1000:
						begin
						ref_particle_id_out <= ref_particle_id_out_wire[4*PARTICLE_ID_WIDTH-1:3*PARTICLE_ID_WIDTH];
						neighbor_particle_id_out <= neighbor_particle_id_out_wire[4*PARTICLE_ID_WIDTH-1:3*PARTICLE_ID_WIDTH];
						r2 <= r2_wire[4*DATA_WIDTH-1:3*DATA_WIDTH];
						dx <= dx_wire[4*DATA_WIDTH-1:3*DATA_WIDTH];
						dy <= dy_wire[4*DATA_WIDTH-1:3*DATA_WIDTH];
						dz <= dz_wire[4*DATA_WIDTH-1:3*DATA_WIDTH];
						out_valid <= 1'b1;
						end
					default:
						begin
						ref_particle_id_out <= ref_particle_id_out;
						neighbor_particle_id_out <= neighbor_particle_id_out;
						r2 <= 0;
						dx <= 0;
						dy <= 0;
						dz <= 0;
						out_valid <= 1'b0;
						end
				endcase
				end
			end
		
		// Filter_num = 7
		else if(NUM_FILTER == 7)
			begin
			always@(posedge clk)
				begin
				case(prev_arbitration_result)
					7'b0000001:
						begin
						ref_particle_id_out <= ref_particle_id_out_wire[PARTICLE_ID_WIDTH-1:0];
						neighbor_particle_id_out <= neighbor_particle_id_out_wire[PARTICLE_ID_WIDTH-1:0];
						r2 <= r2_wire[DATA_WIDTH-1:0];
						dx <= dx_wire[DATA_WIDTH-1:0];
						dy <= dy_wire[DATA_WIDTH-1:0];
						dz <= dz_wire[DATA_WIDTH-1:0];
						out_valid <= 1'b1;
						end
					7'b0000010:
						begin
						ref_particle_id_out <= ref_particle_id_out_wire[2*PARTICLE_ID_WIDTH-1:1*PARTICLE_ID_WIDTH];
						neighbor_particle_id_out <= neighbor_particle_id_out_wire[2*PARTICLE_ID_WIDTH-1:1*PARTICLE_ID_WIDTH];
						r2 <= r2_wire[2*DATA_WIDTH-1:1*DATA_WIDTH];
						dx <= dx_wire[2*DATA_WIDTH-1:1*DATA_WIDTH];
						dy <= dy_wire[2*DATA_WIDTH-1:1*DATA_WIDTH];
						dz <= dz_wire[2*DATA_WIDTH-1:1*DATA_WIDTH];
						out_valid <= 1'b1;
						end
					7'b0000100:
						begin
						ref_particle_id_out <= ref_particle_id_out_wire[3*PARTICLE_ID_WIDTH-1:2*PARTICLE_ID_WIDTH];
						neighbor_particle_id_out <= neighbor_particle_id_out_wire[3*PARTICLE_ID_WIDTH-1:2*PARTICLE_ID_WIDTH];
						r2 <= r2_wire[3*DATA_WIDTH-1:2*DATA_WIDTH];
						dx <= dx_wire[3*DATA_WIDTH-1:2*DATA_WIDTH];
						dy <= dy_wire[3*DATA_WIDTH-1:2*DATA_WIDTH];
						dz <= dz_wire[3*DATA_WIDTH-1:2*DATA_WIDTH];
						out_valid <= 1'b1;
						end
					7'b0001000:
						begin
						ref_particle_id_out <= ref_particle_id_out_wire[4*PARTICLE_ID_WIDTH-1:3*PARTICLE_ID_WIDTH];
						neighbor_particle_id_out <= neighbor_particle_id_out_wire[4*PARTICLE_ID_WIDTH-1:3*PARTICLE_ID_WIDTH];
						r2 <= r2_wire[4*DATA_WIDTH-1:3*DATA_WIDTH];
						dx <= dx_wire[4*DATA_WIDTH-1:3*DATA_WIDTH];
						dy <= dy_wire[4*DATA_WIDTH-1:3*DATA_WIDTH];
						dz <= dz_wire[4*DATA_WIDTH-1:3*DATA_WIDTH];
						out_valid <= 1'b1;
						end
					7'b0010000:
						begin
						ref_particle_id_out <= ref_particle_id_out_wire[5*PARTICLE_ID_WIDTH-1:4*PARTICLE_ID_WIDTH];
						neighbor_particle_id_out <= neighbor_particle_id_out_wire[5*PARTICLE_ID_WIDTH-1:4*PARTICLE_ID_WIDTH];
						r2 <= r2_wire[5*DATA_WIDTH-1:4*DATA_WIDTH];
						dx <= dx_wire[5*DATA_WIDTH-1:4*DATA_WIDTH];
						dy <= dy_wire[5*DATA_WIDTH-1:4*DATA_WIDTH];
						dz <= dz_wire[5*DATA_WIDTH-1:4*DATA_WIDTH];
						out_valid <= 1'b1;
						end
					7'b0100000:
						begin
						ref_particle_id_out <= ref_particle_id_out_wire[6*PARTICLE_ID_WIDTH-1:5*PARTICLE_ID_WIDTH];
						neighbor_particle_id_out <= neighbor_particle_id_out_wire[6*PARTICLE_ID_WIDTH-1:5*PARTICLE_ID_WIDTH];
						r2 <= r2_wire[6*DATA_WIDTH-1:5*DATA_WIDTH];
						dx <= dx_wire[6*DATA_WIDTH-1:5*DATA_WIDTH];
						dy <= dy_wire[6*DATA_WIDTH-1:5*DATA_WIDTH];
						dz <= dz_wire[6*DATA_WIDTH-1:5*DATA_WIDTH];
						out_valid <= 1'b1;
						end
					7'b1000000:
						begin
						ref_particle_id_out <= ref_particle_id_out_wire[7*PARTICLE_ID_WIDTH-1:6*PARTICLE_ID_WIDTH];
						neighbor_particle_id_out <= neighbor_particle_id_out_wire[7*PARTICLE_ID_WIDTH-1:6*PARTICLE_ID_WIDTH];
						r2 <= r2_wire[7*DATA_WIDTH-1:6*DATA_WIDTH];
						dx <= dx_wire[7*DATA_WIDTH-1:6*DATA_WIDTH];
						dy <= dy_wire[7*DATA_WIDTH-1:6*DATA_WIDTH];
						dz <= dz_wire[7*DATA_WIDTH-1:6*DATA_WIDTH];
						out_valid <= 1'b1;
						end
					default:
						begin
						ref_particle_id_out <= 0;
						neighbor_particle_id_out <= 0;
						r2 <= 0;
						dx <= 0;
						dy <= 0;
						dz <= 0;
						out_valid <= 1'b0;
						end
				endcase
				end
			end
		
		// Filter_num = 8
		else if(NUM_FILTER == 8)
			begin
			always@(posedge clk)
				begin
				case(prev_arbitration_result)
					8'b00000001:
						begin
						ref_particle_id_out <= ref_particle_id_out_wire[PARTICLE_ID_WIDTH-1:0];
						neighbor_particle_id_out <= neighbor_particle_id_out_wire[PARTICLE_ID_WIDTH-1:0];
						r2 <= r2_wire[DATA_WIDTH-1:0];
						dx <= dx_wire[DATA_WIDTH-1:0];
						dy <= dy_wire[DATA_WIDTH-1:0];
						dz <= dz_wire[DATA_WIDTH-1:0];
						out_valid <= 1'b1;
						end
					8'b00000010:
						begin
						ref_particle_id_out <= ref_particle_id_out_wire[2*PARTICLE_ID_WIDTH-1:1*PARTICLE_ID_WIDTH];
						neighbor_particle_id_out <= neighbor_particle_id_out_wire[2*PARTICLE_ID_WIDTH-1:1*PARTICLE_ID_WIDTH];
						r2 <= r2_wire[2*DATA_WIDTH-1:1*DATA_WIDTH];
						dx <= dx_wire[2*DATA_WIDTH-1:1*DATA_WIDTH];
						dy <= dy_wire[2*DATA_WIDTH-1:1*DATA_WIDTH];
						dz <= dz_wire[2*DATA_WIDTH-1:1*DATA_WIDTH];
						out_valid <= 1'b1;
						end
					8'b00000100:
						begin
						ref_particle_id_out <= ref_particle_id_out_wire[3*PARTICLE_ID_WIDTH-1:2*PARTICLE_ID_WIDTH];
						neighbor_particle_id_out <= neighbor_particle_id_out_wire[3*PARTICLE_ID_WIDTH-1:2*PARTICLE_ID_WIDTH];
						r2 <= r2_wire[3*DATA_WIDTH-1:2*DATA_WIDTH];
						dx <= dx_wire[3*DATA_WIDTH-1:2*DATA_WIDTH];
						dy <= dy_wire[3*DATA_WIDTH-1:2*DATA_WIDTH];
						dz <= dz_wire[3*DATA_WIDTH-1:2*DATA_WIDTH];
						out_valid <= 1'b1;
						end
					8'b00001000:
						begin
						ref_particle_id_out <= ref_particle_id_out_wire[4*PARTICLE_ID_WIDTH-1:3*PARTICLE_ID_WIDTH];
						neighbor_particle_id_out <= neighbor_particle_id_out_wire[4*PARTICLE_ID_WIDTH-1:3*PARTICLE_ID_WIDTH];
						r2 <= r2_wire[4*DATA_WIDTH-1:3*DATA_WIDTH];
						dx <= dx_wire[4*DATA_WIDTH-1:3*DATA_WIDTH];
						dy <= dy_wire[4*DATA_WIDTH-1:3*DATA_WIDTH];
						dz <= dz_wire[4*DATA_WIDTH-1:3*DATA_WIDTH];
						out_valid <= 1'b1;
						end
					8'b00010000:
						begin
						ref_particle_id_out <= ref_particle_id_out_wire[5*PARTICLE_ID_WIDTH-1:4*PARTICLE_ID_WIDTH];
						neighbor_particle_id_out <= neighbor_particle_id_out_wire[5*PARTICLE_ID_WIDTH-1:4*PARTICLE_ID_WIDTH];
						r2 <= r2_wire[5*DATA_WIDTH-1:4*DATA_WIDTH];
						dx <= dx_wire[5*DATA_WIDTH-1:4*DATA_WIDTH];
						dy <= dy_wire[5*DATA_WIDTH-1:4*DATA_WIDTH];
						dz <= dz_wire[5*DATA_WIDTH-1:4*DATA_WIDTH];
						out_valid <= 1'b1;
						end
					8'b00100000:
						begin
						ref_particle_id_out <= ref_particle_id_out_wire[6*PARTICLE_ID_WIDTH-1:5*PARTICLE_ID_WIDTH];
						neighbor_particle_id_out <= neighbor_particle_id_out_wire[6*PARTICLE_ID_WIDTH-1:5*PARTICLE_ID_WIDTH];
						r2 <= r2_wire[6*DATA_WIDTH-1:5*DATA_WIDTH];
						dx <= dx_wire[6*DATA_WIDTH-1:5*DATA_WIDTH];
						dy <= dy_wire[6*DATA_WIDTH-1:5*DATA_WIDTH];
						dz <= dz_wire[6*DATA_WIDTH-1:5*DATA_WIDTH];
						out_valid <= 1'b1;
						end
					8'b01000000:
						begin
						ref_particle_id_out <= ref_particle_id_out_wire[7*PARTICLE_ID_WIDTH-1:6*PARTICLE_ID_WIDTH];
						neighbor_particle_id_out <= neighbor_particle_id_out_wire[7*PARTICLE_ID_WIDTH-1:6*PARTICLE_ID_WIDTH];
						r2 <= r2_wire[7*DATA_WIDTH-1:6*DATA_WIDTH];
						dx <= dx_wire[7*DATA_WIDTH-1:6*DATA_WIDTH];
						dy <= dy_wire[7*DATA_WIDTH-1:6*DATA_WIDTH];
						dz <= dz_wire[7*DATA_WIDTH-1:6*DATA_WIDTH];
						out_valid <= 1'b1;
						end
					8'b10000000:
						begin
						ref_particle_id_out <= ref_particle_id_out_wire[8*PARTICLE_ID_WIDTH-1:7*PARTICLE_ID_WIDTH];
						neighbor_particle_id_out <= neighbor_particle_id_out_wire[8*PARTICLE_ID_WIDTH-1:7*PARTICLE_ID_WIDTH];
						r2 <= r2_wire[8*DATA_WIDTH-1:7*DATA_WIDTH];
						dx <= dx_wire[8*DATA_WIDTH-1:7*DATA_WIDTH];
						dy <= dy_wire[8*DATA_WIDTH-1:7*DATA_WIDTH];
						dz <= dz_wire[8*DATA_WIDTH-1:7*DATA_WIDTH];
						out_valid <= 1'b1;
						end
					default:
						begin
						ref_particle_id_out <= ref_particle_id_out;
						neighbor_particle_id_out <= neighbor_particle_id_out;
						r2 <= 0;
						dx <= 0;
						dy <= 0;
						dz <= 0;
						out_valid <= 1'b0;
						end
				endcase
				end
			end
		
		// Filter_num = 9
		else if(NUM_FILTER == 9)
			begin
			always@(posedge clk)
				begin
				case(prev_arbitration_result)
					9'b000000001:
						begin
						ref_particle_id_out <= ref_particle_id_out_wire[PARTICLE_ID_WIDTH-1:0];
						neighbor_particle_id_out <= neighbor_particle_id_out_wire[PARTICLE_ID_WIDTH-1:0];
						r2 <= r2_wire[DATA_WIDTH-1:0];
						dx <= dx_wire[DATA_WIDTH-1:0];
						dy <= dy_wire[DATA_WIDTH-1:0];
						dz <= dz_wire[DATA_WIDTH-1:0];
						out_valid <= 1'b1;
						end
					9'b000000010:
						begin
						ref_particle_id_out <= ref_particle_id_out_wire[2*PARTICLE_ID_WIDTH-1:1*PARTICLE_ID_WIDTH];
						neighbor_particle_id_out <= neighbor_particle_id_out_wire[2*PARTICLE_ID_WIDTH-1:1*PARTICLE_ID_WIDTH];
						r2 <= r2_wire[2*DATA_WIDTH-1:1*DATA_WIDTH];
						dx <= dx_wire[2*DATA_WIDTH-1:1*DATA_WIDTH];
						dy <= dy_wire[2*DATA_WIDTH-1:1*DATA_WIDTH];
						dz <= dz_wire[2*DATA_WIDTH-1:1*DATA_WIDTH];
						out_valid <= 1'b1;
						end
					9'b000000100:
						begin
						ref_particle_id_out <= ref_particle_id_out_wire[3*PARTICLE_ID_WIDTH-1:2*PARTICLE_ID_WIDTH];
						neighbor_particle_id_out <= neighbor_particle_id_out_wire[3*PARTICLE_ID_WIDTH-1:2*PARTICLE_ID_WIDTH];
						r2 <= r2_wire[3*DATA_WIDTH-1:2*DATA_WIDTH];
						dx <= dx_wire[3*DATA_WIDTH-1:2*DATA_WIDTH];
						dy <= dy_wire[3*DATA_WIDTH-1:2*DATA_WIDTH];
						dz <= dz_wire[3*DATA_WIDTH-1:2*DATA_WIDTH];
						out_valid <= 1'b1;
						end
					9'b000001000:
						begin
						ref_particle_id_out <= ref_particle_id_out_wire[4*PARTICLE_ID_WIDTH-1:3*PARTICLE_ID_WIDTH];
						neighbor_particle_id_out <= neighbor_particle_id_out_wire[4*PARTICLE_ID_WIDTH-1:3*PARTICLE_ID_WIDTH];
						r2 <= r2_wire[4*DATA_WIDTH-1:3*DATA_WIDTH];
						dx <= dx_wire[4*DATA_WIDTH-1:3*DATA_WIDTH];
						dy <= dy_wire[4*DATA_WIDTH-1:3*DATA_WIDTH];
						dz <= dz_wire[4*DATA_WIDTH-1:3*DATA_WIDTH];
						out_valid <= 1'b1;
						end
					9'b000010000:
						begin
						ref_particle_id_out <= ref_particle_id_out_wire[5*PARTICLE_ID_WIDTH-1:4*PARTICLE_ID_WIDTH];
						neighbor_particle_id_out <= neighbor_particle_id_out_wire[5*PARTICLE_ID_WIDTH-1:4*PARTICLE_ID_WIDTH];
						r2 <= r2_wire[5*DATA_WIDTH-1:4*DATA_WIDTH];
						dx <= dx_wire[5*DATA_WIDTH-1:4*DATA_WIDTH];
						dy <= dy_wire[5*DATA_WIDTH-1:4*DATA_WIDTH];
						dz <= dz_wire[5*DATA_WIDTH-1:4*DATA_WIDTH];
						out_valid <= 1'b1;
						end
					9'b000100000:
						begin
						ref_particle_id_out <= ref_particle_id_out_wire[6*PARTICLE_ID_WIDTH-1:5*PARTICLE_ID_WIDTH];
						neighbor_particle_id_out <= neighbor_particle_id_out_wire[6*PARTICLE_ID_WIDTH-1:5*PARTICLE_ID_WIDTH];
						r2 <= r2_wire[6*DATA_WIDTH-1:5*DATA_WIDTH];
						dx <= dx_wire[6*DATA_WIDTH-1:5*DATA_WIDTH];
						dy <= dy_wire[6*DATA_WIDTH-1:5*DATA_WIDTH];
						dz <= dz_wire[6*DATA_WIDTH-1:5*DATA_WIDTH];
						out_valid <= 1'b1;
						end
					9'b001000000:
						begin
						ref_particle_id_out <= ref_particle_id_out_wire[7*PARTICLE_ID_WIDTH-1:6*PARTICLE_ID_WIDTH];
						neighbor_particle_id_out <= neighbor_particle_id_out_wire[7*PARTICLE_ID_WIDTH-1:6*PARTICLE_ID_WIDTH];
						r2 <= r2_wire[7*DATA_WIDTH-1:6*DATA_WIDTH];
						dx <= dx_wire[7*DATA_WIDTH-1:6*DATA_WIDTH];
						dy <= dy_wire[7*DATA_WIDTH-1:6*DATA_WIDTH];
						dz <= dz_wire[7*DATA_WIDTH-1:6*DATA_WIDTH];
						out_valid <= 1'b1;
						end
					9'b010000000:
						begin
						ref_particle_id_out <= ref_particle_id_out_wire[8*PARTICLE_ID_WIDTH-1:7*PARTICLE_ID_WIDTH];
						neighbor_particle_id_out <= neighbor_particle_id_out_wire[8*PARTICLE_ID_WIDTH-1:7*PARTICLE_ID_WIDTH];
						r2 <= r2_wire[8*DATA_WIDTH-1:7*DATA_WIDTH];
						dx <= dx_wire[8*DATA_WIDTH-1:7*DATA_WIDTH];
						dy <= dy_wire[8*DATA_WIDTH-1:7*DATA_WIDTH];
						dz <= dz_wire[8*DATA_WIDTH-1:7*DATA_WIDTH];
						out_valid <= 1'b1;
						end
					9'b100000000:
						begin
						ref_particle_id_out <= ref_particle_id_out_wire[9*PARTICLE_ID_WIDTH-1:8*PARTICLE_ID_WIDTH];
						neighbor_particle_id_out <= neighbor_particle_id_out_wire[9*PARTICLE_ID_WIDTH-1:8*PARTICLE_ID_WIDTH];
						r2 <= r2_wire[9*DATA_WIDTH-1:8*DATA_WIDTH];
						dx <= dx_wire[9*DATA_WIDTH-1:8*DATA_WIDTH];
						dy <= dy_wire[9*DATA_WIDTH-1:8*DATA_WIDTH];
						dz <= dz_wire[9*DATA_WIDTH-1:8*DATA_WIDTH];
						out_valid <= 1'b1;
						end
					default:
						begin
						ref_particle_id_out <= ref_particle_id_out;
						neighbor_particle_id_out <= neighbor_particle_id_out;
						r2 <= 0;
						dx <= 0;
						dy <= 0;
						dz <= 0;
						out_valid <= 1'b0;
						end
				endcase
				end
			end
		// By default, choose FILTER_NUM = 8
		else
			begin
			always@(posedge clk)
				begin
				case(prev_arbitration_result)
					8'b00000001:
						begin
						ref_particle_id_out <= ref_particle_id_out_wire[PARTICLE_ID_WIDTH-1:0];
						neighbor_particle_id_out <= neighbor_particle_id_out_wire[PARTICLE_ID_WIDTH-1:0];
						r2 <= r2_wire[DATA_WIDTH-1:0];
						dx <= dx_wire[DATA_WIDTH-1:0];
						dy <= dy_wire[DATA_WIDTH-1:0];
						dz <= dz_wire[DATA_WIDTH-1:0];
						out_valid <= 1'b1;
						end
					8'b00000010:
						begin
						ref_particle_id_out <= ref_particle_id_out_wire[2*PARTICLE_ID_WIDTH-1:1*PARTICLE_ID_WIDTH];
						neighbor_particle_id_out <= neighbor_particle_id_out_wire[2*PARTICLE_ID_WIDTH-1:1*PARTICLE_ID_WIDTH];
						r2 <= r2_wire[2*DATA_WIDTH-1:1*DATA_WIDTH];
						dx <= dx_wire[2*DATA_WIDTH-1:1*DATA_WIDTH];
						dy <= dy_wire[2*DATA_WIDTH-1:1*DATA_WIDTH];
						dz <= dz_wire[2*DATA_WIDTH-1:1*DATA_WIDTH];
						out_valid <= 1'b1;
						end
					8'b00000100:
						begin
						ref_particle_id_out <= ref_particle_id_out_wire[3*PARTICLE_ID_WIDTH-1:2*PARTICLE_ID_WIDTH];
						neighbor_particle_id_out <= neighbor_particle_id_out_wire[3*PARTICLE_ID_WIDTH-1:2*PARTICLE_ID_WIDTH];
						r2 <= r2_wire[3*DATA_WIDTH-1:2*DATA_WIDTH];
						dx <= dx_wire[3*DATA_WIDTH-1:2*DATA_WIDTH];
						dy <= dy_wire[3*DATA_WIDTH-1:2*DATA_WIDTH];
						dz <= dz_wire[3*DATA_WIDTH-1:2*DATA_WIDTH];
						out_valid <= 1'b1;
						end
					8'b00001000:
						begin
						ref_particle_id_out <= ref_particle_id_out_wire[4*PARTICLE_ID_WIDTH-1:3*PARTICLE_ID_WIDTH];
						neighbor_particle_id_out <= neighbor_particle_id_out_wire[4*PARTICLE_ID_WIDTH-1:3*PARTICLE_ID_WIDTH];
						r2 <= r2_wire[4*DATA_WIDTH-1:3*DATA_WIDTH];
						dx <= dx_wire[4*DATA_WIDTH-1:3*DATA_WIDTH];
						dy <= dy_wire[4*DATA_WIDTH-1:3*DATA_WIDTH];
						dz <= dz_wire[4*DATA_WIDTH-1:3*DATA_WIDTH];
						out_valid <= 1'b1;
						end
					8'b00010000:
						begin
						ref_particle_id_out <= ref_particle_id_out_wire[5*PARTICLE_ID_WIDTH-1:4*PARTICLE_ID_WIDTH];
						neighbor_particle_id_out <= neighbor_particle_id_out_wire[5*PARTICLE_ID_WIDTH-1:4*PARTICLE_ID_WIDTH];
						r2 <= r2_wire[5*DATA_WIDTH-1:4*DATA_WIDTH];
						dx <= dx_wire[5*DATA_WIDTH-1:4*DATA_WIDTH];
						dy <= dy_wire[5*DATA_WIDTH-1:4*DATA_WIDTH];
						dz <= dz_wire[5*DATA_WIDTH-1:4*DATA_WIDTH];
						out_valid <= 1'b1;
						end
					8'b00100000:
						begin
						ref_particle_id_out <= ref_particle_id_out_wire[6*PARTICLE_ID_WIDTH-1:5*PARTICLE_ID_WIDTH];
						neighbor_particle_id_out <= neighbor_particle_id_out_wire[6*PARTICLE_ID_WIDTH-1:5*PARTICLE_ID_WIDTH];
						r2 <= r2_wire[6*DATA_WIDTH-1:5*DATA_WIDTH];
						dx <= dx_wire[6*DATA_WIDTH-1:5*DATA_WIDTH];
						dy <= dy_wire[6*DATA_WIDTH-1:5*DATA_WIDTH];
						dz <= dz_wire[6*DATA_WIDTH-1:5*DATA_WIDTH];
						out_valid <= 1'b1;
						end
					8'b01000000:
						begin
						ref_particle_id_out <= ref_particle_id_out_wire[7*PARTICLE_ID_WIDTH-1:6*PARTICLE_ID_WIDTH];
						neighbor_particle_id_out <= neighbor_particle_id_out_wire[7*PARTICLE_ID_WIDTH-1:6*PARTICLE_ID_WIDTH];
						r2 <= r2_wire[7*DATA_WIDTH-1:6*DATA_WIDTH];
						dx <= dx_wire[7*DATA_WIDTH-1:6*DATA_WIDTH];
						dy <= dy_wire[7*DATA_WIDTH-1:6*DATA_WIDTH];
						dz <= dz_wire[7*DATA_WIDTH-1:6*DATA_WIDTH];
						out_valid <= 1'b1;
						end
					8'b10000000:
						begin
						ref_particle_id_out <= ref_particle_id_out_wire[8*PARTICLE_ID_WIDTH-1:7*PARTICLE_ID_WIDTH];
						neighbor_particle_id_out <= neighbor_particle_id_out_wire[8*PARTICLE_ID_WIDTH-1:7*PARTICLE_ID_WIDTH];
						r2 <= r2_wire[8*DATA_WIDTH-1:7*DATA_WIDTH];
						dx <= dx_wire[8*DATA_WIDTH-1:7*DATA_WIDTH];
						dy <= dy_wire[8*DATA_WIDTH-1:7*DATA_WIDTH];
						dz <= dz_wire[8*DATA_WIDTH-1:7*DATA_WIDTH];
						out_valid <= 1'b1;
						end
					default:
						begin
						ref_particle_id_out <= ref_particle_id_out;
						neighbor_particle_id_out <= neighbor_particle_id_out;
						r2 <= 0;
						dx <= 0;
						dy <= 0;
						dz <= 0;
						out_valid <= 1'b0;
						end
				endcase
				end
			end
	endgenerate
	
	// Instantiate the Filter_Logic modules
	genvar i;
	generate 
		for(i = 0; i < NUM_FILTER; i = i + 1) begin: Filter_Unit
		Filter_Logic
		#(
			.DATA_WIDTH(DATA_WIDTH),
			.PARTICLE_ID_WIDTH(PARTICLE_ID_WIDTH),
			.FILTER_BUFFER_DEPTH(FILTER_BUFFER_DEPTH),
			.FILTER_BUFFER_ADDR_WIDTH(FILTER_BUFFER_ADDR_WIDTH),
			.CUTOFF_2(CUTOFF_2),													// (12^2=144 in IEEE floating point)
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
		Filter_Logic
		(
			.clk(clk),
			.rst(rst),
			.input_valid(input_valid[i]),
			.ref_particle_id(ref_particle_id[(i+1)*PARTICLE_ID_WIDTH-1:i*PARTICLE_ID_WIDTH]),
			.neighbor_particle_id(neighbor_particle_id[(i+1)*PARTICLE_ID_WIDTH-1:i*PARTICLE_ID_WIDTH]),
			.refx(refx[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH]),
			.refy(refy[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH]),
			.refz(refz[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH]),
			.neighborx(neighborx[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH]),
			.neighbory(neighbory[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH]),
			.neighborz(neighborz[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH]),
			.ref_particle_id_out(ref_particle_id_out_wire[(i+1)*PARTICLE_ID_WIDTH-1:i*PARTICLE_ID_WIDTH]),
			.neighbor_particle_id_out(neighbor_particle_id_out_wire[(i+1)*PARTICLE_ID_WIDTH-1:i*PARTICLE_ID_WIDTH]),
			.r2(r2_wire[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH]),
			.dx(dx_wire[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH]),
			.dy(dy_wire[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH]),
			.dz(dz_wire[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH]),
			// Connect to filter arbiter
			.sel(arbitration_result[i]),									// Input
			.particle_pair_available(filter_data_available[i]),	// Output
			// Connect to input generator
			.filter_back_pressure(out_back_pressure_to_input[i])		// Output: Buffer should have enough space to store 17 pairs after the input stop coming
	);
	end
	endgenerate
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Arbitration logic
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	Filter_Arbiter
	#(
		.NUM_FILTER(NUM_FILTER),
		.ARBITER_MSB(ARBITER_MSB)
	)
	Filter_Arbiter
	(
		.clk(clk),
		.rst(rst),
		.Filter_Available_Flag(filter_data_available),
		.Arbitration_Result(arbitration_result)
	);


endmodule