`timescale 1ns/1ns

module Force_Writeback_Arbitration_Unit_tb;

	parameter BINARY_222							= 9'b010010010;
	parameter BINARY_223							= 9'b010010011;
	parameter BINARY_231							= 9'b010011001;
	parameter BINARY_232							= 9'b010011010;
	parameter BINARY_233							= 9'b010011011;
	parameter BINARY_311							= 9'b011001001;
	parameter BINARY_312							= 9'b011001010;
	parameter BINARY_313							= 9'b011001011;
	parameter BINARY_321							= 9'b011010001;
	parameter BINARY_322							= 9'b011010010;
	parameter BINARY_323							= 9'b011010011;
	parameter BINARY_331							= 9'b011011001;
	parameter BINARY_332							= 9'b011011010;
	parameter BINARY_333							= 9'b011011011;
	parameter NUM_PIPELINES						= 16;
	parameter DATA_WIDTH							= 32;
	parameter CELL_ID_WIDTH						= 3;
	parameter CELL_ADDR_WIDTH					= 7;
	parameter TOTAL_CELL_NUM					= 64;
	parameter PARTICLE_ID_WIDTH				= CELL_ID_WIDTH*3+CELL_ADDR_WIDTH;
	parameter FORCE_WTADDR_ARBITER_SIZE		= 6;
	parameter FORCE_WTADDR_ARBITER_MSB		= 32;
	parameter FORCE_EVAL_FIFO_DATA_WIDTH	= 113;
	
	reg clk;
	reg rst;
	reg [NUM_PIPELINES*FORCE_EVAL_FIFO_DATA_WIDTH-1:0] ref_force_data_from_FIFO;
	reg [NUM_PIPELINES*FORCE_EVAL_FIFO_DATA_WIDTH-1:0] neighbor_force_data_from_FIFO_1;
	reg [NUM_PIPELINES*FORCE_EVAL_FIFO_DATA_WIDTH-1:0] neighbor_force_data_from_FIFO_2;
	reg [NUM_PIPELINES-1:0] ref_force_valid;
	reg [NUM_PIPELINES-1:0] neighbor_force_valid_1;
	reg [NUM_PIPELINES-1:0] neighbor_force_valid_2;
	reg [CELL_ID_WIDTH-1:0] cellz;
	
	wire [NUM_PIPELINES-1:0] ref_force_write_success;
	wire [NUM_PIPELINES-1:0] neighbor_force_write_success_1;
	wire [NUM_PIPELINES-1:0] neighbor_force_write_success_2;
	wire [TOTAL_CELL_NUM*FORCE_EVAL_FIFO_DATA_WIDTH-1:0] valid_force_values;
	
	always #1 clk <= ~clk;
	
	
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
		.FORCE_EVAL_FIFO_DATA_WIDTH(FORCE_EVAL_FIFO_DATA_WIDTH)
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
		.cellz(cellz),
		
		.ref_force_write_success(ref_force_write_success),
		.neighbor_force_write_success_1(neighbor_force_write_success_1),
		.neighbor_force_write_success_2(neighbor_force_write_success_2),
		.valid_force_values(valid_force_values)
	};
	
endmodule
