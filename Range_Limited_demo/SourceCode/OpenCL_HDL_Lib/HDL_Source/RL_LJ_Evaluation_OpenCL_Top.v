/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: RL_LJ_Evaluation_OpenCL_Top.v
//
//	Function: 
//				Top module for OpenCL evaluation.
//				Contains a single filter_logic unit (with buffer) and a single LJ Evaluation Pipeline.
//
// OpenCL HDL Lib setup:
//				Stall-Free: No. Since there is a filter logic, there's no guarantee a valid output appear on the output port after a fixed amount of cycles from input.
//				Interacting with OpenCL control ports: Input and Output buffer
//
// OpenCL Ports clarification:
//				Connect to upstream: ivalid(input), oready(output)
//				Connect to downstream: iready(input), ovalid(output)
//				When ivalid = 1 and oready = 0, the upstream module is expected to hold the values of ivalid, A, and B in the next clock cycle.
//				When ovalid = 1 and iready = 0, the myMod RLT module is expected to hold the valid of the ovalid and C signals in the next clock cycle.
//				myMod module will assert oready for a single clock cycle to indicate it is ready for an active cycle. Cycles during which myMod module is ready for data are called ready cycles. During ready cycles, the module above myMod module can assert ivalid to send data to myMod.
//
//	Purpose:
//				OpenCL HDL library testing
//
// Data Organization:
//				Filter buffer: MSB-LSB: {ref_particle_id, neighbor_particle_id, r2, dz, dy, dx}
//				Input buffer: MSB-LSB: {ref_particle_id, neighbor_particle_id, refx, refy, refz, neighborx, neighbory, neighborz}
//				Output buffer: MSB-LSB: {ref_particle_id, neighbor_particle_id, LJ_Force_X, LJ_Force_Y, LJ_Force_Z}
//
// Used by:
//				N/A
//
// Dependency:
//				Filter_Logic.v
//				RL_LJ_Evaluate_Pairs_1st_Order.v
//
// Testbench:
//				TBD
//
// Timing:
//				RL_LJ_Evaluate_Pairs_1st_Order: 14 cycles
//				r2_compute inside Filter_Logic: 17 cycles				
//
// Created by: 
//				Chen Yang 12/09/18
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module RL_LJ_Evaluation_OpenCL_Top
#(
	parameter DATA_WIDTH 					= 32,
	// Dataset defined parameters
	parameter CELL_ID_WIDTH					= 4,											// log(NUM_NEIGHBOR_CELLS)
	parameter MAX_CELL_PARTICLE_NUM		= 290,										// The maximum # of particles can be in a cell
	parameter CELL_ADDR_WIDTH				= 9,											// log(MAX_CELL_PARTICLE_NUM)
	parameter PARTICLE_ID_WIDTH			= CELL_ID_WIDTH*3+CELL_ADDR_WIDTH,	// # of bit used to represent particle ID, 9*9*7 cells, each 4-bit, each cell have max of 200 particles, 8-bit
	// In & Out buffer parameters
	parameter INPUT_BUFFER_DEPTH			= 4,
	parameter INPUT_BUFFER_ADDR_WIDTH	= 2,											// log INPUT_BUFFER_DEPTH / log 2
	parameter OUTPUT_BUFFER_DEPTH			= 64,											// This one should be large enough to hold all the values in the pipeline 
	parameter OUTPUT_BUFFER_ADDR_WIDTH	= 6,											// log OUTPUT_BUFFER_DEPTH / log 2
	// Filter parameters
	parameter FILTER_BUFFER_DEPTH 		= 32,
	parameter FILTER_BUFFER_ADDR_WIDTH	= 5,
	parameter CUTOFF_2 						= 32'h43100000,							// (12^2=144 in IEEE floating point)
	// Force Evaluation parameters
	parameter SEGMENT_NUM					= 14,
	parameter SEGMENT_WIDTH					= 4,
	parameter BIN_NUM							= 256,
	parameter BIN_WIDTH						= 8,
	parameter LOOKUP_NUM						= SEGMENT_NUM * BIN_NUM,				// SEGMENT_NUM * BIN_NUM
	parameter LOOKUP_ADDR_WIDTH			= SEGMENT_WIDTH + BIN_WIDTH			// log LOOKUP_NUM / log 2
)
(
	input clock,
	input resetn,
	// OpenCL ports
	input ivalid,						// Connect to upstream
	input iready,						// Connect to downstream
	output ovalid,						// Connect to downstream
	output oready,						//	Connect to upstream
	// Data ports
/*	
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
	output [DATA_WIDTH-1:0] out_LJ_Force_X,
	output [DATA_WIDTH-1:0] out_LJ_Force_Y,
	output [DATA_WIDTH-1:0] out_LJ_Force_Z
*/	
	input [2*DATA_WIDTH-1:0] in_particle_id,
	input [4*DATA_WIDTH-1:0] in_reference_pos,
	input [4*DATA_WIDTH-1:0] in_neighbor_pos,
//	output [2*DATA_WIDTH-1:0] out_particle_id,
	output [4*DATA_WIDTH-1:0] out_forceoutput
);
	
	//// Dummy output
	assign out_forceoutput[4*DATA_WIDTH-1:3*DATA_WIDTH] = 0;
	wire [2*DATA_WIDTH-1:0] out_particle_id;

	//////////////////////////////////////////////////////////////////////////////////////////////////
	// OpenCL Input & Output Remapping
	//////////////////////////////////////////////////////////////////////////////////////////////////
	wire [PARTICLE_ID_WIDTH-1:0] in_ref_particle_id;
	wire [PARTICLE_ID_WIDTH-1:0] in_neighbor_particle_id;
	wire [DATA_WIDTH-1:0] in_refx;
	wire [DATA_WIDTH-1:0] in_refy;
	wire [DATA_WIDTH-1:0] in_refz;
	wire [DATA_WIDTH-1:0] in_neighborx;
	wire [DATA_WIDTH-1:0] in_neighbory;
	wire [DATA_WIDTH-1:0] in_neighborz;
	wire [PARTICLE_ID_WIDTH-1:0] out_ref_particle_id;
	wire [PARTICLE_ID_WIDTH-1:0] out_neighbor_particle_id;
	wire [DATA_WIDTH-1:0] out_LJ_Force_X;
	wire [DATA_WIDTH-1:0] out_LJ_Force_Y;
	wire [DATA_WIDTH-1:0] out_LJ_Force_Z;
	
	assign in_ref_particle_id = in_particle_id[PARTICLE_ID_WIDTH+DATA_WIDTH-1:DATA_WIDTH];
	assign in_neighbor_particle_id = in_particle_id[PARTICLE_ID_WIDTH-1:0];
	assign in_refx = in_reference_pos[1*DATA_WIDTH-1:0*DATA_WIDTH];
	assign in_refy = in_reference_pos[2*DATA_WIDTH-1:1*DATA_WIDTH];
	assign in_refz = in_reference_pos[3*DATA_WIDTH-1:2*DATA_WIDTH];
	assign in_neighborx = in_neighbor_pos[1*DATA_WIDTH-1:0*DATA_WIDTH];
	assign in_neighbory = in_neighbor_pos[2*DATA_WIDTH-1:1*DATA_WIDTH];
	assign in_neighborz = in_neighbor_pos[3*DATA_WIDTH-1:2*DATA_WIDTH];
	assign out_particle_id[PARTICLE_ID_WIDTH+DATA_WIDTH-1:DATA_WIDTH] = out_ref_particle_id;
	assign out_particle_id[PARTICLE_ID_WIDTH-1:0] = out_neighbor_particle_id;
	assign out_forceoutput[1*DATA_WIDTH-1:0*DATA_WIDTH] = out_LJ_Force_X;
	assign out_forceoutput[2*DATA_WIDTH-1:1*DATA_WIDTH] = out_LJ_Force_Y;
	assign out_forceoutput[3*DATA_WIDTH-1:2*DATA_WIDTH] = out_LJ_Force_Z;

	wire clk;
	wire rst;
	assign clk = clock;
	assign rst = ~resetn;

	
	//////////////////////////////////////////////////////////////////////////////////////////////////
	// Signals Defination
	//////////////////////////////////////////////////////////////////////////////////////////////////
	//// Input buffer control signal
	wire filter_back_pressure;
	wire [INPUT_BUFFER_ADDR_WIDTH-1:0] in_buffer_usedw;
	wire in_buffer_empty;
	wire in_buffer_full;
	wire in_buffer_rd_en;
	wire in_buffer_wr_en;
	// When input is valid & input buffer has space, enable buffer write
//	assign in_buffer_wr_en = ivalid && ~in_buffer_full;
	assign in_buffer_wr_en = ivalid && (in_buffer_usedw < (INPUT_BUFFER_DEPTH-2));
	// When there's data inside input buffer & filter is ready to take data, enable buffer read
	assign in_buffer_rd_en = ~filter_back_pressure && ~in_buffer_empty;
	reg filter_input_valid;
	// One cycle delay between read enable is assigned and data is read out
	always@(posedge clk)
		begin
		filter_input_valid <= in_buffer_rd_en;
		end
	
	//// Output buffer signal
	wire [OUTPUT_BUFFER_ADDR_WIDTH-1:0] out_buffer_usedw;
	wire out_buffer_empty;
	wire out_buffer_full;
	wire out_buffer_rd_en;
	// When there's data in output buffer & Downstream module is ready to take data, enable output buffer read
	assign out_buffer_rd_en = (~out_buffer_empty && iready);
	
	//// Signals from Input buffer to Filter_Logic
	wire [PARTICLE_ID_WIDTH-1:0] in_buffer_to_filter_ref_particle_id;
	wire [PARTICLE_ID_WIDTH-1:0] in_buffer_to_filter_neighbor_particle_id;
	wire [DATA_WIDTH-1:0] in_buffer_to_filter_refx;
	wire [DATA_WIDTH-1:0] in_buffer_to_filter_refy;
	wire [DATA_WIDTH-1:0] in_buffer_to_filter_refz;
	wire [DATA_WIDTH-1:0] in_buffer_to_filter_neighborx;
	wire [DATA_WIDTH-1:0] in_buffer_to_filter_neighbory;
	wire [DATA_WIDTH-1:0] in_buffer_to_filter_neighborz;
	
	//// Signals from Filter_Logic to Pipeline
	wire [DATA_WIDTH-1:0] filter_to_pipeline_r2;
	wire [DATA_WIDTH-1:0] filter_to_pipeline_dx;
	wire [DATA_WIDTH-1:0] filter_to_pipeline_dy;
	wire [DATA_WIDTH-1:0] filter_to_pipeline_dz;
	
	//// Signals from Pipeline to Output Buffer
	wire [DATA_WIDTH-1:0] pipeline_to_out_buffer_LJ_Force_X;
	wire [DATA_WIDTH-1:0] pipeline_to_out_buffer_LJ_Force_Y;
	wire [DATA_WIDTH-1:0] pipeline_to_out_buffer_LJ_Force_Z;
	wire out_buffer_wr_en;
	
	//// Filter output buffer control signal
	wire filter_buffer_rd_en;
	wire filter_buffer_data_available;
	// Enable input to pipeline when there's data in filter buffer & enough space in output buffer
	assign filter_buffer_rd_en = (filter_buffer_data_available && (OUTPUT_BUFFER_DEPTH - out_buffer_usedw >= 14)) ? 1'b1 : 1'b0;
	reg filter_output_valid;
	// One cycle delay between read enable is assigned and data is read out
	always@(posedge clk)
		begin
		filter_output_valid <= filter_buffer_rd_en;
		end
	
	//// Assign parameters for A, B, QQ (currently not used)
	wire [DATA_WIDTH-1:0] p_a;
	wire [DATA_WIDTH-1:0] p_b;
	wire [DATA_WIDTH-1:0] p_qq;
	assign p_a  = 32'h40000000;				// p_a = 2, in IEEE floating point format
	assign p_b  = 32'h40800000;				// p_b = 4, in IEEE floating point format
	assign p_qq = 32'h41000000;				// p_qq = 8, in IEEE floating point format

	//////////////////////////////////////////////////////////////////////////////////////////////////
	// OpenCL Control Signal Assignment
	//////////////////////////////////////////////////////////////////////////////////////////////////
	reg ovalid_reg;
	// One cycle delay between read enable and valid data readout from Output buffer
	always@(posedge clk)
		begin
		ovalid_reg <= out_buffer_rd_en;
		end
	// Assign output ports
	assign ovalid = ovalid_reg;
//	assign oready = ~in_buffer_full;					// As long as there are available space in input buffer, always ready to take input from Upstream module
	assign oready = (in_buffer_usedw < (INPUT_BUFFER_DEPTH-2)) ? 1'b1 : 1'b0;			// When the filter buffer has not enough space to hold incoming data, then stop receiving incoming data
	//////////////////////////////////////////////////////////////////////////////////////////////////
	// Delay registers for particle IDs from filter logic to force output
	//////////////////////////////////////////////////////////////////////////////////////////////////
	wire [PARTICLE_ID_WIDTH-1:0] filter_logic_out_ref_particle_id;
	wire [PARTICLE_ID_WIDTH-1:0] filter_logic_out_neighbor_particle_id;
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
	reg [PARTICLE_ID_WIDTH-1:0] neighbor_particle_id_delayed;
	// Delay register
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
			neighbor_particle_id_delayed <= 0;
			end
		else
			begin
			ref_particle_id_reg0 <= filter_logic_out_ref_particle_id;
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
			ref_particle_id_delayed <= ref_particle_id_reg12;
			neighbor_particle_id_reg0 <= filter_logic_out_neighbor_particle_id;
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
			neighbor_particle_id_delayed <= neighbor_particle_id_reg12;
			end
		end
	
	//////////////////////////////////////////////////////////////////////////////
	// Input & Output buffer for interacting with the OpenCL ports
	//////////////////////////////////////////////////////////////////////////////
	FIFO
	#(
		.DATA_WIDTH(2*PARTICLE_ID_WIDTH+6*DATA_WIDTH),			// hold ref_id, neighbor_id, refx, refy, refz, neighborx, neighbory, neighborz
		.FIFO_DEPTH(INPUT_BUFFER_DEPTH),
		.FIFO_ADDR_WIDTH(INPUT_BUFFER_ADDR_WIDTH)					// log(FILTER_BUFFER_DEPTH) / log 2
	)
	Input_Buffer
	(
		 .clock(clk),
		 .data({in_ref_particle_id, in_neighbor_particle_id, in_refx, in_refy, in_refz, in_neighborx, in_neighbory, in_neighborz}),
		 .rdreq(in_buffer_rd_en),
		 .wrreq(in_buffer_wr_en),
		 .empty(in_buffer_empty),
		 .full(in_buffer_full),
		 .q({in_buffer_to_filter_ref_particle_id, in_buffer_to_filter_neighbor_particle_id, in_buffer_to_filter_refx, in_buffer_to_filter_refy, in_buffer_to_filter_refz, in_buffer_to_filter_neighborx, in_buffer_to_filter_neighbory, in_buffer_to_filter_neighborz}),
		 .usedw(in_buffer_usedw)
	);
	
	FIFO
	#(
		.DATA_WIDTH(2*PARTICLE_ID_WIDTH+3*DATA_WIDTH),				// hold ref_id, neighbor_id, LJ_Force_X, LJ_Force_Y, LJ_Force_Z
		.FIFO_DEPTH(OUTPUT_BUFFER_DEPTH),
		.FIFO_ADDR_WIDTH(OUTPUT_BUFFER_ADDR_WIDTH)					// log(FILTER_BUFFER_DEPTH) / log 2
	)
	Output_Buffer
	(
		 .clock(clk),
		 .data({ref_particle_id_delayed, neighbor_particle_id_delayed, pipeline_to_out_buffer_LJ_Force_X, pipeline_to_out_buffer_LJ_Force_Y, pipeline_to_out_buffer_LJ_Force_Z}),
		 .rdreq(out_buffer_rd_en),
		 .wrreq(out_buffer_wr_en),
		 .empty(out_buffer_empty),
		 .full(out_buffer_full),
		 .q({out_ref_particle_id, out_neighbor_particle_id, out_LJ_Force_X, out_LJ_Force_Y, out_LJ_Force_Z}),
		 .usedw(out_buffer_usedw)
	);
	
	
	//////////////////////////////////////////////////////////////////////////////
	// Filtering logic
	//////////////////////////////////////////////////////////////////////////////
	Filter_Logic
	#(
		.DATA_WIDTH(DATA_WIDTH),
		.PARTICLE_ID_WIDTH(PARTICLE_ID_WIDTH),
		.FILTER_BUFFER_DEPTH(FILTER_BUFFER_DEPTH),
		.FILTER_BUFFER_ADDR_WIDTH(FILTER_BUFFER_ADDR_WIDTH),
		.CUTOFF_2(CUTOFF_2)
	)
	Filter
	(
		.clk(clk),
		.rst(rst),
		// Input
		.input_valid(filter_input_valid),
		.ref_particle_id(in_buffer_to_filter_ref_particle_id),
		.neighbor_particle_id(in_buffer_to_filter_neighbor_particle_id),
		.refx(in_buffer_to_filter_refx),
		.refy(in_buffer_to_filter_refy),
		.refz(in_buffer_to_filter_refz),
		.neighborx(in_buffer_to_filter_neighborx),
		.neighbory(in_buffer_to_filter_neighbory),
		.neighborz(in_buffer_to_filter_neighborz),
		// Output
		.ref_particle_id_out(filter_logic_out_ref_particle_id),
		.neighbor_particle_id_out(filter_logic_out_neighbor_particle_id),
		.r2(filter_to_pipeline_r2),
		.dx(filter_to_pipeline_dx),
		.dy(filter_to_pipeline_dy),
		.dz(filter_to_pipeline_dz),
		// Connect to filter arbiter
		.sel(filter_buffer_rd_en),
		.particle_pair_available(filter_buffer_data_available),
		// Connect to input generator
		.filter_back_pressure(filter_back_pressure)								// Buffer should have enough space to store 17 pairs after the input stop coming
	);

	//////////////////////////////////////////////////////////////////////////////
	// Force evaluation pipeline
	//////////////////////////////////////////////////////////////////////////////
	RL_LJ_Evaluate_Pairs_1st_Order
	#(
		.DATA_WIDTH(DATA_WIDTH),
		.SEGMENT_NUM(SEGMENT_NUM),
		.SEGMENT_WIDTH(SEGMENT_WIDTH),
		.BIN_NUM(BIN_NUM),
		.BIN_WIDTH(BIN_WIDTH),
		.CUTOFF_2(CUTOFF_2),
		.LOOKUP_NUM(LOOKUP_NUM),
		.LOOKUP_ADDR_WIDTH(LOOKUP_ADDR_WIDTH)
	)
	LJ_Pipeline
	(
		.clk(clk),
		.rst(rst),
		// Input
		.r2_valid(filter_output_valid),
		.r2(filter_to_pipeline_r2),
		.dx(filter_to_pipeline_dx),
		.dy(filter_to_pipeline_dy),
		.dz(filter_to_pipeline_dz),
		.p_a(p_a),
		.p_b(p_b),
		.p_qq(p_qq),
		// Output
		.LJ_Force_X(pipeline_to_out_buffer_LJ_Force_X),
		.LJ_Force_Y(pipeline_to_out_buffer_LJ_Force_Y),
		.LJ_Force_Z(pipeline_to_out_buffer_LJ_Force_Z),
		.LJ_force_valid(out_buffer_wr_en)
	);


endmodule