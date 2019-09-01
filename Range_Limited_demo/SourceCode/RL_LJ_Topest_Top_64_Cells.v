module RL_LJ_Topest_Top_64_Cells
#(
	parameter DATA_WIDTH 					= 32,
	parameter NUM_PIPELINES					= 16,
	// Simulation parameters
	parameter TIME_STEP 						= 32'h27101D7D,							// 2fs time step
	// High level parameters
	parameter NUM_EVAL_UNIT					= 1,											// # of evaluation units in the design
	parameter RDADDR_ARBITER_SIZE			= 5,
	parameter RDADDR_ARBITER_MSB			= 16,
	parameter FORCE_WTADDR_ARBITER_SIZE	= 6,
	parameter FORCE_WTADDR_ARBITER_MSB	= 32,
	// Dataset defined parameters
	parameter X_DIM							= 4,
	parameter Y_DIM							= 4,
	parameter Z_DIM							= 4,
	parameter TOTAL_CELL_NUM				= X_DIM*Y_DIM*Z_DIM,
	parameter GLOBAL_CELL_ADDR_LEN		= 7,
	parameter MAX_CELL_COUNT_PER_DIM 	= 4,//9,										// Maximum cell count among the 3 dimensions
	parameter NUM_NEIGHBOR_CELLS			= 13,											// # of neighbor cells per home cell, for Half-shell method, is 13
	parameter CELL_ID_WIDTH					= 3,//4,										// log(MAX_CELL_COUNT_PER_DIM)
	parameter MAX_CELL_PARTICLE_NUM		= 100,//200,								// The maximum # of particles can be in a cell
	parameter CELL_ADDR_WIDTH				= 7,//8,										// log(MAX_CELL_PARTICLE_NUM)
	parameter PARTICLE_ID_WIDTH			= CELL_ID_WIDTH*3+CELL_ADDR_WIDTH,	// # of bit used to represent particle ID, 9*9*7 cells, each 4-bit, each cell have max of 220 particles, 8-bit
	// Filter parameters
	parameter NUM_FILTER						= 8,		//4
	parameter ARBITER_MSB 					= 128,	//8								// 2^(NUM_FILTER-1)
	parameter FILTER_BUFFER_DEPTH 		= 32,
	parameter FILTER_BUFFER_ADDR_WIDTH	= 5,
	parameter CUTOFF_2 						= 32'h42908000,							// 8.5^2=72.25 in IEEE Floating Point//32'h43100000,			// (12^2=144 in IEEE floating point)
	parameter CUTOFF_TIMES_SQRT_3			= 32'h416b8f15,//32'h41A646DC,		// sqrt(3) * CUTOFF
	parameter FIXED_POINT_WIDTH 			= 24,//32,
	parameter FILTER_IN_PATCH_0_BITS		= 0,//8'b0,									// Width = FIXED_POINT_WIDTH - 1 - 23
	// Bounding box parameters, used when applying PBC inside r2 evaluation
	parameter BOUNDING_BOX_X 				= 32'h42080000,							// 8.5*4 = 34 in IEEE floating point
	parameter BOUNDING_BOX_Y				= 32'h42080000,
	parameter BOUNDING_BOX_Z				= 32'h42080000,
	parameter HALF_BOUNDING_BOX_X_POS	= 32'h41880000,							// 34/2 = 17 in IEEE floating point
	parameter HALF_BOUNDING_BOX_Y_POS	= 32'h41880000,
	parameter HALF_BOUNDING_BOX_Z_POS	= 32'h41880000,
	parameter HALF_BOUNDING_BOX_X_NEG	= 32'hC1880000,							// -34/2 = -17 in IEEE floating point
	parameter HALF_BOUNDING_BOX_Y_NEG	= 32'hC1880000,
	parameter HALF_BOUNDING_BOX_Z_NEG	= 32'hC1880000,
	//parameter BOUNDING_BOX_X				= 32'h426E0000,							// 8.5*7 = 59.5 in IEEE floating point		//32'h42D80000,							// 12*9 = 108 in IEEE floating point
	//parameter BOUNDING_BOX_Y				= 32'h424C0000,							// 8.5*6 = 51 in IEEE floating point		//32'h42D80000,							// 12*9 = 108 in IEEE floating point
	//parameter BOUNDING_BOX_Z				= 32'h424C0000,							// 8.5*6 = 51 in IEEE floating point		//32'h42A80000,							// 12*7 = 84 in IEEE floating point
	//parameter HALF_BOUNDING_BOX_X_POS 	= 32'h41EE0000,							// 59.5/2 = 29.75 in IEEE floating point
	//parameter HALF_BOUNDING_BOX_Y_POS 	= 32'h41CC0000,							// 51/2 = 25.5 in IEEE floating point
	//parameter HALF_BOUNDING_BOX_Z_POS 	= 32'h41CC0000,							// 51/2 = 25.5 in IEEE floating point
	//parameter HALF_BOUNDING_BOX_X_NEG 	= 32'hC1EE0000,							// -59.5/2 = -29.75 in IEEE floating point
	//parameter HALF_BOUNDING_BOX_Y_NEG 	= 32'hC1CC0000,							// -51/2 = -25.5 in IEEE floating point
	//parameter HALF_BOUNDING_BOX_Z_NEG 	= 32'hC1CC0000,							// -51/2 = -25.5 in IEEE floating point
	// Force Evaluation parameters
	parameter SEGMENT_NUM					= 9,//14,
	parameter SEGMENT_WIDTH					= 4,
	parameter BIN_NUM							= 256,
	parameter BIN_WIDTH						= 8,
	parameter LOOKUP_NUM						= SEGMENT_NUM * BIN_NUM,				// SEGMENT_NUM * BIN_NUM
	parameter LOOKUP_ADDR_WIDTH			= SEGMENT_WIDTH + BIN_WIDTH,			// log LOOKUP_NUM / log 2
	// Force (accmulation) cache parameters
	parameter FORCE_CACHE_BUFFER_DEPTH	= 32,											// Force cache input buffer depth, for partial force accumulation
	parameter FORCE_CACHE_BUFFER_ADDR_WIDTH = 5,										// log(FORCE_CACHE_BUFFER_DEPTH) / log 2
	// Used in cell matching
	parameter BINARY_222							= 9'b010010010,
	parameter BINARY_223							= 9'b010010011,
	parameter BINARY_231							= 9'b010011001,
	parameter BINARY_232							= 9'b010011010,
	parameter BINARY_233							= 9'b010011011,
	parameter BINARY_311							= 9'b011001001,
	parameter BINARY_312							= 9'b011001010,
	parameter BINARY_313							= 9'b011001011,
	parameter BINARY_321							= 9'b011010001,
	parameter BINARY_322							= 9'b011010010,
	parameter BINARY_323							= 9'b011010011,
	parameter BINARY_331							= 9'b011011001,
	parameter BINARY_332							= 9'b011011010,
	parameter BINARY_333							= 9'b011011011,
	// Force Evaluation output to FIFO
	parameter FORCE_EVAL_FIFO_DATA_WIDTH = 113,
	parameter FORCE_EVAL_FIFO_DEPTH = 128,
	parameter FORCE_EVAL_FIFO_ADDR_WIDTH = 7
)
(
	input clk,
	input rst,
	input start,
	
	// These are all temp output ports
/*
	output [NUM_EVAL_UNIT*PARTICLE_ID_WIDTH-1:0] ref_particle_id_1_1,
	output [NUM_EVAL_UNIT*DATA_WIDTH-1:0] ref_LJ_Force_X_1_1,
	output [NUM_EVAL_UNIT*DATA_WIDTH-1:0] ref_LJ_Force_Y_1_1,
	output [NUM_EVAL_UNIT*DATA_WIDTH-1:0] ref_LJ_Force_Z_1_1,
	output [NUM_EVAL_UNIT-1:0] ref_forceoutput_valid_1_1,
	output [NUM_EVAL_UNIT*PARTICLE_ID_WIDTH-1:0] neighbor_particle_id_1_1,
	output [NUM_EVAL_UNIT*DATA_WIDTH-1:0] neighbor_LJ_Force_X_1_1,
	output [NUM_EVAL_UNIT*DATA_WIDTH-1:0] neighbor_LJ_Force_Y_1_1,
	output [NUM_EVAL_UNIT*DATA_WIDTH-1:0] neighbor_LJ_Force_Z_1_1,
	output [NUM_EVAL_UNIT-1:0] neighbor_forceoutput_valid_1_1,
*/
	// Done signals
	// When entire home cell is done processing, this will keep high until the next time 'start' signal turn high
	output out_home_cell_evaluation_done_1_1,
	// When motion update is done processing, remain high until the next motion update starts
	output out_motion_update_done,
	
	// Dummy output for motion update
	output [3*CELL_ID_WIDTH-1:0] out_Motion_Update_cur_cell,
	
	// Output for tests
	output [NUM_PIPELINES-1:0] ref_force_buffer_full, 
	output [NUM_PIPELINES-1:0] neighbor_force_buffer_full_1, 
	output [NUM_PIPELINES-1:0] neighbor_force_buffer_full_2
);
	
	wire [NUM_PIPELINES-1:0] out_home_cell_evaluation_done;
	assign out_home_cell_evaluation_done_1_1 = out_home_cell_evaluation_done[0];
	
	// Force writeback signals
	wire [NUM_PIPELINES-1:0] ref_force_write_success;
	wire [NUM_PIPELINES-1:0] neighbor_force_write_success_1;
	wire [NUM_PIPELINES-1:0] neighbor_force_write_success_2;
	
	// Output from the force FIFOs
	wire [NUM_PIPELINES*FORCE_EVAL_FIFO_DATA_WIDTH-1:0] ref_force_data_from_FIFO;
	wire [NUM_PIPELINES*FORCE_EVAL_FIFO_DATA_WIDTH-1:0] neighbor_force_data_from_FIFO_1;
	wire [NUM_PIPELINES*FORCE_EVAL_FIFO_DATA_WIDTH-1:0] neighbor_force_data_from_FIFO_2;
	wire [NUM_PIPELINES-1:0] ref_force_valid;
	wire [NUM_PIPELINES-1:0] neighbor_force_valid_1;
	wire [NUM_PIPELINES-1:0] neighbor_force_valid_2;
	
	// Input to the pipeline
	wire [NUM_PIPELINES*(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:0] cells_to_pipeline;

	// Output from the pipeline
	wire [NUM_PIPELINES*(NUM_NEIGHBOR_CELLS+1)*CELL_ADDR_WIDTH-1:0] Local_FSM_to_Cell_read_addr;
	wire [NUM_PIPELINES*CELL_ID_WIDTH-1:0] cellz;
	wire [NUM_PIPELINES*(NUM_NEIGHBOR_CELLS+1)-1:0] Local_enable_reading;
	wire [NUM_PIPELINES*(NUM_NEIGHBOR_CELLS+1)-1:0] Cell_to_FSM_read_success_bit;
	
	// Pipelines comm
	wire all_pipelines_done_reading;
	assign all_pipelines_done_reading = (out_home_cell_evaluation_done == {(NUM_PIPELINES){1'b1}}) ? 1'b1 : 1'b0;
	
	wire [NUM_PIPELINES-1:0] Local_Motion_Update_start;
	wire Motion_Update_start;
	assign Motion_Update_start	 = (Local_Motion_Update_start == {(NUM_PIPELINES){1'b1}}) ? 1'b1 : 1'b0;
	
	// Input to the position and velocity caches
	wire Motion_Update_enable;
	wire [3*CELL_ID_WIDTH-1:0] Motion_Update_dst_cell;
	
	wire [CELL_ADDR_WIDTH-1:0] Motion_Update_position_read_addr;
	wire [TOTAL_CELL_NUM*CELL_ADDR_WIDTH-1:0] FSM_to_Cell_read_addr;
	wire [3*DATA_WIDTH-1:0] Motion_Update_out_position_data;
	wire Motion_Update_out_position_data_valid;
	wire Motion_Update_position_read_en;
	wire [TOTAL_CELL_NUM-1:0] enable_reading;
	
	wire [CELL_ADDR_WIDTH-1:0] Motion_Update_velocity_read_addr;
	wire [3*DATA_WIDTH-1:0] Motion_Update_out_velocity_data;
	wire Motion_Update_out_velocity_data_valid;
	wire Motion_Update_velocity_read_en;
	
	// Output from the position and velocity caches
	wire [TOTAL_CELL_NUM*3*DATA_WIDTH-1:0] Position_Cache_readout_position;
	wire [TOTAL_CELL_NUM*3*DATA_WIDTH-1:0] all_Motion_Update_velocity_data;
	
	reg [CELL_ID_WIDTH-1:0] reg_cellz;
	
	wire [TOTAL_CELL_NUM*FORCE_EVAL_FIFO_DATA_WIDTH-1:0] valid_force_values;
	
	always@(posedge clk)
		begin
		if (rst)
			begin
			reg_cellz <= 0;
			end
		else
			reg_cellz <= (all_pipelines_done_reading) ? cellz[CELL_ID_WIDTH-1:0] : reg_cellz;
		end
	
	All_Position_Caches_64_Cells
	#(
		.DATA_WIDTH(DATA_WIDTH),
		.CELL_ID_WIDTH(CELL_ID_WIDTH),
		.TOTAL_CELL_NUM(TOTAL_CELL_NUM),
		.MAX_CELL_PARTICLE_NUM(MAX_CELL_PARTICLE_NUM),
		.CELL_ADDR_WIDTH(CELL_ADDR_WIDTH)
	)
	All_Position_Caches
	(
		.clk(clk),
		.rst(rst),
		.Motion_Update_enable(Motion_Update_enable),
		.Motion_Update_position_read_addr(Motion_Update_position_read_addr),
		.FSM_to_Cell_read_addr(FSM_to_Cell_read_addr),
		.Motion_Update_out_position_data(Motion_Update_out_position_data),
		.Motion_Update_dst_cell(Motion_Update_dst_cell),
		.Motion_Update_out_position_data_valid(Motion_Update_out_position_data_valid),
		.Motion_Update_position_read_en(Motion_Update_position_read_en),
		.FSM_to_Cell_rden(enable_reading),
		
		.Position_Cache_readout_position(Position_Cache_readout_position)
	);
	
	All_Velocity_Caches_64_Cells
	#(
		.DATA_WIDTH(DATA_WIDTH),
		.CELL_ID_WIDTH(CELL_ID_WIDTH),
		.TOTAL_CELL_NUM(TOTAL_CELL_NUM),
		.MAX_CELL_PARTICLE_NUM(MAX_CELL_PARTICLE_NUM),
		.CELL_ADDR_WIDTH(CELL_ADDR_WIDTH)
	)
	All_Velocity_Caches
	(
		.clk(clk),
		.rst(rst),
		.Motion_Update_enable(Motion_Update_enable),
		.Motion_Update_velocity_read_addr(Motion_Update_velocity_read_addr),
		.Motion_Update_out_velocity_data(Motion_Update_out_velocity_data),
		.Motion_Update_dst_cell(Motion_Update_dst_cell),
		.Motion_Update_out_velocity_data_valid(Motion_Update_out_velocity_data_valid),
		.Motion_Update_velocity_read_en(Motion_Update_velocity_read_en),
		
		.Motion_Update_velocity_data(all_Motion_Update_velocity_data)
	);
	
	// Input to the force caches
/*
	wire [TOTAL_CELL_NUM-1:0] to_force_cache_partial_force_valid;
	wire [TOTAL_CELL_NUM*PARTICLE_ID_WIDTH-1:0] to_force_cache_particle_id;
	wire [TOTAL_CELL_NUM*DATA_WIDTH-1:0] to_force_cache_LJ_Force_Z;
	wire [TOTAL_CELL_NUM*DATA_WIDTH-1:0] to_force_cache_LJ_Force_Y;
	wire [TOTAL_CELL_NUM*DATA_WIDTH-1:0] to_force_cache_LJ_Force_X;
*/
	wire [TOTAL_CELL_NUM-1:0] wire_motion_update_to_cache_read_force_request;
	wire [CELL_ADDR_WIDTH-1:0]Motion_Update_force_read_addr;
	
	// Output from the force caches
	wire [TOTAL_CELL_NUM*3*DATA_WIDTH-1:0] all_Motion_Update_force_data;
	wire [TOTAL_CELL_NUM*PARTICLE_ID_WIDTH-1:0] wire_cache_to_motion_update_particle_id;
	wire [TOTAL_CELL_NUM-1:0] wire_cache_to_motion_update_partial_force_valid;
	
	
	All_Force_Caches_64_Cells
	#(
		.DATA_WIDTH(DATA_WIDTH),
		.TOTAL_CELL_NUM(TOTAL_CELL_NUM),
		.FORCE_CACHE_BUFFER_DEPTH(FORCE_CACHE_BUFFER_DEPTH),
		.FORCE_CACHE_BUFFER_ADDR_WIDTH(FORCE_CACHE_BUFFER_ADDR_WIDTH),	
		.CELL_ID_WIDTH(CELL_ID_WIDTH),
		.MAX_CELL_PARTICLE_NUM(MAX_CELL_PARTICLE_NUM),
		.CELL_ADDR_WIDTH(CELL_ADDR_WIDTH),
		.PARTICLE_ID_WIDTH(PARTICLE_ID_WIDTH)
	)
	All_Force_Caches
	(
		.clk(clk),
		.rst(rst),
		/*
		.to_force_cache_partial_force_valid(to_force_cache_partial_force_valid),
		.to_force_cache_particle_id(to_force_cache_particle_id),
		.to_force_cache_LJ_Force_Z(to_force_cache_LJ_Force_Z),
		.to_force_cache_LJ_Force_Y(to_force_cache_LJ_Force_Y),
		.to_force_cache_LJ_Force_X(to_force_cache_LJ_Force_X),
		*/
		.valid_force_values(valid_force_values),
		.wire_motion_update_to_cache_read_force_request(wire_motion_update_to_cache_read_force_request),
		.Motion_Update_force_read_addr(Motion_Update_force_read_addr),
		
		.wire_cache_to_motion_update_partial_force(all_Motion_Update_force_data),
		.wire_cache_to_motion_update_particle_id(wire_cache_to_motion_update_particle_id),
		.wire_cache_to_motion_update_partial_force_valid(wire_cache_to_motion_update_partial_force_valid)
	);
	
	genvar i;
	generate 
		for(i = 0; i < NUM_PIPELINES; i = i + 1) begin: Pipeline
		RL_LJ_Top_64_Cells
		#(
			.DATA_WIDTH(DATA_WIDTH),
			.TIME_STEP(TIME_STEP),
			// The home cell this unit is working on, always (222)
			.CELL_X(4'd2),
			.CELL_Y(4'd2),
			.CELL_Z(4'd2),
			.GLOBAL_CELL_X(4'd1),
			.GLOBAL_CELL_Y(4'd1),
			.X_DIM(X_DIM),
			.Y_DIM(Y_DIM),
			.Z_DIM(Z_DIM),
			.TOTAL_CELL_NUM(TOTAL_CELL_NUM),
			.NUM_EVAL_UNIT(NUM_EVAL_UNIT),
			.MAX_CELL_COUNT_PER_DIM(MAX_CELL_COUNT_PER_DIM),
			.NUM_NEIGHBOR_CELLS(NUM_NEIGHBOR_CELLS),
			.CELL_ID_WIDTH(CELL_ID_WIDTH),
			.MAX_CELL_PARTICLE_NUM(MAX_CELL_PARTICLE_NUM),
			.CELL_ADDR_WIDTH(CELL_ADDR_WIDTH),
			.PARTICLE_ID_WIDTH(PARTICLE_ID_WIDTH),
			// Filter parameters
			.NUM_FILTER(NUM_FILTER),
			.ARBITER_MSB(ARBITER_MSB),
			.FILTER_BUFFER_DEPTH(FILTER_BUFFER_DEPTH),
			.FILTER_BUFFER_ADDR_WIDTH(FILTER_BUFFER_ADDR_WIDTH),
			.CUTOFF_2(CUTOFF_2),
			.CUTOFF_TIMES_SQRT_3(CUTOFF_TIMES_SQRT_3),
			.FIXED_POINT_WIDTH(FIXED_POINT_WIDTH),
			.FILTER_IN_PATCH_0_BITS(FILTER_IN_PATCH_0_BITS),
			// Bounding box parameters, used when applying PBC inside r2 evaluation
			.BOUNDING_BOX_X(BOUNDING_BOX_X),
			.BOUNDING_BOX_Y(BOUNDING_BOX_Y),
			.BOUNDING_BOX_Z(BOUNDING_BOX_Z),
			.HALF_BOUNDING_BOX_X_POS(HALF_BOUNDING_BOX_X_POS),
			.HALF_BOUNDING_BOX_Y_POS(HALF_BOUNDING_BOX_Y_POS),
			.HALF_BOUNDING_BOX_Z_POS(HALF_BOUNDING_BOX_Z_POS),
			.HALF_BOUNDING_BOX_X_NEG(HALF_BOUNDING_BOX_X_NEG),
			.HALF_BOUNDING_BOX_Y_NEG(HALF_BOUNDING_BOX_Y_NEG),
			.HALF_BOUNDING_BOX_Z_NEG(HALF_BOUNDING_BOX_Z_NEG),
			// Force Evaluation parameters
			.SEGMENT_NUM(SEGMENT_NUM),
			.SEGMENT_WIDTH(SEGMENT_WIDTH),
			.BIN_NUM(BIN_NUM),
			.BIN_WIDTH(BIN_WIDTH),
			.LOOKUP_NUM(LOOKUP_NUM),
			.LOOKUP_ADDR_WIDTH(LOOKUP_ADDR_WIDTH),
			// Force (accmulation) cache parameters
			.FORCE_CACHE_BUFFER_DEPTH(FORCE_CACHE_BUFFER_DEPTH),
			.FORCE_CACHE_BUFFER_ADDR_WIDTH(FORCE_CACHE_BUFFER_ADDR_WIDTH),
			// Force Evaluation output to FIFO
			.FORCE_EVAL_FIFO_DATA_WIDTH(FORCE_EVAL_FIFO_DATA_WIDTH),
			.FORCE_EVAL_FIFO_DEPTH(FORCE_EVAL_FIFO_DEPTH),
			.FORCE_EVAL_FIFO_ADDR_WIDTH(FORCE_EVAL_FIFO_ADDR_WIDTH)
		)
		RL_LJ_Top_64_Cells
		(
			.clk(clk),
			.rst(rst),
			.start(start),
			.from_cells_particle_info(cells_to_pipeline[(i+1)*(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH-1:i*(NUM_NEIGHBOR_CELLS+1)*3*DATA_WIDTH]),
			.Cell_to_FSM_read_success_bit(Cell_to_FSM_read_success_bit[(i+1)*(NUM_NEIGHBOR_CELLS+1)-1:i*(NUM_NEIGHBOR_CELLS+1)]),
			// From motion update
			.motion_update_done(out_motion_update_done),
			//From other pipelines
			.all_pipelines_done_reading(all_pipelines_done_reading),	
			// From force cache arbiters
			.ref_force_write_success(ref_force_write_success[i]),
			.neighbor_force_write_success_1(neighbor_force_write_success_1[i]),
			.neighbor_force_write_success_2(neighbor_force_write_success_2[i]),
			
			// To force caches
			.ref_force_data_from_FIFO(ref_force_data_from_FIFO[(i+1)*FORCE_EVAL_FIFO_DATA_WIDTH-1:i*FORCE_EVAL_FIFO_DATA_WIDTH]),
			.neighbor_force_data_from_FIFO_1(neighbor_force_data_from_FIFO_1[(i+1)*FORCE_EVAL_FIFO_DATA_WIDTH-1:i*FORCE_EVAL_FIFO_DATA_WIDTH]),
			.neighbor_force_data_from_FIFO_2(neighbor_force_data_from_FIFO_2[(i+1)*FORCE_EVAL_FIFO_DATA_WIDTH-1:i*FORCE_EVAL_FIFO_DATA_WIDTH]),
			.ref_force_buffer_full(ref_force_buffer_full[i]),
			.neighbor_force_buffer_full_1(neighbor_force_buffer_full_1[i]),
			.neighbor_force_buffer_full_2(neighbor_force_buffer_full_2[i]),
			.ref_force_valid(ref_force_valid[i]),
			.neighbor_force_valid_1(neighbor_force_valid_1[i]),
			.neighbor_force_valid_2(neighbor_force_valid_2[i]),
			// pair gen done signals
			.out_home_cell_evaluation_done(out_home_cell_evaluation_done[i]),
			// To caches
			.cellz(cellz[(i+1)*CELL_ID_WIDTH-1:i*CELL_ID_WIDTH]),
			.out_FSM_to_cell_read_addr(Local_FSM_to_Cell_read_addr[(i+1)*(NUM_NEIGHBOR_CELLS+1)*CELL_ADDR_WIDTH-1:i*(NUM_NEIGHBOR_CELLS+1)*CELL_ADDR_WIDTH]),
			.enable_reading(Local_enable_reading[(i+1)*(NUM_NEIGHBOR_CELLS+1)-1:i*(NUM_NEIGHBOR_CELLS+1)]),
			// To motion update
			.out_Motion_Update_start(Local_Motion_Update_start[i])
		);
		end
	endgenerate

	
	// Input to Motion Update
	wire [3*DATA_WIDTH-1:0] Motion_Update_position_data;
	wire [3*DATA_WIDTH-1:0] Motion_Update_velocity_data;
	wire [3*DATA_WIDTH-1:0] Motion_Update_force_data;
	
	// Output from Motion Update
	wire [GLOBAL_CELL_ADDR_LEN-1:0] cell_being_updated_id;
	
	Motion_Update_64_Cells
	#(
		.DATA_WIDTH(DATA_WIDTH),
		.TIME_STEP(TIME_STEP),
		.GLOBAL_CELL_ADDR_LEN(GLOBAL_CELL_ADDR_LEN),
		.X_DIM(X_DIM),
		.Y_DIM(Y_DIM),
		.Z_DIM(Z_DIM),
		.TOTAL_CELL_NUM(TOTAL_CELL_NUM),
		.MAX_CELL_COUNT_PER_DIM(MAX_CELL_COUNT_PER_DIM),
		.CELL_ID_WIDTH(CELL_ID_WIDTH),
		.MAX_CELL_PARTICLE_NUM(MAX_CELL_PARTICLE_NUM),
		.CELL_ADDR_WIDTH(CELL_ADDR_WIDTH),
		.PARTICLE_ID_WIDTH(PARTICLE_ID_WIDTH)
	)
	Motion_Update
	(
		.clk(clk),
		.rst(rst),
		.motion_update_start(Motion_Update_start),					// Start Motion update after the home cell is done evaluating
		.motion_update_done(out_motion_update_done),					// Remain high until the next motion update starts
		// Output the targeting home cell
		// When this module is responsible for multiple cells, then the control signal is broadcast to multiple cells, while a mux need to implement on the input side to select from those cells
		.out_cur_working_cell_x(out_Motion_Update_cur_cell[3*CELL_ID_WIDTH-1:2*CELL_ID_WIDTH]),
		.out_cur_working_cell_y(out_Motion_Update_cur_cell[2*CELL_ID_WIDTH-1:1*CELL_ID_WIDTH]),
		.out_cur_working_cell_z(out_Motion_Update_cur_cell[1*CELL_ID_WIDTH-1:0*CELL_ID_WIDTH]),
		// Read from Position Cache
		.in_position_data(Motion_Update_position_data),
		.out_position_cache_rd_en(Motion_Update_position_read_en),
		.out_position_cache_rd_addr(Motion_Update_position_read_addr),
		// Read from Force Cache
		.in_force_data(Motion_Update_force_data),
		.out_force_cache_rd_en(Motion_Update_force_read_en),
		.out_force_cache_rd_addr(Motion_Update_force_read_addr),
		// Read from Velocity Cache
		.in_velocity_data(Motion_Update_velocity_data),
		.out_velocity_cache_rd_en(Motion_Update_velocity_read_en),
		.out_velocity_cache_rd_addr(Motion_Update_velocity_read_addr),
		// Motion update enable signal
		.out_motion_update_enable(Motion_Update_enable),		// Remain high during the entire motion update process
		// Write back to Velocity Cache
		.out_velocity_data(Motion_Update_out_velocity_data),
		.out_velocity_data_valid(Motion_Update_out_velocity_data_valid),
		.out_velocity_destination_cell(Motion_Update_dst_cell),
		// Write back to Position Cache
		.out_position_data(Motion_Update_out_position_data),
		.out_position_data_valid(Motion_Update_out_position_data_valid),
		.out_position_destination_cell(),
		.out_cell_num(cell_being_updated_id)
	);
	
	Local_global_mapping
	#(
		.NUM_PIPELINES(NUM_PIPELINES),
		.NUM_NEIGHBOR_CELLS(NUM_NEIGHBOR_CELLS),
		.CELL_ADDR_WIDTH(CELL_ADDR_WIDTH),
		.CELL_ID_WIDTH(CELL_ID_WIDTH),
		.NUM_FILTER(NUM_FILTER),
		.RDADDR_ARBITER_SIZE(RDADDR_ARBITER_SIZE),
		.RDADDR_ARBITER_MSB(RDADDR_ARBITER_MSB),
		.TOTAL_CELL_NUM(TOTAL_CELL_NUM),
		.DATA_WIDTH(DATA_WIDTH)
	)
	Local_global_mapping
	(
		.clk(clk),
		.rst(rst),
		.cellz(reg_cellz),
		.Local_FSM_to_Cell_read_addr(Local_FSM_to_Cell_read_addr),
		.Local_enable_reading(Local_enable_reading),
		.Position_Cache_readout_position(Position_Cache_readout_position),
		
		.enable_reading(enable_reading),
		.FSM_to_Cell_read_addr(FSM_to_Cell_read_addr),
		.Cell_to_FSM_read_success_bit(Cell_to_FSM_read_success_bit),
		.cells_to_pipeline(cells_to_pipeline)
	);
	
	Motion_Update_input_selector
	#(
		.DATA_WIDTH(DATA_WIDTH),
		.GLOBAL_CELL_ADDR_LEN(GLOBAL_CELL_ADDR_LEN),
		.TOTAL_CELL_NUM(TOTAL_CELL_NUM)
	)
	Motion_Update_input_selector
	(
		.clk(clk),
		.rst(rst),
		.cell_being_updated_id(cell_being_updated_id),
		.all_Motion_Update_velocity_data(all_Motion_Update_velocity_data),
		.all_Motion_Update_position_data(Position_Cache_readout_position),
		.all_Motion_Update_force_data(all_Motion_Update_force_data),
		.Motion_Update_enable(Motion_Update_enable),
		
		.motion_update_to_cache_read_force_request(wire_motion_update_to_cache_read_force_request),
		.Motion_Update_velocity_data(Motion_Update_velocity_data),
		.Motion_Update_position_data(Motion_Update_position_data),
		.Motion_Update_force_data(Motion_Update_force_data)
	);
	
	Force_Writeback_Arbitration_Unit
	#(
		.BINARY_222(BINARY_222),
		.BINARY_223(BINARY_223),
		.BINARY_231(BINARY_231),
		.BINARY_232(BINARY_232),
		.BINARY_233(BINARY_233),
		.BINARY_311(BINARY_311),
		.BINARY_312(BINARY_312),
		.BINARY_313(BINARY_313),
		.BINARY_321(BINARY_321),
		.BINARY_322(BINARY_322),
		.BINARY_323(BINARY_323),
		.BINARY_331(BINARY_331),
		.BINARY_332(BINARY_332),
		.BINARY_333(BINARY_333),
		.NUM_PIPELINES(NUM_PIPELINES),
		.DATA_WIDTH(DATA_WIDTH),
		.CELL_ID_WIDTH(CELL_ID_WIDTH),
		.CELL_ADDR_WIDTH(CELL_ADDR_WIDTH),
		.TOTAL_CELL_NUM(TOTAL_CELL_NUM),
		.PARTICLE_ID_WIDTH(PARTICLE_ID_WIDTH),
		.FORCE_WTADDR_ARBITER_SIZE(FORCE_WTADDR_ARBITER_SIZE),
		.FORCE_WTADDR_ARBITER_MSB(FORCE_WTADDR_ARBITER_MSB),
		.FORCE_EVAL_FIFO_DATA_WIDTH(FORCE_EVAL_FIFO_DATA_WIDTH),
		.FORCE_EVAL_FIFO_DEPTH(FORCE_EVAL_FIFO_DEPTH),
		.FORCE_EVAL_FIFO_ADDR_WIDTH(FORCE_EVAL_FIFO_ADDR_WIDTH)
	)
	Force_Writeback_Arbitration_Unit
	(
		.clk(clk),
		.rst(rst),
		.ref_force_data_from_FIFO(ref_force_data_from_FIFO),
		.neighbor_force_data_from_FIFO_1(neighbor_force_data_from_FIFO_1),
		.neighbor_force_data_from_FIFO_2(neighbor_force_data_from_FIFO_2),
		.ref_force_valid(ref_force_valid),
		.neighbor_force_valid_1(neighbor_force_valid_1),
		.neighbor_force_valid_2(neighbor_force_valid_2),
		.cellz(reg_cellz),
		
		.ref_force_write_success(ref_force_write_success),
		.neighbor_force_write_success_1(neighbor_force_write_success_1),
		.neighbor_force_write_success_2(neighbor_force_write_success_2),
		.valid_force_values(valid_force_values)
	);
endmodule