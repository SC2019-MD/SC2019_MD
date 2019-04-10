module DeMux_Tree
#(
	parameter DATA_WIDTH = 32*3,
	parameter NUM_OUTPUT_PORTS = 128,
	parameter SEL_DIWTH = 7
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
	
	always@(posedge clk)
		begin
		if(rst)
			sel_bit <= 0;
		else
			sel_bit <= 1'b1 << in_sel;
		end
	
	genvar i;
	generate
		for(i=0; i < NUM_OUTPUT_PORTS; i=i+1) begin:demux_logic
			always@(posedge clk)
				begin
				if(rst)
					begin
					out_data[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH] <= 0;
					out_valid[i] <= 1'b0;
					end
				else
					begin
					//out_data[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH] <= in_data && {(96){sel_bit[i]}};
					out_valid[i] <= sel_bit[i] & in_valid;
					if(sel_bit[i] == 1'b1)
						out_data[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH] <= in_data;
					else
						out_data[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH] <= 0;
					end
				end
		end
	endgenerate
	
	
	

endmodule