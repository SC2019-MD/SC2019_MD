/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: Force_Write_Back_Controller.v

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module Force_Write_Back_Controller
#(
	parameter DATA_WIDTH 					= 32,											// Data width of a single force value, 32-bit
	// Cell id this unit related to
	parameter CELL_X							= 2,
	parameter CELL_Y							= 2,
	parameter CELL_Z							= 2,
	// Force cache input buffer
	parameter FORCE_CACHE_BUFFER_DEPTH	= 16,											// Force cache input buffer depth, for partial force accumulation
	parameter FORCE_CACHE_BUFFER_ADDR_WIDTH = 4,										// log(FORCE_CACHE_BUFFER_DEPTH) / log 2
	// Dataset defined parameters
	parameter CELL_ID_WIDTH					= 4,
	parameter MAX_CELL_PARTICLE_NUM		= 290,										// The maximum # of particles can be in a cell
	parameter CELL_ADDR_WIDTH				= 9,											// log(MAX_CELL_PARTICLE_NUM)
	parameter PARTICLE_ID_WIDTH			= CELL_ID_WIDTH*3+CELL_ADDR_WIDTH	// # of bit used to represent particle ID, 9*9*7 cells, each 4-bit, each cell have max of 220 particles, 8-bit
)
(
	input  clk,
	input  rst,
	// Cache input force
	input  in_partial_force_valid,
	input  [PARTICLE_ID_WIDTH-1:0] in_particle_id,
	input  [3*DATA_WIDTH-1:0] in_partial_force,
	// Cache output force
	input  in_read_data_request,																	// Enables read data from the force cache, if this signal is high, then no write operation is permitted
	input  [CELL_ADDR_WIDTH-1:0] in_cache_read_address,
	output reg [3*DATA_WIDTH-1:0] out_partial_force,
	output reg [PARTICLE_ID_WIDTH-1:0] out_particle_id,
	output reg out_cache_readout_valid
);

	//// Delay registers
	// Conpensate for the 2 cycle delay between read request is issued and data read out from Force_Cache: Cycle 1: Read address registered to cache_rd_address; Cycle 2: Data read out
	reg in_read_data_request_reg1;
	reg delay_in_read_data_request;
	reg [CELL_ADDR_WIDTH-1:0] in_cache_read_address_reg1;
	reg [CELL_ADDR_WIDTH-1:0] delay_in_cache_read_address;
	// Delay the write enable signal by 4 cycles: 1 cycle for assigning read address, 1 cycle for fetching data from cache, 2 cycles for waiting addition finish
	reg cache_write_enable_reg1;
	reg cache_write_enable_reg2;
	reg cache_write_enable_reg3;
	reg delay_cache_write_enable;
	// Delay the cache write address by 4 cycles: 1 cycle for assigning read address, 1 cycle for fetching data from cache, 2 cycles for waiting addition finish
	reg [CELL_ADDR_WIDTH-1:0] cache_wr_address_reg1;
	reg [CELL_ADDR_WIDTH-1:0] cache_wr_address_reg2;
	reg [CELL_ADDR_WIDTH-1:0] cache_wr_address_reg3;
	reg [CELL_ADDR_WIDTH-1:0] delay_cache_wr_address;
	// Delay the input particle information by one cycle to conpensating the one cycle delay to read from input FIFO
	reg [CELL_ADDR_WIDTH-1:0] delay_particle_address;
	reg [3*DATA_WIDTH-1:0] delay_in_partial_force;
	// Delay the control signal derived from the input information by one cycle
	reg delay_input_matching;
	reg delay_input_buffer_empty;
	// Delay the input to accumulator by one cycle to conpensate the one cycle delay to read previous data from force cache
	reg [3*DATA_WIDTH-1:0] delay_partial_force_to_accumulator;
	

	//// Registers recording the active particles that is currently being accumulated (6 stage -> Cycle 1: Determine the ID (either from input or input FIFO); Cycle 2: read out current force; Cycle 3-5: accumulation; Cycle 6: write back force)
	// If the new incoming forces requires to accumulate to a particle that is being processed in the pipeline, then need to push this new incoming force into a FIFO, until the accumulated force is write back into the force cache
	reg [CELL_ADDR_WIDTH-1:0] active_particle_address;
	reg [CELL_ADDR_WIDTH-1:0] active_particle_address_reg1;
	reg [CELL_ADDR_WIDTH-1:0] active_particle_address_reg2;
	reg [CELL_ADDR_WIDTH-1:0] active_particle_address_reg3;
	reg [CELL_ADDR_WIDTH-1:0] active_particle_address_reg4;
	reg [CELL_ADDR_WIDTH-1:0] active_particle_address_reg5;

	
	//// Signals connected to force input buffer
	wire input_buffer_wr_en, input_buffer_rd_en;
	wire input_buffer_empty, input_buffer_full;
	wire [CELL_ADDR_WIDTH+3*DATA_WIDTH-1:0] input_buffer_readout_data;

	//// Signals derived from input
	// Extract the current cell id
	wire [CELL_ID_WIDTH-1:0] cur_cell_x, cur_cell_y, cur_cell_z;
	assign cur_cell_x = CELL_X;
	assign cur_cell_y = CELL_Y;
	assign cur_cell_z = CELL_Z;
	// Extract the cell id from the incoming particle id
	wire [CELL_ID_WIDTH-1:0] particle_cell_x, particle_cell_y, particle_cell_z;
	assign {particle_cell_x, particle_cell_y, particle_cell_z} = in_particle_id[PARTICLE_ID_WIDTH-1:PARTICLE_ID_WIDTH-3*CELL_ID_WIDTH];
	// Extract the particle read address from the incoming partile id
	wire [CELL_ADDR_WIDTH-1:0] particle_address;
	assign particle_address = in_particle_id[CELL_ADDR_WIDTH-1:0];
	// Determine if the input is targeting this cell
	wire input_matching;
	assign input_matching = in_partial_force_valid && particle_cell_x == CELL_X && particle_cell_y == CELL_Y && particle_cell_z == CELL_Z;
	// Determine if the input requires particle that is being processed when making the selection between FIFO output or input to send down for processing
	// Note: when making the occupied decision, use the delayed input information
	wire particle_occupied;
	assign particle_occupied = (delay_particle_address == active_particle_address) || (delay_particle_address == active_particle_address_reg1) || (delay_particle_address == active_particle_address_reg2) || (delay_particle_address == active_particle_address_reg3) || (delay_particle_address == active_particle_address_reg4) || (delay_particle_address == active_particle_address_reg5);
	// Determine if the input buffer output requires particle that is being processed when making the selection between FIFO output or input to send down for processing
	wire [CELL_ADDR_WIDTH-1:0] input_buffer_out_particle_address;
	assign input_buffer_out_particle_address = input_buffer_readout_data[CELL_ADDR_WIDTH+3*DATA_WIDTH-1:3*DATA_WIDTH];
	wire input_buffer_out_particle_occupied;
	assign input_buffer_out_particle_occupied = (input_buffer_out_particle_address == active_particle_address) || (input_buffer_out_particle_address == active_particle_address_reg1) || (input_buffer_out_particle_address == active_particle_address_reg2) || (input_buffer_out_particle_address == active_particle_address_reg3) || (input_buffer_out_particle_address == active_particle_address_reg4) || (input_buffer_out_particle_address == active_particle_address_reg5);
	
	//// Signals for controlling Force_Cache
	reg  [CELL_ADDR_WIDTH-1:0] cache_rd_address;										// Connect directly to Force_Cache
	reg  [CELL_ADDR_WIDTH-1:0] cache_wr_address;										// Delay for 4 cycles and connect to Force_Cache
	wire  [3*DATA_WIDTH-1:0] cache_write_data;										// Connect to accumulator output and direct send to Force_Cache
	reg  cache_write_enable;																// Delay for 4 cycles and connect to Force_Cache
	wire [3*DATA_WIDTH-1:0] cache_readout_data;										// Send the read out data from Force_Cache to Accumulator input
	
	//// Signals connected to accumulator
	// The input to force accumulator
	reg [3*DATA_WIDTH-1:0] partial_force_to_accumulator;
	
	
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Input FIFO control logic
	// Assign the read enable when: data in FIFO && current output is not valid
	// If the input is not valid or matching the cell, assign the the read enable if there are data inside FIFO
	//	If the input is valid, but the request data is in process, then write to FIFO
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// FIFO output valid
	// Set this flag when FIFO one cycle after rd_en is set
	// Clear this flag when FIFO output is taken by partial_force_to_accumulator
	reg input_buffer_read_valid;
	// Input FIFO rd & wr control
	assign input_buffer_wr_en = (delay_input_matching && particle_occupied) ? 1'b1 : 1'b0;
	assign input_buffer_rd_en = (~input_buffer_read_valid && ~input_buffer_empty) ? 1'b1 : 1'b0;
		
	
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Force Cache Controller
	// Since there is a 3 cycle latency for the adder, when there is a particle force being accumulated, while new forces for the same particle arrive, need to wait
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	always@(posedge clk)
		if(rst)
			begin
			// Delay registers
			// For assigning the read out valid
			in_read_data_request_reg1 <= 1'b0;
			delay_in_read_data_request <= 1'b0;
			in_cache_read_address_reg1 <= {(CELL_ADDR_WIDTH){1'b0}};
			delay_in_cache_read_address <= {(CELL_ADDR_WIDTH){1'b0}};
			// For conpensating the 4 cycles delay from write enable is assigned and accumulated value is calculated
			cache_write_enable_reg1 <= 1'b0;
			cache_write_enable_reg2 <= 1'b0;
			cache_write_enable_reg3 <= 1'b0;
			delay_cache_write_enable <= 1'b0;
			// For conpensating the 4 cycles delay from write address is generated and accumulated value is calculated
			cache_wr_address_reg1 <= {(CELL_ADDR_WIDTH){1'b0}};
			cache_wr_address_reg2 <= {(CELL_ADDR_WIDTH){1'b0}};
			cache_wr_address_reg3 <= {(CELL_ADDR_WIDTH){1'b0}};
			delay_cache_wr_address <= {(CELL_ADDR_WIDTH){1'b0}};
			// For conpensating the one cycle delay to read from input FIFO, delay the input particle information by one cycle
			delay_particle_address <= {(CELL_ADDR_WIDTH){1'b0}};
			delay_in_partial_force <= {(3*DATA_WIDTH){1'b0}};
			// For conpensating the one cycle delay to read from input FIFO, delay the control signal derived from the input information by one cycle
			delay_input_matching <= 1'b0;
			delay_input_buffer_empty <= 1'b1;
			// For conpensating the one cycle delay of reading the previous value from force cache
			delay_partial_force_to_accumulator <= {(3*DATA_WIDTH){1'b1}};
			// For registering the active particles in the pipeline
			active_particle_address <= {(CELL_ADDR_WIDTH){1'b0}};
			active_particle_address_reg1 <= {(CELL_ADDR_WIDTH){1'b0}};
			active_particle_address_reg2 <= {(CELL_ADDR_WIDTH){1'b0}};
			active_particle_address_reg3 <= {(CELL_ADDR_WIDTH){1'b0}};
			active_particle_address_reg4 <= {(CELL_ADDR_WIDTH){1'b0}};
			active_particle_address_reg5 <= {(CELL_ADDR_WIDTH){1'b0}};
			
			// Read output ports
			out_partial_force <= {(3*DATA_WIDTH){1'b0}};
			out_particle_id <= {(PARTICLE_ID_WIDTH){1'b0}};
			out_cache_readout_valid <= 1'b0;
			// Cache control signals
			cache_rd_address <= {(CELL_ADDR_WIDTH){1'b0}};
			cache_wr_address <= {(CELL_ADDR_WIDTH){1'b0}};
			cache_write_enable <= 1'b0;
			// Input to force accumulator
			partial_force_to_accumulator <= {(3*DATA_WIDTH){1'b0}};
			// FIFO read valid flag
			input_buffer_read_valid <= 1'b0;
			end
		else
			begin
			//// Delay registers
			// For assigning the read out valid
			in_read_data_request_reg1 <= in_read_data_request;
			delay_in_read_data_request <= in_read_data_request_reg1;
			in_cache_read_address_reg1 <= in_cache_read_address;
			delay_in_cache_read_address <= in_cache_read_address_reg1;
			// For conpensating the 3 cycles delay from write enable is assigned and accumulated value is calculated
			cache_write_enable_reg1 <= cache_write_enable;
			cache_write_enable_reg2 <= cache_write_enable_reg1;
			cache_write_enable_reg3 <= cache_write_enable_reg2;
			delay_cache_write_enable <= cache_write_enable_reg3;
			// For conpensating the 3 cycles delay from write address is generated and accumulated value is calculated
			cache_wr_address_reg1 <= cache_wr_address;
			cache_wr_address_reg2 <= cache_wr_address_reg1;
			cache_wr_address_reg3 <= cache_wr_address_reg2;
			delay_cache_wr_address <= cache_wr_address_reg3;
			/// For conpensating the one cycle delay to read from input FIFO, delay the input particle information by one cycle
			delay_particle_address <= particle_address;
			delay_in_partial_force <= in_partial_force;
			// For conpensating the one cycle delay to read from input FIFO, delay the control signal derived from the input information by one cycle
			delay_input_matching <= input_matching;
			delay_input_buffer_empty <= input_buffer_empty;
			// For conpensating the one cycle delay of reading the previous value from force cache
			delay_partial_force_to_accumulator <= partial_force_to_accumulator;
			// For registering the active particles in the pipeline
			active_particle_address_reg1 <= active_particle_address;
			active_particle_address_reg2 <= active_particle_address_reg1;
			active_particle_address_reg3 <= active_particle_address_reg2;
			active_particle_address_reg4 <= active_particle_address_reg3;
			active_particle_address_reg5 <= active_particle_address_reg4;
			
			//// Priority grant to read request (usually read enable need to keep low during force evaluation process)
			// if outside read request set, then no write activity is permitted
			// There are 2 cycles delay between read request is assigned and force value is read out, thus keep the read_request state for 2 extra cycles after the in_read_data_request is cleared
			if(in_read_data_request || in_read_data_request_reg1 || delay_in_read_data_request)
				begin
				// Active particle id for data dependence detection
				active_particle_address <= 0;
				// Read output ports
				out_partial_force <= cache_readout_data;
				out_particle_id <= {cur_cell_x,cur_cell_y,cur_cell_z,delay_in_cache_read_address};
				out_cache_readout_valid <= delay_in_read_data_request;
				// Cache control signals
				cache_rd_address <= in_cache_read_address;
				cache_wr_address <= {(CELL_ADDR_WIDTH){1'b0}};
				cache_write_enable <= 1'b0;
				// Input to force accumulator
				partial_force_to_accumulator <= {(3*DATA_WIDTH){1'b0}};
				// FIFO read valid flag
				input_buffer_read_valid <= 1'b0;
				end
			//// Accumulation and write into force memory
			else
				begin
				// During force accumulation period, output the data that is being written into the memory
				out_partial_force <= cache_write_data;
				out_particle_id <= {cur_cell_x,cur_cell_y,cur_cell_z,delay_cache_wr_address};
				out_cache_readout_valid <= 1'b0;
				// If the input is valid and not being processed, then process the input
				if(delay_input_matching && ~particle_occupied)
					begin
					// Active particle id for data dependence detection
					active_particle_address <= delay_particle_address;
					// Cache control signal
					cache_rd_address <= delay_particle_address;
					cache_wr_address <= delay_particle_address;
					cache_write_enable <= 1'b1;
					// Input to force accumulator 
					partial_force_to_accumulator <= delay_in_partial_force;
					// FIFO read valid flag
					// When FIFO rd_en is set, set this flag as high
					if(input_buffer_rd_en)
						input_buffer_read_valid <= 1'b1;
					else
						input_buffer_read_valid <= input_buffer_read_valid;
					end
				// If the input is not valid, or the input is valid but requested particle is being processed, then process particle from the input buffer
				else if(~input_buffer_out_particle_occupied && input_buffer_read_valid && (~delay_input_matching || (delay_input_matching && particle_occupied)))
//				else if(~input_buffer_out_particle_occupied && input_buffer_read_valid && ~delay_input_matching)
					begin
					// Active particle id for data dependence detection
					active_particle_address <= input_buffer_readout_data[CELL_ADDR_WIDTH+3*DATA_WIDTH-1:3*DATA_WIDTH];
					// Cache control signal
					cache_rd_address <= input_buffer_readout_data[CELL_ADDR_WIDTH+3*DATA_WIDTH-1:3*DATA_WIDTH];
					cache_wr_address <= input_buffer_readout_data[CELL_ADDR_WIDTH+3*DATA_WIDTH-1:3*DATA_WIDTH];
					cache_write_enable <= 1'b1;
					// Input to force accumulator 
					partial_force_to_accumulator <= input_buffer_readout_data[3*DATA_WIDTH-1:0];
					// FIFO read valid flag
					// When FIFO output is taken, clear this flag
					input_buffer_read_valid <= 1'b0;
					end
				else
					begin
					// Active particle id for data dependence detection
					active_particle_address <= {(CELL_ADDR_WIDTH){1'b0}};
					// Cache control signal
					cache_rd_address <= {(CELL_ADDR_WIDTH){1'b0}};
					cache_wr_address <= {(CELL_ADDR_WIDTH){1'b0}};
					cache_write_enable <= 1'b0;
					// Input to force accumulator
					partial_force_to_accumulator <= {(3*DATA_WIDTH){1'b0}};
					// FIFO read valid flag
					// When FIFO rd_en is set, set this flag as high
					if(input_buffer_rd_en)
						input_buffer_read_valid <= 1'b1;
					else
						input_buffer_read_valid <= input_buffer_read_valid;
					end
				end
			end
	
	////////////////////////////////////////////////////////////////////////////////////////////////
	// Force Accumulator
	////////////////////////////////////////////////////////////////////////////////////////////////
	// Force_X Accumulator
	FP_ADD Force_X_Acc(
		.clk(clk),
		.ena(1'b1),
		.clr(rst),
		.ax(cache_readout_data[1*DATA_WIDTH-1:0*DATA_WIDTH]),
		.ay(delay_partial_force_to_accumulator[1*DATA_WIDTH-1:0*DATA_WIDTH]),
		.result(cache_write_data[1*DATA_WIDTH-1:0*DATA_WIDTH])
	);
	
	// Force_Y Accumulator
	FP_ADD Force_Y_Acc(
		.clk(clk),
		.ena(1'b1),
		.clr(rst),
		.ax(cache_readout_data[2*DATA_WIDTH-1:1*DATA_WIDTH]),
		.ay(delay_partial_force_to_accumulator[2*DATA_WIDTH-1:1*DATA_WIDTH]),
		.result(cache_write_data[2*DATA_WIDTH-1:1*DATA_WIDTH])
	);
	
	// Force_Z Accumulator
	FP_ADD Force_Z_Acc(
		.clk(clk),
		.ena(1'b1),
		.clr(rst),
		.ax(cache_readout_data[3*DATA_WIDTH-1:2*DATA_WIDTH]),
		.ay(delay_partial_force_to_accumulator[3*DATA_WIDTH-1:2*DATA_WIDTH]),
		.result(cache_write_data[3*DATA_WIDTH-1:2*DATA_WIDTH])
	);

	////////////////////////////////////////////////////////////////////////////////////////////////
	// Force Cache
	////////////////////////////////////////////////////////////////////////////////////////////////
	// Dual port ram
	force_cache
	#(
		.DATA_WIDTH(DATA_WIDTH*3),
		.PARTICLE_NUM(MAX_CELL_PARTICLE_NUM),
		.ADDR_WIDTH(CELL_ADDR_WIDTH)
	)
	force_cache
	(
		.clock(clk),
		.data(cache_write_data),
		.rdaddress(cache_rd_address),
		.wraddress(delay_cache_wr_address),
		.wren(delay_cache_write_enable),
		.q(cache_readout_data)
	);
	
	////////////////////////////////////////////////////////////////////////////////////////////////
	// Force Input Buffer
	// Handles data dependency
	////////////////////////////////////////////////////////////////////////////////////////////////
	Force_Cache_Input_Buffer
	#(
		.DATA_WIDTH(CELL_ADDR_WIDTH+3*DATA_WIDTH),								// hold particle ID and force value
		.BUFFER_DEPTH(FORCE_CACHE_BUFFER_DEPTH),
		.BUFFER_ADDR_WIDTH(FORCE_CACHE_BUFFER_ADDR_WIDTH)						// log(BUFFER_DEPTH) / log 2
	)
	Force_Cache_Input_Buffer
	(
		 .clock(clk),
		 .data({delay_particle_address, delay_in_partial_force}),
		 .rdreq(input_buffer_rd_en),
		 .wrreq(input_buffer_wr_en),
		 .empty(input_buffer_empty),
		 .full(input_buffer_full),
		 .q(input_buffer_readout_data),
		 .usedw()
	);

endmodule