/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Module: DeMux_Tree.v
//
// Function: 
//				
//
// Data Organization:
//				
//
// Used by:
//				N/A
//
// Dependency:
//				N/A
//
// Testbench:
//				_tb.v
//
// Timing:
//				TBD
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module DeMux_Tree
#(
	parameter DATA_WIDTH = 32*3,
	parameter NUM_OUTPUT_PORTS = 128,
	parameter SEL_DIWTH = $clog2(NUM_OUTPUT_PORTS)
)
(
	input clk,
	input rst,
	input [DATA_WIDTH-1:0] in_data,
	input in_valid,
	input [SEL_DIWTH-1:0] in_sel,
	output reg [NUM_OUTPUT_PORTS*DATA_WIDTH-1:0] out_data,
	output reg [NUM_OUTPUT_PORTS-1:0] out_valid
);

	reg [NUM_OUTPUT_PORTS-1:0] sel_bit;
	reg [DATA_WIDTH-1:0] in_data_d;
	
	always@(posedge clk)
		begin
		if(rst)
			sel_bit <= 0;
		else if (in_valid)
		    sel_bit <= 1'b1 << in_sel;
		else
			sel_bit <= 0;
		end

    always@(posedge clk)
		begin
		if(rst)
		begin
			in_data_d <= 0;
			out_valid <= 0;
		end
		else
		begin
			in_data_d <= in_data;
			out_valid <= sel_bit;
		end
		end
	
	genvar i;
	generate
		for(i=0; i < NUM_OUTPUT_PORTS; i=i+1) begin:demux_logic
			always@(posedge clk)
				begin
				if(rst)
					begin
					out_data[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH] <= 0;
					end
				else
					begin
					//out_data[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH] <= in_data && {(96){sel_bit[i]}};
					if(sel_bit[i] == 1'b1)
						out_data[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH] <= in_data_d;
					else
						out_data[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH] <= 0;
					end
				end
		end
	endgenerate
	
	
	

endmodule