/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: Mux_4_to_1.v
//
//	Function: 
//				Mux used to construct reduction tree for very large muxes
//
// Data Organization:
//				TBD
//
// Used by:
//				TBD
//
// Dependency:
//				N/A
//
// Testbench:
//				TBD
//
// Timing:
//				1 cycle				
//
// Created by: 
//				Chen Yang 01/01/2019
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module Mux_4_to_1
#(
	parameter DATA_WIDTH 		= 32*3,
	parameter NUM_INPUT_PORTS	= 4,
	parameter SEL_DIWTH 			= 2				// log(NUM_INPUT_PORTS) / log(2)
)
(
	input clk,
	input rst,
	input [SEL_DIWTH-1:0] sel,
	input [NUM_INPUT_PORTS-1:0] in_valid,
	input [NUM_INPUT_PORTS*DATA_WIDTH-1:0] in,
	output reg [DATA_WIDTH-1:0] out,
	output reg out_valid
);
	
	reg [NUM_INPUT_PORTS*DATA_WIDTH-1:0] in_reg;

	always@(posedge clk)
		begin
		in_reg <= in;
		if(rst)
			begin
			out <= 0;
			out_valid <= 1'b0;
			end
		else
			begin
			case(sel)
				0:
					begin
					out <= in_reg[1*DATA_WIDTH-1:0*DATA_WIDTH];
					out_valid <= in_valid[0];
					end
				1:
					begin
					out <= in_reg[2*DATA_WIDTH-1:1*DATA_WIDTH];
					out_valid <= in_valid[1];
					end
				2:
					begin
					out <= in_reg[3*DATA_WIDTH-1:2*DATA_WIDTH];
					out_valid <= in_valid[2];
					end
				3:
					begin
					out <= in_reg[4*DATA_WIDTH-1:3*DATA_WIDTH];
					out_valid <= in_valid[3];
					end

				default:
					begin
					out <= in_reg[1*DATA_WIDTH-1:0*DATA_WIDTH];
					out_valid <= in_valid[0];
					end
			endcase
			end
		end


endmodule