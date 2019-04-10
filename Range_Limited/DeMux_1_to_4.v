/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: DeMux_1_to_4.v
//
//	Function: 
//				DeMux used to construct reduction tree for very large muxes
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
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module DeMux_1_to_4
#(
	parameter DATA_WIDTH 		= 32*3,
	parameter NUM_OUTPUT_PORTS	= 4,
	parameter SEL_DIWTH 			= 2				// log(NUM_INPUT_PORTS) / log(2)
)
(
	input clk,
	input rst,
	input [SEL_DIWTH-1:0] sel,
	input in_valid,
	input [DATA_WIDTH-1:0] in,
	output reg [NUM_OUTPUT_PORTS*DATA_WIDTH-1:0] out,
	output reg [NUM_OUTPUT_PORTS-1:0] out_valid
);

	always@(posedge clk)
		begin
		if(rst)
			begin
			out <= 0;
			out_valid <= 0;
			end
		else
			begin
			case(sel)
				0:
					begin
					out[1*DATA_WIDTH-1:0*DATA_WIDTH] <= in;
					out_valid[0] <= in_valid;
					end
				1:
					begin
					out[2*DATA_WIDTH-1:1*DATA_WIDTH] <= in;
					out_valid[1] <= in_valid;
					end
				2:
					begin
					out[3*DATA_WIDTH-1:2*DATA_WIDTH] <= in;
					out_valid[2] <= in_valid;
					end
				3:
					begin
					out[4*DATA_WIDTH-1:3*DATA_WIDTH] <= in;
					out_valid[3] <= in_valid;
					end
				default:
					begin
					out[1*DATA_WIDTH-1:0*DATA_WIDTH] <= in;
					out_valid[0] <= in_valid;
					end
			endcase
			end
		end


endmodule