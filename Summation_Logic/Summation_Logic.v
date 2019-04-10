/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: Summation_Logic.v
//
// Function: 
//				Perform Summation of 3 MD forces: Short Range, Long Range, and Bonded Force
//				A scoreboarding mechanism is implemented to start evaluation on cells right after the short range force evaluation is done on that cell
// 				Controls the force read on Short Range, Long Range, and Bonded Force caches
//				The summed up force is send to Motion Update Unit immediately
//
// Data Organization:
//				
//
// Used by:
//				RL_Top.v
//
// Dependency:
//				Score_Board.v
//				FSM_access.v
//				Ready_Buffer.v
//				Force_Summation_Unit.v
//
// Testbench:
//				_tb.v
//
// Timing:
//				TBD
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module Summation_Logic
#(
	parameter DATA_WIDTH 					= 32,
	parameter TOTAL_PARTICLE_NUM 			= 20000,
	parameter PARTICLE_GLOBAL_ID_WIDTH 	= 15,											// log(TOTAL_PARTICLE_NUM)/log(2)
	parameter NUM_CELL_X 					= 5,
	parameter NUM_CELL_Y 					= 5,
	parameter NUM_CELL_Z 					= 5,
	parameter NUM_TOTAL_CELL 				= NUM_CELL_X * NUM_CELL_Y * NUM_CELL_Z
)
(
	input clk,
	input rst,
	input [NUM_TOTAL_CELL-1:0] cell_done_from_pipeline,
	output [3*DATA_WIDTH-1:0] force_summed_to_motion_update,
	output [NUM_TOTAL_CELL-1:0] read_request_to_force_cache,
	output [PARTICLE_GLOBAL_ID_WIDTH-1:0] read_address_to_force_cache,
	output [NUM_TOTAL_CELL-1:0] read_cell_id,
	input [3*DATA_WIDTH-1:0] force_from_force_cache_lr,
	input [3*DATA_WIDTH-1:0] force_from_force_cache_sr,
	input [3*DATA_WIDTH-1:0] force_from_force_cache_bf,
	input force_valid_from_force_cache,
	input [PARTICLE_GLOBAL_ID_WIDTH-1:0] gid_in,
	output [PARTICLE_GLOBAL_ID_WIDTH-1:0] gid_out,
	output valid_sum
);
    
    wire [NUM_TOTAL_CELL-1:0] ready_to_sum;
    wire [15:0] cell_id_to_sum;
    Scoreboard
	 #(
		.NUM_TOTAL_CELL(NUM_TOTAL_CELL)
	 )
	 Scoreboard
	 (
		 .clk(clk),
		 .rst(rst),
		 .cell_done(cell_done_from_pipeline),
		 .ready_to_sum(ready_to_sum)
	 );
    wire valid_out_to_FSM;
    wire resume;
    Ready_Buffer
	 #(
		.NUM_TOTAL_CELL(NUM_TOTAL_CELL)
	 )
	 Ready_Buffer
	 (
		 .clk(clk),
		 .rst(rst),
		 .ready_to_sum(ready_to_sum),
		 .cell_id_to_sum(cell_id_to_sum),
		 .valid_out(valid_out_to_FSM),
		 .resume(resume)
	 );
    wire valid_out_to_adder;
	 
    FSM_Access
	 #(
		.DATA_WIDTH(DATA_WIDTH),
		.TOTAL_PARTICLE_NUM(TOTAL_PARTICLE_NUM),
		.PARTICLE_GLOBAL_ID_WIDTH(PARTICLE_GLOBAL_ID_WIDTH),
		.NUM_CELL_X(NUM_CELL_X),
		.NUM_CELL_Y(NUM_CELL_Y),
		.NUM_CELL_Z(NUM_CELL_Z),
		.NUM_TOTAL_CELL(NUM_TOTAL_CELL)
	 )
	 FSM
	 (
		 .clk(clk),
		 .rst(rst),
		 .cell_id_to_sum(cell_id_to_sum),
		 .cell_id_access_valid(valid_out_to_FSM),
		 .number_of_partical(force_from_force_cache_bf),
		 .access_address(read_address_to_force_cache),
		 .cell_id(read_cell_id),
		 .rd_en(read_request_to_force_cache),
		 .resume(resume),
		 .valid_in(force_valid_from_force_cache),
		 .valid_out_to_adder(valid_out_to_adder)
	 );
    
    reg valid_out_to_adder_d; reg valid_out_to_adder_2d;
    always @(posedge clk)
		 begin
		 if (rst)
			 begin
				  valid_out_to_adder_d <= 0;
				  valid_out_to_adder_2d <= 0;
			 end
		 else
			 begin
				  valid_out_to_adder_d <= valid_out_to_adder;
				  valid_out_to_adder_2d <= valid_out_to_adder_d;
			 end
		 end
	 
	 
	 // Force Summation
    Force_Summation_Unit
	 #(
		.DATA_WIDTH(DATA_WIDTH)
	 )
	 Force_Summation_Unit
	 (
		 .clk(clk),
		 .rst(rst),
		 .valid_in(valid_out_to_adder_2d),
		 .force_to_sum_from_lr(force_from_force_cache_lr),
		 .force_to_sum_from_sr(force_from_force_cache_sr),
		 .force_to_sum_from_bf(force_from_force_cache_bf),
		 .out_Sumed_Force(force_summed_to_motion_update),
		 .valid_out(valid_sum)
	 );

    assign gid_out = gid_in;
    
endmodule
