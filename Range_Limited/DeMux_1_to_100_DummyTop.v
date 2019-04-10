module DeMux_1_to_100_DummyTop
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
	output reg [DATA_WIDTH-1:0] out_data,
	output [NUM_OUTPUT_PORTS-1:0] out_valid,
	input [4:0] in_dummy_ram_wr_addr,
	input [9:0] in_dummy_ram_rd_addr
);

	wire [NUM_OUTPUT_PORTS*DATA_WIDTH-1:0] wire_mux_out_to_mem;
	wire [383:0] wire_mem_readout_data;
	reg [95:0] temp1, temp2;

	DeMux_Tree
	#(
		.DATA_WIDTH(DATA_WIDTH),
		.NUM_OUTPUT_PORTS(NUM_OUTPUT_PORTS),
		.SEL_DIWTH(SEL_DIWTH)
	)
	UUT
	(
		.clk(clk),
		.rst(rst),
		.in_data(in_data),
		.in_valid(in_valid),
		.in_sel(in_sel),
		.out_data(wire_mux_out_to_mem),
		.out_valid(out_valid)
	);
	
	
	RAM_DualPort Dummy_RAM (
		.data      (wire_mux_out_to_mem),      //   input,  width = 12288,  ram_input.datain
		.wraddress (in_dummy_ram_wr_addr), //   input,      width = 5,           .wraddress
		.rdaddress (in_dummy_ram_rd_addr), //   input,      width = 7,           .rdaddress
		.wren      (1'b1),      //   input,      width = 1,           .wren
		.clock     (clk),     //   input,      width = 1,           .clock
		.q         (wire_mem_readout_data)          //  output,   width = 3072, ram_output.dataout
	);
	
	always@(posedge clk)
		begin
		temp1 <= wire_mem_readout_data[95:0] & wire_mem_readout_data[191:96];
		temp2 <= wire_mem_readout_data[287:192] ^ wire_mem_readout_data[383:288];
		out_data <= temp1 | temp2;
		end

endmodule